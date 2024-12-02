import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';
import 'station_screen.dart';  // StationScreen import 필요

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // 정류장 위치 정보를 저장할 Map
  final Map<String, LatLng> stationLocations = {
    "사색의광장(정문행)": const LatLng(37.2402833, 127.0824),
    "생명과학대.산업대학(정문행)": const LatLng(37.24335, 127.0807667),
    "경희대체육대학.외대(정문행)": const LatLng(37.2444333, 127.0791833),
    "경희대학교(정문행)": const LatLng(37.2477833, 127.0776333),
    "경희대정문(사색행)": const LatLng(37.24745, 127.0778833),
    "외국어대학(사색행)": const LatLng(37.2452167, 127.0784667),
    "생명과학대(사색행)": const LatLng(37.2430333, 127.0806167),
    "사색의광장(사색행)": const LatLng(37.2403667, 127.0820833),
  };

  // 마커들을 저장할 Set
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _createMarkers();
  }

  void _createMarkers() {
    setState(() {
      _markers = stationLocations.entries.map((station) {
        return Marker(
          markerId: MarkerId(station.key),
          position: station.value,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(
            title: station.key,
            snippet: '클릭하여 정류장 정보 보기',
          ),
          onTap: () => _onMarkerTapped(station.key),
        );
      }).toSet();
    });
  }

  void _onMarkerTapped(String stationName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StationScreen(stationName: stationName),
      ),
    );
  }

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.2430333, 127.0806167), // 경희대학교 국제캠퍼스 좌표
    zoom: 16, // 줌 레벨 조정
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('캠퍼스 지도'),
      ),
      body: GoogleMap(
        mapType: MapType.normal,
        initialCameraPosition: _kGooglePlex,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        zoomControlsEnabled: true,
        markers: _markers, // 마커 추가
        onMapCreated: (GoogleMapController controller) {
          // 필요한 경우 컨트롤러 저장
        },
      ),
    );
  }
}