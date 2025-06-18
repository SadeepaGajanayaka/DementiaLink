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
      home: Scaffold (appBar: AppBar(
        title: Text("FEEDBACK "),
      ),
      body: Center(

        child: Text("Hello world s" , style: TextStyle(fontStyle:FontStyle.italic),),
      ),
      ),
    );
  }

}

