
import 'package:flutter/material.dart';
import 'package:dv_geo_core/dv_geo_core.dart';
import 'package:dv_map/maps/world/50m.dart';

/// Global offline map based on bundled Natural Earth 1:50m data.
///
/// No network tiles, map API key, or internet connection are required.
class OfflineWorldMap extends StatefulWidget {
  const OfflineWorldMap({
    super.key,
    this.onCountrySelected,
    this.initialScale = 1.0,
    this.showGrid = true,
  });

  final ValueChanged<String>? onCountrySelected;
  final double initialScale;
  final bool showGrid;

  @override
  State<OfflineWorldMap> createState() => _OfflineWorldMapState();
}

class _OfflineWorldMapState extends State<OfflineWorldMap>
    with TickerProviderStateMixin {
  final TransformationController _transformationController =
      TransformationController();

  String? _selectedCountry;
  late final AnimationController _glowController;

  static const Color _ocean = Color(0xFF071B2B);
  static const Color _land = Color(0xFF173B4B);
  static const Color _border = Color(0xFF4D8290);
  static const Color _accent = Color(0xFFD6B36A);

  @override
  void initState() {
    super.initState();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _selectCountry(String name) {
    if (!mounted) return;

    setState(() => _selectedCountry = name);
    widget.onCountrySelected?.call(name);
  }

  void _resetView() {
    _transformationController.value = Matrix4.identity();

    setState(() {
      _selectedCountry = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: double.infinity,
          height: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: _ocean,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: _accent.withValues(alpha: 0.30),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.28),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Stack(
            children: [
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(0, -0.15),
                      radius: 1.2,
                      colors: [
                        Color(0xFF12364B),
                        Color(0xFF091F31),
                        Color(0xFF061522),
                      ],
                    ),
                  ),
                ),
              ),

              if (widget.showGrid)
                const Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _WorldGridPainter(),
                    ),
                  ),
                ),

              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _glowController,
                  builder: (context, child) {
                    final glow = 0.10 + (_glowController.value * 0.08);

                    return DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.center,
                          radius: 0.75,
                          colors: [
                            _accent.withValues(alpha: glow),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: child,
                    );
                  },
                  child: InteractiveViewer(
                    transformationController: _transformationController,
                    minScale: 1,
                    maxScale: 7,
                    constrained: true,
                    boundaryMargin: const EdgeInsets.all(70),
                    clipBehavior: Clip.none,
                    child: SizedBox(
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                      child: World50mWidget(
                        projection: MercatorProjection(),
                        fillColor: _land,
                        strokeColor: _border,
                        strokeWidth: 0.75,
                        antiAlias: true,
                        onFeatureTap: (feature, position) {
                          final properties = feature.properties;

                          final name =
                              properties?['NAME']?.toString() ??
                              properties?['name']?.toString() ??
                              properties?['ADMIN']?.toString() ??
                              properties?['NAME_EN']?.toString();

                          if (name != null && name.trim().isNotEmpty) {
                            _selectCountry(name.trim());
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ),

              Positioned(
                top: 14,
                left: 14,
                child: _MapStatusPill(
                  icon: Icons.public_rounded,
                  label: 'WORLD ATLAS',
                  color: _accent,
                ),
              ),

              Positioned(
                top: 14,
                right: 14,
                child: _MapStatusPill(
                  icon: Icons.wifi_off_rounded,
                  label: 'OFFLINE',
                  color: const Color(0xFF8ED6B0),
                ),
              ),

              Positioned(
                right: 14,
                bottom: 16,
                child: Column(
                  children: [
                    _MapControlButton(
                      icon: Icons.add_rounded,
                      onTap: () {
                        final current = _transformationController.value;
                        final scale = current.getMaxScaleOnAxis();

                        if (scale >= 7) return;

                        final nextScale = (scale * 1.35).clamp(1.0, 7.0);
                        _transformationController.value =
                            Matrix4.identity()..scale(nextScale);
                      },
                    ),
                    const SizedBox(height: 8),
                    _MapControlButton(
                      icon: Icons.remove_rounded,
                      onTap: () {
                        final current = _transformationController.value;
                        final scale = current.getMaxScaleOnAxis();

                        if (scale <= 1) {
                          _resetView();
                          return;
                        }

                        final nextScale = (scale / 1.35).clamp(1.0, 7.0);
                        _transformationController.value =
                            Matrix4.identity()..scale(nextScale);
                      },
                    ),
                    const SizedBox(height: 8),
                    _MapControlButton(
                      icon: Icons.center_focus_strong_rounded,
                      onTap: _resetView,
                    ),
                  ],
                ),
              ),

              if (_selectedCountry != null)
                Positioned(
                  left: 14,
                  right: 72,
                  bottom: 18,
                  child: _SelectedCountryPanel(
                    country: _selectedCountry!,
                    onClose: () {
                      setState(() => _selectedCountry = null);
                    },
                  ),
                ),

              Positioned(
                left: 14,
                bottom: 14,
                child: IgnorePointer(
                  child: Text(
                    'NATURAL EARTH • 1:50m',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.48),
                      fontSize: 9,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MapStatusPill extends StatelessWidget {
  const _MapStatusPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xE6102638),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: color.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _MapControlButton extends StatelessWidget {
  const _MapControlButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xE6102638),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(13),
        side: BorderSide(
          color: Colors.white.withValues(alpha: 0.13),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(
            icon,
            color: const Color(0xFFE8D5A8),
            size: 19,
          ),
        ),
      ),
    );
  }
}

class _SelectedCountryPanel extends StatelessWidget {
  const _SelectedCountryPanel({
    required this.country,
    required this.onClose,
  });

  final String country;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 11, 8, 11),
      decoration: BoxDecoration(
        color: const Color(0xF0142D40),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFD6B36A).withValues(alpha: 0.38),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.location_on_rounded,
            color: Color(0xFFD6B36A),
            size: 19,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              country,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          IconButton(
            onPressed: onClose,
            visualDensity: VisualDensity.compact,
            icon: const Icon(
              Icons.close_rounded,
              color: Colors.white70,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _WorldGridPainter extends CustomPainter {
  const _WorldGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF8CB6C2).withValues(alpha: 0.075)
      ..strokeWidth = 0.6
      ..style = PaintingStyle.stroke;

    for (int i = 1; i < 8; i++) {
      final x = size.width * i / 8;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    for (int i = 1; i < 6; i++) {
      final y = size.height * i / 6;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }

    final horizonPaint = Paint()
      ..color = const Color(0xFFD6B36A).withValues(alpha: 0.12)
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      horizonPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _WorldGridPainter oldDelegate) => false;
}
