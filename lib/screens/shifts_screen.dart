import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../colors.dart';
import '../firebase_store.dart';
import '../products.dart' show productRupiah;
import '../session.dart';
import '../shifts.dart';
import '../transactions.dart';
import '../widgets/profile_components.dart';
import '../widgets/shift_history_components.dart';
import '../widgets/shift_summary_card.dart';
import '../rupiah_input.dart';

class ShiftsScreen extends StatefulWidget {
  const ShiftsScreen({super.key, this.repository});
  final ShiftRepository? repository;

  @override
  State<ShiftsScreen> createState() => _ShiftsScreenState();
}

class _ShiftsScreenState extends State<ShiftsScreen>
    with SingleTickerProviderStateMixin {
  late final _repository = widget.repository ?? ShiftRepository();
  late Stream<List<CashierShift>> _shifts = _repository.watch();
  late final _tabs = TabController(length: 2, vsync: this);
  DateTime _historyDate = DateUtils.dateOnly(DateTime.now());

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _pickDate(List<CashierShift> shifts) async {
    final today = DateUtils.dateOnly(DateTime.now());
    var firstDate = DateTime(2000);
    for (final shift in shifts) {
      if (shift.startedAt.isBefore(firstDate)) {
        firstDate = DateUtils.dateOnly(shift.startedAt);
      }
    }
    final date = await showDatePicker(
      context: context,
      initialDate: _historyDate,
      firstDate: firstDate,
      lastDate: today,
      helpText: 'Pilih Tanggal Riwayat',
      cancelText: 'Batal',
      confirmText: 'Terapkan',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.background,
            brightness: Brightness.light,
            surface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (mounted && date != null) setState(() => _historyDate = date);
  }

  Future<void> _form([CashierShift? shift]) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ShiftForm(repository: _repository, shift: shift),
    );
    if (!mounted || saved != true) return;
    if (shift != null) {
      setState(() => _historyDate = DateUtils.dateOnly(DateTime.now()));
      _tabs.animateTo(1);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          shift == null
              ? 'Shift berhasil dimulai.'
              : 'Shift ditutup. Ringkasan tersimpan di riwayat.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.surface,
    appBar: const ProfileHeader(title: 'Shift Kasir'),
    body: SafeArea(
      child: Column(
        children: [
          Material(
            color: AppColors.background,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TabBar(
                  controller: _tabs,
                  labelColor: AppColors.background,
                  unselectedLabelColor: const Color(0xFFD9E4FF),
                  labelStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'Shift Aktif'),
                    Tab(text: 'Riwayat Shift'),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<CashierShift>>(
              stream: _shifts,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            firebaseMessage(snapshot.error!),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: () =>
                                setState(() => _shifts = _repository.watch()),
                            child: const Text('Coba Lagi'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final shifts = snapshot.data!;
                final active = shifts
                    .where((shift) => shift.active)
                    .firstOrNull;
                return ListenableBuilder(
                  listenable: TransactionHistory.instance,
                  builder: (context, _) => TabBarView(
                    controller: _tabs,
                    children: [_activePage(active), _history(shifts)],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );

  Widget _activePage(CashierShift? active) => _page('active-shift', [
    Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                active == null ? 'Mulai hari dengan siap' : 'Ringkasan shift',
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                transactionDate(DateTime.now()),
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Icon(
            Icons.today_outlined,
            color: AppColors.background,
            size: 20,
          ),
        ),
      ],
    ),
    const SizedBox(height: 20),
    if (active == null) ...[
      ProfileCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            Center(
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: AppColors.softBlue,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Icon(
                  Icons.point_of_sale_rounded,
                  size: 44,
                  color: AppColors.background,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Belum ada shift aktif',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Siapkan modal kas, lalu mulai mencatat\npenjualan selama Anda bertugas.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 13,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _form(),
              style: _primaryButtonStyle,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Mulai Shift'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
      const SizedBox(height: 24),
      const Text(
        'Alur shift Anda',
        style: TextStyle(
          color: AppColors.ink,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 14),
      const _GuideStep(
        number: '01',
        title: 'Siapkan kas awal',
        description: 'Masukkan nama petugas dan modal kembalian.',
      ),
      const _GuideStep(
        number: '02',
        title: 'Catat penjualan',
        description: 'Transaksi tunai dan QRIS direkap otomatis.',
      ),
      const _GuideStep(
        number: '03',
        title: 'Cocokkan & tutup kas',
        description: 'Hitung uang di laci dan simpan hasil shift.',
      ),
    ] else ...[
      ShiftSummaryCard(shift: active),
      const SizedBox(height: 18),
      FilledButton.icon(
        onPressed: () => _form(active),
        style: _primaryButtonStyle,
        icon: const Icon(Icons.lock_outline_rounded, size: 19),
        label: const Text('Tutup Shift'),
      ),
      const SizedBox(height: 14),
      const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: AppColors.muted, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Kas seharusnya = modal awal + penjualan tunai setelah kembalian. QRIS tidak menambah kas di laci.',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 11,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    ],
  ]);

  Widget _page(String key, List<Widget> children) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 760),
      child: ListView(
        key: PageStorageKey(key),
        padding: const EdgeInsets.all(20),
        children: children,
      ),
    ),
  );

  Widget _history(List<CashierShift> shifts) {
    final today = DateUtils.dateOnly(DateTime.now());
    final isToday = DateUtils.isSameDay(_historyDate, today);
    final closed =
        shifts
            .where((shift) => DateUtils.isSameDay(shift.endedAt, _historyDate))
            .toList()
          ..sort((a, b) => b.endedAt!.compareTo(a.endedAt!));
    final events = <({CashierShift shift, DateTime time, bool opening})>[
      for (final shift in shifts) ...[
        if (DateUtils.isSameDay(shift.startedAt, _historyDate))
          (shift: shift, time: shift.startedAt, opening: true),
        if (DateUtils.isSameDay(shift.endedAt, _historyDate))
          (shift: shift, time: shift.endedAt!, opening: false),
      ],
    ]..sort((a, b) => b.time.compareTo(a.time));
    return _page('shift-history-${_historyDate.toIso8601String()}', [
      const Row(
        children: [
          Expanded(
            child: Text(
              'Riwayat harian',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 23,
                fontWeight: FontWeight.w800,
                letterSpacing: -.6,
              ),
            ),
          ),
          SizedBox(width: 12),
          Icon(Icons.history_rounded, color: AppColors.background, size: 26),
        ],
      ),
      const SizedBox(height: 6),
      const Text(
        'Ringkasan kas dan aktivitas shift Anda.',
        style: TextStyle(color: AppColors.muted, fontSize: 12),
      ),
      const SizedBox(height: 20),
      ProfileCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Hari sebelumnya',
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.softBlue,
                    foregroundColor: AppColors.background,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _historyDate.isAfter(DateTime(2000))
                      ? () => setState(
                          () => _historyDate = DateTime(
                            _historyDate.year,
                            _historyDate.month,
                            _historyDate.day - 1,
                          ),
                        )
                      : null,
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                Expanded(
                  child: Column(
                    children: [
                      const Text(
                        'TANGGAL RIWAYAT',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 9,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${isToday ? 'Hari ini • ' : ''}${transactionDate(_historyDate)}',
                        key: const ValueKey('shift-history-date'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Hari berikutnya',
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.softBlue,
                    foregroundColor: AppColors.background,
                    disabledBackgroundColor: AppColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _historyDate.isBefore(today)
                      ? () => setState(
                          () => _historyDate = DateTime(
                            _historyDate.year,
                            _historyDate.month,
                            _historyDate.day + 1,
                          ),
                        )
                      : null,
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _pickDate(shifts),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.background,
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.calendar_month_outlined, size: 18),
                  label: const Text('Pilih Tanggal'),
                ),
                if (!isToday)
                  TextButton(
                    onPressed: () => setState(() => _historyDate = today),
                    child: const Text('Hari Ini'),
                  ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      if (closed.isNotEmpty) ...[
        ShiftHistoryOverview(shifts: closed),
        const SizedBox(height: 28),
      ],
      Text(
        'Shift selesai (${closed.length})',
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 6),
      const Text(
        'Berdasarkan tanggal selesai, mencakup seluruh shift.',
        style: TextStyle(color: AppColors.muted, fontSize: 12, height: 1.5),
      ),
      const SizedBox(height: 14),
      if (closed.isEmpty) const ShiftHistoryEmpty(activity: false),
      for (final shift in closed) ...[
        ShiftSummaryCard(shift: shift),
        const SizedBox(height: 12),
      ],
      const SizedBox(height: 20),
      const Row(
        children: [
          Icon(Icons.timeline_rounded, color: AppColors.background, size: 21),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Log Aktivitas',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 6),
      const Text(
        'Aktivitas mulai dan tutup shift, terbaru dahulu.',
        style: TextStyle(color: AppColors.muted, fontSize: 12),
      ),
      const SizedBox(height: 14),
      if (events.isEmpty) const ShiftHistoryEmpty(activity: true),
      if (events.isNotEmpty)
        ProfileCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              for (final event in events)
                ShiftHistoryEvent(
                  shift: event.shift,
                  time: event.time,
                  opening: event.opening,
                  last: event == events.last,
                ),
            ],
          ),
        ),
    ]);
  }
}

class _GuideStep extends StatelessWidget {
  const _GuideStep({
    required this.number,
    required this.title,
    required this.description,
  });
  final String number, title, description;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF0F8),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            number,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.background,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 11,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

final _primaryButtonStyle = FilledButton.styleFrom(
  backgroundColor: AppColors.background,
  foregroundColor: Colors.white,
  minimumSize: const Size(48, 52),
  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
);

String _difference(int value) => value == 0
    ? 'Sesuai'
    : '${value > 0 ? 'Lebih' : 'Kurang'} ${productRupiah(value.abs())}';

class _Amount extends StatelessWidget {
  const _Amount(this.label, this.value, {this.emphasis = false});
  final String label, value;
  final bool emphasis;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: AppColors.background,
              fontSize: 14,
              fontWeight: emphasis ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

class _ShiftForm extends StatefulWidget {
  const _ShiftForm({required this.repository, this.shift});
  final ShiftRepository repository;
  final CashierShift? shift;
  @override
  State<_ShiftForm> createState() => _ShiftFormState();
}

class _ShiftFormState extends State<_ShiftForm> {
  final _key = GlobalKey<FormState>();
  late final _cashier = TextEditingController(text: StoreSession.instance.name);
  final _cash = TextEditingController();
  final _note = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _cashier.dispose();
    _cash.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy || !_key.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final shift = widget.shift;
      if (shift == null) {
        await widget.repository.start(
          cashier: _cashier.text,
          openingCash: parseRupiahInput(_cash.text)!,
        );
      } else {
        await widget.repository.close(
          id: shift.id,
          countedCash: parseRupiahInput(_cash.text)!,
          note: _note.text,
        );
      }
      if (mounted) {
        setState(() => _busy = false);
        Navigator.pop(context, true);
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = firebaseMessage(error);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final closing = widget.shift != null;
    final content = Form(
      key: _key,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!closing) ...[
            const Text(
              'Petugas shift',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _cashier,
              enabled: !_busy,
              maxLength: 100,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration:
                  profileInput(
                    'Nama Petugas',
                    icon: Icons.person_outline_rounded,
                  ).copyWith(
                    counterText: '',
                    floatingLabelBehavior: FloatingLabelBehavior.never,
                  ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Nama petugas wajib diisi.'
                  : null,
            ),
            const SizedBox(height: 24),
            const Text(
              'Uang kas awal',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Jumlah uang tunai di laci untuk kembalian.',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 14),
          ] else ...[
            const Text(
              'Selesaikan pembayaran yang sedang berlangsung, lalu hitung seluruh uang tunai di laci.',
              style: TextStyle(color: AppColors.muted, height: 1.5),
            ),
            const SizedBox(height: 16),
          ],
          TextFormField(
            controller: _cash,
            enabled: !_busy,
            keyboardType: TextInputType.number,
            textInputAction: closing
                ? TextInputAction.next
                : TextInputAction.done,
            onFieldSubmitted: closing ? null : (_) => _save(),
            style: closing
                ? null
                : const TextStyle(
                    color: AppColors.background,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.5,
                  ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(12),
              RupiahInputFormatter(),
            ],
            decoration: closing
                ? profileInput(
                    'Uang Tunai Aktual (Rp)',
                    icon: Icons.payments_outlined,
                  )
                : InputDecoration(
                    hintText: '0',
                    hintStyle: const TextStyle(color: Color(0xFF9CAED0)),
                    labelText: 'Nominal kas (Rp)',
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    labelStyle: const TextStyle(
                      color: AppColors.background,
                      fontSize: 13,
                    ),
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(left: 18, right: 12),
                      child: Text(
                        'Rp',
                        style: TextStyle(
                          color: AppColors.background,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    prefixIconConstraints: const BoxConstraints(minWidth: 58),
                    filled: true,
                    fillColor: AppColors.softBlue,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 22,
                    ),
                    errorMaxLines: 3,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: Color(0xFFCBDCF8)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(
                        color: AppColors.logoBlue,
                        width: 2,
                      ),
                    ),
                  ),
            onChanged: (_) => setState(() {}),
            validator: (value) => parseRupiahInput(value ?? '') == null
                ? 'Masukkan nominal rupiah, isi 0 jika tidak ada.'
                : null,
          ),
          if (!closing) ...[
            const SizedBox(height: 10),
            const Text(
              'Isi 0 jika tidak ada modal awal.',
              style: TextStyle(fontSize: 12, color: AppColors.muted),
            ),
            const SizedBox(height: 20),
            const Text(
              'Pilih nominal cepat',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final amount in [0, 50000, 100000, 200000, 500000])
                  ChoiceChip(
                    key: ValueKey('opening-cash-$amount'),
                    label: Text(productRupiah(amount)),
                    selected: parseRupiahInput(_cash.text) == amount,
                    showCheckmark: false,
                    selectedColor: AppColors.background,
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(
                      color: parseRupiahInput(_cash.text) == amount
                          ? AppColors.background
                          : AppColors.border,
                    ),
                    labelStyle: TextStyle(
                      color: parseRupiahInput(_cash.text) == amount
                          ? Colors.white
                          : AppColors.background,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                    onSelected: _busy
                        ? null
                        : (_) => setState(
                            () => _cash.value = TextEditingValue(
                              text: formatRupiahInput(amount),
                              selection: TextSelection.collapsed(
                                offset: formatRupiahInput(amount).length,
                              ),
                            ),
                          ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: AppColors.muted,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Kas awal dicatat sebagai modal kembalian dan tidak dihitung sebagai penjualan.',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (closing) ...[
            const SizedBox(height: 12),
            ListenableBuilder(
              listenable: TransactionHistory.instance,
              builder: (context, _) {
                final summary = ShiftSummary(
                  widget.shift!,
                  TransactionHistory.instance.items,
                );
                final counted = parseRupiahInput(_cash.text);
                return Column(
                  children: [
                    _Amount(
                      'Kas seharusnya',
                      productRupiah(summary.expectedCash),
                    ),
                    if (counted != null)
                      _Amount(
                        'Selisih kas',
                        _difference(counted - summary.expectedCash),
                        emphasis: true,
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _note,
              enabled: !_busy,
              minLines: 2,
              maxLines: 4,
              maxLength: 1000,
              decoration: profileInput('Catatan (opsional)'),
            ),
          ],
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
        ],
      ),
    );
    return PopScope(
      canPop: !_busy,
      child: !closing
          ? _StartShiftDialog(
              busy: _busy,
              onCancel: () => Navigator.pop(context),
              onSave: _save,
              child: content,
            )
          : ProfileDialog(
              icon: Icons.lock_outline_rounded,
              title: const Text('Tutup Shift'),
              description: 'Cocokkan uang di laci dengan hasil penjualan sebelum mengakhiri shift.',
              content: content,
              actions: [
                TextButton(
                  onPressed: _busy ? null : () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                FilledButton(
                  onPressed: _busy ? null : _save,
                  child: Text(_busy ? 'Menyimpan...' : 'Simpan & Tutup'),
                ),
              ],
            ),
    );
  }
}

class _StartShiftDialog extends StatelessWidget {
  const _StartShiftDialog({
    required this.child,
    required this.busy,
    required this.onCancel,
    required this.onSave,
  });

  final Widget child;
  final bool busy;
  final VoidCallback onCancel, onSave;

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    clipBehavior: Clip.antiAlias,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.background, Color(0xFF3059B7)],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(11),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: .14),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: .18),
                                ),
                              ),
                              child: const Icon(
                                Icons.point_of_sale_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'PERSIAPAN SHIFT',
                                style: TextStyle(
                                  color: Color(0xFFD9E6FF),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Semantics(
                          namesRoute: true,
                          header: true,
                          child: const Text(
                            'Mulai Shift',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 25,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -.6,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Siapkan kas, lalu mulai hari Anda.',
                          style: TextStyle(
                            color: Color(0xFFD9E6FF),
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(padding: const EdgeInsets.all(24), child: child),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                TextButton(
                  onPressed: busy ? null : onCancel,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.muted,
                    minimumSize: const Size(64, 52),
                  ),
                  child: const Text('Batal'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: busy ? null : onSave,
                    style: _primaryButtonStyle,
                    child: busy
                        ? Semantics(
                            label: 'Menyimpan shift',
                            child: const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.background,
                              ),
                            ),
                          )
                        : const Text(
                            'Mulai',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
