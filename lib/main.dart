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
          gradient: LinearGradient(
            colors:[
              Color(0xFF667eea),Color(0xFF764ba2)
            ],

          begin: Alignment.topLeft,
          end:Alignment.bottomRight,
          ),
        ),

        child : Column(
          children:[
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(25),
              margin: EdgeInsets.only(top:50),
              
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  Color(0xFF4CAF50),  // Green
                  Color(0xFF45a049),  // Darker green
                ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),

                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color:Colors.black.withOpacity(0.5),
                    spreadRadius: 5,
                    blurRadius: 7,
                    offset: Offset(0,3),

                  ),
                ],

              ),

              child:Column(
                children:[
                  Text(
                      '🧠 Dementia Support App',
                      style:TextStyle(
                        color:Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,

                      ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height:8),

                  Text(
                    'Help us improve with your feedback',
                    style:TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );


  }
}

