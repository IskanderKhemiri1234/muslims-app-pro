import 'package:geolocator/geolocator.dart';

class LocationDataSource {
  Future<Position> getCurrentLocation() async {
    final enabled = await Geolocator.isLocationServiceEnabled();

    if (!enabled) {
      throw Exception('يرجى تفعيل خدمة الموقع.');
    }

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.deniedForever) {
      throw Exception('يرجى تفعيل إذن الموقع من إعدادات التطبيق.');
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

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 15),
      ),
    );
  }
}
