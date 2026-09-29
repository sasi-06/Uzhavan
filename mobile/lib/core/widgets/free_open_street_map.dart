import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'osm_view_registry_stub.dart'
    if (dart.library.html) 'osm_view_registry_web.dart';

class LatLng {
  final double latitude;
  final double longitude;
  const LatLng(this.latitude, this.longitude);
}

/// A 100% free interactive map widget powered by OpenStreetMap.
/// On Flutter Web: renders an OSM iframe with real road tiles.
/// Shows two pins (owner + farmer) and a straight-line distance.
class FreeOpenStreetMap extends StatefulWidget {
  const FreeOpenStreetMap({
    super.key,
    required this.latitude,
    required this.longitude,
    this.startLatitude,
    this.startLongitude,
    this.startTitle,
    this.destLatitude,
    this.destLongitude,
    this.destTitle,
    this.initialZoom = 11,
    this.interactive = true,
    this.markerTitle,
    this.height,
  });

  final double latitude;
  final double longitude;
  final double? startLatitude;
  final double? startLongitude;
  final String? startTitle;
  final double? destLatitude;
  final double? destLongitude;
  final String? destTitle;
  final int initialZoom;
  final bool interactive;
  final String? markerTitle;
  final double? height;

  @override
  State<FreeOpenStreetMap> createState() => _FreeOpenStreetMapState();
}

class _FreeOpenStreetMapState extends State<FreeOpenStreetMap> {
  String? _viewId;

  bool get _hasRoute =>
      widget.startLatitude != null &&
      widget.startLongitude != null &&
      widget.destLatitude != null &&
      widget.destLongitude != null;

  double get _centerLat => _hasRoute
      ? (widget.startLatitude! + widget.destLatitude!) / 2
      : widget.latitude;

  double get _centerLng => _hasRoute
      ? (widget.startLongitude! + widget.destLongitude!) / 2
      : widget.longitude;

  int get _autoZoom {
    if (!_hasRoute) return widget.initialZoom;
    final latDiff = (widget.startLatitude! - widget.destLatitude!).abs();
    final lngDiff = (widget.startLongitude! - widget.destLongitude!).abs();
    final maxDiff = math.max(latDiff, lngDiff);
    if (maxDiff > 5) return 7;
    if (maxDiff > 2) return 9;
    if (maxDiff > 1) return 10;
    if (maxDiff > 0.5) return 11;
    if (maxDiff > 0.2) return 12;
    if (maxDiff > 0.05) return 13;
    return 14;
  }

  double _calculateDistanceKm(double lat1, double lon1, double lat2, double lon2) {
    final p = 0.017453292519943295;
    final a = 0.5 -
        math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) * math.cos(lat2 * p) *
            (1 - math.cos((lon2 - lon1) * p)) / 2;
    return 12742 * math.asin(math.sqrt(a));
  }

  @override
  void initState() {
    super.initState();
    _initWebMap();
  }

  void _initWebMap() {
    if (kIsWeb && _viewId == null) {
      _viewId = 'osm-map-${DateTime.now().microsecondsSinceEpoch}';
      _registerWebView();
    }
  }

  void _registerWebView() {
    final zoom = _autoZoom;
    final lat = _centerLat;
    final lng = _centerLng;

    // Build OSM iframe HTML with markers for both points
    String markersJs = '';
    if (_hasRoute) {
      markersJs = '''
        var ownerMarker = L.marker([${widget.startLatitude}, ${widget.startLongitude}])
          .addTo(map)
          .bindPopup('<b>${widget.startTitle ?? 'Owner'}</b>')
          .openPopup();
        var farmerMarker = L.marker([${widget.destLatitude}, ${widget.destLongitude}], {
          icon: L.icon({
            iconUrl: 'https://raw.githubusercontent.com/pointhi/leaflet-color-markers/master/img/marker-icon-red.png',
            iconSize: [25, 41], iconAnchor: [12, 41]
          })
        })
          .addTo(map)
          .bindPopup('<b>${widget.destTitle ?? 'Farmer'}</b>');
        L.polyline([[${widget.startLatitude}, ${widget.startLongitude}], [${widget.destLatitude}, ${widget.destLongitude}]], {
          color: '#1B5E20', weight: 4, opacity: 0.9, dashArray: '8, 6'
        }).addTo(map);
        map.fitBounds([
          [${widget.startLatitude}, ${widget.startLongitude}],
          [${widget.destLatitude}, ${widget.destLongitude}]
        ], { padding: [50, 50] });
      ''';
    } else {
      markersJs = '''
        L.marker([$lat, $lng]).addTo(map)
          .bindPopup('<b>${widget.markerTitle ?? ''}</b>').openPopup();
      ''';
    }

    final srcdoc = '''<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css"/>
  <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
  <style>html,body,#map{margin:0;padding:0;width:100%;height:100%;}</style>
</head>
<body>
  <div id="map"></div>
  <script>
    var map = L.map('map', { zoomControl: true }).setView([$lat, $lng], $zoom);
    L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
      maxZoom: 19,
      attribution: '© <a href="https://openstreetmap.org">OpenStreetMap</a> contributors'
    }).addTo(map);
    $markersJs
  </script>
</body>
</html>''';

    registerOsmViewFactory(_viewId!, srcdoc);
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb && _viewId == null) {
      _initWebMap();
    }

    final double? distanceKm = _hasRoute
        ? _calculateDistanceKm(
            widget.startLatitude!,
            widget.startLongitude!,
            widget.destLatitude!,
            widget.destLongitude!,
          )
        : null;

    final containerHeight = widget.height ?? 350;

    return Container(
      height: containerHeight,
      decoration: BoxDecoration(
        color: const Color(0xFFE5E3DF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // ── Map ───────────────────────────────────────────────────────────
          if (kIsWeb && _viewId != null)
            SizedBox.expand(
              child: HtmlElementView(viewType: _viewId!),
            )
          else
            _FallbackMapView(
              centerLat: _centerLat,
              centerLng: _centerLng,
              startLat: widget.startLatitude,
              startLng: widget.startLongitude,
              destLat: widget.destLatitude,
              destLng: widget.destLongitude,
              startTitle: widget.startTitle,
              destTitle: widget.destTitle,
              markerTitle: widget.markerTitle,
              zoom: _autoZoom,
            ),

          // ── Distance Badge ────────────────────────────────────────────────
          if (distanceKm != null)
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 6),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.alt_route_rounded, color: Colors.amber, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'பாதை தூரம் / Distance: ${distanceKm.toStringAsFixed(1)} km',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),

          // ── OSM Attribution ───────────────────────────────────────────────
          if (!kIsWeb)
            Positioned(
              bottom: 6,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('© OpenStreetMap',
                    style: TextStyle(fontSize: 10, color: Colors.black87)),
              ),
            ),
        ],
      ),
    );
  }
}

/// Fallback tile-based map for non-web platforms (mobile/desktop).
class _FallbackMapView extends StatefulWidget {
  const _FallbackMapView({
    required this.centerLat,
    required this.centerLng,
    this.startLat,
    this.startLng,
    this.destLat,
    this.destLng,
    this.startTitle,
    this.destTitle,
    this.markerTitle,
    required this.zoom,
  });

  final double centerLat, centerLng;
  final double? startLat, startLng, destLat, destLng;
  final String? startTitle, destTitle, markerTitle;
  final int zoom;

  @override
  State<_FallbackMapView> createState() => _FallbackMapViewState();
}

class _FallbackMapViewState extends State<_FallbackMapView> {
  late double _lat;
  late double _lng;
  late int _zoom;

  @override
  void initState() {
    super.initState();
    _lat = widget.centerLat;
    _lng = widget.centerLng;
    _zoom = widget.zoom;
  }

  int _long2tilex(double lon, int z) =>
      ((lon + 180) / 360 * math.pow(2, z)).floor();

  int _lat2tiley(double lat, int z) =>
      ((1 -
                  math.log(math.tan(lat * math.pi / 180) +
                          1 / math.cos(lat * math.pi / 180)) /
                      math.pi) /
              2 *
              math.pow(2, z))
          .floor();

  Offset _project(double lat, double lng, Size size) {
    final scale = math.pow(2, _zoom) * 256.0;
    final cx = (_lng + 180) / 360 * scale;
    final cy = (1 -
            math.log(math.tan(_lat * math.pi / 180) +
                    1 / math.cos(_lat * math.pi / 180)) /
                math.pi) /
        2 *
        scale;
    final px = (lng + 180) / 360 * scale;
    final py = (1 -
            math.log(math.tan(lat * math.pi / 180) +
                    1 / math.cos(lat * math.pi / 180)) /
                math.pi) /
        2 *
        scale;
    return Offset(
      (px - cx) + size.width / 2,
      (py - cy) + size.height / 2,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cx = _long2tilex(_lng, _zoom);
    final cy = _lat2tiley(_lat, _zoom);
    final bool hasRoute = widget.startLat != null && widget.destLat != null;

    return LayoutBuilder(builder: (context, constraints) {
      final size = Size(constraints.maxWidth,
          constraints.maxHeight.isFinite ? constraints.maxHeight : 350);
      Offset? startOff, destOff;
      if (hasRoute) {
        startOff = _project(widget.startLat!, widget.startLng!, size);
        destOff = _project(widget.destLat!, widget.destLng!, size);
      }

      return GestureDetector(
        onPanUpdate: (d) {
          setState(() {
            final deg = 360 / (math.pow(2, _zoom) * 256);
            _lng -= d.delta.dx * deg;
            _lat += d.delta.dy * deg * math.cos(_lat * math.pi / 180);
          });
        },
        onScaleUpdate: (d) {
          if (d.scale > 1.05 && _zoom < 18) setState(() => _zoom++);
          if (d.scale < 0.95 && _zoom > 3) setState(() => _zoom--);
        },
        child: Stack(children: [
          // 5x5 tile grid for better coverage
          Positioned.fill(
            child: OverflowBox(
              maxWidth: 2000,
              maxHeight: 2000,
              child: SizedBox(
                width: size.width + 512,
                height: size.height + 512,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    childAspectRatio: 1,
                  ),
                  itemCount: 25,
                  itemBuilder: (_, i) {
                    final dx = (i % 5) - 2;
                    final dy = (i ~/ 5) - 2;
                    final url =
                        'https://tile.openstreetmap.org/$_zoom/${cx + dx}/${cy + dy}.png';
                    return Image.network(
                      url,
                      fit: BoxFit.cover,
                      headers: const {'User-Agent': 'UzhavanApp/1.0'},
                      errorBuilder: (_, __, ___) =>
                          Container(color: const Color(0xFFE0E0E0)),
                    );
                  },
                ),
              ),
            ),
          ),

          // Route line
          if (hasRoute && startOff != null && destOff != null)
            CustomPaint(
              size: size,
              painter: _RoutePainter(startOffset: startOff, destOffset: destOff),
            ),

          // Owner pin
          if (hasRoute && startOff != null)
            Positioned(
              left: startOff.dx - 20,
              top: startOff.dy - 44,
              child: _Pin(
                label: widget.startTitle ?? 'Owner',
                color: const Color(0xFF2E7D32),
                icon: Icons.agriculture_rounded,
              ),
            ),

          // Farmer pin
          if (hasRoute && destOff != null)
            Positioned(
              left: destOff.dx - 20,
              top: destOff.dy - 44,
              child: _Pin(
                label: widget.destTitle ?? 'Farmer',
                color: Colors.redAccent,
                icon: Icons.location_on_rounded,
              ),
            ),

          // Single marker
          if (!hasRoute)
            Center(
              child: _Pin(
                label: widget.markerTitle ?? '',
                color: Colors.redAccent,
                icon: Icons.location_on_rounded,
              ),
            ),

          // Zoom controls
          Positioned(
            right: 12,
            bottom: 30,
            child: Column(children: [
              _ZoomBtn(Icons.add, () => setState(() { if (_zoom < 18) _zoom++; })),
              const SizedBox(height: 6),
              _ZoomBtn(Icons.remove, () => setState(() { if (_zoom > 3) _zoom--; })),
              const SizedBox(height: 6),
              _ZoomBtn(Icons.my_location, () => setState(() {
                _lat = widget.centerLat;
                _lng = widget.centerLng;
                _zoom = widget.zoom;
              }), color: AppColors.ownerAccent),
            ]),
          ),
        ]),
      );
    });
  }
}

class _Pin extends StatelessWidget {
  const _Pin({required this.label, required this.color, required this.icon});
  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Column(mainAxisSize: MainAxisSize.min, children: [
    if (label.isNotEmpty)
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
        child: Text(label,
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
      ),
    Icon(icon, color: color, size: 36),
  ]);
}

class _ZoomBtn extends StatelessWidget {
  const _ZoomBtn(this.icon, this.onTap, {this.color = Colors.black87});
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) => FloatingActionButton.small(
    heroTag: null,
    onPressed: onTap,
    backgroundColor: Colors.white,
    child: Icon(icon, color: color),
  );
}

class _RoutePainter extends CustomPainter {
  _RoutePainter({required this.startOffset, required this.destOffset});
  final Offset startOffset, destOffset;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawLine(startOffset, destOffset,
        Paint()..color = Colors.black26..strokeWidth = 9..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
    // Dashed route line
    final Paint linePaint = Paint()
      ..color = const Color(0xFF1B5E20)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path()..moveTo(startOffset.dx, startOffset.dy)..lineTo(destOffset.dx, destOffset.dy);
    _drawDashedPath(canvas, path, linePaint, dashLength: 14, gapLength: 8);
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint,
      {double dashLength = 10, double gapLength = 5}) {
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final end = math.min(distance + dashLength, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += dashLength + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RoutePainter old) =>
      old.startOffset != startOffset || old.destOffset != destOffset;
}
