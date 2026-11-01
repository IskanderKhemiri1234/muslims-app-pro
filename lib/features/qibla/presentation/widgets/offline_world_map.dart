
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:dv_geo_core/dv_geo_core.dart';
import 'package:dv_map/maps/world/50m.dart';
import 'package:vector_math/vector_math_64.dart' show Matrix4;

/// Offline world atlas using Natural Earth 50m country boundaries.
///
/// Features:
/// - Offline world map without network tiles.
/// - Country selection.
/// - Pinch-to-zoom and pan.
/// - Zoom controls.
/// - Live zoom percentage.
/// - Optional coordinate grid.
class OfflineWorldMap extends StatefulWidget {
  const OfflineWorldMap({
    super.key,
    this.showGrid = true,
    this.initialScale = 1.0,
    this.onCountrySelected,
  });

  final bool showGrid;
  final double initialScale;
  final ValueChanged<String>? onCountrySelected;

  @override
  State<OfflineWorldMap> createState() => _OfflineWorldMapState();
}

class _OfflineWorldMapState extends State<OfflineWorldMap> {
  static const Color _backgroundColor = Color(0xFF101B2A);
  static const Color _landColor = Color(0xFF244C57);
  static const Color _borderColor = Color(0xFF6F9D9A);
  static const Color _accentColor = Color(0xFF53D6B2);

  static const double _minZoom = 0.5;
  static const double _maxZoom = 8.0;
  static const double _zoomStep = 0.35;

  late final TransformationController _transformController;

  String? _selectedCountry;
  double _zoom = 1.0;

  @override
  void initState() {
    super.initState();

    _zoom = widget.initialScale
        .clamp(_minZoom, _maxZoom)
        .toDouble();

    _transformController = TransformationController(
      Matrix4.identity()..scale(_zoom),
    );

    _transformController.addListener(_handleTransformChanged);
  }

  @override
  void didUpdateWidget(covariant OfflineWorldMap oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.initialScale != widget.initialScale) {
      final nextZoom = widget.initialScale
          .clamp(_minZoom, _maxZoom)
          .toDouble();

      _zoom = nextZoom;

      _transformController.value = Matrix4.identity()
        ..scale(nextZoom);
    }
  }

  @override
  void dispose() {
    _transformController.removeListener(_handleTransformChanged);
    _transformController.dispose();
    super.dispose();
  }

  void _handleTransformChanged() {
    final currentZoom = _transformController.value
        .getMaxScaleOnAxis()
        .clamp(_minZoom, _maxZoom)
        .toDouble();

    if ((_zoom - currentZoom).abs() < 0.01) return;

    if (!mounted) return;

    setState(() {
      _zoom = currentZoom;
    });
  }

  void _setZoom(double value) {
    final nextZoom = value.clamp(_minZoom, _maxZoom).toDouble();

    _transformController.value = Matrix4.identity()
      ..scale(nextZoom);
  }

  void _zoomIn() {
    _setZoom(_zoom + _zoomStep);
  }

  void _zoomOut() {
    _setZoom(_zoom - _zoomStep);
  }

  void _resetZoom() {
    _setZoom(widget.initialScale);
  }

  void _handleCountryTap(
    GeoJsonFeature feature,
    math.Point position,
  ) {
    final properties = feature.properties;
    final name = properties?['name']?.toString().trim();

    if (name == null || name.isEmpty) return;

    if (!mounted) return;

    setState(() {
      _selectedCountry = name;
    });

    widget.onCountrySelected?.call(name);
  }

  void _clearSelectedCountry() {
    setState(() {
      _selectedCountry = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _buildMapHeader(),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: _buildInteractiveMap(),
                ),
                Positioned(
                  right: 14,
                  top: 14,
                  child: _buildZoomControls(),
                ),
                if (_selectedCountry != null)
                  Positioned(
                    left: 14,
                    right: 14,
                    bottom: 14,
                    child: _buildSelectedCountry(),
                  ),
              ],
            ),
          ),
          _buildMapFooter(),
        ],
      ),
    );
  }

  Widget _buildMapHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.public_rounded,
              color: _accentColor,
              size: 23,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Qibla Atlas',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'WORLD EXPLORER · OFFLINE MAP',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 9,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: _accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.cloud_off_rounded,
                  color: _accentColor,
                  size: 13,
                ),
                SizedBox(width: 5),
                Text(
                  'OFFLINE',
                  style: TextStyle(
                    color: _accentColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.7,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveMap() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        return InteractiveViewer(
          transformationController: _transformController,
          minScale: _minZoom,
          maxScale: _maxZoom,
          constrained: true,
          boundaryMargin: const EdgeInsets.all(60),
          clipBehavior: Clip.hardEdge,
          child: SizedBox(
            width: width,
            height: height,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (widget.showGrid)
                  CustomPaint(
                    painter: _CoordinateGridPainter(),
                  ),
                World50mWidget(
                  projection: MercatorProjection(),
                  fillColor: _landColor,
                  strokeColor: _borderColor,
                  strokeWidth: 0.65,
                  antiAlias: true,
                  onFeatureTap: _handleCountryTap,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildZoomControls() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xE8172638),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _zoomButton(
            icon: Icons.add_rounded,
            onTap: _zoomIn,
          ),
          Container(
            width: 30,
            height: 1,
            color: Colors.white.withValues(alpha: 0.12),
          ),
          _zoomButton(
            icon: Icons.remove_rounded,
            onTap: _zoomOut,
          ),
          Container(
            width: 30,
            height: 1,
            color: Colors.white.withValues(alpha: 0.12),
          ),
          _zoomButton(
            icon: Icons.center_focus_strong_rounded,
            onTap: _resetZoom,
          ),
        ],
      ),
    );
  }

  Widget _zoomButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 42,
          height: 40,
          child: Icon(
            icon,
            color: Colors.white,
            size: 19,
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedCountry() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xF01A2B3D),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: _accentColor.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.location_on_rounded,
            color: _accentColor,
            size: 19,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              _selectedCountry!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          GestureDetector(
            onTap: _clearSelectedCountry,
            child: const Icon(
              Icons.close_rounded,
              color: Colors.white60,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: Row(
        children: [
          const Icon(
            Icons.touch_app_rounded,
            color: _accentColor,
            size: 15,
          ),
          const SizedBox(width: 7),
          const Expanded(
            child: Text(
              'Tap a country · Pinch to zoom · Drag to explore',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            '${(_zoom * 100).round()}%',
            style: const TextStyle(
              color: _accentColor,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _CoordinateGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.055)
      ..strokeWidth = 0.6
      ..style = PaintingStyle.stroke;

    const divisions = 12;

    for (var i = 1; i < divisions; i++) {
      final x = size.width * i / divisions;
      final y = size.height * i / divisions;

      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );

      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }

    final equatorPaint = Paint()
      ..color = const Color(0xFF53D6B2).withValues(alpha: 0.20)
      ..strokeWidth = 0.9;

    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      equatorPaint,
    );

    final centerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..strokeWidth = 0.7;

    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      math.min(size.width, size.height) * 0.015,
      centerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CoordinateGridPainter oldDelegate) {
    return false;
  }
}
