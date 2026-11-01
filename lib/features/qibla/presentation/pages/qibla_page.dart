
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';

import '../../data/datasources/qibla_landmark_local_data_source.dart';
import '../../data/repositories/qibla_landmark_repository_impl.dart';
import '../../domain/models/qibla_landmark.dart';
import '../../domain/services/qibla_service.dart';
import '../widgets/offline_world_map.dart';

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
  static const Color _historicalColor = Color(0xFF9B7132);

  late final QiblaLandmarkRepositoryImpl _landmarkRepository;

  Position? _position;

  double? _qiblaBearing;
  double? _distanceKm;
  double? _declination;

  double? _magneticHeading;
  double? _trueHeading;
  double? _relativeQiblaAngle;

  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isLoadingLandmarks = true;

  String? _locationError;
  String? _landmarkError;
  String? _selectedCountry;

  List<QiblaLandmark> _landmarks = [];

  Stream<CompassEvent>? _compassStream;
  StreamSubscription<CompassEvent>? _compassSubscription;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _landmarkRepository = QiblaLandmarkRepositoryImpl(
      dataSource: QiblaLandmarkLocalDataSource(),
    );

    _connectCompass();

    _loadLandmarks();
    _loadLocation();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _compassSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _connectCompass();
      _loadLocation(silent: true);
    } else if (state == AppLifecycleState.paused) {
      _compassSubscription?.cancel();
      _compassSubscription = null;
    }
  }

  void _connectCompass() {
    _compassSubscription?.cancel();

    _compassStream = FlutterCompass.events;

    _compassSubscription = _compassStream?.listen(
      _onCompassEvent,
      onError: (_) {
        if (!mounted) return;

        setState(() {
          _magneticHeading = null;
          _trueHeading = null;
          _relativeQiblaAngle = null;
        });
      },
    );
  }

  void _onCompassEvent(CompassEvent event) {
    final heading = event.heading;

    if (heading == null || !heading.isFinite) {
      if (!mounted) return;

      setState(() {
        _magneticHeading = null;
        _trueHeading = null;
        _relativeQiblaAngle = null;
      });
      return;
    }

    final trueHeading = _declination != null
        ? QiblaService.magneticToTrueHeading(
            magneticHeading: heading,
            declination: _declination!,
          )
        : QiblaService.normalize(heading);

    final relativeAngle = _qiblaBearing == null
        ? null
        : QiblaService.shortestAngleDifference(
            _qiblaBearing!,
            trueHeading,
          );

    if (!mounted) return;

    setState(() {
      _magneticHeading = heading;
      _trueHeading = trueHeading;
      _relativeQiblaAngle = relativeAngle;
    });
  }

  Future<void> _loadLandmarks() async {
    if (!mounted) return;

    setState(() {
      _isLoadingLandmarks = true;
      _landmarkError = null;
    });

    try {
      final results = await _landmarkRepository.getAll();

      if (!mounted) return;

      setState(() {
        _landmarks = results;
        _isLoadingLandmarks = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _landmarkError = 'تعذر تحميل بيانات المعالم المحلية.';
        _isLoadingLandmarks = false;
      });
    }
  }

  Future<void> _loadLocation({bool silent = false}) async {
    if (_isRefreshing) return;

    _isRefreshing = true;

    if (mounted) {
      setState(() {
        if (!silent && _position == null) {
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

      // Recalculate the true heading after the new declination is loaded.
      if (_magneticHeading != null) {
        _onCompassEvent(
          CompassEvent(
            heading: _magneticHeading,
          ),
        );
      }
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
    } catch (_) {
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

  bool _isIslamicLandmark(QiblaLandmark landmark) {
    return landmark.id.startsWith('islamic-');
  }

  String _localizedCategory(QiblaLandmark landmark) {
    switch (landmark.category) {
      case QiblaLandmarkCategory.landmark:
        return 'معلم تاريخي';
      case QiblaLandmarkCategory.historicalSite:
        return 'موقع تاريخي';
      default:
        return 'موقع تراثي';
    }
  }

  IconData _landmarkIcon(QiblaLandmark landmark) {
    if (_isIslamicLandmark(landmark)) {
      if (landmark.id.contains('citadel')) {
        return Icons.castle_rounded;
      }

      return Icons.mosque_rounded;
    }

    if (landmark.id.contains('pyramid')) {
      return Icons.account_balance_rounded;
    }

    if (landmark.id.contains('wall')) {
      return Icons.landscape_rounded;
    }

    if (landmark.id.contains('colosseum')) {
      return Icons.stadium_rounded;
    }

    if (landmark.id.contains('petra')) {
      return Icons.terrain_rounded;
    }

    return Icons.account_balance_rounded;
  }

  Color _landmarkColor(QiblaLandmark landmark) {
    return _isIslamicLandmark(landmark)
        ? _primaryGreen
        : _historicalColor;
  }

  String _directionInstruction(double angle) {
    final difference = angle.abs();

    if (difference <= 3) {
      return 'أنت الآن في اتجاه القبلة تقريباً';
    }

    if (difference <= 12) {
      return 'اقتربت من اتجاه القبلة، اضبط الهاتف قليلاً';
    }

    if (angle > 0) {
      return 'أدر الهاتف إلى اليمين باتجاه القبلة';
    }

    return 'أدر الهاتف إلى اليسار باتجاه القبلة';
  }

  String _directionStep(double angle) {
    final difference = angle.abs();

    if (difference <= 3) {
      return 'الخطوة 4: ثبّت الهاتف، أنت بمحاذاة اتجاه القبلة';
    }

    if (difference <= 12) {
      return 'الخطوة 3: اقتربت، أجرِ تعديلاً بسيطاً';
    }

    if (difference <= 45) {
      return angle > 0
          ? 'الخطوة 2: أدر الهاتف يميناً تدريجياً'
          : 'الخطوة 2: أدر الهاتف يساراً تدريجياً';
    }

    return angle > 0
        ? 'الخطوة 1: ابدأ بالدوران نحو اليمين'
        : 'الخطوة 1: ابدأ بالدوران نحو اليسار';
  }

  void _openLandmark(QiblaLandmark landmark) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final isDark =
            Theme.of(sheetContext).brightness == Brightness.dark;

        final sheetColor = isDark
            ? const Color(0xFF172820)
            : Colors.white;

        final mainTextColor =
            isDark ? Colors.white : const Color(0xFF19382E);

        final secondaryTextColor =
            isDark ? Colors.white70 : Colors.black54;

        return DraggableScrollableSheet(
          initialChildSize: 0.68,
          minChildSize: 0.40,
          maxChildSize: 0.94,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: sheetColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 30),
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 5,
                      decoration: BoxDecoration(
                        color: secondaryTextColor.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 23),
                  _buildLandmarkHero(landmark),
                  const SizedBox(height: 22),
                  Text(
                    landmark.nameAr,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: mainTextColor,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    landmark.nameEn,
                    textAlign: TextAlign.left,
                    textDirection: TextDirection.ltr,
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _detailRow(
                    Icons.location_on_outlined,
                    [
                      if (landmark.cityAr?.isNotEmpty == true)
                        landmark.cityAr!,
                      landmark.countryCode,
                    ].join('، '),
                    mainTextColor,
                    secondaryTextColor,
                  ),
                  if (landmark.historicalPeriodAr?.isNotEmpty == true)
                    _detailRow(
                      Icons.history_rounded,
                      landmark.historicalPeriodAr!,
                      mainTextColor,
                      secondaryTextColor,
                    ),
                  if (landmark.establishedYear != null)
                    _detailRow(
                      Icons.calendar_today_outlined,
                      _formatHistoricalYear(landmark.establishedYear!),
                      mainTextColor,
                      secondaryTextColor,
                    ),
                  const SizedBox(height: 18),
                  _sectionHeading('نبذة تاريخية', mainTextColor),
                  const SizedBox(height: 9),
                  Text(
                    landmark.descriptionAr,
                    textAlign: TextAlign.justify,
                    style: TextStyle(
                      color: secondaryTextColor,
                      height: 1.8,
                      fontSize: 13,
                    ),
                  ),
                  if (landmark.historicalEvents.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _sectionHeading('المحطات التاريخية', mainTextColor),
                    const SizedBox(height: 13),
                    ...landmark.chronologicalEvents.map(
                      (event) => _buildHistoricalEvent(
                        event,
                        mainTextColor,
                        secondaryTextColor,
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  _sectionHeading('الموقع الجغرافي', mainTextColor),
                  const SizedBox(height: 9),
                  Text(
                    '${landmark.latitude.toStringAsFixed(5)}, ${landmark.longitude.toStringAsFixed(5)}',
                    textDirection: TextDirection.ltr,
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontFeatures: const [
                        FontFeature.tabularFigures(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  _sectionHeading('المصادر والمراجع', mainTextColor),
                  const SizedBox(height: 10),
                  if (landmark.sources.isEmpty)
                    Text(
                      'لا توجد مراجع مسجلة لهذا المعلم بعد.',
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 12,
                      ),
                    )
                  else
                    ...landmark.sources.map(
                      (source) => Container(
                        margin: const EdgeInsets.only(bottom: 9),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: secondaryTextColor.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.menu_book_rounded,
                              color: _gold,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    source.name,
                                    style: TextStyle(
                                      color: mainTextColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  SelectableText(
                                    source.url,
                                    textDirection: TextDirection.ltr,
                                    style: const TextStyle(
                                      color: _primaryGreen,
                                      fontSize: 10,
                                    ),
                                  ),
                                  if (source.publisher?.isNotEmpty == true)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 5),
                                      child: Text(
                                        source.publisher!,
                                        style: TextStyle(
                                          color: secondaryTextColor,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  if (source.license?.isNotEmpty == true)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        'الترخيص: ${source.license}',
                                        style: TextStyle(
                                          color: secondaryTextColor,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        setState(() {
                          _selectedCountry = landmark.countryCode;
                        });
                      },
                      icon: const Icon(Icons.travel_explore_rounded),
                      label: const Text('العودة إلى الأطلس'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLandmarkHero(QiblaLandmark landmark) {
    final color = _landmarkColor(landmark);

    return Container(
      height: 170,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, _darkGreen],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -35,
            child: Icon(
              _landmarkIcon(landmark),
              size: 180,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Center(
            child: Icon(
              _landmarkIcon(landmark),
              size: 76,
              color: _gold,
            ),
          ),
          Positioned(
            bottom: 14,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _localizedCategory(landmark),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatHistoricalYear(int year) {
    if (year < 0) {
      return 'التاريخ التقريبي: ${year.abs()} ق.م';
    }

    return 'التاريخ التقريبي: $year م';
  }

  Widget _sectionHeading(String title, Color color) {
    return Text(
      title,
      style: TextStyle(
        color: color,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildHistoricalEvent(
    QiblaLandmarkHistoricalEvent event,
    Color mainTextColor,
    Color secondaryTextColor,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 11,
            height: 11,
            margin: const EdgeInsets.only(top: 5),
            decoration: const BoxDecoration(
              color: _gold,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.dateLabelAr,
                  style: const TextStyle(
                    color: _historicalColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  event.titleAr,
                  style: TextStyle(
                    color: mainTextColor,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  event.descriptionAr,
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 11,
                    height: 1.65,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(
    IconData icon,
    String value,
    Color textColor,
    Color secondaryColor,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: _gold, size: 19),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: secondaryColor,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
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
          'قبلة وأطلس',
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
                    onRefresh: () async {
                      await Future.wait([
                        _loadLocation(),
                        _loadLandmarks(),
                      ]);
                    },
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
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
                        const SizedBox(height: 18),
                        _buildDirectionGuide(
                          cardColor,
                          textColor,
                          secondaryColor,
                        ),
                        const SizedBox(height: 25),
                        _buildAtlasHeader(textColor, secondaryColor),
                        const SizedBox(height: 13),
                        _buildAtlasMap(
                          cardColor,
                          textColor,
                          secondaryColor,
                        ),
                        const SizedBox(height: 22),
                        _buildLandmarkCollection(
                          cardColor,
                          textColor,
                          secondaryColor,
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
          'احسب اتجاه القبلة واستكشف المعالم الإسلامية والتاريخية حول العالم',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: secondaryColor,
            fontSize: 12,
            height: 1.6,
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
          if (_qiblaBearing != null && _relativeQiblaAngle != null)
            Column(
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
                        turns: _relativeQiblaAngle! / 360.0,
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
                  'الانحراف عن اتجاه القبلة',
                  style: TextStyle(
                    color: secondaryColor,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  '${_relativeQiblaAngle!.abs().toStringAsFixed(1)}°',
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
                  _directionInstruction(_relativeQiblaAngle!),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                _buildHeadingDetails(secondaryColor),
              ],
            )
          else
            _buildCompassUnavailable(textColor, secondaryColor),
        ],
      ),
    );
  }

  Widget _buildHeadingDetails(Color secondaryColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: secondaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          _headingRow(
            'اتجاه القبلة الجغرافي',
            _qiblaBearing == null ? '--' : _formatBearing(_qiblaBearing!),
            secondaryColor,
          ),
          const SizedBox(height: 8),
          _headingRow(
            'اتجاه الهاتف الحقيقي',
            _trueHeading == null ? '--' : _formatBearing(_trueHeading!),
            secondaryColor,
          ),
          const SizedBox(height: 8),
          _headingRow(
            'قراءة الحساس المغناطيسية',
            _magneticHeading == null
                ? '--'
                : _formatBearing(_magneticHeading!),
            secondaryColor,
          ),
        ],
      ),
    );
  }

  Widget _headingRow(
    String label,
    String value,
    Color secondaryColor,
  ) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: secondaryColor,
              fontSize: 10,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: _gold,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
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
          onPressed: _connectCompass,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('إعادة الاتصال بالحساس'),
        ),
      ],
    );
  }

  Widget _buildDirectionGuide(
    Color cardColor,
    Color textColor,
    Color secondaryColor,
  ) {
    final angle = _relativeQiblaAngle;

    final isAligned = angle != null && angle.abs() <= 3;

    final steps = [
      'أمسك الهاتف أفقياً وبعيداً عن المعادن والمغناطيس.',
      'انتظر استقرار قراءة البوصلة قبل البدء بالدوران.',
      angle == null
          ? 'انتظر قراءة حساس الاتجاه.'
          : _directionStep(angle),
      isAligned
          ? 'ثبّت الهاتف؛ أنت بمحاذاة اتجاه القبلة تقريباً.'
          : 'واصل التعديل حتى تقترب زاوية الانحراف من الصفر.',
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(
          color: _gold.withValues(alpha: 0.24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.assistant_direction_rounded,
                color: _gold,
                size: 23,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  'خطوات ضبط اتجاه القبلة',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (isAligned)
                const Icon(
                  Icons.check_circle_rounded,
                  color: _primaryGreen,
                ),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(steps.length, (index) {
            final active = index == 2 && angle != null;
            final completed = index == 3 && isAligned;

            return Padding(
              padding: const EdgeInsets.only(bottom: 13),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 27,
                    height: 27,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: completed
                          ? _primaryGreen
                          : active
                              ? _gold.withValues(alpha: 0.22)
                              : secondaryColor.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: completed
                        ? const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 16,
                          )
                        : Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: active ? _historicalColor : textColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      steps[index],
                      style: TextStyle(
                        color: textColor,
                        fontSize: 11,
                        height: 1.6,
                        fontWeight: active || completed
                            ? FontWeight.w700
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          const Divider(height: 14),
          Text(
            'ملاحظة: اتجاه الهاتف يعتمد على حساس الجهاز، '
            'ولا يمكن ضمان دقته من التطبيق وحده.',
            style: TextStyle(
              color: secondaryColor,
              fontSize: 10,
              height: 1.6,
            ),
          ),
        ],
      ),
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

  Widget _buildAtlasHeader(
    Color textColor,
    Color secondaryColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.public_rounded,
              color: _gold,
              size: 25,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                'أطلس العالم والمعالم التاريخية',
                style: TextStyle(
                  color: textColor,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: _primaryGreen.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'OFFLINE',
                style: TextStyle(
                  color: _primaryGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  letterSpacing: 0.7,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Text(
          'استكشف دول العالم دون إنترنت، واضغط على أي دولة لاكتشاف موقعها.',
          style: TextStyle(
            color: secondaryColor,
            fontSize: 11,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildAtlasMap(
    Color cardColor,
    Color textColor,
    Color secondaryColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(
              height: 430,
              width: double.infinity,
              child: OfflineWorldMap(
                showGrid: true,
                initialScale: 1,
                onCountrySelected: (country) {
                  if (!mounted) return;

                  setState(() {
                    _selectedCountry = country;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 13),
          if (_selectedCountry != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 13,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: _primaryGreen.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    color: _primaryGreen,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedCountry!,
                      style: const TextStyle(
                        color: _primaryGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'مسح التحديد',
                    onPressed: () {
                      setState(() {
                        _selectedCountry = null;
                      });
                    },
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.touch_app_rounded,
                color: _gold,
                size: 18,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  'اسحب الخريطة للتحريك، واستخدم إصبعين للتكبير والتصغير، واضغط على الدولة لتحديدها.',
                  style: TextStyle(
                    color: secondaryColor,
                    fontSize: 10,
                    height: 1.6,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.offline_pin_rounded,
                color: _primaryGreen,
                size: 18,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  'حدود الدول وبيانات الخريطة الأساسية مضمنة في التطبيق ولا تحتاج إلى الإنترنت.',
                  style: TextStyle(
                    color: secondaryColor,
                    fontSize: 10,
                    height: 1.6,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLandmarkCollection(
    Color cardColor,
    Color textColor,
    Color secondaryColor,
  ) {
    if (_isLoadingLandmarks) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(
            color: _gold,
          ),
        ),
      );
    }

    if (_landmarks.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.travel_explore_rounded,
              color: _gold,
              size: 35,
            ),
            const SizedBox(height: 10),
            Text(
              'لا توجد معالم متاحة حالياً',
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_landmarkError != null) ...[
              const SizedBox(height: 8),
              Text(
                _landmarkError!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: secondaryColor,
                  fontSize: 11,
                ),
              ),
            ],
            TextButton.icon(
              onPressed: _loadLandmarks,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة تحميل البيانات'),
            ),
          ],
        ),
      );
    }

    final islamicLandmarks = _landmarks
        .where(_isIslamicLandmark)
        .toList(growable: false);

    final wonders = _landmarks
        .where((item) => !_isIslamicLandmark(item))
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _collectionTitle(
          'المعالم الإسلامية',
          '${islamicLandmarks.length} مواقع',
          textColor,
        ),
        const SizedBox(height: 11),
        if (islamicLandmarks.isEmpty)
          _emptyCollectionMessage(
            'ستظهر هنا المساجد والمعالم الإسلامية عند إضافتها إلى قاعدة البيانات.',
            cardColor,
            secondaryColor,
          )
        else
          _horizontalLandmarkCards(
            islamicLandmarks,
            cardColor,
            textColor,
            secondaryColor,
          ),
        const SizedBox(height: 22),
        _collectionTitle(
          'العجائب والمواقع التاريخية',
          '${wonders.length} مواقع',
          textColor,
        ),
        const SizedBox(height: 11),
        _horizontalLandmarkCards(
          wonders,
          cardColor,
          textColor,
          secondaryColor,
        ),
      ],
    );
  }

  Widget _emptyCollectionMessage(
    String message,
    Color cardColor,
    Color secondaryColor,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: secondaryColor,
          fontSize: 11,
          height: 1.6,
        ),
      ),
    );
  }

  Widget _collectionTitle(
    String title,
    String count,
    Color textColor,
  ) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Text(
          count,
          style: const TextStyle(
            color: _gold,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _horizontalLandmarkCards(
    List<QiblaLandmark> landmarks,
    Color cardColor,
    Color textColor,
    Color secondaryColor,
  ) {
    if (landmarks.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 158,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: landmarks.length,
        separatorBuilder: (_, __) => const SizedBox(width: 11),
        itemBuilder: (context, index) {
          final landmark = landmarks[index];
          final color = _landmarkColor(landmark);

          return SizedBox(
            width: 190,
            child: Material(
              color: cardColor,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => _openLandmark(landmark),
                child: Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: secondaryColor.withValues(alpha: 0.10),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.11),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _landmarkIcon(landmark),
                              color: color,
                              size: 21,
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.arrow_outward_rounded,
                            color: _gold,
                            size: 17,
                          ),
                        ],
                      ),
                      const SizedBox(height: 11),
                      Text(
                        landmark.nameAr,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        landmark.cityAr ?? landmark.countryCode,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: secondaryColor,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAccuracyNote(Color secondaryColor) {
    final accuracy = _position?.accuracy;

    String accuracyText;

    if (accuracy == null) {
      accuracyText = 'لم تتوفر قراءة دقة GPS بعد.';
    } else if (accuracy <= 10) {
      accuracyText =
          'دقة الموقع جيدة جداً وفق قراءة GPS الحالية (±${accuracy.toStringAsFixed(1)} متر).';
    } else if (accuracy <= 30) {
      accuracyText =
          'دقة الموقع متوسطة (±${accuracy.toStringAsFixed(1)} متر). انتظر قليلاً لتحسين القراءة.';
    } else {
      accuracyText =
          'دقة الموقع منخفضة حالياً (±${accuracy.toStringAsFixed(1)} متر). انتقل إلى مكان مفتوح وحاول مجدداً.';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _gold.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _gold.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.gps_fixed_rounded,
                color: _gold,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  accuracyText,
                  style: TextStyle(
                    color: secondaryColor,
                    fontSize: 11,
                    height: 1.7,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Row(
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
                  'لتحسين قراءة البوصلة، أبعد الهاتف عن المعادن '
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
