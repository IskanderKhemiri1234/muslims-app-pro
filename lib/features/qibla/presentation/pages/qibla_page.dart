import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  static const String _languageKey = 'qibla_page_language';

  static const int _invalidCompassReadingsThreshold = 3;

  late final QiblaLandmarkRepositoryImpl _landmarkRepository;

  String _language = 'ar';
  int _languageRevision = 0;

  bool get _isArabic => _language == 'ar';

  TextDirection get _textDirection =>
      _isArabic ? TextDirection.rtl : TextDirection.ltr;

  String _tr(String ar, String en, String fr) {
    switch (_language) {
      case 'en':
        return en;
      case 'fr':
        return fr;
      default:
        return ar;
    }
  }

  String _localizedLandmarkName(QiblaLandmark landmark) {
    if (_language == 'ar') return landmark.nameAr;

    return landmark.nameEn.trim().isNotEmpty
        ? landmark.nameEn
        : landmark.nameAr;
  }

  Future<void> _loadSavedLanguage() async {
    final revision = _languageRevision;

    try {
      final preferences = await SharedPreferences.getInstance();
      final String? saved = preferences.getString(_languageKey);

      if (!mounted || revision != _languageRevision) {
        return;
      }

      if (saved == 'ar' || saved == 'en' || saved == 'fr') {
        setState(() {
          _language = saved!;
        });
      }
    } catch (error, stackTrace) {
      debugPrint('Could not load saved language: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _changeLanguage(String language) async {
    if (!['ar', 'en', 'fr'].contains(language)) return;
    if (_language == language || !mounted) return;

    _languageRevision++;

    setState(() => _language = language);

    try {
      final preferences = await SharedPreferences.getInstance();

      if (!mounted) return;

      await preferences.setString(_languageKey, language);
    } catch (error) {
      debugPrint('Could not save language: $error');

      if (!mounted) return;

      _showMessage(
        _tr(
          'تعذر حفظ اختيار اللغة.',
          'Could not save the language preference.',
          'Impossible d’enregistrer la langue.',
        ),
      );
    }
  }

  void _showLanguageSelector() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      builder: (sheetContext) {
        final textColor =
            Theme.of(sheetContext).colorScheme.onSurface;

        return Directionality(
          textDirection: _textDirection,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _tr(
                      'لغة الصفحة',
                      'Page language',
                      'Langue de la page',
                    ),
                    style: TextStyle(
                      color: textColor,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _languageOption('ar', 'العربية'),
                  _languageOption('en', 'English'),
                  _languageOption('fr', 'Français'),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _languageOption(String code, String label) {
    final selected = _language == code;

    return ListTile(
      title: Text(label),
      trailing: selected
          ? const Icon(
              Icons.check_circle_rounded,
              color: _gold,
            )
          : null,
      onTap: () {
        Navigator.pop(context);
        unawaited(_changeLanguage(code));
      },
    );
  }

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
  bool _isAppActive = true;

  bool _isCompassUnavailable = false;
  bool _isCompassConnecting = false;

  bool _locationPermissionPermanentlyDenied = false;
  bool _locationServiceDisabled = false;

  int _invalidCompassReadings = 0;
  int _compassGeneration = 0;

  String? _locationError;
  String? _landmarkError;
  String? _selectedCountry;

  List<QiblaLandmark> _landmarks = [];

  StreamSubscription<CompassEvent>? _compassSubscription;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _landmarkRepository = QiblaLandmarkRepositoryImpl(
      dataSource: QiblaLandmarkLocalDataSource(),
    );

    unawaited(_connectCompass());
    unawaited(_loadLandmarks());
    unawaited(_loadLocation());
    unawaited(_loadSavedLanguage());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _isAppActive = false;
    _isCompassConnecting = false;

    _compassGeneration++;

    final subscription = _compassSubscription;
    _compassSubscription = null;

    if (subscription != null) {
      unawaited(subscription.cancel());
    }

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!_isAppActive) {
        _isAppActive = true;
        _invalidCompassReadings = 0;

        unawaited(_connectCompass());
        unawaited(_loadLocation(silent: true));
      }

      return;
    }

    if (_isAppActive) {
      _isAppActive = false;
      _disconnectCompass();
    }
  }

  Future<void> _connectCompass() async {
    if (!mounted || !_isAppActive) return;

    if (_compassSubscription != null ||
        _isCompassConnecting) {
      return;
    }

    _isCompassConnecting = true;

    final generation = ++_compassGeneration;

    StreamSubscription<CompassEvent>? newSubscription;

    try {
      final stream = FlutterCompass.events;

      if (stream == null) {
        if (mounted &&
            _isAppActive &&
            generation == _compassGeneration) {
          _setCompassUnavailable();
        }

        return;
      }

      newSubscription = stream.listen(
        (event) {
          if (!mounted ||
              !_isAppActive ||
              generation != _compassGeneration) {
            return;
          }

          _onCompassEvent(event);
        },
        onError: (Object error, StackTrace stackTrace) {
          if (!mounted ||
              !_isAppActive ||
              generation != _compassGeneration) {
            return;
          }

          debugPrint('Compass stream error: $error');

          _setCompassUnavailable();
        },
        onDone: () {
          if (!mounted ||
              generation != _compassGeneration) {
            return;
          }

          if (identical(
            _compassSubscription,
            newSubscription,
          )) {
            _compassSubscription = null;
          }

          _isCompassConnecting = false;

          _setCompassUnavailable();
        },
        cancelOnError: false,
      );

      if (!mounted ||
          !_isAppActive ||
          generation != _compassGeneration) {
        await newSubscription.cancel();
        return;
      }

      if (_compassSubscription != null) {
        await newSubscription.cancel();
        return;
      }

      _compassSubscription = newSubscription;
      _invalidCompassReadings = 0;

      if (mounted && _isCompassUnavailable) {
        setState(() {
          _isCompassUnavailable = false;
        });
      }
    } catch (error) {
      debugPrint('Compass connection error: $error');

      if (mounted &&
          _isAppActive &&
          generation == _compassGeneration) {
        _setCompassUnavailable();
      }

      if (newSubscription != null) {
        try {
          await newSubscription.cancel();
        } catch (cancelError) {
          debugPrint(
            'Compass subscription cancellation error: $cancelError',
          );
        }
      }
    } finally {
      if (generation == _compassGeneration) {
        _isCompassConnecting = false;
      }
    }
  }

  void _setCompassUnavailable() {
    if (!mounted) return;

    _invalidCompassReadings =
        _invalidCompassReadingsThreshold;

    setState(() {
      _isCompassUnavailable = true;
      _magneticHeading = null;
      _trueHeading = null;
      _relativeQiblaAngle = null;
    });
  }

  void _disconnectCompass() {
    _compassGeneration++;
    _isCompassConnecting = false;
    _invalidCompassReadings = 0;

    final subscription = _compassSubscription;
    _compassSubscription = null;

    if (subscription != null) {
      unawaited(subscription.cancel());
    }

    if (!mounted) {
      _magneticHeading = null;
      _trueHeading = null;
      _relativeQiblaAngle = null;
      return;
    }

    setState(() {
      _magneticHeading = null;
      _trueHeading = null;
      _relativeQiblaAngle = null;
    });
  }

  Future<void> _reconnectCompass() async {
    if (!mounted || !_isAppActive || _isCompassConnecting) {
      return;
    }

    _disconnectCompass();

    if (!mounted || !_isAppActive) return;

    setState(() {
      _isCompassUnavailable = false;
    });

    await _connectCompass();
  }

  void _onCompassEvent(CompassEvent event) {
    if (!mounted || !_isAppActive) return;

    final heading = event.heading;

    if (heading == null || !heading.isFinite) {
      _invalidCompassReadings++;

      if (_invalidCompassReadings >=
          _invalidCompassReadingsThreshold) {
        _setCompassUnavailable();
      } else {
        setState(() {
          _magneticHeading = null;
          _trueHeading = null;
          _relativeQiblaAngle = null;
        });
      }

      return;
    }

    try {
      final normalizedHeading =
          QiblaService.normalize(heading);

      if (!normalizedHeading.isFinite) {
        _invalidCompassReadings++;

        if (_invalidCompassReadings >=
            _invalidCompassReadingsThreshold) {
          _setCompassUnavailable();
        }

        return;
      }

      _invalidCompassReadings = 0;

      _magneticHeading = normalizedHeading;

      if (_isCompassUnavailable) {
        setState(() {
          _isCompassUnavailable = false;
        });
      }

      _recalculateCompassHeading();
    } catch (error) {
      debugPrint('Invalid compass heading: $error');

      _invalidCompassReadings++;

      if (_invalidCompassReadings >=
          _invalidCompassReadingsThreshold) {
        _setCompassUnavailable();
      }
    }
  }

  void _recalculateCompassHeading() {
    if (!mounted) return;

    final magneticHeading = _magneticHeading;

    if (magneticHeading == null ||
        !magneticHeading.isFinite) {
      setState(() {
        _trueHeading = null;
        _relativeQiblaAngle = null;
      });

      return;
    }

    double trueHeading;

    try {
      final declination = _declination;

      trueHeading =
          declination != null && declination.isFinite
              ? QiblaService.magneticToTrueHeading(
                  magneticHeading: magneticHeading,
                  declination: declination,
                )
              : QiblaService.normalize(magneticHeading);

      if (!trueHeading.isFinite) {
        trueHeading = QiblaService.normalize(
          magneticHeading,
        );
      }
    } catch (error) {
      debugPrint('True heading calculation error: $error');

      trueHeading = QiblaService.normalize(
        magneticHeading,
      );
    }

    double? relativeAngle;

    final bearing = _qiblaBearing;

    if (bearing != null && bearing.isFinite) {
      try {
        final calculatedAngle =
            QiblaService.shortestAngleDifference(
          bearing,
          trueHeading,
        );

        if (calculatedAngle.isFinite) {
          relativeAngle = calculatedAngle;
        }
      } catch (error) {
        debugPrint('Relative Qibla angle error: $error');
        relativeAngle = null;
      }
    }

    if (!mounted) return;

    setState(() {
      _trueHeading = trueHeading;
      _relativeQiblaAngle = relativeAngle;
      _isCompassUnavailable = false;
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

      final validResults = results.where((landmark) {
        try {
          return landmark.hasValidBasicData &&
              landmark.hasValidCoordinates;
        } catch (error) {
          debugPrint('Invalid landmark record: $error');
          return false;
        }
      }).toList(growable: false);

      if (!mounted) return;

      setState(() {
        _landmarks = validResults;
        _isLoadingLandmarks = false;

        if (validResults.length != results.length) {
          _landmarkError = _tr(
            'تم تجاهل بعض سجلات المعالم لوجود بيانات أو إحداثيات غير صالحة.',
            'Some landmark records were skipped because their data or coordinates are invalid.',
            'Certaines fiches de monuments ont été ignorées car leurs données ou coordonnées sont invalides.',
          );
        }
      });
    } catch (error) {
      debugPrint('Landmark loading error: $error');

      if (!mounted) return;

      setState(() {
        _landmarkError = _tr(
          'تعذر تحميل بيانات المعالم المحلية.',
          'Could not load local landmark data.',
          'Impossible de charger les données locales des monuments.',
        );

        _isLoadingLandmarks = false;
      });
    }
  }

  Future<void> _loadLocation({bool silent = false}) async {
    if (!mounted || _isRefreshing) return;

    setState(() {
      _isRefreshing = true;

      if (_position == null) {
        _isLoading = true;
      }

      if (!silent) {
        _locationError = null;
      }
    });

    try {
      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!mounted) return;

      if (!serviceEnabled) {
        _locationServiceDisabled = true;

        throw _LocationException(
          _tr(
            'خدمة الموقع GPS غير مفعّلة. فعّل الموقع من إعدادات الهاتف.',
            'Location services are disabled. Enable GPS in your device settings.',
            'Les services de localisation sont désactivés. Activez le GPS dans les paramètres du téléphone.',
          ),
        );
      }

      _locationServiceDisabled = false;

      var permission = await Geolocator.checkPermission();

      if (!mounted) return;

      if (permission == LocationPermission.denied &&
          !silent) {
        permission = await Geolocator.requestPermission();

        if (!mounted) return;
      }

      if (permission == LocationPermission.denied) {
        _locationPermissionPermanentlyDenied = false;

        throw _LocationException(
          _tr(
            'لم يتم منح إذن الوصول إلى الموقع. يمكنك السماح به ثم إعادة المحاولة.',
            'Location permission was not granted. Allow access and try again.',
            'L’autorisation de localisation n’a pas été accordée. Autorisez l’accès puis réessayez.',
          ),
        );
      }

      if (permission == LocationPermission.deniedForever) {
        _locationPermissionPermanentlyDenied = true;

        throw _LocationException(
          _tr(
            'إذن الموقع مرفوض نهائياً. افتح إعدادات التطبيق واسمح بالوصول إلى الموقع.',
            'Location permission is permanently denied. Open app settings and allow location access.',
            'L’autorisation de localisation est définitivement refusée. Ouvrez les paramètres de l’application pour autoriser l’accès.',
          ),
        );
      }

      if (permission == LocationPermission.unableToDetermine) {
        throw _LocationException(
          _tr(
            'تعذر تحديد حالة إذن الموقع على هذا الجهاز.',
            'Unable to determine location permission status on this device.',
            'Impossible de déterminer l’état de l’autorisation de localisation sur cet appareil.',
          ),
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          timeLimit: Duration(seconds: 20),
        ),
      );

      if (!mounted) return;

      if (!_isValidPosition(position)) {
        throw _LocationException(
          _tr(
            'استقبل التطبيق إحداثيات غير صالحة من خدمة الموقع.',
            'The location service returned invalid coordinates.',
            'Le service de localisation a renvoyé des coordonnées invalides.',
          ),
        );
      }

      final distance = QiblaService.calculateDistanceKm(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      if (!distance.isFinite || distance < 0) {
        throw _LocationException(
          _tr(
            'تعذر حساب المسافة الجغرافية إلى الكعبة.',
            'Could not calculate the geographic distance to the Kaaba.',
            'Impossible de calculer la distance géographique jusqu’à la Kaaba.',
          ),
        );
      }

      double? bearing;

      if (distance > 0.001) {
        try {
          final calculatedBearing =
              QiblaService.calculateQiblaBearing(
            latitude: position.latitude,
            longitude: position.longitude,
          );

          if (calculatedBearing.isFinite) {
            bearing = QiblaService.normalize(
              calculatedBearing,
            );
          }
        } catch (error) {
          debugPrint('Qibla bearing calculation error: $error');
          bearing = null;
        }
      }

      double? declination;

      try {
        final value =
            QiblaService.calculateMagneticDeclination(
          latitude: position.latitude,
          longitude: position.longitude,
        );

        if (value.isFinite && value.abs() <= 180) {
          declination = value;
        }
      } catch (error) {
        debugPrint('Magnetic declination error: $error');
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
        _locationPermissionPermanentlyDenied = false;
      });

      _recalculateCompassHeading();
    } on _LocationException catch (error) {
      if (!mounted) return;

      setState(() {
        if (!silent || _position == null) {
          _locationError = error.message;
        }

        _isLoading = false;
      });
    } on TimeoutException {
      if (!mounted) return;

      setState(() {
        if (!silent || _position == null) {
          _locationError = _tr(
            'انتهت مهلة تحديد الموقع. تحقق من GPS وحاول مرة أخرى.',
            'Location request timed out. Check GPS and try again.',
            'La localisation a expiré. Vérifiez le GPS et réessayez.',
          );
        }

        _isLoading = false;
      });
    } catch (error) {
      debugPrint('Location error: $error');

      if (!mounted) return;

      setState(() {
        if (!silent || _position == null) {
          _locationError = _tr(
            'تعذر تحديد موقعك حالياً. تحقق من إعدادات الموقع وحاول مجدداً.',
            'Unable to determine your location. Check location settings and try again.',
            'Impossible de déterminer votre position. Vérifiez les paramètres de localisation et réessayez.',
          );
        }

        _isLoading = false;
      });
    } finally {
      _isRefreshing = false;

      if (mounted) {
        setState(() {});
      }
    }
  }

  bool _isValidPosition(Position position) {
    return position.latitude.isFinite &&
        position.longitude.isFinite &&
        position.latitude >= -90 &&
        position.latitude <= 90 &&
        position.longitude >= -180 &&
        position.longitude <= 180;
  }

  Future<void> _openLocationSettings() async {
    try {
      await Geolocator.openLocationSettings();
    } catch (error) {
      debugPrint('Open location settings error: $error');

      if (!mounted) return;

      _showMessage(
        _tr(
          'تعذر فتح إعدادات الموقع على هذا الجهاز.',
          'Could not open location settings on this device.',
          'Impossible d’ouvrir les paramètres de localisation.',
        ),
      );
    }
  }

  Future<void> _openAppSettings() async {
    try {
      await Geolocator.openAppSettings();
    } catch (error) {
      debugPrint('Open app settings error: $error');

      if (!mounted) return;

      _showMessage(
        _tr(
          'تعذر فتح إعدادات التطبيق.',
          'Could not open app settings.',
          'Impossible d’ouvrir les paramètres de l’application.',
        ),
      );
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message)),
      );
  }

  String _formatBearing(double bearing) =>
      '${bearing.toStringAsFixed(1)}°';

  String _formatDistance(double distance) {
    if (distance >= 1000) {
      final value = (distance / 1000).toStringAsFixed(2);

      return _tr(
        '$value ألف كم',
        '$value thousand km',
        '$value milliers de km',
      );
    }

    return _tr(
      '${distance.toStringAsFixed(1)} كم',
      '${distance.toStringAsFixed(1)} km',
      '${distance.toStringAsFixed(1)} km',
    );
  }

  bool _isIslamicLandmark(QiblaLandmark landmark) {
    switch (landmark.category) {
      case QiblaLandmarkCategory.holyMosque:
      case QiblaLandmarkCategory.mosque:
      case QiblaLandmarkCategory.historicalMosque:
        return true;

      case QiblaLandmarkCategory.historicalSite:
      case QiblaLandmarkCategory.landmark:
        return false;
    }
  }

  String _localizedCategory(QiblaLandmark landmark) {
    switch (landmark.category) {
      case QiblaLandmarkCategory.holyMosque:
        return _tr(
          'مسجد مقدس',
          'Holy mosque',
          'Mosquée sacrée',
        );

      case QiblaLandmarkCategory.mosque:
        return _tr('مسجد', 'Mosque', 'Mosquée');

      case QiblaLandmarkCategory.historicalMosque:
        return _tr(
          'مسجد تاريخي',
          'Historic mosque',
          'Mosquée historique',
        );

      case QiblaLandmarkCategory.landmark:
        return _tr(
          'معلم تاريخي',
          'Historic landmark',
          'Monument historique',
        );

      case QiblaLandmarkCategory.historicalSite:
        return _tr(
          'موقع تاريخي',
          'Historic site',
          'Site historique',
        );
    }
  }

  IconData _landmarkIcon(QiblaLandmark landmark) {
    switch (landmark.category) {
      case QiblaLandmarkCategory.holyMosque:
      case QiblaLandmarkCategory.mosque:
      case QiblaLandmarkCategory.historicalMosque:
        return Icons.mosque_rounded;

      case QiblaLandmarkCategory.historicalSite:
      case QiblaLandmarkCategory.landmark:
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

        if (landmark.id.contains('citadel')) {
          return Icons.castle_rounded;
        }

        return Icons.account_balance_rounded;
    }
  }

  Color _landmarkColor(QiblaLandmark landmark) =>
      _isIslamicLandmark(landmark)
          ? _primaryGreen
          : _historicalColor;

  String _directionInstruction(double angle) {
    final difference = angle.abs();

    if (difference <= 3) {
      return _tr(
        'أنت الآن في اتجاه القبلة تقريباً',
        'You are approximately aligned with the Qibla',
        'Vous êtes presque aligné avec la Qibla',
      );
    }

    if (difference <= 12) {
      return _tr(
        'اقتربت من اتجاه القبلة، اضبط الهاتف قليلاً',
        'Almost aligned. Adjust your phone slightly',
        'Presque aligné. Ajustez légèrement votre téléphone',
      );
    }

    return angle > 0
        ? _tr(
            'أدر الهاتف إلى اليمين باتجاه القبلة',
            'Turn your phone to the right towards the Qibla',
            'Tournez votre téléphone vers la droite en direction de la Qibla',
          )
        : _tr(
            'أدر الهاتف إلى اليسار باتجاه القبلة',
            'Turn your phone to the left towards the Qibla',
            'Tournez votre téléphone vers la gauche en direction de la Qibla',
          );
  }

  String _directionStep(double angle) {
    final difference = angle.abs();

    if (difference <= 3) {
      return _tr(
        'ثبّت الهاتف، أنت بمحاذاة اتجاه القبلة',
        'Hold still. You are aligned with the Qibla',
        'Gardez le téléphone immobile, vous êtes aligné avec la Qibla',
      );
    }

    if (difference <= 12) {
      return _tr(
        'اقتربت، أجرِ تعديلاً بسيطاً',
        'Almost there. Make a small adjustment',
        'Vous y êtes presque. Effectuez un léger ajustement',
      );
    }

    return angle > 0
        ? _tr(
            'أدر الهاتف يميناً تدريجياً',
            'Gradually turn your phone to the right',
            'Tournez progressivement votre téléphone vers la droite',
          )
        : _tr(
            'أدر الهاتف يساراً تدريجياً',
            'Gradually turn your phone to the left',
            'Tournez progressivement votre téléphone vers la gauche',
          );
  }

  void _openLandmark(QiblaLandmark landmark) {
    if (!landmark.hasValidBasicData ||
        !landmark.hasValidCoordinates) {
      _showMessage(
        _tr(
          'بيانات هذا المعلم غير مكتملة أو غير صالحة.',
          'This landmark has incomplete or invalid data.',
          'Les données de ce monument sont incomplètes ou invalides.',
        ),
      );

      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final isDark =
            Theme.of(sheetContext).brightness == Brightness.dark;

        final sheetColor =
            isDark ? const Color(0xFF172820) : Colors.white;

        final mainTextColor =
            isDark ? Colors.white : const Color(0xFF19382E);

        final secondaryTextColor =
            isDark ? Colors.white70 : Colors.black54;

        final description = landmark.descriptionAr?.trim();

        return Directionality(
          textDirection: _textDirection,
          child: DraggableScrollableSheet(
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
                  padding: const EdgeInsets.fromLTRB(
                    22,
                    12,
                    22,
                    30,
                  ),
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 5,
                        decoration: BoxDecoration(
                          color: secondaryTextColor.withValues(
                            alpha: 0.3,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 23),
                    _buildLandmarkHero(landmark),
                    const SizedBox(height: 22),
                    Text(
                      _localizedLandmarkName(landmark),
                      textAlign: _isArabic
                          ? TextAlign.right
                          : TextAlign.left,
                      style: TextStyle(
                        color: mainTextColor,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_language != 'ar') ...[
                      const SizedBox(height: 5),
                      Text(
                        landmark.nameAr,
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    _detailRow(
                      Icons.location_on_outlined,
                      [
                        if (landmark.cityAr?.trim().isNotEmpty == true)
                          landmark.cityAr!.trim(),
                        landmark.countryCode,
                      ].join('، '),
                      mainTextColor,
                      secondaryTextColor,
                    ),
                    if (landmark.historicalPeriodAr
                            ?.trim()
                            .isNotEmpty ==
                        true)
                      _detailRow(
                        Icons.history_rounded,
                        landmark.historicalPeriodAr!.trim(),
                        mainTextColor,
                        secondaryTextColor,
                      ),
                    if (landmark.establishedYear != null)
                      _detailRow(
                        Icons.calendar_today_outlined,
                        _formatHistoricalYear(
                          landmark.establishedYear!,
                        ),
                        mainTextColor,
                        secondaryTextColor,
                      ),
                    const SizedBox(height: 18),
                    _sectionHeading(
                      _tr(
                        'نبذة تاريخية',
                        'Historical overview',
                        'Aperçu historique',
                      ),
                      mainTextColor,
                    ),
                    const SizedBox(height: 9),
                    Text(
                      description?.isNotEmpty == true
                          ? description!
                          : _tr(
                              'لا يتوفر وصف تاريخي لهذا المعلم حالياً.',
                              'No historical description is currently available.',
                              'Aucune description historique n’est disponible actuellement.',
                            ),
                      textAlign: TextAlign.justify,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        color: secondaryTextColor,
                        height: 1.8,
                        fontSize: 13,
                      ),
                    ),
                    if (landmark.chronologicalEvents.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _sectionHeading(
                        _tr(
                          'المحطات التاريخية',
                          'Historical timeline',
                          'Chronologie historique',
                        ),
                        mainTextColor,
                      ),
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
                    _sectionHeading(
                      _tr(
                        'الموقع الجغرافي',
                        'Geographic location',
                        'Emplacement géographique',
                      ),
                      mainTextColor,
                    ),
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
                    _sectionHeading(
                      _tr(
                        'المصادر والمراجع',
                        'Sources and references',
                        'Sources et références',
                      ),
                      mainTextColor,
                    ),
                    const SizedBox(height: 10),
                    if (landmark.sources.isEmpty)
                      Text(
                        _tr(
                          'لا توجد مراجع مسجلة لهذا المعلم بعد.',
                          'No references have been registered for this landmark yet.',
                          'Aucune référence n’est encore enregistrée pour ce monument.',
                        ),
                        style: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 12,
                        ),
                      )
                    else
                      ...landmark.sources.map((source) {
                        final sourceName = source.name.trim();
                        final sourceUrl = source.url.trim();

                        if (sourceName.isEmpty &&
                            sourceUrl.isEmpty) {
                          return const SizedBox.shrink();
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 9),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: secondaryTextColor.withValues(
                              alpha: 0.06,
                            ),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.menu_book_rounded,
                                color: _gold,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    if (sourceName.isNotEmpty)
                                      Text(
                                        sourceName,
                                        style: TextStyle(
                                          color: mainTextColor,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    if (sourceUrl.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      SelectableText(
                                        sourceUrl,
                                        textDirection:
                                            TextDirection.ltr,
                                        style: const TextStyle(
                                          color: _primaryGreen,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                    if (source.publisher
                                            ?.trim()
                                            .isNotEmpty ==
                                        true)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(
                                          top: 5,
                                        ),
                                        child: Text(
                                          source.publisher!.trim(),
                                          style: TextStyle(
                                            color:
                                                secondaryTextColor,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                    if (source.license
                                            ?.trim()
                                            .isNotEmpty ==
                                        true)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(
                                          top: 4,
                                        ),
                                        child: Text(
                                          '${_tr('الترخيص', 'License', 'Licence')}: ${source.license!.trim()}',
                                          style: TextStyle(
                                            color:
                                                secondaryTextColor,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                        },
                        icon: const Icon(Icons.arrow_back_rounded),
                        label: Text(
                          _tr(
                            'العودة إلى الأطلس',
                            'Back to atlas',
                            'Retour à l’atlas',
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
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
          ),
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
      return _tr(
        'التاريخ التقريبي: ${year.abs()} ق.م',
        'Approximate date: ${year.abs()} BCE',
        'Date approximative : ${year.abs()} av. J.-C.',
      );
    }

    return _tr(
      'التاريخ التقريبي: $year م',
      'Approximate date: $year CE',
      'Date approximative : $year apr. J.-C.',
    );
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
    final title = event.titleAr.trim();
    final description = event.descriptionAr.trim();
    final dateLabel = event.dateLabelAr.trim();

    if (title.isEmpty &&
        description.isEmpty &&
        dateLabel.isEmpty) {
      return const SizedBox.shrink();
    }

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
                if (dateLabel.isNotEmpty)
                  Text(
                    dateLabel,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(
                      color: _historicalColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                if (title.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    title,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      color: mainTextColor,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    description,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 11,
                      height: 1.65,
                    ),
                  ),
                ],
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
    if (value.trim().isEmpty) {
      return const SizedBox.shrink();
    }

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
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    final backgroundColor =
        isDark ? const Color(0xFF101C18) : _background;

    final cardColor =
        isDark ? const Color(0xFF1A2B24) : Colors.white;

    final textColor =
        isDark ? Colors.white : const Color(0xFF19382E);

    final secondaryColor =
        isDark ? Colors.white70 : Colors.black54;

    return Directionality(
      textDirection: _textDirection,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: _primaryGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: Text(
            _tr(
              'قبلة وأطلس',
              'Qibla & Atlas',
              'Qibla et Atlas',
            ),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 19,
            ),
          ),
          actions: [
            IconButton(
              tooltip: _tr(
                'تغيير اللغة',
                'Change language',
                'Changer de langue',
              ),
              onPressed: _showLanguageSelector,
              icon: const Icon(Icons.language_rounded),
            ),
            IconButton(
              tooltip: _tr(
                'تحديث الموقع',
                'Refresh location',
                'Actualiser la position',
              ),
              onPressed: _isRefreshing
                  ? null
                  : () => _loadLocation(),
              icon: _isRefreshing
                  ? const SizedBox(
                      width: 19,
                      height: 19,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: SafeArea(
          child: RefreshIndicator(
            color: _primaryGreen,
            onRefresh: () async {
              await Future.wait([
                _loadLocation(),
                _loadLandmarks(),
              ]);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                18,
                18,
                18,
                30,
              ),
              children: [
                _buildIntro(textColor, secondaryColor),
                const SizedBox(height: 18),
                _buildLocationStatus(
                  cardColor,
                  textColor,
                  secondaryColor,
                ),
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
                _buildAtlasHeader(
                  textColor,
                  secondaryColor,
                ),
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
      ),
    );
  }

  Widget _buildLocationStatus(
    Color cardColor,
    Color textColor,
    Color secondaryColor,
  ) {
    final hasError = _locationError != null;
    final isLoading = _isLoading && _position == null;

    if (!hasError && !isLoading && _position != null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: hasError
              ? Colors.orange.withValues(alpha: 0.35)
              : _gold.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            hasError
                ? Icons.location_off_rounded
                : Icons.gps_fixed_rounded,
            color: hasError ? Colors.orange : _gold,
            size: 23,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasError
                      ? _tr(
                          'تعذر تحديد الموقع',
                          'Location unavailable',
                          'Position indisponible',
                        )
                      : _tr(
                          'جارٍ تحديد موقعك',
                          'Finding your location',
                          'Recherche de votre position',
                        ),
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _locationError ??
                      _tr(
                        'يتم تحديد موقعك لحساب اتجاه القبلة. يمكنك استكشاف الأطلس والمعالم أثناء الانتظار.',
                        'Your location is being determined to calculate the Qibla. You can explore the atlas and landmarks while waiting.',
                        'Votre position est en cours de détermination pour calculer la Qibla. Vous pouvez explorer l’atlas et les monuments en attendant.',
                      ),
                  style: TextStyle(
                    color: secondaryColor,
                    fontSize: 11,
                    height: 1.6,
                  ),
                ),
                if (hasError) ...[
                  const SizedBox(height: 9),
                  Wrap(
                    spacing: 8,
                    runSpacing: 5,
                    children: [
                      TextButton(
                        onPressed: _isRefreshing
                            ? null
                            : () => _loadLocation(),
                        child: Text(
                          _tr(
                            'إعادة المحاولة',
                            'Try again',
                            'Réessayer',
                          ),
                        ),
                      ),
                      if (_locationServiceDisabled)
                        TextButton(
                          onPressed: _openLocationSettings,
                          child: Text(
                            _tr(
                              'إعدادات الموقع',
                              'Location settings',
                              'Paramètres de localisation',
                            ),
                          ),
                        ),
                      if (_locationPermissionPermanentlyDenied)
                        TextButton(
                          onPressed: _openAppSettings,
                          child: Text(
                            _tr(
                              'صلاحيات التطبيق',
                              'App permissions',
                              'Autorisations de l’application',
                            ),
                          ),
                        ),
                      if (!_locationServiceDisabled &&
                          !_locationPermissionPermanentlyDenied)
                        TextButton(
                          onPressed: _openAppSettings,
                          child: Text(
                            _tr(
                              'إعدادات الصلاحيات',
                              'Permission settings',
                              'Paramètres des autorisations',
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
                if (isLoading && _isRefreshing) ...[
                  const SizedBox(height: 10),
                  const LinearProgressIndicator(
                    color: _gold,
                    minHeight: 2,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntro(
    Color textColor,
    Color secondaryColor,
  ) {
    return Column(
      children: [
        const Icon(
          Icons.mosque_rounded,
          color: _gold,
          size: 38,
        ),
        const SizedBox(height: 9),
        Text(
          _tr(
            'توجّه نحو بيت الله الحرام',
            'Find the direction of the Kaaba',
            'Orientez-vous vers la Kaaba',
          ),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: textColor,
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _tr(
            'احسب اتجاه القبلة واستكشف المعالم الإسلامية والتاريخية حول العالم',
            'Calculate the Qibla direction and explore Islamic and historical landmarks around the world',
            'Calculez la direction de la Qibla et explorez les monuments islamiques et historiques du monde',
          ),
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
    final hasQibla = _qiblaBearing != null;
    final hasLiveDirection =
        hasQibla && _relativeQiblaAngle != null;

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
                _tr(
                  'البوصلة الحية',
                  'Live compass',
                  'Boussole en direct',
                ),
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          if (hasLiveDirection)
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
                              color: _primaryGreen.withValues(
                                alpha: 0.2,
                              ),
                              blurRadius: 22,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                      _buildCompassTicks(),
                      Positioned(
                        top: 20,
                        child: _compassLabel(_tr('شمال', 'N', 'N')),
                      ),
                      Positioned(
                        bottom: 20,
                        child: _compassLabel(_tr('جنوب', 'S', 'S')),
                      ),
                      Positioned(
                        right: 20,
                        child: _compassLabel(_tr('شرق', 'E', 'E')),
                      ),
                      Positioned(
                        left: 20,
                        child: _compassLabel(_tr('غرب', 'W', 'O')),
                      ),
                      AnimatedRotation(
                        turns: _relativeQiblaAngle! / 360.0,
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOut,
                        child: SizedBox(
                          width: 80,
                          height: 80,
                          child: CustomPaint(
                            painter: _AnimeSajdahCompassPainter(),
                          ),
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
                  _tr(
                    'الانحراف عن اتجاه القبلة',
                    'Deviation from Qibla direction',
                    'Écart par rapport à la Qibla',
                  ),
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
            _buildCompassUnavailable(
              textColor,
              secondaryColor,
              hasQibla: hasQibla,
            ),
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
            _tr(
              'اتجاه القبلة الجغرافي',
              'Geographic Qibla bearing',
              'Azimut géographique de la Qibla',
            ),
            _qiblaBearing == null ? '--' : _formatBearing(_qiblaBearing!),
            secondaryColor,
          ),
          const SizedBox(height: 8),
          _headingRow(
            _tr(
              'اتجاه الهاتف الحقيقي',
              'True phone heading',
              'Cap du téléphone (vrai nord)',
            ),
            _trueHeading == null ? '--' : _formatBearing(_trueHeading!),
            secondaryColor,
          ),
          const SizedBox(height: 8),
          _headingRow(
            _tr(
              'قراءة الحساس المغناطيسية',
              'Magnetic sensor reading',
              'Lecture du capteur magnétique',
            ),
            _magneticHeading == null ? '--' : _formatBearing(_magneticHeading!),
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
            fontFeatures: [
              FontFeature.tabularFigures(),
            ],
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
    Color secondaryColor, {
    required bool hasQibla,
  }) {
    final isAtKaaba =
        _distanceKm != null && _distanceKm! <= 0.001;

    final title = isAtKaaba
        ? _tr(
            'أنت عند الكعبة تقريباً',
            'You are near the Kaaba',
            'Vous êtes près de la Kaaba',
          )
        : !hasQibla
            ? _tr(
                'اتجاه القبلة غير متاح بعد',
                'Qibla direction not available yet',
                'Direction de la Qibla non disponible',
              )
            : _isCompassUnavailable
                ? _tr(
                    'حساس البوصلة غير متاح',
                    'Compass sensor unavailable',
                    'Capteur de boussole indisponible',
                  )
                : _tr(
                    'في انتظار قراءة البوصلة',
                    'Waiting for compass reading',
                    'En attente de la lecture de la boussole',
                  );

    final message = isAtKaaba
        ? _tr(
            'المسافة المحسوبة تشير إلى أنك قريب جداً من الكعبة؛ لذلك لا يكون اتجاه المسار إليها معرفاً.',
            'The calculated distance indicates that you are very close to the Kaaba, so a route direction is not defined.',
            'La distance calculée indique que vous êtes très proche de la Kaaba ; un azimut de trajet n’est donc pas défini.',
          )
        : !hasQibla
            ? _tr(
                'يلزم تحديد موقعك أولاً لحساب اتجاه القبلة. يمكنك استخدام الأطلس والمعالم دون GPS.',
                'Your location is required to calculate the Qibla. You can use the atlas and landmarks without GPS.',
                'Votre position est nécessaire pour calculer la Qibla. Vous pouvez utiliser l’atlas et les monuments sans GPS.',
              )
            : _isCompassUnavailable
                ? _tr(
                    'اتجاه القبلة الجغرافي محسوب، لكن حساس البوصلة لا يقدم حالياً قراءات صالحة. تحقق من الحساس وحاول إعادة الاتصال.',
                    'The geographic Qibla bearing is calculated, but the compass sensor is not currently providing valid readings. Check the sensor and try reconnecting.',
                    'L’azimut géographique de la Qibla est calculé, mais le capteur ne fournit pas actuellement de lectures valides. Vérifiez le capteur et réessayez.',
                  )
                : _tr(
                    'تم الاتصال بحساس البوصلة. ينتظر التطبيق أول قراءة صالحة لتفعيل التوجيه المباشر.',
                    'The compass sensor is connected. The app is waiting for its first valid reading to enable live guidance.',
                    'Le capteur de boussole est connecté. L’application attend sa première lecture valide pour activer le guidage en direct.',
                  );

    return Column(
      children: [
        Icon(
          isAtKaaba
              ? Icons.mosque_rounded
              : !hasQibla
                  ? Icons.location_searching_rounded
                  : _isCompassUnavailable
                      ? Icons.sensors_off_rounded
                      : Icons.explore_rounded,
          color: isAtKaaba
              ? _gold
              : _isCompassUnavailable
                  ? Colors.orange
                  : _gold,
          size: 45,
        ),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: secondaryColor,
            fontSize: 12,
            height: 1.6,
          ),
        ),
        if (!hasQibla && !isAtKaaba) ...[
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _isRefreshing
                ? null
                : () => _loadLocation(),
            icon: const Icon(Icons.refresh_rounded),
            label: Text(
              _tr(
                'تحديث الموقع',
                'Refresh location',
                'Actualiser la position',
              ),
            ),
          ),
        ] else if (hasQibla &&
            !isAtKaaba &&
            _isCompassUnavailable) ...[
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _isCompassConnecting
                ? null
                : _reconnectCompass,
            icon: _isCompassConnecting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.refresh_rounded),
            label: Text(
              _tr(
                'إعادة الاتصال بالحساس',
                'Reconnect sensor',
                'Reconnecter le capteur',
              ),
            ),
          ),
        ],
        if (hasQibla) ...[
          const SizedBox(height: 12),
          _buildHeadingDetails(secondaryColor),
        ],
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
      _tr(
        'أمسك الهاتف أفقياً وبعيداً عن المعادن والمغناطيس.',
        'Hold the phone horizontally and keep it away from metal and magnets.',
        'Tenez le téléphone horizontalement, loin des métaux et des aimants.',
      ),
      _tr(
        'انتظر استقرار قراءة البوصلة قبل البدء بالدوران.',
        'Wait for the compass reading to stabilize before turning.',
        'Attendez que la boussole se stabilise avant de tourner.',
      ),
      angle == null
          ? _tr(
              'انتظر حساب اتجاه القبلة وتوفر قراءة الحساس.',
              'Wait for the Qibla calculation and a valid sensor reading.',
              'Attendez le calcul de la Qibla et une lecture valide du capteur.',
            )
          : _directionStep(angle),
      isAligned
          ? _tr(
              'ثبّت الهاتف؛ أنت بمحاذاة اتجاه القبلة تقريباً.',
              'Hold the phone still; you are approximately aligned with the Qibla.',
              'Gardez le téléphone immobile ; vous êtes presque aligné avec la Qibla.',
            )
          : _tr(
              'واصل التعديل حتى تقترب زاوية الانحراف من الصفر.',
              'Keep adjusting until the deviation angle approaches zero.',
              'Continuez à ajuster jusqu’à ce que l’écart approche zéro.',
            ),
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
                  _tr(
                    'خطوات ضبط اتجاه القبلة',
                    'How to align with the Qibla',
                    'Comment vous aligner avec la Qibla',
                  ),
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
                              : secondaryColor.withValues(
                                  alpha: 0.10,
                                ),
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
                              color: active
                                  ? _historicalColor
                                  : textColor,
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
            _tr(
              'ملاحظة: اتجاه الهاتف يعتمد على حساس الجهاز، ولا يمكن ضمان دقته من التطبيق وحده.',
              'Note: The phone heading depends on the device sensor. Its accuracy cannot be guaranteed by the app alone.',
              'Remarque : l’orientation du téléphone dépend du capteur de l’appareil. L’application seule ne peut pas garantir sa précision.',
            ),
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
            title: _tr(
              'اتجاه القبلة',
              'Qibla bearing',
              'Direction de la Qibla',
            ),
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
            title: _tr(
              'المسافة إلى الكعبة',
              'Distance to Kaaba',
              'Distance jusqu’à la Kaaba',
            ),
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
                _tr(
                  'أطلس العالم والمعالم التاريخية',
                  'World atlas and historical landmarks',
                  'Atlas du monde et monuments historiques',
                ),
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
          _tr(
            'استكشف حدود دول العالم دون إنترنت. هذه خريطة جغرافية عامة وليست خريطة شوارع أو مبانٍ.',
            'Explore country borders offline. This is a general geographic map, not a street or building map.',
            'Explorez les frontières des pays hors ligne. Il s’agit d’une carte géographique générale, pas d’une carte des rues ou des bâtiments.',
          ),
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
                    tooltip: _tr(
                      'مسح التحديد',
                      'Clear selection',
                      'Effacer la sélection',
                    ),
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
                  _tr(
                    'اسحب الخريطة للتحريك، واستخدم إصبعين للتكبير والتصغير، واضغط على الدولة لتحديدها.',
                    'Drag to pan, use two fingers to zoom, and tap a country to select it.',
                    'Faites glisser pour déplacer, utilisez deux doigts pour zoomer et touchez un pays pour le sélectionner.',
                  ),
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
                  _tr(
                    'حدود الدول وبيانات الخريطة الأساسية مضمنة في التطبيق ولا تحتاج إلى الإنترنت.',
                    'Country borders and basic map data are bundled in the app and do not require internet access.',
                    'Les frontières et les données cartographiques de base sont intégrées à l’application et ne nécessitent pas Internet.',
                  ),
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
              _tr(
                'لا توجد معالم متاحة حالياً',
                'No landmarks available',
                'Aucun monument disponible',
              ),
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
              onPressed: () => _loadLandmarks(),
              icon: const Icon(Icons.refresh_rounded),
              label: Text(
                _tr(
                  'إعادة تحميل البيانات',
                  'Reload data',
                  'Recharger les données',
                ),
              ),
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
        if (_landmarkError != null) ...[
          Text(
            _landmarkError!,
            style: TextStyle(
              color: secondaryColor,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 10),
        ],
        _collectionTitle(
          _tr(
            'المعالم الإسلامية',
            'Islamic landmarks',
            'Monuments islamiques',
          ),
          _tr(
            '${islamicLandmarks.length} مواقع',
            '${islamicLandmarks.length} places',
            '${islamicLandmarks.length} lieux',
          ),
          textColor,
        ),
        const SizedBox(height: 11),
        if (islamicLandmarks.isEmpty)
          _emptyCollectionMessage(
            _tr(
              'ستظهر هنا المساجد والمعالم الإسلامية عند إضافتها إلى قاعدة البيانات.',
              'Mosques and Islamic landmarks will appear here when added to the database.',
              'Les mosquées et monuments islamiques apparaîtront ici lorsqu’ils seront ajoutés à la base de données.',
            ),
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
          _tr(
            'العجائب والمواقع التاريخية',
            'Wonders and historic sites',
            'Merveilles et sites historiques',
          ),
          _tr(
            '${wonders.length} مواقع',
            '${wonders.length} places',
            '${wonders.length} lieux',
          ),
          textColor,
        ),
        const SizedBox(height: 11),
        if (wonders.isEmpty)
          _emptyCollectionMessage(
            _tr(
              'لا توجد مواقع تاريخية أخرى متاحة حالياً.',
              'No other historic sites are currently available.',
              'Aucun autre site historique n’est disponible actuellement.',
            ),
            cardColor,
            secondaryColor,
          )
        else
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
                      color: secondaryColor.withValues(
                        alpha: 0.10,
                      ),
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
                        _localizedLandmarkName(landmark),
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
                        landmark.cityAr?.trim().isNotEmpty == true
                            ? landmark.cityAr!.trim()
                            : landmark.countryCode,
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

    if (accuracy == null || !accuracy.isFinite || accuracy < 0) {
      return const SizedBox.shrink();
    }

    final accuracyText = accuracy <= 10
        ? _tr(
            'تقدير دقة GPS جيد جداً وفق القراءة الحالية (±${accuracy.toStringAsFixed(1)} متر).',
            'GPS accuracy estimate is very good (±${accuracy.toStringAsFixed(1)} m).',
            'La précision GPS estimée est très bonne (±${accuracy.toStringAsFixed(1)} m).',
          )
        : accuracy <= 30
            ? _tr(
                'تقدير دقة GPS متوسط (±${accuracy.toStringAsFixed(1)} متر). انتظر قليلاً لتحسين القراءة.',
                'GPS accuracy estimate is moderate (±${accuracy.toStringAsFixed(1)} m). Wait for a better reading.',
                'La précision GPS estimée est moyenne (±${accuracy.toStringAsFixed(1)} m). Attendez une meilleure lecture.',
              )
            : _tr(
                'تقدير دقة GPS منخفض حالياً (±${accuracy.toStringAsFixed(1)} متر). انتقل إلى مكان مفتوح وحاول مجدداً.',
                'GPS accuracy is currently low (±${accuracy.toStringAsFixed(1)} m). Move to an open area and try again.',
                'La précision GPS est actuellement faible (±${accuracy.toStringAsFixed(1)} m). Placez-vous dans un espace ouvert et réessayez.',
              );

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
                  _tr(
                    'لتحسين قراءة البوصلة، أبعد الهاتف عن المعادن والأجهزة المغناطيسية، وحرّكه بشكل الرقم 8 لمعايرة الحساس عند الحاجة. لا يعرض التطبيق رقماً لدقة البوصلة ما لم توفره واجهة الحساس.',
                    'To improve compass readings, keep the phone away from metal and magnetic devices. Move it in a figure-eight pattern to calibrate the sensor if needed. The app does not display a compass accuracy value unless the sensor API provides one.',
                    'Pour améliorer la lecture de la boussole, éloignez le téléphone des métaux et des appareils magnétiques. Effectuez un mouvement en huit pour calibrer le capteur si nécessaire. L’application n’affiche aucune valeur de précision de la boussole si l’interface du capteur ne la fournit pas.',
                  ),
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

/// Custom painter for elite anime-style prostrating avatar (Sajdah) inside the live compass dial.
class _AnimeSajdahCompassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Glow aura
    final glowPaint = Paint()
      ..color = const Color(0xFFD8B66A).withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawCircle(center, 24, glowPaint);

    // Directional pointer needle pointing North/Qibla direction
    final needlePath = Path()
      ..moveTo(center.dx, center.dy - 32)
      ..lineTo(center.dx - 9, center.dy + 8)
      ..lineTo(center.dx, center.dy + 3)
      ..lineTo(center.dx + 9, center.dy + 8)
      ..close();

    final needlePaint = Paint()
      ..color = const Color(0xFFD8B66A)
      ..style = PaintingStyle.fill;

    canvas.drawPath(needlePath, needlePaint);

    // Anime Sajdah Avatar inside the compass center
    final bodyPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final headPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Head in sajdah
    canvas.drawCircle(center.translate(-6, 2), 3.0, headPaint);

    // Prostrating silhouette curve
    final path = Path()
      ..moveTo(center.dx + 8, center.dy + 6)
      ..quadraticBezierTo(
        center.dx + 2,
        center.dy - 4,
        center.dx - 4,
        center.dy + 2,
      );
    canvas.drawPath(path, bodyPaint);

    // Hands on ground
    canvas.drawLine(
      center.translate(-3, 3),
      center.translate(-7, 6),
      bodyPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CompassTicksPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(
      size.width / 2,
      size.height / 2,
    );

    final radius = size.width / 2;

    final tickPaint = Paint()
      ..color = const Color(0xFFD8B66A)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < 60; i++) {
      final angle = (i * 6 - 90) * math.pi / 180;
      final isMajor = i % 5 == 0;

      final outerRadius = radius - 4;
      final innerRadius =
          outerRadius - (isMajor ? 12 : 6);

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
  bool shouldRepaint(
    covariant _CompassTicksPainter oldDelegate,
  ) =>
      false;
}

class _LocationException implements Exception {
  final String message;

  const _LocationException(this.message);
}
