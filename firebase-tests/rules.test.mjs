import { readFileSync } from 'node:fs';
import { after, before, test } from 'node:test';
import { initializeTestEnvironment, assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { doc, setDoc, getDoc, deleteDoc, serverTimestamp, writeBatch } from 'firebase/firestore';
import { ref, uploadBytes } from 'firebase/storage';

let environment;
before(async () => {
  environment = await initializeTestEnvironment({
    projectId: 'demo-nalara',
    firestore: { host: '127.0.0.1', port: 8085, rules: readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8') },
    storage: { host: '127.0.0.1', port: 9195, rules: readFileSync(new URL('../storage.rules', import.meta.url), 'utf8') },
  });
});
after(async () => { await environment?.cleanup(); });

test('owners can save profiles; guests and other accounts cannot read them', async () => {
  const owner = environment.authenticatedContext('owner').firestore();
  await assertSucceeds(setDoc(doc(owner, 'users/owner'), { name: 'Pemilik', paymentMethods: { Tunai: true } }));
  await assertSucceeds(getDoc(doc(owner, 'users/owner')));
  await assertFails(getDoc(doc(environment.unauthenticatedContext().firestore(), 'users/owner')));
  await assertFails(getDoc(doc(environment.authenticatedContext('other').firestore(), 'users/owner')));
  await assertFails(setDoc(doc(owner, 'users/other'), { name: 'Other' }));
});

test('clients cannot grant unbounded premium or write arbitrary profile fields', async () => {
  const owner = environment.authenticatedContext('owner').firestore();
  await assertFails(setDoc(doc(owner, 'users/owner/subscription/current'), { status: 'active' }));
  await assertFails(setDoc(doc(owner, 'users/owner'), { premium: true }));
});

test('demo activation is owner-only, starts at server time and cannot extend an active period', async () => {
  const owner = environment.authenticatedContext('demo-owner').firestore();
  const path = 'users/demo-owner/subscription/current';
  const data = { source: 'demo', status: 'active', startedAt: serverTimestamp(), periodDays: 30 };
  await assertFails(setDoc(doc(environment.unauthenticatedContext().firestore(), path), data));
  await assertFails(setDoc(doc(environment.authenticatedContext('other').firestore(), path), data));
  await assertFails(setDoc(doc(owner, path), { ...data, periodDays: 365 }));
  await assertFails(setDoc(doc(owner, path), { ...data, startedAt: new Date(Date.now() + 86400000) }));
  await assertFails(setDoc(doc(owner, path), { ...data, expiresAt: new Date(Date.now() + 365 * 86400000) }));
  await assertFails(setDoc(doc(owner, 'users/demo-owner/subscription/other'), data));
  await assertSucceeds(setDoc(doc(owner, path), data));
  await assertSucceeds(getDoc(doc(owner, path)));
  await assertFails(setDoc(doc(owner, path), data));
  await assertFails(deleteDoc(doc(owner, path)));

  await environment.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), path), {
      ...data, startedAt: new Date(Date.now() - 31 * 86400000),
    });
  });
  await assertSucceeds(setDoc(doc(owner, path), data));
});

test('profile email must match the authenticated account and preserve store updates', async () => {
  const owner = environment.authenticatedContext('google-owner', { email: 'owner@example.com' }).firestore();
  const profile = doc(owner, 'users/google-owner');
  await assertSucceeds(setDoc(profile, { name: 'Pemilik', email: 'owner@example.com', updatedAt: serverTimestamp() }));
  await assertSucceeds(setDoc(profile, { storeName: 'Toko Saya' }, { merge: true }));
  await assertFails(setDoc(profile, { email: 'someone-else@example.com' }, { merge: true }));
  await assertFails(setDoc(profile, { email: 123 }, { merge: true }));
  await assertFails(getDoc(doc(environment.authenticatedContext('other').firestore(), 'users/google-owner')));
});

test('products require valid stock, price and server time', async () => {
  const owner = environment.authenticatedContext('owner').firestore();
  const data = { name: 'Produk', price: 100, cost: 40, stock: 5, minimumStock: 1, category: 'Minuman', active: true, favorite: false, sold: 0, photoUrl: null, updatedAt: serverTimestamp() };
  await assertSucceeds(setDoc(doc(owner, 'users/owner/products/valid'), data));
  await assertFails(setDoc(doc(owner, 'users/owner/products/invalid'), { ...data, stock: -1 }));
  await assertFails(setDoc(doc(owner, 'users/other/products/invalid'), data));
});

test('receipts are immutable and support manual QRIS without cash', async () => {
  const owner = environment.authenticatedContext('owner').firestore();
  const data = { date: serverTimestamp(), method: 'Tunai', items: [{ productId: 'valid', name: 'Produk', price: 100, cost: 40, quantity: 1 }], discount: 0, points: 0, total: 100, cash: 100 };
  const receipt = doc(owner, 'users/owner/transactions/receipt');
  await assertSucceeds(setDoc(receipt, data));
  await assertFails(setDoc(receipt, { ...data, total: 1 }));
  await assertFails(deleteDoc(receipt));
  await assertFails(setDoc(doc(owner, 'users/owner/transactions/qris'), { ...data, method: 'QRIS' }));
  await assertSucceeds(setDoc(doc(owner, 'users/owner/transactions/qris'), { ...data, method: 'QRIS', cash: 0 }));
  await assertFails(setDoc(doc(owner, 'users/owner/transactions/transfer'), { ...data, method: 'Transfer Bank' }));
  await assertFails(setDoc(doc(owner, 'users/owner/transactions/short-cash'), { ...data, cash: 50 }));
  await assertFails(setDoc(doc(environment.authenticatedContext('other').firestore(), 'users/owner/transactions/other-qris'), { ...data, method: 'QRIS', cash: 0 }));
});

test('payment preferences allow only cash and manual QRIS with boolean values', async () => {
  const owner = environment.authenticatedContext('payment-owner').firestore();
  const profile = doc(owner, 'users/payment-owner');
  await assertSucceeds(setDoc(profile, { paymentMethods: { Tunai: true, QRIS: true } }));
  await assertSucceeds(setDoc(profile, { paymentMethods: { Tunai: false, QRIS: true } }));
  await assertFails(setDoc(profile, { paymentMethods: { QRIS: 'yes' } }));
  await assertFails(setDoc(profile, { paymentMethods: { 'Transfer Bank': true } }));
});

test('shifts require an atomic lock, permit one active shift, and preserve closed history', async () => {
  const owner = environment.authenticatedContext('shift-owner').firestore();
  const state = doc(owner, 'users/shift-owner/shiftState/current');
  const shift = doc(owner, 'users/shift-owner/shifts/first');
  const data = { cashier: 'Petugas', openingCash: 100000, startedAt: serverTimestamp(), endedAt: null, countedCash: null, note: '' };
  const start = (id, values = data) => {
    const batch = writeBatch(owner);
    batch.set(doc(owner, `users/shift-owner/shifts/${id}`), values);
    batch.set(state, { activeShiftId: id });
    return batch.commit();
  };
  await assertFails(setDoc(shift, data));
  await assertFails(setDoc(state, { activeShiftId: 'missing' }));
  await assertFails(start('invalid', { ...data, openingCash: -1 }));
  await assertFails(start('future', { ...data, startedAt: new Date(Date.now() + 86400000) }));
  await assertSucceeds(start('first'));
  await assertFails(start('second'));
  await assertFails(getDoc(doc(environment.authenticatedContext('other').firestore(), shift.path)));
  await assertFails(getDoc(doc(environment.unauthenticatedContext().firestore(), shift.path)));
  await assertFails(setDoc(shift, { openingCash: 0 }, { merge: true }));
  await assertFails(setDoc(state, { activeShiftId: null }));
  await assertFails(setDoc(shift, { endedAt: serverTimestamp(), countedCash: 100000 }, { merge: true }));
  const close = (cash = 100000, extra = {}) => {
    const batch = writeBatch(owner);
    batch.update(shift, { endedAt: serverTimestamp(), countedCash: cash, note: 'Selesai', ...extra });
    batch.set(state, { activeShiftId: null });
    return batch.commit();
  };
  await assertFails(close(-1));
  await assertFails(close(100000, { cashier: 'Changed' }));
  await assertSucceeds(close());
  await assertFails(setDoc(shift, { countedCash: 999 }, { merge: true }));
  await assertFails(deleteDoc(shift));
  await assertFails(deleteDoc(state));
  await assertFails(close());
  await assertSucceeds(start('second'));
  await assertSucceeds(getDoc(shift));
});

test('photos are scoped to their owner and reject non-image uploads', async () => {
  const storage = environment.authenticatedContext('owner').storage();
  await assertSucceeds(uploadBytes(ref(storage, 'users/owner/products/p/image'), new Uint8Array([1, 2]), { contentType: 'image/png' }));
  await assertFails(uploadBytes(ref(storage, 'users/other/products/p/image'), new Uint8Array([1, 2]), { contentType: 'image/png' }));
  await assertFails(uploadBytes(ref(storage, 'users/owner/products/p/file'), new Uint8Array([1, 2]), { contentType: 'text/plain' }));
});
