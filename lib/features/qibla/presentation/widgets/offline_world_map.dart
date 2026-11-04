import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:dv_geo_core/dv_geo_core.dart';
import 'package:dv_map/maps/world/50m.dart';

/// Offline world atlas using Natural Earth 50m country boundaries.
///
/// Features:
/// - Offline world map without network tiles.
/// - Country selection.
/// - Pinch-to-zoom and pan.
/// - Zoom controls.
/// - Live zoom percentage.
/// - Optional coordinate grid.
/// - Optional user location marker with an elite anime-style prostrating avatar.
/// - Optional Qibla direction indicator with glowing divine laser vector.
/// - Optional Kaaba marker with sacred illumination.
class OfflineWorldMap extends StatefulWidget {
  const OfflineWorldMap({
    super.key,
    this.showGrid = true,
    this.initialScale = 1.0,
    this.onCountrySelected,
    this.userLatitude,
    this.userLongitude,
    this.qiblaBearing,
    this.showKaabaMarker = true,
    this.showUserMarker = true,
    this.showQiblaDirection = true,
  });

  final bool showGrid;
  final double initialScale;
  final ValueChanged<String>? onCountrySelected;

  /// User latitude in decimal degrees.
  final double? userLatitude;

  /// User longitude in decimal degrees.
  final double? userLongitude;

  /// True geographic Qibla bearing in degrees.
  final double? qiblaBearing;

  /// Whether the Kaaba marker should be rendered.
  final bool showKaabaMarker;

  /// Whether the user's location marker should be rendered.
  final bool showUserMarker;

  /// Whether the Qibla direction arrow should be rendered.
  final bool showQiblaDirection;

  @override
  State<OfflineWorldMap> createState() => _OfflineWorldMapState();
}

class _OfflineWorldMapState extends State<OfflineWorldMap> {
  static const Color _backgroundColor = Color(0xFF101B2A);
  static const Color _landColor = Color(0xFF244C57);
  static const Color _borderColor = Color(0xFF6F9D9A);
  static const Color _accentColor = Color(0xFF53D6B2);
  // ignore: unused_field
  static const Color _goldColor = Color(0xFFD9B45B);

  static const double _minZoom = 0.5;
  static const double _maxZoom = 8.0;
  static const double _zoomStep = 0.35;

  late final TransformationController _transformController;

  String? _selectedCountry;
  double _zoom = 1.0;

  double _normalizeZoom(double value) {
    if (!value.isFinite) {
      return 1.0;
    }

    return value.clamp(_minZoom, _maxZoom).toDouble();
  }

  Matrix4 _createZoomMatrix(double zoom) {
    return Matrix4.diagonal3Values(
      zoom,
      zoom,
      1.0,
    );
  }

  bool get _hasValidUserLocation {
    final latitude = widget.userLatitude;
    final longitude = widget.userLongitude;

    if (latitude == null || longitude == null) {
      return false;
    }

    return latitude.isFinite &&
        longitude.isFinite &&
        latitude >= -90.0 &&
        latitude <= 90.0 &&
        longitude >= -180.0 &&
        longitude <= 180.0;
  }

  bool get _hasValidQiblaBearing {
    final bearing = widget.qiblaBearing;

    return bearing != null && bearing.isFinite;
  }

  @override
  void initState() {
    super.initState();

    _zoom = _normalizeZoom(widget.initialScale);

    _transformController = TransformationController(
      _createZoomMatrix(_zoom),
    );

    _transformController.addListener(_handleTransformChanged);
  }

  @override
  void didUpdateWidget(covariant OfflineWorldMap oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.initialScale != widget.initialScale) {
      final nextZoom = _normalizeZoom(widget.initialScale);

      _zoom = nextZoom;

      _transformController.value = _createZoomMatrix(nextZoom);
    }
  }

  @override
  void dispose() {
    _transformController.removeListener(_handleTransformChanged);
    _transformController.dispose();

    super.dispose();
  }

  void _handleTransformChanged() {
    final currentZoom = _normalizeZoom(
      _transformController.value.getMaxScaleOnAxis(),
    );

    if ((_zoom - currentZoom).abs() < 0.01) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _zoom = currentZoom;
    });
  }

  void _setZoom(double value) {
    final nextZoom = _normalizeZoom(value);

    _transformController.value = _createZoomMatrix(nextZoom);
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

  void _handleCountryTap(GeoJsonFeature feature) {
    final rawName = feature.properties['name'];

    if (rawName == null) {
      return;
    }

    final name = rawName.toString().trim();

    if (name.isEmpty) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _selectedCountry = name;
    });

    widget.onCountrySelected?.call(name);
  }

  void _clearSelectedCountry() {
    if (!mounted || _selectedCountry == null) {
      return;
    }

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
                  'Qibla Atlas Pro',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'WORLD EXPLORER · ELITE OFFLINE MAP',
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

        if (!width.isFinite ||
            !height.isFinite ||
            width <= 0 ||
            height <= 0) {
          return const SizedBox.shrink();
        }

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
                  onFeatureTap: (feature, _) {
                    _handleCountryTap(feature);
                  },
                ),
                if (_hasValidUserLocation ||
                    widget.showKaabaMarker)
                  IgnorePointer(
                    child: CustomPaint(
                      painter: _QiblaMapOverlayPainter(
                        userLatitude: _hasValidUserLocation
                            ? widget.userLatitude
                            : null,
                        userLongitude: _hasValidUserLocation
                            ? widget.userLongitude
                            : null,
                        qiblaBearing: _hasValidQiblaBearing
                            ? widget.qiblaBearing
                            : null,
                        showUserMarker: widget.showUserMarker,
                        showKaabaMarker: widget.showKaabaMarker,
                        showQiblaDirection:
                            widget.showQiblaDirection,
                      ),
                    ),
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
    final selectedCountry = _selectedCountry;

    if (selectedCountry == null) {
      return const SizedBox.shrink();
    }

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
              selectedCountry,
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

/// Paints the user's position, the Kaaba, and the Qibla direction.
///
/// Features an exclusive high-end Anime-style prostrating avatar (Sajdah)
/// and divine illuminated vector laser pointing straight towards the Kaaba.
class _QiblaMapOverlayPainter extends CustomPainter {
  const _QiblaMapOverlayPainter({
    required this.userLatitude,
    required this.userLongitude,
    required this.qiblaBearing,
    required this.showUserMarker,
    required this.showKaabaMarker,
    required this.showQiblaDirection,
  });

  static const double _kaabaLatitude = 21.4225;
  static const double _kaabaLongitude = 39.8262;
  static const double _maximumMercatorLatitude = 85.05112878;

  final double? userLatitude;
  final double? userLongitude;
  final double? qiblaBearing;
  final bool showUserMarker;
  final bool showKaabaMarker;
  final bool showQiblaDirection;

  Offset _projectCoordinate({
    required double latitude,
    required double longitude,
    required Size size,
  }) {
    final safeLatitude = latitude.clamp(
      -_maximumMercatorLatitude,
      _maximumMercatorLatitude,
    );

    final safeLongitude = longitude.clamp(-180.0, 180.0);

    final latitudeRadians = safeLatitude * math.pi / 180.0;

    final mercatorY = math.log(
      math.tan(
        math.pi / 4.0 + latitudeRadians / 2.0,
      ),
    );

    final normalizedX = (safeLongitude + 180.0) / 360.0;

    final normalizedY = 0.5 - mercatorY / (2.0 * math.pi);

    return Offset(
      normalizedX * size.width,
      normalizedY * size.height,
    );
  }

  void _drawKaaba(
    Canvas canvas,
    Offset position,
  ) {
    final outerGlow = Paint()
      ..color = const Color(0xFFD9B45B).withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
      ..style = PaintingStyle.fill;

    final glowPaint = Paint()
      ..color = const Color(0xFFD9B45B).withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;

    final outerPaint = Paint()
      ..color = const Color(0xFFD9B45B)
      ..style = PaintingStyle.fill;

    final innerPaint = Paint()
      ..color = const Color(0xFF18232D)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(position, 16, outerGlow);
    canvas.drawCircle(position, 12, glowPaint);
    canvas.drawCircle(position, 8, outerPaint);

    canvas.drawRect(
      Rect.fromCenter(
        center: position,
        width: 6,
        height: 6,
      ),
      innerPaint,
    );

    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.95)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(position.dx - 3, position.dy - 2),
      Offset(position.dx + 3, position.dy - 2),
      highlightPaint,
    );
  }

  /// Draws an elite exclusive anime-style avatar of a person in Sajdah (prostration)
  void _drawUserMarker(
    Canvas canvas,
    Offset position,
  ) {
    // Sacred aura shadow
    final shadowPaint = Paint()
      ..color = const Color(0xFF53D6B2).withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    canvas.drawCircle(position, 14, shadowPaint);

    // Outer radar ring
    final outerRing = Paint()
      ..color = const Color(0xFF53D6B2).withValues(alpha: 0.8)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(position, 11, outerRing);

    // Background core badge
    final corePaint = Paint()
      ..color = const Color(0xFF0C1B2A)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(position, 9.5, corePaint);

    // Anime-style Prostrating Silhouette (Tajweed / Sajdah icon style)
    final animePaint = Paint()
      ..color = const Color(0xFF53D6B2)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final headPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Head (down in sajdah)
    canvas.drawCircle(position.translate(-4, 1), 2.2, headPaint);

    // Back & body curve path in prostration
    final path = Path()
      ..moveTo(position.dx + 5, position.dy + 3) // feet/legs folded
      ..quadraticBezierTo(
        position.dx + 1,
        position.dy - 3,
        position.dx - 3,
        position.dy + 1,
      ); // curved back

    canvas.drawPath(path, animePaint);

    // Hands placed forward on ground in sajdah
    canvas.drawLine(
      position.translate(-2, 2),
      position.translate(-5, 4),
      animePaint,
    );
  }

  Offset? _calculateArrowEndpoint({
    required Offset origin,
    required double bearing,
    required Size size,
  }) {
    if (!bearing.isFinite ||
        !origin.dx.isFinite ||
        !origin.dy.isFinite ||
        size.width <= 0 ||
        size.height <= 0) {
      return null;
    }

    final radians = bearing * math.pi / 180.0;

    final direction = Offset(
      math.sin(radians),
      -math.cos(radians),
    );

    const inset = 18.0;

    final minimumX = inset;
    final maximumX = size.width - inset;
    final minimumY = inset;
    final maximumY = size.height - inset;

    if (minimumX >= maximumX || minimumY >= maximumY) {
      return null;
    }

    double distance = double.infinity;

    if (direction.dx > 0) {
      distance = math.min(
        distance,
        (maximumX - origin.dx) / direction.dx,
      );
    } else if (direction.dx < 0) {
      distance = math.min(
        distance,
        (minimumX - origin.dx) / direction.dx,
      );
    }

    if (direction.dy > 0) {
      distance = math.min(
        distance,
        (maximumY - origin.dy) / direction.dy,
      );
    } else if (direction.dy < 0) {
      distance = math.min(
        distance,
        (minimumY - origin.dy) / direction.dy,
      );
    }

    if (!distance.isFinite || distance <= 0) {
      return null;
    }

    final endpoint = origin + direction * distance;

    if (!endpoint.dx.isFinite || !endpoint.dy.isFinite) {
      return null;
    }

    return endpoint;
  }

  void _drawQiblaDirection(
    Canvas canvas,
    Offset origin,
    Offset endpoint,
  ) {
    final divineGlow = Paint()
      ..color = const Color(0xFFD9B45B).withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final linePaint = Paint()
      ..color = const Color(0xFFD9B45B)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(origin, endpoint, divineGlow);
    canvas.drawLine(origin, endpoint, linePaint);

    final direction = endpoint - origin;
    final length = direction.distance;

    if (!length.isFinite || length < 12) {
      return;
    }

    final unitDirection = direction / length;

    final perpendicular = Offset(
      -unitDirection.dy,
      unitDirection.dx,
    );

    const arrowLength = 12.0;
    const arrowWidth = 6.0;

    final arrowBase = endpoint - unitDirection * arrowLength;

    final arrowPath = Path()
      ..moveTo(endpoint.dx, endpoint.dy)
      ..lineTo(
        arrowBase.dx + perpendicular.dx * arrowWidth,
        arrowBase.dy + perpendicular.dy * arrowWidth,
      )
      ..lineTo(
        arrowBase.dx - perpendicular.dx * arrowWidth,
        arrowBase.dy - perpendicular.dy * arrowWidth,
      )
      ..close();

    canvas.drawPath(
      arrowPath,
      Paint()
        ..color = const Color(0xFFD9B45B)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) {
      return;
    }

    if (showKaabaMarker) {
      final kaabaPosition = _projectCoordinate(
        latitude: _kaabaLatitude,
        longitude: _kaabaLongitude,
        size: size,
      );

      _drawKaaba(
        canvas,
        kaabaPosition,
      );
    }

    final latitude = userLatitude;
    final longitude = userLongitude;

    if (latitude == null || longitude == null) {
      return;
    }

    if (!latitude.isFinite ||
        !longitude.isFinite ||
        latitude < -90.0 ||
        latitude > 90.0 ||
        longitude < -180.0 ||
        longitude > 180.0) {
      return;
    }

    final userPosition = _projectCoordinate(
      latitude: latitude,
      longitude: longitude,
      size: size,
    );

    final bearing = qiblaBearing;

    if (showQiblaDirection &&
        bearing != null &&
        bearing.isFinite) {
      final endpoint = _calculateArrowEndpoint(
        origin: userPosition,
        bearing: bearing,
        size: size,
      );

      if (endpoint != null) {
        _drawQiblaDirection(
          canvas,
          userPosition,
          endpoint,
        );
      }
    }

    if (showUserMarker) {
      _drawUserMarker(
        canvas,
        userPosition,
      );
    }
  }

  @override
    bool shouldRepaint(
    covariant _QiblaMapOverlayPainter oldDelegate,
  ) {
    return oldDelegate.userLatitude != userLatitude ||
        oldDelegate.userLongitude != userLongitude ||
        oldDelegate.qiblaBearing != qiblaBearing ||
        oldDelegate.showUserMarker != showUserMarker ||
        oldDelegate.showKaabaMarker != showKaabaMarker ||
        oldDelegate.showQiblaDirection != showQiblaDirection;
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
  bool shouldRepaint(
    covariant _CoordinateGridPainter oldDelegate,
  ) {
    return false;
  }
}
