import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:trackini/reusable_widgets/Driver.dart';
import 'package:image_picker/image_picker.dart';

class AddDriver extends StatefulWidget {
  const AddDriver({Key? key}) : super(key: key);

  @override
  State<AddDriver> createState() => _AddDriverState();
}

class NewCar {
  int index;
  String color = "#" + (math.Random().nextDouble() * 0xFFFFFF).toInt().toRadixString(16);
  String position = "36.81465465620368, 10.166621166510582";
  int serialNum;
  Driver? driver;

  NewCar({this.index = 999, this.serialNum = 0, this.driver});

  void save() async {
    DatabaseEvent indexEvent = await FirebaseDatabase.instance.ref('/carsNum').once();
    int index = int.parse(indexEvent.snapshot.value.toString());

    DatabaseReference carRef = FirebaseDatabase.instance.ref('/cars/$index');
    DatabaseReference numRef = FirebaseDatabase.instance.ref('/carsNum');

    await carRef.set({
      'color': color,
      'position': position,
      'serialNum': serialNum,
      'driver': {
        'name': driver!.name,
        'gender': driver!.gender,
        'age': driver!.age,
        'CIN': driver!.cin,
        'phone': driver!.phone,
      }
    });

    await numRef.set(index + 1);
  }
}

class _AddDriverState extends State<AddDriver> {
  final _formKey = GlobalKey<FormState>();
  XFile? image;

  NewCar newCar = NewCar(
    index: 999,
    serialNum: 0000000,
    driver: Driver()
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(top: 50.0),
        child: Form(
          key: _formKey,

          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  labelText: "Full Name",
                  labelStyle: TextStyle(
                    fontSize: 17.0,
                  ),
                ),

                onChanged: (val) => setState(() {
                  newCar.driver!.name = val;
                }),

                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name !';
                  }

                  return null;
                },
              ),

              TextFormField(
                decoration: const InputDecoration(
                  labelText: "CIN",
                  labelStyle: TextStyle(
                    fontSize: 17.0,
                  ),
                ),

                onChanged: (val) => setState(() {
                  newCar.driver!.cin = int.parse(val);
                }),

                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a valid CIN !';
                  }

                  return null;
                },
              ),

              DropdownButtonFormField(
                  value: 'Male',

                  items: <String>['Male', 'Female']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),

                  onChanged: (value) => setState(() {
                    newCar.driver!.gender = value.toString();
                  }),
              ),

              TextFormField(
                decoration: const InputDecoration(
                  labelText: "Age",
                  labelStyle: TextStyle(
                    fontSize: 17.0,
                  ),
                ),

                onChanged: (val) => setState(() {
                  newCar.driver!.age = int.parse(val);
                }),

                validator: (value) {
                  if (value == null || value.isEmpty || value.toString().length == 2) {
                    return 'Please a valid age !';
                  }

                  return null;
                },
              ),

              TextFormField(
                decoration: const InputDecoration(
                  labelText: "Phone Number",
                  labelStyle: TextStyle(
                    fontSize: 17.0,
                  ),
                ),

                onChanged: (val) => setState(() {
                  newCar.driver!.phone = int.parse(val);
                }),

                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a valid phone number !';
                  }

                  return null;
                },
              ),

              TextFormField(
                decoration: const InputDecoration(
                  labelText: "Serial Number",
                  labelStyle: TextStyle(
                    fontSize: 17.0,
                  ),
                ),

                keyboardType: TextInputType.number,

                onChanged: (val) => setState(() {
                  newCar.serialNum = int.parse(val);
                }),

                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a valid serial number !';
                  }

                  return null;
                },
              ),

              ElevatedButton(
                onPressed: () {
                  if(_formKey.currentState!.validate()){
                    newCar.save();

                    newCar = NewCar(
                        index: 999,
                        serialNum: 0000000,
                        driver: Driver()
                    );
                  }
                },

                child: const Text("Add Driver !"),
              )
            ],
          ),
        ),
      ),
    );
  }
}
