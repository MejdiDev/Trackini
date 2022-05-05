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
  String position = "0.0, 0.0";
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
    index: 3,
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
                    return 'Please enter some text';
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
                    return 'Please enter some text';
                  }

                  return null;
                },
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
                  if (value == null || value.isEmpty) {
                    return 'Please enter some text';
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
                    return 'Please enter some text';
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
                    return 'Please enter some text';
                  }

                  return null;
                },
              ),

              ElevatedButton(
                onPressed: () {
                  if(_formKey.currentState!.validate()){
                    newCar.save();
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
