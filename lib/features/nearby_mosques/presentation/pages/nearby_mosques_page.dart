
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/design_system/mumin_design_tokens.dart';
import '../../../../core/localization/mumin_domain_localizations.dart';
import '../../../../core/localization/mumin_localizations.dart';
import '../../domain/models/nearby_mosque.dart';
import '../../domain/models/mosque_search_area.dart';
import '../controllers/nearby_mosques_controller.dart';

/// Mumin Pro — Worldwide Nearby Mosques Map.
///
/// The user chooses the search area by moving the map.
/// This page never requests GPS or device location permission.
class NearbyMosquesPage extends StatefulWidget {
  const NearbyMosquesPage({
    super.key,
    this.languageCode = 'ar',
  });

  final String languageCode;

  @override
  State<NearbyMosquesPage> createState() =>
      _NearbyMosquesPageState();
}

class _NearbyMosquesPageState extends State<NearbyMosquesPage> {
  static const LatLng _initialCenter = LatLng(20, 0);
  static const double _initialZoom = 2.5;
  static const double _minimumSearchZoom = 5.5;

  late final MapController _mapController;
  late final NearbyMosquesController _mosquesController;
  late final TextEditingController _searchController;

  bool _mapReady = false;
  bool _showResultsList = false;

  String get _languageCode {
    final code = widget.languageCode
        .trim()
        .toLowerCase()
        .split(RegExp('[-_]'))
        .first;

    return const {'ar', 'en', 'fr'}.contains(code)
        ? code
        : 'ar';
  }

  MuminLocalizations get _localizations =>
      MuminLocalizations.fromCode(_languageCode);

  TextDirection get _direction =>
      _languageCode == 'ar'
          ? TextDirection.rtl
          : TextDirection.ltr;

  String _tr(String key) =>
      _localizations.domainText(key);

  @override
  void initState() {
    super.initState();

    _mapController = MapController();
    _mosquesController = NearbyMosquesController();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mosquesController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  MosqueSearchArea? _currentVisibleArea() {
    if (!_mapReady) return null;

    try {
      final bounds = _mapController.camera.visibleBounds;

      final south = bounds.southWest.latitude
          .clamp(-85.0, 85.0)
          .toDouble();

      final north = bounds.northEast.latitude
          .clamp(-85.0, 85.0)
          .toDouble();

      final west = bounds.southWest.longitude
          .clamp(-180.0, 180.0)
          .toDouble();

      final east = bounds.northEast.longitude
          .clamp(-180.0, 180.0)
          .toDouble();

      final area = MosqueSearchArea(
        south: south,
        west: west,
        north: north,
        east: east,
      );

      return area.isValid ? area : null;
    } catch (error) {
      debugPrint('Could not read visible map area: $error');
      return null;
    }
  }

  Future<void> _searchVisibleArea() async {
    if (!_mapReady || _mosquesController.isLoading) {
      return;
    }

    final area = _currentVisibleArea();

    if (area == null) {
      _showMessage(_tr('nearby_mosques_select_area'));
      return;
    }

    final zoom = _mapController.camera.zoom;

    if (zoom < _minimumSearchZoom) {
      _showMessage(_tr('nearby_mosques_move_map'));
      return;
    }

    FocusScope.of(context).unfocus();

    await _mosquesController.search(
      area: area,
      languageCode: _languageCode,
      query: _searchController.text,
      limit: 300,
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  String _placeTypeLabel(NearbyMosque mosque) {
  switch (mosque.placeType) {
    case MosquePlaceType.mosque:
      return _tr('nearby_mosques_mosque');
    case MosquePlaceType.prayerRoom:
      return _tr('nearby_mosques_prayer_room');
    case MosquePlaceType.musalla:
      return _tr('nearby_mosques_musalla');
    case MosquePlaceType.unknown:
      return _tr('nearby_mosques_location_unavailable');
  }
}
  String _mosqueTitle(NearbyMosque mosque) {
    final name = mosque.nameForLanguage(_languageCode);

    return name.isEmpty ? _placeTypeLabel(mosque) : name;
  }

  void _showMosqueDetails(NearbyMosque mosque) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final brightness =
            Theme.of(sheetContext).brightness;

        final surface = MuminColors.surface(brightness);
        final primaryText =
            MuminColors.primaryText(brightness);
        final secondaryText =
            MuminColors.secondaryText(brightness);

        return Directionality(
          textDirection: _direction,
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: secondaryText.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      _mosqueIcon(size: 48),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              _mosqueTitle(mosque),
                              style: TextStyle(
                                color: primaryText,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              _placeTypeLabel(mosque),
                              style: TextStyle(
                                color: secondaryText,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (mosque.address?.isNotEmpty == true) ...[
                    const SizedBox(height: 20),
                    _detailRow(
                      Icons.location_on_outlined,
                      _tr('nearby_mosques_address'),
                      mosque.address!,
                      primaryText,
                      secondaryText,
                    ),
                  ],
                  if (mosque.city?.isNotEmpty == true) ...[
                    const SizedBox(height: 12),
                    _detailRow(
                      Icons.location_city_rounded,
                      _tr('nearby_mosques_city'),
                      mosque.city!,
                      primaryText,
                      secondaryText,
                    ),
                  ],
                  const SizedBox(height: 18),
                  Text(
                    '${mosque.latitude.toStringAsFixed(5)}, '
                    '${mosque.longitude.toStringAsFixed(5)}',
                    textDirection: TextDirection.ltr,
                    style: TextStyle(
                      color: secondaryText,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'OpenStreetMap',
                    style: TextStyle(
                      color: secondaryText,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(
    IconData icon,
    String label,
    String value,
    Color primary,
    Color secondary,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: MuminColors.gold, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: secondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: TextStyle(
                  color: primary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _mosqueIcon({double size = 42}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            MuminColors.deepEmerald,
            MuminColors.emeraldLight,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.32),
        border: Border.all(
          color: MuminColors.gold.withValues(alpha: 0.65),
        ),
      ),
      child: Icon(
        Icons.mosque_rounded,
        color: MuminColors.goldLight,
        size: size * 0.55,
      ),
    );
  }

  Widget _buildSearchHeader(Brightness brightness) {
    final surface = MuminColors.surface(brightness);
    final primary = MuminColors.primaryText(brightness);
    final secondary = MuminColors.secondaryText(brightness);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: surface,
        border: Border(
          bottom: BorderSide(
            color: MuminColors.border(brightness),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _tr('nearby_mosques_subtitle'),
            style: TextStyle(
              color: secondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            textDirection: _direction,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _searchVisibleArea(),
            style: TextStyle(
              color: primary,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: _tr('nearby_mosques_search_hint'),
              hintStyle: TextStyle(
                color: secondary.withValues(alpha: 0.8),
                fontSize: 13,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: MuminColors.goldDark,
              ),
              filled: true,
              fillColor: MuminColors.background(brightness),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 13,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: MuminColors.border(brightness),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _mosquesController.isLoading
                  ? null
                  : _searchVisibleArea,
              icon: const Icon(Icons.travel_explore_rounded),
              label: Text(
                _tr('nearby_mosques_search_area'),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: MuminColors.emerald,
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
  }

  Widget _buildPrivacyNotice(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: MuminColors.gold.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: MuminColors.gold.withValues(alpha: 0.28),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.privacy_tip_outlined,
            color: MuminColors.goldDark,
            size: 18,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              _tr('nearby_mosques_privacy_notice'),
              style: TextStyle(
                color: isDark
                    ? MuminColors.ivory
                    : MuminColors.neutralDark,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  
  Widget _buildMap(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedBuilder(
          animation: _mosquesController,
          builder: (context, _) {
            final mosques =
                _mosquesController.result?.mosques ??
                    const <NearbyMosque>[];

            return FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _initialCenter,
                initialZoom: _initialZoom,
                minZoom: 2,
                maxZoom: 18,
                onMapReady: () {
                  if (mounted && !_mapReady) {
                    setState(() => _mapReady = true);
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.iskander.muslimspro',
                  maxZoom: 19,
                ),
                MarkerLayer(
                  markers: [
                    for (final mosque in mosques)
                      Marker(
                        point: LatLng(
                          mosque.latitude,
                          mosque.longitude,
                        ),
                        width: 44,
                        height: 52,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _showMosqueDetails(mosque),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: MuminColors.deepEmerald,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: MuminColors.gold,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.25,
                                      ),
                                      blurRadius: 7,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.mosque_rounded,
                                  color: MuminColors.goldLight,
                                  size: 20,
                                ),
                              ),
                              Container(
                                width: 3,
                                height: 9,
                                color: MuminColors.gold,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                RichAttributionWidget(
                  alignment: Alignment.bottomLeft,
                  attributions: const [
                    TextSourceAttribution(
                      '© OpenStreetMap contributors',
                    ),
                  ],
                ),
              ],
            );
          },
        ),
        if (isDark)
          Positioned.fill(
            child: IgnorePointer(
              child: ColoredBox(
                color: Color(0x14000000),
              ),
            ),
          ),
        PositionedDirectional(
          end: 12,
          top: 12,
          child: Column(
            children: [
              _mapControl(
                icon: Icons.add_rounded,
                onTap: () {
                  if (!_mapReady) return;
                  final camera = _mapController.camera;
                  _mapController.move(
                    camera.center,
                    (camera.zoom + 1).clamp(2.0, 18.0),
                  );
                },
              ),
              const SizedBox(height: 8),
              _mapControl(
                icon: Icons.remove_rounded,
                onTap: () {
                  if (!_mapReady) return;
                  final camera = _mapController.camera;
                  _mapController.move(
                    camera.center,
                    (camera.zoom - 1).clamp(2.0, 18.0),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _mapControl({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: MuminColors.deepEmerald,
      elevation: 4,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(
            icon,
            color: MuminColors.goldLight,
          ),
        ),
      ),
    );
  }

  Widget _buildResultPanel(Brightness brightness) {
    final primary = MuminColors.primaryText(brightness);
    final secondary = MuminColors.secondaryText(brightness);
    final surface = MuminColors.surface(brightness);

    return AnimatedBuilder(
      animation: _mosquesController,
      builder: (context, _) {
        final controller = _mosquesController;
        final result = controller.result;

        if (controller.isLoading) {
          return Container(
            color: surface,
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.3,
                    color: MuminColors.goldDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _tr('nearby_mosques_searching'),
                    style: TextStyle(color: primary),
                  ),
                ),
              ],
            ),
          );
        }

        if (controller.hasError) {
          return Container(
            color: surface,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(
                  Icons.wifi_off_rounded,
                  color: MuminColors.error,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _tr('nearby_mosques_error'),
                    style: TextStyle(color: primary),
                  ),
                ),
                TextButton(
                  onPressed: controller.retry,
                  child: Text(_tr('nearby_mosques_retry')),
                ),
              ],
            ),
          );
        }

        if (result == null) {
          return Container(
            color: surface,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.pan_tool_alt_rounded,
                  color: MuminColors.goldDark,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _tr('nearby_mosques_move_map'),
                    style: TextStyle(
                      color: secondary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          color: surface,
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${_tr('nearby_mosques_results')} '
                      '(${result.resultCount})',
                      style: TextStyle(
                        color: primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: _tr('nearby_mosques_list'),
                    onPressed: () {
                      setState(() {
                        _showResultsList = !_showResultsList;
                      });
                    },
                    icon: Icon(
                      _showResultsList
                          ? Icons.map_rounded
                          : Icons.list_alt_rounded,
                      color: MuminColors.goldDark,
                    ),
                  ),
                ],
              ),
              if (controller.isPartial)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 15,
                        color: MuminColors.warning,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _tr('nearby_mosques_partial'),
                          style: TextStyle(
                            color: secondary,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (result.mosques.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                  ),
                  child: Text(
                    _tr('nearby_mosques_empty'),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: secondary),
                  ),
                )
              else if (_showResultsList)
                SizedBox(
                  height: 180,
                  child: ListView.separated(
                    itemCount: result.mosques.length,
                    separatorBuilder: (_, __) =>
                        Divider(
                          height: 1,
                          color: MuminColors.border(brightness),
                        ),
                    itemBuilder: (context, index) {
                      final mosque = result.mosques[index];

                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: _mosqueIcon(size: 38),
                        title: Text(
                          _mosqueTitle(mosque),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          mosque.city ??
                              _placeTypeLabel(mosque),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: secondary),
                        ),
                        onTap: () {
                         setState(() {
                         _showResultsList = false;
                        });
                         _mapController.move(
                         LatLng(
                         mosque.latitude,
                         mosque.longitude,
                         ),
                         16,
                         );
                         _showMosqueDetails(mosque);
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Directionality(
      textDirection: _direction,
      child: Scaffold(
        backgroundColor: MuminColors.background(brightness),
        appBar: AppBar(
          title: Text(_tr('nearby_mosques_title')),
          backgroundColor: MuminColors.surface(brightness),
          foregroundColor: MuminColors.primaryText(brightness),
          elevation: 0,
          actions: [
            IconButton(
              tooltip: _tr('nearby_mosques_retry'),
              onPressed: _mosquesController.isLoading
                  ? null
                  : _searchVisibleArea,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: Column(
          children: [
            _buildSearchHeader(brightness),
            _buildPrivacyNotice(brightness),
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(22),
                ),
                child: _buildMap(brightness),
              ),
            ),
            _buildResultPanel(brightness),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 5, 12, 9),
              child: Text(
                _tr('nearby_mosques_source_notice'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: MuminColors.secondaryText(brightness),
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
