import 'package:flutter/material.dart';

class TechChipMark extends StatelessWidget {
  final double size;

  const TechChipMark({super.key, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'TECHNOLOGIA chip mark',
      image: true,
      child: SizedBox.square(
        dimension: size,
        child: const CustomPaint(painter: TechChipMarkPainter()),
      ),
    );
  }
}

class TechChipMarkPainter extends CustomPainter {
  static const backgroundColor = Color(0xFF09090B);
  static const borderColor = Color(0xFF262626);
  static const markColor = Color(0xFF4EDCC6);

  const TechChipMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..save()
      ..scale(size.width / 100, size.height / 100);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 100, 100),
      Paint()..color = backgroundColor,
    );

    final frame = Paint()
      ..color = borderColor
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.square
      ..style = PaintingStyle.stroke;
    final chip = Path()
      ..moveTo(21.5, 22)
      ..lineTo(78.5, 22)
      ..lineTo(78.5, 78)
      ..lineTo(21.5, 78)
      ..close();
    canvas.drawPath(chip, frame);
    canvas
      ..drawLine(const Offset(50, 13), const Offset(50, 22), frame)
      ..drawLine(const Offset(50, 78), const Offset(50, 87), frame);

    final monogram = Path()
      ..moveTo(31, 31)
      ..lineTo(69, 31)
      ..lineTo(67, 41)
      ..lineTo(55, 41)
      ..lineTo(55, 69)
      ..lineTo(45, 69)
      ..lineTo(45, 41)
      ..lineTo(33, 41)
      ..close();
    canvas
      ..drawPath(monogram, Paint()..color = markColor)
      ..restore();
  }

  @override
  bool shouldRepaint(TechChipMarkPainter oldDelegate) => false;
}

class TechBrandLockup extends StatelessWidget {
  final bool compact;
  final bool showDescriptor;

  const TechBrandLockup({
    super.key,
    this.compact = false,
    this.showDescriptor = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 34 : 40,
          height: compact ? 34 : 40,
          alignment: Alignment.center,
          child: TechChipMark(size: compact ? 34 : 40),
        ),
        const SizedBox(width: 11),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'TECHNOLOGIA',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 0.9,
              ),
            ),
            if (showDescriptor)
              Text(
                'TOOLS FOR EVERY BUILD',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 9,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class TechHeroBanner extends StatelessWidget {
  const TechHeroBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 520;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const TechEyebrow('Precision gear / zero noise'),
                    const SizedBox(height: 12),
                    Text(
                      'BUILT FOR\nTHE NEXT BUILD.',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontSize: compact ? 29 : 40,
                                height: 0.98,
                                letterSpacing: -1.6,
                              ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      'PC parts and tools, selected for the work.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              if (!compact) ...[
                const SizedBox(width: 16),
                const TechChipMark(size: 112),
              ],
            ],
          );
        },
      ),
    );
  }
}

class TechEyebrow extends StatelessWidget {
  final String text;
  final IconData? icon;

  const TechEyebrow(
    this.text, {
    super.key,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
        ],
        Text(
          text.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }
}

class TechPageIntro extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String? description;

  const TechPageIntro({
    super.key,
    required this.eyebrow,
    required this.title,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TechEyebrow(eyebrow),
          const SizedBox(height: 10),
          Text(title, style: theme.textTheme.headlineMedium),
          if (description != null) ...[
            const SizedBox(height: 7),
            Text(
              description!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class TechStatusLabel extends StatelessWidget {
  final String status;

  const TechStatusLabel({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();
    final (icon, label) = switch (normalized) {
      'paid' => (Icons.check_circle_outline, 'PAID'),
      'failed' => (Icons.error_outline, 'PAYMENT FAILED'),
      'disabled' => (Icons.block_outlined, 'DISABLED'),
      'admin' => (Icons.admin_panel_settings_outlined, 'ADMIN'),
      'seller' => (Icons.storefront_outlined, 'SELLER'),
      'customer' => (Icons.person_outline, 'CUSTOMER'),
      _ => (Icons.schedule_outlined, normalized.toUpperCase()),
    };
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 5),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
