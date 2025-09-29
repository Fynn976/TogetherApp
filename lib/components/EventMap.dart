import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class EventMap extends StatelessWidget {
  final double latitude;
  final double longitude;

  const EventMap({
    super.key,
    required this.latitude,
    required this.longitude,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10.0),
      child: SizedBox(
        width: 600,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: LatLng(latitude, longitude), // richtige Property
            initialZoom: 14.0,
            maxZoom: 18.0,
            minZoom: 5.0,
          ),
          children: [
            TileLayer(
              urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
              userAgentPackageName: 'com.example.loginpage', // wichtig!
            ),
            MarkerLayer(
              markers: [
                Marker(
                  width: 40.0,
                  height: 40.0,
                  point: LatLng(latitude, longitude),
                  child: Icon(Icons.location_on, size: 40.0, color: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
