import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  final ref = FirebaseDatabase.instance.ref('/latLng');

  late Marker marker;
  CameraPosition? camPos;
  double speed = 0.0;
  DateTime? timestamp;
  bool widowVis = false;

  var carPos;   //The variable in which the location data coming from the database is stored.
  void fetchData() async {
    BitmapDescriptor markerbitmap = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(),
      "assets/images/car.png",
    );


    DatabaseEvent event = await ref.once();
    final location = event.snapshot.value;
    var lastCarPos = carPos;

    if(location.toString() == lastCarPos) {
      if(speed == 0.0) return;

      setState(() {
        speed = 0.0;
      });
      return;
    }

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
        consumeTapEvents: true,

        onTap: () {
          setState(() {
            widowVis = true;
          });
        }
      );
    });

    var lastTimestamp = timestamp;
    timestamp = DateTime.now();

    var timeDiff = timestamp!.difference(lastTimestamp!).inSeconds;   //The time between positions A and B in seconds.
    var distanceDiff = calculateDistance(
        parsecords(lastCarPos)[0],
        parsecords(lastCarPos)[1],
        parsecords(carPos)[0],
        parsecords(carPos)[1]
    );

    speed = distanceDiff / (timeDiff / 3600);
    transition();
  }

  @override
  void initState() {
    Future.delayed(const Duration(seconds: 2), () {
      Timer.periodic(const Duration(milliseconds: 500), (Timer timer) async {
        fetchData();
      });
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
      (camPos == null) ?
      const SpinKitDualRing(
        color: Colors.blueAccent,
        size: 80.0,
        lineWidth: 10.0,
      ):

      Stack(
        alignment: Alignment.centerRight,
        children: [
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: camPos!,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },

            onTap: (pos) => setState(() {
              widowVis = false;
            }),

            markers: {marker},
          ),

          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            bottom: widowVis ? 10.0 : -100.0,
            left: 0.0,
            child: Container(
              width: (MediaQuery.of(context).size.width - 20.0),
              margin: const EdgeInsets.only(left: 10.0),
              height: 75.0,
              padding: const EdgeInsets.only(left: 25.0),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: Colors.white,

                borderRadius: const BorderRadius.all(
                    Radius.circular(15.0)
                ),

                border: Border.all(
                  color: Colors.black,
                  width: 1.0,
                ),

                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.8),
                    spreadRadius: 5,
                    blurRadius: 8,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Text(
                'Speed:  ${speed.toStringAsFixed(1)} Km/h',
                style: const TextStyle(
                  fontSize: 18.0,
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
    controller.animateCamera(CameraUpdate.newCameraPosition(camPos!));
  }

  double calculateDistance(lat1, lon1, lat2, lon2){
    var p = 0.017453292519943295;
    var a = 0.5 - cos((lat2 - lat1) * p)/2 +
        cos(lat1 * p) * cos(lat2 * p) *
            (1 - cos((lon2 - lon1) * p))/2;

    return 12742 * asin(sqrt(a));
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