import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';


void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: LocationTrackerApp(),
    );
  }
}

class LocationTrackerApp extends StatefulWidget {
  @override
  _LocationTrackerAppState createState() => _LocationTrackerAppState();
}

class _LocationTrackerAppState extends State<LocationTrackerApp> {
  GoogleMapController? mapController;
  Completer<GoogleMapController> _controller = Completer();
  StreamSubscription<Position>? _positionStreamSubscription;
  List<Location> locations = [];
  List<Marker> markers = [];

  @override
  void initState() {
    super.initState();
    getLocationsFromDatabase().then((locations) {
      setState(() {
        this.locations = locations;
        for (var location in locations) {
          markers.add(Marker(
              position: LatLng(location.latitude, location.longitude),
              infoWindow: InfoWindow(
                  title: "Loc", snippet: location.timestamp.toString()),
              markerId: MarkerId(DateTime.timestamp().toString())));
        }
      });
    });

    _positionStreamSubscription =
        GeolocatorPlatform.instance.getPositionStream().listen((position) {
      setState(() {
        locations.add(
            Location(position.latitude, position.longitude, DateTime.now()));

        saveLocationToDatabase(locations);

        markers.add(Marker(
            position: LatLng(position.latitude, position.longitude),
            infoWindow: InfoWindow(
                title: 'User Location', snippet: DateTime.now().toString()),
            markerId: MarkerId(DateTime.timestamp().toString())));
        mapController?.moveCamera(CameraUpdate.newLatLng(
            LatLng(position.latitude, position.longitude)));
      });
    });
  }

  Future<List<Location>> getLocationsFromDatabase() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? locationStrings = prefs.getStringList('locations');

    List<Location> locations = [];
    for (var locationString in locationStrings!) {
      Location location = Location.fromJson(locationString);
      locations.add(location);
    }

    return locations;
  }

  Future<void> saveLocationToDatabase(List<Location> locations) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    List<String> locationStrings = [];
    for (var location in locations) {
      locationStrings.add(location.toJson());
    }

    prefs.setStringList('locations', locationStrings);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Tracker'),
      ),
      body: GoogleMap(
        mapType: MapType.normal,
        initialCameraPosition:
            const CameraPosition(target: LatLng(11, 77), zoom: 16.0),
        onMapCreated: (controller) {
          _controller.complete(controller);
          mapController = controller;
        },
        markers: markers.toSet(),
      ),
    );
  }
}

class Location {
  double latitude;
  double longitude;
  DateTime timestamp;

  Location(this.latitude, this.longitude, this.timestamp);

  String toJson() {
    return '{"latitude": $latitude, "longitude": $longitude, "timestamp": "$timestamp"}';
  }

  factory Location.fromJson(String json) {
    Map<String, dynamic> map = jsonDecode(json);
    return Location(
        map['latitude'], map['longitude'], DateTime.parse(map['timestamp']));
  }
}
