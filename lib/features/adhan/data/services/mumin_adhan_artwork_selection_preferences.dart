import 'package:shared_preferences/shared_preferences.dart';

/// Persists the user's selected bundled Adhan artwork.
class MuminAdhanArtworkSelectionPreferences {
  static const String _preferenceKey =
      'mumin_adhan_selected_artwork_id';

  /// Returns the previously selected artwork ID.
  Future<String?> getSelectedArtworkId() async {
    final preferences = await SharedPreferences.getInstance();

    final id = preferences.getString(_preferenceKey);

    if (id == null || id.trim().isEmpty) {
      return null;
    }

    return id;
  }

  /// Saves the selected artwork ID.
  Future<void> saveSelectedArtworkId(String artworkId) async {
    final id = artworkId.trim();

    if (id.isEmpty) {
      throw ArgumentError.value(
        artworkId,
        'artworkId',
        'Artwork ID cannot be empty.',
      );
    }

    final preferences = await SharedPreferences.getInstance();

    final saved = await preferences.setString(
      _preferenceKey,
      id,
    );

    if (!saved) {
      throw StateError(
        'Could not save the selected Adhan artwork.',
      );
    }
  }

  /// Clears the selected artwork preference.
  Future<void> clearSelectedArtwork() async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.remove(_preferenceKey);
  }
}
