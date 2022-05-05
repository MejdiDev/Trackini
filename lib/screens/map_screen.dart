import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:trackini/reusable_widgets/marker.dart';
import 'package:trackini/reusable_widgets/Driver.dart';

List parsecords(String coords) {
  return [
    double.parse(coords.substring(0, coords.indexOf(','))),   //First value is for 'Latitude'.
    double.parse(coords.substring((coords.indexOf(',') + 1), coords.length))    //Second value is for 'Longitude'.
  ];
}

class LocalCar {
  String? position;
  List? latLng;
  CameraPosition? camPos;
  DateTime timestamp = DateTime.now();
  Driver? driver;

  LocalCar(String? carPos, this.driver) {
    position = carPos;
    latLng = parsecords(position.toString());
    camPos = CameraPosition(
      target: LatLng(latLng![0], latLng![1]),
      zoom: 12.2
    );
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  final ref = FirebaseDatabase.instance.ref('/latLng');

  List<LocalCar> localCars = [];
  Set<Marker> markers = {};
  bool windowVis = false;
  bool windowExpanded = false;
  double speed = 0.0;
  int selectedCar = 0;
  String driverPic = "https://firebasestorage.googleapis.com/v0/b/tracking-c7cb4.appspot.com/o/default.jpg?alt=media&token=8870f0bd-feba-4e48-8d86-ce0a196cc2fa";

  void fetchData() async {
    //Calculating the height and width of the svg.
    var devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    var width = 48 * devicePixelRatio; // SVG's original width.
    var height = 48 * devicePixelRatio; // same thing.

    DatabaseEvent carsNumEvent = await FirebaseDatabase.instance.ref('/carsNum').once();
    int carsNum = int.parse(carsNumEvent.snapshot.value.toString());

    List<LocalCar> tempoCars = [];
    Set<Marker> tempoMarkers = {};

    for (int i = 0; i < carsNum; i++) {
      //This entire section is used for Fetching and Parsing the driver data.
      DatabaseReference driverRef = FirebaseDatabase.instance.ref('/cars/$i/driver');
      DatabaseEvent driverNameEvent = await driverRef.child('name').once();
      DatabaseEvent driverGenderEvent = await driverRef.child('gender').once();
      DatabaseEvent driverAgeEvent = await driverRef.child('age').once();
      DatabaseEvent driverCinEvent = await driverRef.child('CIN').once();
      DatabaseEvent driverPhoneEvent = await driverRef.child('phone').once();

      String driverName = driverNameEvent.snapshot.value.toString();
      String driverGender = driverGenderEvent.snapshot.value.toString();
      int driverAge = int.parse(driverAgeEvent.snapshot.value.toString());
      int driverCin = int.parse(driverCinEvent.snapshot.value.toString());
      int driverPhone = int.parse(driverPhoneEvent.snapshot.value.toString());

      DatabaseEvent posEvent = await FirebaseDatabase.instance.ref('/cars/$i/position').once();
      DatabaseEvent colorEvent = await FirebaseDatabase.instance.ref('/cars/$i/color').once();

      String position = posEvent.snapshot.value.toString();
      String color = colorEvent.snapshot.value.toString();
      Driver driver = Driver(
        name: driverName,
        gender: driverGender,
        age: driverAge,
        cin: driverCin,
        phone: driverPhone,
      );

      //Converting the svg String to a Drawable.
      var svgDrawableRoot = await svg.fromSvgString(svgString(color), svgString(color));

      //Converting the svg Drawable to an image (Asset).
      var picture = svgDrawableRoot.toPicture(size: Size(width, height));
      var image = await picture.toImage(width.toInt(), height.toInt());

      //Converting the Image we made into Bytes, then a Bitmap from set Bytes.
      var bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      BitmapDescriptor markerbitmap = BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());

      tempoCars.add(
          LocalCar(
            position,
            driver
          )
      );

      if(localCars.length == tempoCars.length) {
        if(localCars[selectedCar].position == tempoCars[selectedCar].position) {
          setState(() {
            speed = 0.0;
          });
        }

        else {
          var distanceDiff = calculateDistance(
              localCars[selectedCar].latLng![0],
              localCars[selectedCar].latLng![1],
              tempoCars[selectedCar].latLng![0],
              tempoCars[selectedCar].latLng![1]
          );

          setState(() {
            speed = distanceDiff / (0.5 / 3600);  //Since this loop executes every 500 milliseconds, that's the time difference we divide by.
          });
        }
      }

      tempoMarkers.add(
        Marker(
          markerId: MarkerId('Car $i ID'),
          position: LatLng(tempoCars[i].latLng![0], tempoCars[i].latLng![1]),
          icon: markerbitmap,
          consumeTapEvents: true,

          onTap: () {
            setState(() {
              windowVis = true;

              if(selectedCar == i) return;
              transition(tempoCars[i].camPos);
              selectedCar = i;
            });
          },
        )
      );
    }

    if(localCars.length == tempoCars.length && localCars[selectedCar].position != tempoCars[selectedCar].position) {
      transition(tempoCars[selectedCar].camPos);
    }

    setState(() {
      localCars = tempoCars;
      markers = tempoMarkers;
    });
  }

  Widget DriverDataLine({String? label, String? data}) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 21.0,
          height: 2.3,
        ),

        children: [
          TextSpan(
            text: '$label:',
            style: const TextStyle(
              color: Colors.blue,
              decoration: TextDecoration.underline,
              fontWeight: FontWeight.w500,
            ),
          ),

          TextSpan(
            text: ' $data',
            style: const TextStyle(
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    Timer.periodic(const Duration(milliseconds: 500), (Timer timer) async {
      fetchData();
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
      (localCars.isEmpty) ?
      const SpinKitDualRing(
        color: Colors.blueAccent,
        size: 80.0,
        lineWidth: 10.0,
      ):

      Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: localCars[selectedCar].camPos!,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },

            onTap: (pos) => setState(() {
              windowExpanded = false;
              windowVis = false;
            }),

            markers: markers,
          ),

          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            bottom: windowVis ? 10.0 : -100.0,
            left: 0.0,
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: (MediaQuery.of(context).size.width - 15.0),
                  height: windowExpanded ? (MediaQuery.of(context).size.height - 240.0) : 75.0,
                  margin: windowExpanded ? const EdgeInsets.fromLTRB(7.5, 0.0, 0.0, 95.0) : const EdgeInsets.only(left: 7.5),
                  clipBehavior: Clip.hardEdge,
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
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(25.0, 10.0, 10.0, 0),
                    child: Wrap(
                      direction: Axis.horizontal,
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Visibility(
                          visible: !windowExpanded,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: windowExpanded ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                            children: [
                              Text(
                                'Speed:  ${speed.toStringAsFixed(1)} Km/h',
                                style: const TextStyle(
                                  fontSize: 18.0,
                                ),
                              ),

                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    windowExpanded = true;
                                  });
                                },
                                color: Colors.blue,
                                iconSize: 30.0,
                                icon: const Icon(Icons.info_outline),
                              )
                            ],
                          ),
                        ),

                        Visibility(
                          visible: windowExpanded,
                          child: Stack(
                            children: [
                              Positioned(
                                top: 10.0,
                                right: 1.5,
                                child: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      windowExpanded = false;
                                    });
                                  },
                                  icon: const Icon(Icons.close),
                                ),
                              ),

                              Container(
                                margin: const EdgeInsets.only(top: 50.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    ClipOval(
                                      child: Image.network(
                                        driverPic,
                                        width: 220.0,
                                        height: 220.0,
                                        fit: BoxFit.cover,
                                        alignment: Alignment.topCenter,
                                      ),
                                    ),

                                    Container(
                                      margin: const EdgeInsets.only(top: 18.0),
                                      child: SizedBox(
                                        width: double.infinity,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            DriverDataLine(
                                                label: "Name",
                                                data: localCars[selectedCar].driver!.name
                                            ),

                                            DriverDataLine(
                                                label: "CIN",
                                                data: localCars[selectedCar].driver!.cin.toString()
                                            ),

                                            DriverDataLine(
                                                label: "Age",
                                                data: localCars[selectedCar].driver!.age.toString()
                                            ),

                                            DriverDataLine(
                                                label: "Gender",
                                                data: localCars[selectedCar].driver!.gender.toString()
                                            ),

                                            DriverDataLine(
                                                label: "Phone Number",
                                                data: localCars[selectedCar].driver!.phone.toString()
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void transition(CameraPosition? camPos) async {
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

  void printWarning(text) {
    print('\x1B[33m$text\x1B[0m');
  }
}