import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class BadgeMap extends StatefulWidget {
  Set<Marker> markers;

  BadgeMap({required this.markers});
  @override
  _BadgeMap createState() => _BadgeMap();
}

class _BadgeMap extends State<BadgeMap> {
  late GoogleMapController mapController;

  final LatLng _center = const LatLng(45.5017, -73.5673);

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  buildMaps() {
    return GoogleMap(
      onMapCreated: _onMapCreated,
      initialCameraPosition: CameraPosition(
        target: _center,
        zoom: 11.0,
      ),
      markers: widget.markers,
    );
  }

  @override
  Widget build(BuildContext context) {
    return buildMaps();
  }
}
