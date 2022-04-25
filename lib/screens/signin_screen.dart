import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:trackini/screens/home_screen.dart';
import 'package:trackini/screens/signup_screen.dart';
import 'package:trackini/utils/color_util.dart';

import '../reusable_widgets/reusable_widget.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({Key? key}) : super(key: key);

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {




  TextEditingController _passwordTextController = TextEditingController();
  TextEditingController _emailTextController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
          hexStringToColor("33539E"),
          hexStringToColor("7FACD6"),
          hexStringToColor("BFB8DA"),
          hexStringToColor("E8B7D4"),
          hexStringToColor("A5678E")
        ], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
        child: SingleChildScrollView(
            child: Padding(
          padding: EdgeInsets.fromLTRB(
              20, MediaQuery.of(context).size.height * 0.2, 20, 0),
          child: Column(
            children: <Widget>[
              logoWidget("assets/images/logo.png"),
              SizedBox(
                height: 30,
              ),
              reusableTextField("Enter UserName", Icons.person_outline,false, _emailTextController),
              
              SizedBox(
                height: 30,
              ),
              reusableTextField("Enter Password",Icons.lock_outline,true, _passwordTextController),
              SizedBox(
                height: 30,
              ),

              signInSignUpButton(context, true, (){
              
                  FirebaseAuth.instance.signInWithEmailAndPassword(
                      email: _emailTextController.text,
                      password: _passwordTextController.text).then((value){
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => SignUpScreeen()));

                      }).onError((error, stackTrace) {
                          print("Error ${error.toString()}");
                      });
              }),
              signUpOption()
            ],
          ),
        ),
        ),
      ),
    );
  }

  Row signUpOption(){
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Don't have account ?" ,
        style: TextStyle(color: Colors.white70)),
        GestureDetector(
          onTap: (){
            Navigator.push(context, MaterialPageRoute(builder:(context) => SignUpScreeen()));
          },
          child: const Text(
            "Sign Up",
            style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),
          ),
          ),
        
      ],
    );
  }

 
}
