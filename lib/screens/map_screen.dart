import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  final ref = FirebaseDatabase.instance.ref('/latLng');

  late Marker marker;
  late CameraPosition camPos;
  double speed = 0.0;
  var timestamp;

  // CameraPosition camPos = CameraPosition(
  // target: LatLng(34.64879975941712, 10.590110805813373),
  // zoom: 17.5,
  // );
  //
  // Marker marker = Marker(
  // markerId: const MarkerId('Car Location'),
  // position: LatLng(34.64879975941712, 10.590110805813373),
  //
  // infoWindow: InfoWindow(
  // title: 'Speed',
  // snippet: '0.0 Km/h'
  // )
  // );

  var carPos;   //The variable in which the location data coming from the database is stored.
  void fetchData() async {
    BitmapDescriptor markerbitmap = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(),
      "assets/images/car.png",
    );

    ref.onValue.listen((event) {
      final location = event.snapshot.value;
      var lastCarPos = carPos;

      setState(() {
        carPos = location;
        LatLng newPos = LatLng(parsecords(carPos)[0], parsecords(carPos)[1]);

        //Update marker and camera position to the new position we got in the database.
        camPos = CameraPosition(
          target: newPos,
          zoom: 17.5,
        );

        marker = Marker(
          markerId: const MarkerId('Car Location'),
          position: newPos, //position of the marker.
          icon: markerbitmap, //Icon for Marker.
        );
      });

      double calculateDistance(lat1, lon1, lat2, lon2){
        var p = 0.017453292519943295;
        var a = 0.5 - cos((lat2 - lat1) * p)/2 +
            cos(lat1 * p) * cos(lat2 * p) *
                (1 - cos((lon2 - lon1) * p))/2;

        return 12742 * asin(sqrt(a));
      }

      var lastTimestamp = timestamp;
      timestamp = DateTime.now();

      var timeDiff = timestamp.difference(lastTimestamp).inSeconds;   //The time between positions A and B in seconds.
      var distanceDiff = calculateDistance(
          parsecords(lastCarPos)[0],
          parsecords(lastCarPos)[1],
          parsecords(carPos)[0],
          parsecords(carPos)[1]
      );

      speed = distanceDiff / (timeDiff / 3600);
      transition();
    });
  }

  @override
  void initState() {
    fetchData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: camPos,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },

            markers: {marker},
          ),

          Positioned(
            bottom: 0.0,
            left: 0.0,
            child: Container(
              width: 100.0,
              height: 70.0,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                    topRight: Radius.circular(15.0)
                ),
                color: Colors.white,
              ),
              child: Text(
                'Speed: \n${speed.toStringAsFixed(1)} Km/h',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15.5
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void transition() async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(camPos));
  }

  List parsecords(String coords) {
    return [
      double.parse(coords.substring(0, coords.indexOf(','))),   //First value is for 'Latitude'.
      double.parse(coords.substring((coords.indexOf(',') + 1), coords.length))    //Second value is for 'Longitude'.
    ];
  }

  void printWarning(text) {
    print('\x1B[33m$text\x1B[0m');
  }
}