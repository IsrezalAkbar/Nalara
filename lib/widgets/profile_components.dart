import 'package:flutter/material.dart';

import '../colors.dart';

class ProfileHeader extends StatelessWidget implements PreferredSizeWidget {
  const ProfileHeader({super.key, required this.title});
  final String title;
  @override
  Size get preferredSize => const Size.fromHeight(76);
  @override
  Widget build(BuildContext context) => AppBar(
    backgroundColor: AppColors.background,
    foregroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    toolbarHeight: 76,
    titleSpacing: 20,
    leading: Navigator.of(context).canPop()
        ? Padding(
            padding: const EdgeInsets.only(left: 12, top: 16, bottom: 16),
            child: IconButton(
              tooltip: 'Kembali',
              onPressed: () => Navigator.pop(context),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: .12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.chevron_left_rounded),
            ),
          )
        : null,
    title: Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
    ),
  );
}

class ProfileCard extends StatelessWidget {
  const ProfileCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xFFE9EEF6)),
    ),
    child: child,
  );
}

class ProfileIntro extends StatelessWidget {
  const ProfileIntro({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
  });
  final IconData icon;
  final String title, description;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.softBlue,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(icon, color: AppColors.background, size: 24),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 13,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

InputDecoration profileInput(String label, {IconData? icon}) => InputDecoration(
  labelText: label,
  labelStyle: const TextStyle(color: AppColors.muted, fontSize: 13),
  prefixIcon: icon == null
      ? null
      : Icon(icon, color: AppColors.muted, size: 20),
  filled: true,
  fillColor: const Color(0xFFF7F9FC),
  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: Color(0xFFE5EBF4)),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: AppColors.logoBlue, width: 1.5),
  ),
);

class ProfileDialog extends StatelessWidget {
  const ProfileDialog({
    super.key,
    required this.title,
    required this.content,
    required this.actions,
    this.description,
    this.icon = Icons.tune_rounded,
    this.danger = false,
  });
  final Widget title, content;
  final List<Widget> actions;
  final String? description;
  final IconData icon;
  final bool danger;
  @override
  Widget build(BuildContext context) {
    final accent = danger ? const Color(0xFFD64550) : AppColors.background;
    return Theme(
      data: Theme.of(context).copyWith(
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? Colors.white : null,
          ),
          trackColor: WidgetStateProperty.resolveWith(
            (s) =>
                s.contains(WidgetState.selected) ? AppColors.background : null,
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: Colors.white,
            minimumSize: const Size(48, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.muted,
            minimumSize: const Size(48, 48),
          ),
        ),
      ),
      child: AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        scrollable: true,
        icon: Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: accent, size: 25),
          ),
        ),
        title: Align(alignment: Alignment.centerLeft, child: title),
        titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: AppColors.ink,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
        contentTextStyle: Theme.of(context).textTheme.bodyMedium
            ?.copyWith(color: AppColors.muted, fontSize: 13, height: 1.6),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (description != null) ...[
                Text(description!),
                const SizedBox(height: 20),
              ],
              content,
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        actions: actions,
      ),
    );
  }
}
