
import 'dart:async';

import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(const MuslimsApp());
}

class MuslimsApp extends StatelessWidget {
  const MuslimsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Muslims',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF087F5B),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF6F8F5),
        fontFamily: 'Roboto',
      ),
      home: const PrayerHomePage(),
    );
  }
}

class PrayerHomePage extends StatefulWidget {
  const PrayerHomePage({super.key});

  @override
  State<PrayerHomePage> createState() => _PrayerHomePageState();
}

class _PrayerHomePageState extends State<PrayerHomePage> {
  Timer? _timer;

  // Default location: Casablanca, Morocco.
  double _latitude = 33.5731;
  double _longitude = -7.5898;
  String _city = 'الدار البيضاء';

  // Correct enum names for the adhan package.
  CalculationMethod _method =
      CalculationMethod.muslim_world_league;

  Madhab _madhab = Madhab.shafi;

  DateTime _now = DateTime.now();
  bool _loadingLocation = false;
  String? _message;

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;

      setState(() {
        _now = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  PrayerTimes _calculatePrayerTimes() {
    final coordinates = Coordinates(_latitude, _longitude);
    final date = DateComponents.from(_now);
    final params = _method.getParameters();

    params.madhab = _madhab;

    return PrayerTimes(coordinates, date, params);
  }

  String _twoDigits(int value) =>
      value.toString().padLeft(2, '0');

  String _formatTime(DateTime time) {
    return '${_twoDigits(time.hour)}:${_twoDigits(time.minute)}';
  }

  String _formatRemaining(Duration duration) {
    if (duration.isNegative) {
      return '00:00:00';
    }

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    return '${_twoDigits(hours)}:'
        '${_twoDigits(minutes)}:'
        '${_twoDigits(seconds)}';
  }

  String _prayerName(Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr:
        return 'الفجر';
      case Prayer.sunrise:
        return 'الشروق';
      case Prayer.dhuhr:
        return 'الظهر';
      case Prayer.asr:
        return 'العصر';
      case Prayer.maghrib:
        return 'المغرب';
      case Prayer.isha:
        return 'العشاء';
      case Prayer.none:
        return 'لا توجد صلاة تالية';
    }
  }

  IconData _prayerIcon(Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr:
        return Icons.nightlight_round;
      case Prayer.sunrise:
        return Icons.wb_twilight;
      case Prayer.dhuhr:
        return Icons.wb_sunny_outlined;
      case Prayer.asr:
        return Icons.wb_cloudy_outlined;
      case Prayer.maghrib:
        return Icons.wb_twilight;
      case Prayer.isha:
        return Icons.nights_stay_outlined;
      case Prayer.none:
        return Icons.access_time;
    }
  }

  Future<void> _useCurrentLocation() async {
    if (_loadingLocation) return;

    setState(() {
      _loadingLocation = true;
      _message = null;
    });

    try {
      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        throw Exception('يرجى تفعيل خدمة الموقع في الهاتف.');
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        throw Exception('لم يتم السماح بالوصول إلى الموقع.');
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'إذن الموقع مرفوض نهائيًا. فعّله من إعدادات التطبيق.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );

      if (!mounted) return;

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _city = 'موقعي الحالي';
        _message = 'تم تحديث الموقع بنجاح.';
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _message = error
            .toString()
            .replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingLocation = false;
        });
      }
    }
  }

  Future<void> _chooseCalculationMethod() async {
    final selected =
        await showModalBottomSheet<CalculationMethod>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const ListTile(
                title: Text(
                  'طريقة حساب مواقيت الصلاة',
                  textDirection: TextDirection.rtl,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              ...CalculationMethod.values.map((method) {
                return ListTile(
                  title: Text(
                    _methodName(method),
                    textDirection: TextDirection.rtl,
                  ),
                  trailing: method == _method
                      ? const Icon(
                          Icons.check_circle,
                          color: Color(0xFF087F5B),
                        )
                      : null,
                  onTap: () {
                    Navigator.pop(sheetContext, method);
                  },
                );
              }),
            ],
          ),
        );
      },
    );

    if (selected != null && mounted) {
      setState(() {
        _method = selected;
      });
    }
  }
  
String _methodName(CalculationMethod method) {
  switch (method) {
    case CalculationMethod.muslim_world_league:
      return 'رابطة العالم الإسلامي';
    case CalculationMethod.egyptian:
      return 'الهيئة المصرية العامة للمساحة';
    case CalculationMethod.karachi:
      return 'جامعة العلوم الإسلامية بكراتشي';
    case CalculationMethod.umm_al_qura:
      return 'أم القرى';
    case CalculationMethod.dubai:
      return 'دبي';
    case CalculationMethod.north_america:
      return 'أمريكا الشمالية';
    case CalculationMethod.kuwait:
      return 'الكويت';
    case CalculationMethod.qatar:
      return 'قطر';
    case CalculationMethod.singapore:
      return 'سنغافورة';
    case CalculationMethod.turkey:
      return 'تركيا';
    case CalculationMethod.tehran:
      return 'طهران';
    case CalculationMethod.other:
      return 'إعدادات مخصصة';
    default:
      return method.toString().split('.').last;
  }
}

  @override
  Widget build(BuildContext context) {
    final prayerTimes = _calculatePrayerTimes();

    final prayers = <Prayer, DateTime>{
      Prayer.fajr: prayerTimes.fajr,
      Prayer.sunrise: prayerTimes.sunrise,
      Prayer.dhuhr: prayerTimes.dhuhr,
      Prayer.asr: prayerTimes.asr,
      Prayer.maghrib: prayerTimes.maghrib,
      Prayer.isha: prayerTimes.isha,
    };

    final nextPrayer = prayerTimes.nextPrayer();
    final nextPrayerTime = nextPrayer == Prayer.none
        ? null
        : prayerTimes.timeForPrayer(nextPrayer);

    final countdown = nextPrayerTime == null
        ? Duration.zero
        : nextPrayerTime.difference(_now);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Muslims',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              tooltip: 'طريقة الحساب',
              onPressed: _chooseCalculationMethod,
              icon: const Icon(Icons.tune),
            ),
          ],
        ),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _useCurrentLocation,
            child: ListView(
              padding: const EdgeInsets.all(18),
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF075E46),
                        Color(0xFF10966C),
                      ],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: Colors.white70,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'موقعك',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _city,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_now.year}/'
                        '${_twoDigits(_now.month)}/'
                        '${_twoDigits(_now.day)}',
                        style: const TextStyle(
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'الصلاة القادمة',
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _prayerName(nextPrayer),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        nextPrayerTime == null
                            ? '--:--'
                            : _formatTime(nextPrayerTime),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Divider(color: Colors.white30),
                      const SizedBox(height: 8),
                      const Text(
                        'الوقت المتبقي',
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _formatRemaining(countdown),
                        textDirection: TextDirection.ltr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'مواقيت الصلاة',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...prayers.entries.map((entry) {
                  final isNext = entry.key == nextPrayer;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 9),
                    decoration: BoxDecoration(
                      color: isNext
                          ? const Color(0xFFE0F2E9)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isNext
                            ? const Color(0xFF10966C)
                            : const Color(0xFFE7ECE8),
                      ),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isNext
                            ? const Color(0xFF087F5B)
                            : const Color(0xFFF0F4F1),
                        child: Icon(
                          _prayerIcon(entry.key),
                          color: isNext
                              ? Colors.white
                              : Colors.black54,
                        ),
                      ),
                      title: Text(
                        _prayerName(entry.key),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      trailing: Text(
                        _formatTime(entry.value),
                        textDirection: TextDirection.ltr,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: isNext
                              ? const Color(0xFF087F5B)
                              : Colors.black87,
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _loadingLocation
                      ? null
                      : _useCurrentLocation,
                  icon: _loadingLocation
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.my_location),
                  label: Text(
                    _loadingLocation
                        ? 'جارٍ تحديد الموقع...'
                        : 'استخدام موقعي الحالي',
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _chooseCalculationMethod,
                  icon: const Icon(Icons.settings),
                  label: Text(
                    'طريقة الحساب: ${_methodName(_method)}',
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<Madhab>(
                  initialValue: _madhab,
                  decoration: const InputDecoration(
                    labelText: 'طريقة حساب العصر',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: Madhab.shafi,
                      child: Text('الشافعي / المالكي / الحنبلي'),
                    ),
                    DropdownMenuItem(
                      value: Madhab.hanafi,
                      child: Text('الحنفي'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;

                    setState(() {
                      _madhab = value;
                    });
                  },
                ),
                if (_message != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _message!,
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
                const SizedBox(height: 20),
                const Text(
                  'ملاحظة: قد تختلف المواقيت عن الجهة المحلية '
                  'المعتمدة. اختر طريقة الحساب المناسبة لمدينتك '
                  'وقارن النتائج قبل الاعتماد.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
