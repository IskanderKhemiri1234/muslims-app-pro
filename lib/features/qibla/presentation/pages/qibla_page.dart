
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/services/qibla_service.dart';

class QiblaPage extends StatefulWidget {
  const QiblaPage({super.key});

  @override
  State<QiblaPage> createState() => _QiblaPageState();
}

class _QiblaPageState extends State<QiblaPage> {
  Position? _position;
  double? _qiblaBearing;
  double? _distanceKm;
  double? _declination;

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        throw Exception('Location permission was denied.');
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'Location permission is permanently denied. '
          'Enable it from app settings.',
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

      final declination =
          QiblaService.calculateMagneticDeclination(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      if (!mounted) return;

      setState(() {
        _position = position;
        _qiblaBearing = bearing;
        _distanceKm = distance;
        _declination = declination;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('اتجاه القبلة'),
        actions: [
          IconButton(
            tooltip: 'تحديث الموقع',
            onPressed: _loading ? null : _loadLocation,
            icon: const Icon(Icons.my_location_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildError()
                : _buildContent(isDark),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.location_off_rounded,
              size: 48,
              color: Colors.orange,
            ),
            const SizedBox(height: 16),
            Text(
              _error ?? 'تعذر تحديد موقعك.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _loadLocation,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة'),
            ),
            TextButton(
              onPressed: Geolocator.openAppSettings,
              child: const Text('إعدادات صلاحيات الموقع'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    final position = _position!;
    final bearing = _qiblaBearing!;
    final declination = _declination!;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
      children: [
        _buildIntro(),
        const SizedBox(height: 20),

        StreamBuilder<CompassEvent>(
          stream: FlutterCompass.events,
          builder: (context, snapshot) {
            final magneticHeading = snapshot.data?.heading;
            final sensorAccuracy = snapshot.data?.accuracy;

            if (magneticHeading == null ||
                !magneticHeading.isFinite) {
              return _buildSensorUnavailable();
            }

            final trueHeading =
                QiblaService.magneticToTrueHeading(
              magneticHeading: magneticHeading,
              declination: declination,
            );

            final relativeAngle =
                QiblaService.shortestAngleDifference(
              bearing,
              trueHeading,
            );

            return Column(
              children: [
                _buildCompass(
                  relativeAngle,
                  isDark,
                ),
                const SizedBox(height: 16),
                _buildBearingInfo(
                  bearing,
                  relativeAngle,
                  sensorAccuracy,
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 24),
        _buildDistanceCard(),
        const SizedBox(height: 24),
        _buildMap(position),
        const SizedBox(height: 12),
        _buildAccuracyNote(),
      ],
    );
  }

  Widget _buildIntro() {
    return Column(
      children: [
        const Text(
          'اتجه بقلبك نحو بيت الله الحرام',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'حرّك هاتفك ببطء حتى يشير السهم إلى القبلة',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.color
                ?.withValues(alpha: 0.65),
          ),
        ),
      ],
    );
  }

  Widget _buildCompass(double relativeAngle, bool isDark) {
    return Container(
      width: 290,
      height: 290,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: isDark
              ? const [
                  Color(0xFF173D31),
                  Color(0xFF071713),
                ]
              : const [
                  Color(0xFFE4F1E9),
                  Color(0xFFF3F7F4),
                ],
        ),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.55),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.emerald.withValues(alpha: 0.18),
            blurRadius: 30,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Positioned(
            top: 8,
            child: Text(
              'N',
              style: TextStyle(
                color: AppColors.gold,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
          ),
          const Positioned(
            bottom: 8,
            child: Text('S'),
          ),
          const Positioned(
            left: 8,
            child: Text('W'),
          ),
          const Positioned(
            right: 8,
            child: Text('E'),
          ),
          Container(
            width: 225,
            height: 225,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.30),
                width: 1,
              ),
            ),
          ),

          // The prayer rug rotates relative to the phone's
          // corrected true-north heading.
          AnimatedRotation(
            turns: relativeAngle / 360,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            child: _PrayerRug(),
          ),

          Positioned(
            top: 44,
            child: Container(
              width: 4,
              height: 35,
              decoration: BoxDecoration(
                color: AppColors.gold,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBearingInfo(
    double bearing,
    double relativeAngle,
    double? sensorAccuracy,
  ) {
    final direction = relativeAngle.abs() < 3
        ? 'أنت تواجه القبلة تقريبًا'
        : relativeAngle > 0
            ? 'حرّك الهاتف إلى اليمين'
            : 'حرّك الهاتف إلى اليسار';

    return Column(
      children: [
        Text(
          '${bearing.toStringAsFixed(1)}°',
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: AppColors.gold,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          direction,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          sensorAccuracy == null
              ? 'دقة المستشعر غير متاحة'
              : 'انحراف المستشعر المقدر: ±${sensorAccuracy.toStringAsFixed(1)}°',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildDistanceCard() {
    return _InfoCard(
      icon: Icons.mosque_rounded,
      title: 'المسافة إلى الكعبة المشرفة',
      value: '${_distanceKm!.toStringAsFixed(1)} كم',
    );
  }

  Widget _buildMap(Position position) {
    final start = LatLng(
      position.latitude,
      position.longitude,
    );

    const kaaba = LatLng(
      QiblaService.kaabaLatitude,
      QiblaService.kaabaLongitude,
    );

    final route = QiblaService.greatCircleRoute(
      startLatitude: position.latitude,
      startLongitude: position.longitude,
      endLatitude: QiblaService.kaabaLatitude,
      endLongitude: QiblaService.kaabaLongitude,
    );

    final routePoints = route
        .map((point) => LatLng(
              point.latitude,
              point.longitude,
            ))
        .toList();

    final fitPoints = <LatLng>[start, kaaba];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'المسار المباشر إلى مكة المكرمة',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: SizedBox(
            height: 260,
            child: FlutterMap(
              options: MapOptions(
                initialCameraFit: CameraFit.coordinates(
                  coordinates: fitPoints,
                  padding: const EdgeInsets.all(42),
                ),
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
                      strokeWidth: 4,
                      color: AppColors.gold,
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: start,
                      width: 42,
                      height: 42,
                      child: const Icon(
                        Icons.my_location_rounded,
                        color: Colors.blue,
                        size: 30,
                      ),
                    ),
                    Marker(
                      point: kaaba,
                      width: 46,
                      height: 46,
                      child: const Icon(
                        Icons.mosque_rounded,
                        color: AppColors.gold,
                        size: 34,
                      ),
                    ),
                  ],
                ),
                RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution(
                      '© OpenStreetMap contributors',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSensorUnavailable() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.emerald.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.explore_off_rounded,
            size: 38,
            color: AppColors.gold,
          ),
          SizedBox(height: 10),
          Text(
            'تعذر قراءة البوصلة',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 5),
          Text(
            'قد لا يحتوي هاتفك على مستشعر مغناطيسي، '
            'أو قد تكون قراءته غير متاحة.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAccuracyNote() {
    return Text(
      'ملاحظة: اتجاه القبلة محسوب جغرافيًا، '
      'أما دقة التوجيه الحي فتعتمد على معايرة البوصلة '
      'والتداخل المغناطيسي وجودة مستشعر الهاتف.',
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodySmall,
    );
  }
}

class _PrayerRug extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 112,
      height: 155,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF087F5B),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: AppColors.gold,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: AppColors.gold.withValues(alpha: 0.85),
            width: 1.2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.change_history_rounded,
              color: AppColors.gold,
              size: 25,
            ),
            SizedBox(height: 7),
            Icon(
              Icons.mosque_rounded,
              color: Colors.white,
              size: 42,
            ),
            SizedBox(height: 7),
            Icon(
              Icons.star_rounded,
              color: AppColors.gold,
              size: 19,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.emerald.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Icon(
  icon,
  color: AppColors.gold,
  size: 30,
),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
