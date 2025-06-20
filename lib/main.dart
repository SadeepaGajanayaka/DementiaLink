import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
main(){
  runApp(MyApp());


}
class MyApp extends StatelessWidget{
  Widget build (BuildContext context){
    return MaterialApp(
     title: 'Dementia App Feedback',
      home:FeedbackScreen(),
      );


  }

}

class FeedbackScreen extends StatelessWidget{
  @override

  Widget build(BuildContext context){
    return Scaffold(
      body: Container(
        width : double.infinity,
        height: double.infinity,

        decoration: BoxDecoration(
          gradient: LinearGradient(colors:[Color(0xFF667eea),Color(0xFF764ba2)
          ],

          begin: Alignment.topLeft,
          end:Alignment.bottomRight,
          ),
        ),
        child:Center(
          child:Text(
            'Feedback ',style: TextStyle(color:Colors.white,fontSize: 24,fontWeight: FontWeight.bold),
          )
        )

      ),
    );
  }
}

