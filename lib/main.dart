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

class FeedbackScreen extends StatefulWidget {
  @override
  FeedbackScreenState createState() => FeedbackScreenState();
}
  @override
class FeedbackScreenState extends State<FeedbackScreen>{

  String? selectedUserType;

  final List<String>userTypeOptions=[
    'Person with dementia',
    'Family caregiver',
    'Professional caregiver',
    'Healthcare provider',
    'Family member/friend',
  ];
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

            Expanded(
                child:Container(
                  margin: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color:Colors.white,
                    borderRadius: BorderRadius.circular(15),

                    boxShadow: [
                      BoxShadow(
                        color:Colors.black.withOpacity(0.1),
                        spreadRadius: 3,
                        blurRadius: 7,
                        offset: Offset(0,8),
                      ),
                    ],
                  ),

                  child : SingleChildScrollView(
                    padding : EdgeInsets.all(30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children:[
                        Center(
                          child:Text(
                            "We value your feedback! 💬",
                            style:TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color:Colors.green.shade700,

                            ),
                          ),
                        ),

                        SizedBox(height: 15),

                        Container(
                          width: double.infinity,
                          padding:EdgeInsets.all(15),
                          decoration:BoxDecoration(
                            color:Colors.green,
                            borderRadius: BorderRadius.circular(10),
                            border:Border.all(
                              color:Colors.green.shade50,
                              width: 1,
                            ),
                          ),
                          child:Text(
                            '👤 About You',
                            style:TextStyle(
                              fontSize:18,
                              fontWeight: FontWeight.bold,
                              color:Colors.green.shade800,
                            ),
                          ),
                        ),
                          SizedBox(height: 20),
                  Text(
                    'I am a : ',
                  style:TextStyle(
                      fontSize:16,
                      color:Colors.black,
                      fontWeight: FontWeight.w600,
                  ),
                ),

                SizedBox(height: 8,),

                DropdownButtonFormField<String>(
                  value:selectedUserType,
                  decoration:InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.green, width: 2),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    hintText: 'Please select your role...',
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                  ),
                  items: userTypeOptions.map<DropdownMenuItem<String>>((String value){
                    return DropdownMenuItem<String>(
                      value: value,
                      child:Text(
                        value,
                        style:TextStyle(fontSize:16),
                      ),
                    );
                  }
                  ).toList(),

                  onChanged: (String? newValue) {
                    setState(() {
                      selectedUserType = newValue;
                    });

                    // Show what was selected (for testing)
                    print('User selected: $newValue');
                  },
                ),

                    SizedBox(height: 20),

                    // SHOW SELECTED VALUE (for testing)
                    if (selectedUserType != null)
              Container(
              width: double.infinity,
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Text(
                '✅ You selected: $selectedUserType',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),











                        Center(
                          child:Text(
                              'Your input helps us create better tools for dementia care and support.',
                            style:TextStyle(
                              fontSize:16,
                              color:Colors.black,
                            ),
                              textAlign: TextAlign.center,

                          ),
                        ),

                        SizedBox(height: 30),

                        Container(
                          width: double.infinity,
                          padding:EdgeInsets.all(20),
                            decoration: BoxDecoration(
                            color:Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border:Border.all(
                              color:Colors.grey.shade300,
                              width: 1,
                            ),
                          ),


                          child:Center(
                            child:Text(
                                'Form fields will go here! 📝\n\nNext step: Add user type dropdown',
                              style:TextStyle(
                                fontSize:16,
                                color:Colors.grey.shade500,
                                fontStyle:FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,

                            ),
                          ),
                        ),
                      ],

                    ),
                  ),
                ),


            ),
          ],
        ),
      ),
    );


  }
}

