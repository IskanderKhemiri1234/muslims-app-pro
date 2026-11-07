
/// Central registry for bundled offline Adhan audio and mosque artwork.
///
/// Asset files must be physically added to the project before their
/// paths are declared in pubspec.yaml or played at runtime.
class MuminAdhanAsset {
  const MuminAdhanAsset({
    required this.id,
    required this.titleAr,
    required this.titleEn,
    required this.titleFr,
    required this.assetPath,
    required this.license,
    required this.sourceUrl,
    required this.attribution,
  });

  final String id;
  final String titleAr;
  final String titleEn;
  final String titleFr;
  final String assetPath;
  final String license;
  final String sourceUrl;
  final String attribution;

  String titleFor(String languageCode) {
    switch (languageCode) {
      case 'fr':
        return titleFr;
      case 'en':
        return titleEn;
      case 'ar':
      default:
        return titleAr;
    }
  }
}

class MuminMosqueArtwork {
  const MuminMosqueArtwork({
    required this.id,
    required this.titleAr,
    required this.titleEn,
    required this.titleFr,
    required this.assetPath,
    required this.license,
    required this.sourceUrl,
    required this.attribution,
  });

  final String id;
  final String titleAr;
  final String titleEn;
  final String titleFr;
  final String assetPath;
  final String license;
  final String sourceUrl;
  final String attribution;

  String titleFor(String languageCode) {
    switch (languageCode) {
      case 'fr':
        return titleFr;
      case 'en':
        return titleEn;
      case 'ar':
      default:
        return titleAr;
    }
  }
}

abstract final class MuminMediaAssetRegistry {
  static const String adhanBasePath = 'assets/audio/adhan';
  static const String mosqueBasePath = 'assets/images/mosques';

  static const List<MuminAdhanAsset> adhanRecordings = [
    MuminAdhanAsset(
      id: 'doha_fajr',
      titleAr: 'أذان الفجر – الدوحة',
      titleEn: 'Doha Fajr Adhan',
      titleFr: 'Adhan du Fajr – Doha',
      assetPath: '$adhanBasePath/adhan_fajr.ogg',
      license: 'Public Domain Mark 1.0',
      sourceUrl:
          'https://archive.org/details/adhan.recordings.from.doha.qatar',
      attribution: 'Doha, Qatar – Internet Archive',
    ),
    MuminAdhanAsset(
      id: 'doha_dhuhr',
      titleAr: 'أذان الظهر – الدوحة',
      titleEn: 'Doha Dhuhr Adhan',
      titleFr: 'Adhan du Dhuhr – Doha',
      assetPath: '$adhanBasePath/adhan_dhuhr.ogg',
      license: 'Public Domain Mark 1.0',
      sourceUrl:
          'https://archive.org/details/adhan.recordings.from.doha.qatar',
      attribution: 'Doha, Qatar – Internet Archive',
    ),
    MuminAdhanAsset(
      id: 'doha_asr',
      titleAr: 'أذان العصر – الدوحة',
      titleEn: 'Doha Asr Adhan',
      titleFr: 'Adhan du Asr – Doha',
      assetPath: '$adhanBasePath/adhan_asr.ogg',
      license: 'Public Domain Mark 1.0',
      sourceUrl:
          'https://archive.org/details/adhan.recordings.from.doha.qatar',
      attribution: 'Doha, Qatar – Internet Archive',
    ),
    MuminAdhanAsset(
      id: 'doha_maghrib',
      titleAr: 'أذان المغرب – الدوحة',
      titleEn: 'Doha Maghrib Adhan',
      titleFr: 'Adhan du Maghrib – Doha',
      assetPath: '$adhanBasePath/adhan_maghrib.ogg',
      license: 'Public Domain Mark 1.0',
      sourceUrl:
          'https://archive.org/details/adhan.recordings.from.doha.qatar',
      attribution: 'Doha, Qatar – Internet Archive',
    ),
    MuminAdhanAsset(
      id: 'doha_isha',
      titleAr: 'أذان العشاء – الدوحة',
      titleEn: 'Doha Isha Adhan',
      titleFr: 'Adhan du Isha – Doha',
      assetPath: '$adhanBasePath/adhan_isha.ogg',
      license: 'Public Domain Mark 1.0',
      sourceUrl:
          'https://archive.org/details/adhan.recordings.from.doha.qatar',
      attribution: 'Doha, Qatar – Internet Archive',
    ),
  ];

  static const List<MuminMosqueArtwork> mosqueArtwork = [
    MuminMosqueArtwork(
      id: 'hassan_mosque_rabat',
      titleAr: 'بوابة مسجد حسان – الرباط',
      titleEn: 'Hassan Mosque Portal – Rabat',
      titleFr: 'Portail de la mosquée Hassan – Rabat',
      assetPath: '$mosqueBasePath/hassan_mosque_rabat.jpg',
      license: 'CC BY-SA 4.0',
      sourceUrl:
          'https://commons.wikimedia.org/wiki/File:Rabat_-_Hassan_Mosque_-_20241014153944.jpg',
      attribution: 'UmaimaJM',
    ),
    MuminMosqueArtwork(
      id: 'hassan_mosque_dove',
      titleAr: 'مسجد حسان – مشهد الحمامة',
      titleEn: 'Hassan Mosque – Dove Scene',
      titleFr: 'Mosquée Hassan – Scène de la colombe',
      assetPath: '$mosqueBasePath/hassan_mosque_dove.jpg',
      license: 'CC0 1.0',
      sourceUrl:
          'https://commons.wikimedia.org/wiki/File:Dove_at_the_Hassan_Mosque_in_Rabat,_Morocco.jpg',
      attribution: 'Mustang Joe',
    ),
  ];

  static MuminAdhanAsset? adhanById(String id) {
    for (final asset in adhanRecordings) {
      if (asset.id == id) return asset;
    }
    return null;
  }

  static MuminMosqueArtwork? mosqueById(String id) {
    for (final artwork in mosqueArtwork) {
      if (artwork.id == id) return artwork;
    }
    return null;
  }

  static List<String> get requiredAudioPaths =>
      List.unmodifiable(
        adhanRecordings.map((asset) => asset.assetPath),
      );

  static List<String> get requiredImagePaths =>
      List.unmodifiable(
        mosqueArtwork.map((artwork) => artwork.assetPath),
      );
}
