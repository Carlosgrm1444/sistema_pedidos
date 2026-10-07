import 'package:flutter/material.dart';

const brandBlue = Color(0xFF215FD1);
const brandSlate = Color(0xFF68788F);

ThemeData appTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final base = ThemeData(useMaterial3: true, brightness: brightness);
  final scheme =
      ColorScheme.fromSeed(
        seedColor: brandBlue,
        brightness: brightness,
      ).copyWith(
        primary: dark ? const Color(0xFF91B6FF) : brandBlue,
        onPrimary: dark ? const Color(0xFF102B54) : Colors.white,
        surface: dark ? const Color(0xFF162337) : Colors.white,
        onSurface: dark ? const Color(0xFFF0F5FF) : const Color(0xFF182B49),
        outlineVariant: dark
            ? const Color(0xFF34455D)
            : const Color(0xFFDDE5F0),
      );
  final card = dark ? const Color(0xFF17263A) : Colors.white;
  final foreground = dark ? const Color(0xFFF0F5FF) : const Color(0xFF182B49);
  final muted = dark ? const Color(0xFFAAB8CD) : const Color(0xFF61718A);

  return base.copyWith(
    colorScheme: scheme,
    scaffoldBackgroundColor: dark
        ? const Color(0xFF0D1726)
        : const Color(0xFFF4F7FC),
    cardColor: card,
    textTheme: base.textTheme.apply(
      bodyColor: foreground,
      displayColor: foreground,
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: card,
      foregroundColor: foreground,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        color: foreground,
        fontSize: 21,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: card,
      margin: const EdgeInsets.all(4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titleTextStyle: TextStyle(
        color: foreground,
        fontSize: 21,
        fontWeight: FontWeight.w700,
      ),
    ),
    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant,
      thickness: 1,
      space: 24,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 46),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 46),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        side: BorderSide(color: scheme.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? const Color(0xFF1E2D42) : const Color(0xFFF8FAFD),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: TextStyle(color: muted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide(color: scheme.primary, width: 1.7),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: dark ? const Color(0xFF223550) : const Color(0xFFEAF1FD),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      labelStyle: TextStyle(color: foreground, fontWeight: FontWeight.w600),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: dark ? const Color(0xFF2C4160) : const Color(0xFF203B62),
      contentTextStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}

Duration motionDuration(BuildContext context, [int milliseconds = 280]) =>
    MediaQuery.disableAnimationsOf(context)
    ? Duration.zero
    : Duration(milliseconds: milliseconds);

class AppBackdrop extends StatelessWidget {
  const AppBackdrop({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: dark
                    ? const [Color(0xFF101F35), Color(0xFF0B1422)]
                    : const [Color(0xFFE8F0FF), Color(0xFFF7F9FD)],
              ),
            ),
          ),
        ),
        Positioned(
          top: -170,
          right: -110,
          child: _GlowOrb(
            size: 490,
            color: brandBlue.withValues(alpha: dark ? 0.15 : 0.10),
          ),
        ),
        Positioned(
          bottom: -210,
          left: -160,
          child: _GlowOrb(
            size: 470,
            color: const Color(
              0xFF88A9D9,
            ).withValues(alpha: dark ? 0.07 : 0.16),
          ),
        ),
        Positioned.fill(child: child),
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
      ),
    ),
  );
}

class MotionReveal extends StatelessWidget {
  const MotionReveal({required this.child, this.offset = 16, super.key});
  final Widget child;
  final double offset;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: motionDuration(context, 420),
    curve: Curves.easeOutCubic,
    child: child,
    builder: (context, progress, child) => Opacity(
      opacity: progress,
      child: Transform.translate(
        offset: Offset(0, (1 - progress) * offset),
        child: child,
      ),
    ),
  );
}

class PolishedCard extends StatefulWidget {
  const PolishedCard({
    required this.child,
    this.margin = const EdgeInsets.all(4),
    super.key,
  });
  final Widget child;
  final EdgeInsetsGeometry margin;

  @override
  State<PolishedCard> createState() => _PolishedCardState();
}

class _PolishedCardState extends State<PolishedCard> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return MouseRegion(
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      child: AnimatedContainer(
        duration: motionDuration(context, 190),
        curve: Curves.easeOut,
        margin: widget.margin,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: hovered
                ? theme.colorScheme.primary.withValues(alpha: dark ? 0.5 : 0.28)
                : theme.colorScheme.outlineVariant.withValues(
                    alpha: dark ? 0.65 : 0.85,
                  ),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(
                0xFF122747,
              ).withValues(alpha: dark ? 0.10 : (hovered ? 0.10 : 0.045)),
              blurRadius: hovered ? 22 : 12,
              offset: Offset(0, hovered ? 9 : 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          child: widget.child,
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    super.key,
  });
  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      child: PolishedCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
          child: Column(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, color: theme.colorScheme.primary, size: 29),
              ),
              const SizedBox(height: 16),
              Text(title, style: theme.textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CatalogIcon extends StatelessWidget {
  const CatalogIcon(this.icon, {super.key});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Container(
      width: 43,
      height: 43,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}

class ActiveBadge extends StatelessWidget {
  const ActiveBadge(this.active, {super.key});
  final bool active;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final color = active
        ? (dark ? const Color(0xFF82D3B8) : const Color(0xFF147C66))
        : Theme.of(context).colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        active ? 'Activo' : 'Inactivo',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
