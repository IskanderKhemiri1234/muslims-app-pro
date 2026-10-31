
import 'dart:async';

import 'package:geolocator/geolocator.dart';

class LocationDataSource {
  /// الحصول على آخر موقع معروف دون طلب تحديد موقع جديد.
  /// لا يعمل إلا إذا كانت الصلاحية ممنوحة.
  Future<Position?> getLastKnownLocation() async {
    try {
      final enabled =
          await Geolocator.isLocationServiceEnabled();

      if (!enabled) return null;

      final permission = await Geolocator.checkPermission();

      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        return null;
      }

      return await Geolocator.getLastKnownPosition();
    } catch (_) {
      return null;
    }
  }

  /// الحصول على موقع حديث بعد موافقة المستخدم.
  Future<Position> getCurrentLocation() async {
    final enabled =
        await Geolocator.isLocationServiceEnabled();

    if (!enabled) {
      throw Exception('يرجى تفعيل خدمة الموقع.');
    }

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'يرجى تفعيل إذن الموقع من إعدادات التطبيق.',
      );
    }

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception('لم يتم منح إذن الموقع.');
    }

    if (permission != LocationPermission.whileInUse &&
        permission != LocationPermission.always) {
      throw Exception('إذن الموقع غير متاح.');
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } on TimeoutException {
      throw Exception(
        'انتهت مهلة تحديد الموقع. حاول مرة أخرى.',
      );
    }
  }
}
