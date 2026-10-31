import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../domain/services/qibla_service.dart';

class QiblaPage extends StatefulWidget {
  const QiblaPage({super.key});

  @override
  State<QiblaPage> createState() => _QiblaPageState();
}

class _QiblaPageState extends State<QiblaPage>
    with WidgetsBindingObserver {
  static const Color _primaryGreen = Color(0xFF075B46);
  static const Color _darkGreen = Color(0xFF064536);
  static const Color _gold = Color(0xFFD8B66A);
  static const Color _background = Color(0xFFF5F7F3);

  Position? _position;

  double? _qiblaBearing;
  double? _distanceKm;
  double? _declination;

  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _locationError;

  Stream<CompassEvent>? _compassStream;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _compassStream = FlutterCompass.events;
    _loadLocation();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _compassStream = FlutterCompass.events;
      _loadLocation(silent: true);
    }
  }

  Future<void> _loadLocation({bool silent = false}) async {
    if (_isRefreshing) return;

    _isRefreshing = true;

    if (mounted) {
      setState(() {
        if (!silent) {
          _isLoading = true;
        }
        _locationError = null;
      });
    }

    try {
      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        throw const _LocationException(
          'خدمة الموقع GPS غير مفعّلة. فعّل الموقع من إعدادات الهاتف.',
        );
      }

      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        throw const _LocationException(
          'لم يتم منح إذن الوصول إلى الموقع.',
        );
      }

      if (permission == LocationPermission.deniedForever) {
        throw const _LocationException(
          'إذن الموقع مرفوض نهائياً. افتح إعدادات التطبيق واسمح بالوصول للموقع.',
        );
      }

      if (permission == LocationPermission.unableToDetermine) {
        throw const _LocationException(
          'تعذر تحديد حالة إذن الموقع على هذا الجهاز.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          timeLimit: Duration(seconds: 20),
        ),
      );

      final bearing = QiblaService.calculateQiblaBearing(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      final distance = QiblaService.calculateDistanceKm(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      double? declination;

      try {
        declination = QiblaService.calculateMagneticDeclination(
          latitude: position.latitude,
          longitude: position.longitude,
        );
      } catch (_) {
        // لا نوقف حساب القبلة إذا تعذر حساب الانحراف المغناطيسي.
        declination = null;
      }

      if (!mounted) return;

      setState(() {
        _position = position;
        _qiblaBearing = bearing;
        _distanceKm = distance;
        _declination = declination;
        _locationError = null;
        _isLoading = false;
      });
    } on _LocationException catch (error) {
      if (!mounted) return;

      setState(() {
        _locationError = error.message;
        _isLoading = false;
      });
    } on TimeoutException {
      if (!mounted) return;

      setState(() {
        _locationError =
            'انتهت مهلة تحديد الموقع. تحقق من GPS وحاول مرة أخرى.';
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _locationError =
            'تعذر تحديد موقعك حالياً. تحقق من إعدادات الموقع وحاول مجدداً.';
        _isLoading = false;
      });
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> _openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  Future<void> _openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  String _formatBearing(double bearing) {
    return '${bearing.toStringAsFixed(1)}°';
  }

  String _formatDistance(double distance) {
    if (distance >= 1000) {
      return '${(distance / 1000).toStringAsFixed(2)} ألف كم';
    }

    return '${distance.toStringAsFixed(1)} كم';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor =
        isDark ? const Color(0xFF101C18) : _background;

    final cardColor =
        isDark ? const Color(0xFF1A2B24) : Colors.white;

    final textColor =
        isDark ? Colors.white : const Color(0xFF19382E);

    final secondaryColor =
        isDark ? Colors.white70 : Colors.black54;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: _primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'اتجاه القبلة',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 19,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'تحديث الموقع',
            onPressed: _isRefreshing ? null : () => _loadLocation(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading && _position == null
            ? _buildLoading()
            : _locationError != null && _position == null
                ? _buildError()
                : RefreshIndicator(
                    color: _primaryGreen,
                    onRefresh: _loadLocation,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
                      children: [
                        _buildIntro(textColor, secondaryColor),
                        const SizedBox(height: 22),
                        _buildCompassCard(
                          cardColor: cardColor,
                          textColor: textColor,
                          secondaryColor: secondaryColor,
                        ),
                        const SizedBox(height: 18),
                        _buildInformationCards(
                          cardColor: cardColor,
                          textColor: textColor,
                          secondaryColor: secondaryColor,
                        ),
                        const SizedBox(height: 20),
                        _buildMapCard(
                          cardColor: cardColor,
                          textColor: textColor,
                          secondaryColor: secondaryColor,
                        ),
                        const SizedBox(height: 18),
                        _buildAccuracyNote(secondaryColor),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            color: _gold,
            strokeWidth: 3,
          ),
          const SizedBox(height: 18),
          Text(
            'جارٍ تحديد موقعك وحساب اتجاه القبلة...',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_off_rounded,
                color: Colors.orange,
                size: 42,
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'تعذر تحديد موقعك',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _locationError ?? 'حدث خطأ غير متوقع.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isRefreshing ? null : () => _loadLocation(),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('إعادة المحاولة'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: _openLocationSettings,
              icon: const Icon(Icons.location_searching_rounded),
              label: const Text('إعدادات الموقع'),
            ),
            TextButton.icon(
              onPressed: _openAppSettings,
              icon: const Icon(Icons.settings_rounded),
              label: const Text('إعدادات التطبيق والصلاحيات'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntro(Color textColor, Color secondaryColor) {
    return Column(
      children: [
        const Icon(
          Icons.mosque_rounded,
          color: _gold,
          size: 38,
        ),
        const SizedBox(height: 9),
        Text(
          'توجّه نحو بيت الله الحرام',
          style: TextStyle(
            color: textColor,
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'حرّك هاتفك ببطء حتى يستقر المؤشر على اتجاه القبلة',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: secondaryColor,
            fontSize: 12,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildCompassCard({
    required Color cardColor,
    required Color textColor,
    required Color secondaryColor,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.explore_rounded,
                color: _gold,
                size: 19,
              ),
              const SizedBox(width: 7),
              Text(
                'البوصلة الحية',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          if (_qiblaBearing != null)
            StreamBuilder<CompassEvent>(
              stream: _compassStream,
              builder: (context, snapshot) {
                final magneticHeading = snapshot.data?.heading;

                if (snapshot.hasError ||
                    magneticHeading == null ||
                    !magneticHeading.isFinite) {
                  return _buildCompassUnavailable(
                    textColor,
                    secondaryColor,
                  );
                }

                final trueHeading = _declination == null
                    ? QiblaService.normalize(magneticHeading)
                    : QiblaService.magneticToTrueHeading(
                        magneticHeading: magneticHeading,
                        declination: _declination!,
                      );

                final relativeAngle =
                    QiblaService.shortestAngleDifference(
                  _qiblaBearing!,
                  trueHeading,
                );

                return Column(
                  children: [
                    SizedBox(
                      width: 270,
                      height: 270,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 260,
                            height: 260,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF0B7055),
                                  Color(0xFF063E31),
                                ],
                              ),
                              border: Border.all(
                                color: _gold.withValues(alpha: 0.8),
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _primaryGreen.withValues(alpha: 0.2),
                                  blurRadius: 22,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                          _buildCompassTicks(),
                          Positioned(
                            top: 20,
                            child: _compassLabel('شمال'),
                          ),
                          Positioned(
                            bottom: 20,
                            child: _compassLabel('جنوب'),
                          ),
                          Positioned(
                            right: 20,
                            child: _compassLabel('شرق'),
                          ),
                          Positioned(
                            left: 20,
                            child: _compassLabel('غرب'),
                          ),
                          AnimatedRotation(
                            turns: relativeAngle / 360.0,
                            duration: const Duration(milliseconds: 180),
                            curve: Curves.easeOut,
                            child: const Icon(
                              Icons.navigation_rounded,
                              color: _gold,
                              size: 82,
                              shadows: [
                                Shadow(
                                  color: Colors.black45,
                                  blurRadius: 8,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 15,
                            height: 15,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(
                                color: _gold,
                                width: 3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'اتجاه القبلة بالنسبة لهاتفك',
                      style: TextStyle(
                        color: secondaryColor,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      '${relativeAngle.toStringAsFixed(1)}°',
                      style: const TextStyle(
                        color: _primaryGreen,
                        fontSize: 29,
                        fontWeight: FontWeight.bold,
                        fontFeatures: [
                          FontFeature.tabularFigures(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'الاتجاه الحقيقي: ${_formatBearing(_qiblaBearing!)}',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                );
              },
            )
          else
            _buildCompassUnavailable(textColor, secondaryColor),
        ],
      ),
    );
  }

  Widget _buildCompassTicks() {
    return SizedBox(
      width: 244,
      height: 244,
      child: CustomPaint(
        painter: _CompassTicksPainter(),
      ),
    );
  }

  Widget _compassLabel(String value) {
    return Text(
      value,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 11,
      ),
    );
  }

  Widget _buildCompassUnavailable(
    Color textColor,
    Color secondaryColor,
  ) {
    return Column(
      children: [
        const Icon(
          Icons.sensors_off_rounded,
          color: Colors.orange,
          size: 45,
        ),
        const SizedBox(height: 12),
        Text(
          'حساس البوصلة غير متاح',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          'يمكنك معرفة اتجاه القبلة المحسوب والخريطة، '
          'لكن التوجيه المباشر يحتاج إلى جهاز يدعم حساس البوصلة.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: secondaryColor,
            fontSize: 12,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () {
            setState(() {
              _compassStream = FlutterCompass.events;
            });
          },
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('إعادة الاتصال بالحساس'),
        ),
      ],
    );
  }

  Widget _buildInformationCards({
    required Color cardColor,
    required Color textColor,
    required Color secondaryColor,
  }) {
    return Row(
      children: [
        Expanded(
          child: _infoCard(
            cardColor: cardColor,
            textColor: textColor,
            secondaryColor: secondaryColor,
            icon: Icons.explore_rounded,
            title: 'اتجاه القبلة',
            value: _qiblaBearing == null
                ? '--'
                : _formatBearing(_qiblaBearing!),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _infoCard(
            cardColor: cardColor,
            textColor: textColor,
            secondaryColor: secondaryColor,
            icon: Icons.straighten_rounded,
            title: 'المسافة إلى الكعبة',
            value: _distanceKm == null
                ? '--'
                : _formatDistance(_distanceKm!),
          ),
        ),
      ],
    );
  }

  Widget _infoCard({
    required Color cardColor,
    required Color textColor,
    required Color secondaryColor,
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 17,
      ),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(icon, color: _gold, size: 25),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: secondaryColor,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 7),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapCard({
    required Color cardColor,
    required Color textColor,
    required Color secondaryColor,
  }) {
    final position = _position;

    if (position == null) {
      return const SizedBox.shrink();
    }

    final userLocation = LatLng(
      position.latitude,
      position.longitude,
    );

    final kaabaLocation = LatLng(
      QiblaService.kaabaLatitude,
      QiblaService.kaabaLongitude,
    );

    final route = QiblaService.greatCircleRoute(
      startLatitude: position.latitude,
      startLongitude: position.longitude,
    );

    final routePoints = route
        .map((point) => LatLng(point.latitude, point.longitude))
        .toList(growable: false);

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.map_rounded,
                color: _gold,
                size: 21,
              ),
              const SizedBox(width: 8),
              Text(
                'المسار إلى الكعبة',
                style: TextStyle(
                  color: textColor,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            'عرض جغرافي لموقعك واتجاه الكعبة المشرفة',
            style: TextStyle(
              color: secondaryColor,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(17),
            child: SizedBox(
              height: 230,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: userLocation,
                  initialZoom: 3,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.iskander.muslims_app',
                  ),
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: routePoints,
                        strokeWidth: 3.5,
                        color: _primaryGreen,
                      ),
                    ],
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: userLocation,
                        width: 42,
                        height: 42,
                        child: const Icon(
                          Icons.my_location_rounded,
                          color: Colors.blue,
                          size: 31,
                        ),
                      ),
                      Marker(
                        point: kaabaLocation,
                        width: 46,
                        height: 46,
                        child: const Icon(
                          Icons.mosque_rounded,
                          color: _primaryGreen,
                          size: 35,
                        ),
                      ),
                    ],
                  ),
                  RichAttributionWidget(
                    attributions: [
                      TextSourceAttribution(
                        'OpenStreetMap contributors',
                        onTap: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: _gold,
                size: 16,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'الخريطة تحتاج إلى الإنترنت. البوصلة وحساب الاتجاه '
                  'يعملان بصورة مستقلة عنها.',
                  style: TextStyle(
                    color: secondaryColor,
                    fontSize: 10,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccuracyNote(Color secondaryColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _gold.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _gold.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.tips_and_updates_outlined,
            color: _gold,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'للحصول على قراءة أدق، أبعد الهاتف عن المعادن '
              'والأجهزة المغناطيسية، وحرّكه بشكل الرقم 8 '
              'لمعايرة الحساس عند الحاجة.',
              style: TextStyle(
                color: secondaryColor,
                fontSize: 11,
                height: 1.7,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompassTicksPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final tickPaint = Paint()
      ..color = const Color(0xFFD8B66A)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < 60; i++) {
      final angle = (i * 6 - 90) * math.pi / 180;
      final isMajor = i % 5 == 0;

      final outerRadius = radius - 4;
      final innerRadius = outerRadius - (isMajor ? 12 : 6);

      final start = Offset(
        center.dx + innerRadius * math.cos(angle),
        center.dy + innerRadius * math.sin(angle),
      );

      final end = Offset(
        center.dx + outerRadius * math.cos(angle),
        center.dy + outerRadius * math.sin(angle),
      );

      tickPaint.strokeWidth = isMajor ? 2.2 : 1.1;

      canvas.drawLine(start, end, tickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CompassTicksPainter oldDelegate) {
    return false;
  }
}

class _LocationException implements Exception {
  final String message;

  const _LocationException(this.message);
}
