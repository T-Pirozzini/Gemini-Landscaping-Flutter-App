import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'main.dart';

class AddReport extends StatelessWidget {
  TextEditingController date = TextEditingController();
  TextEditingController siteName = TextEditingController();
  TextEditingController team1 = TextEditingController();
  TextEditingController team2 = TextEditingController();
  TextEditingController team3 = TextEditingController();
  TextEditingController team4 = TextEditingController();

  TextEditingController timeOn1 = TextEditingController();
  TextEditingController timeOff1 = TextEditingController();
  TextEditingController timeOn2 = TextEditingController();
  TextEditingController timeOff2 = TextEditingController();
  TextEditingController timeOn3 = TextEditingController();
  TextEditingController timeOff3 = TextEditingController();
  TextEditingController timeOn4 = TextEditingController();
  TextEditingController timeOff4 = TextEditingController();

  CollectionReference ref =
      FirebaseFirestore.instance.collection('SiteReports2023');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 31, 182, 77),
        leading: MaterialButton(
          onPressed: () {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => Home()));
          },
          child: Row(
            children: [
              Icon(Icons.arrow_circle_left_outlined,
                  color: Colors.white, size: 18),
              Text(
                " Back",
                style: TextStyle(
                  fontSize: 15,
                  color: Color.fromARGB(255, 251, 251, 251),
                ),
              ),
            ],
          ),
        ),
        leadingWidth: 100,
        title: Image.asset("assets/gemini-icon-transparent.png",
            color: Colors.white, fit: BoxFit.contain, height: 50),
        centerTitle: true,
        actions: [
          MaterialButton(
            onPressed: () {
              ref.add({
                'date': date.text,
                'site name': siteName.text,
                'team1': team1.text,
                'team2': team1.text,
                'team3': team1.text,
                'team4': team1.text,
                'timeOn1': timeOn1.text,
                'timeOff1': timeOff1.text,
                'timeOn2': timeOn2.text,
                'timeOff2': timeOff2.text,
                'timeOn3': timeOn3.text,
                'timeOff3': timeOff3.text,
                'timeOn4': timeOn4.text,
                'timeOff4': timeOff4.text,
              }).whenComplete(() {
                Navigator.pushReplacement(
                    context, MaterialPageRoute(builder: (_) => Home()));
              });
            },
            child: Row(
              children: [
                Text(
                  "Submit ",
                  style: TextStyle(
                    fontSize: 15,
                    color: Color.fromARGB(255, 251, 251, 251),
                  ),
                ),
                Icon(
                  Icons.send,
                  color: Colors.white,
                  size: 18,
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(border: Border.all()),
              child: TextField(
                controller: date,
                decoration: InputDecoration(
                  hintText: 'Enter date',
                ),
              ),
            ),
            SizedBox(
              height: 10,
            ),
            Container(
              decoration: BoxDecoration(border: Border.all()),
              child: TextField(
                controller: siteName,
                maxLines: null,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  hintText: 'Enter site name',
                ),
              ),
            ),
            SizedBox(
              height: 10,
            ),
            Container(
              decoration: BoxDecoration(border: Border.all()),
              child: TextField(
                controller: team1,
                maxLines: null,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  hintText: 'Enter crew leader name',
                ),
              ),
            ),
            SizedBox(
              height: 10,
            ),
            Container(
              decoration: BoxDecoration(border: Border.all()),
              child: TextField(
                controller: timeOn1,
                maxLines: null,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Enter time On',
                ),
              ),
            ),
            SizedBox(
              height: 10,
            ),
            Container(
              decoration: BoxDecoration(border: Border.all()),
              child: TextField(
                controller: timeOff1,
                maxLines: null,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Enter time Off',
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(border: Border.all()),
              child: TextField(
                controller: team2,
                maxLines: null,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  hintText: 'Enter name',
                ),
              ),
            ),
            SizedBox(
              height: 10,
            ),
            Container(
              decoration: BoxDecoration(border: Border.all()),
              child: TextField(
                controller: timeOn2,
                maxLines: null,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Enter time On',
                ),
              ),
            ),
            SizedBox(
              height: 10,
            ),
            Container(
              decoration: BoxDecoration(border: Border.all()),
              child: TextField(
                controller: timeOff2,
                maxLines: null,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Enter time Off',
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(border: Border.all()),
              child: TextField(
                controller: team3,
                maxLines: null,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  hintText: 'Enter name',
                ),
              ),
            ),
            SizedBox(
              height: 10,
            ),
            Container(
              decoration: BoxDecoration(border: Border.all()),
              child: TextField(
                controller: timeOn3,
                maxLines: null,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Enter time On',
                ),
              ),
            ),
            SizedBox(
              height: 10,
            ),
            Container(
              decoration: BoxDecoration(border: Border.all()),
              child: TextField(
                controller: timeOff3,
                maxLines: null,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Enter time Off',
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(border: Border.all()),
              child: TextField(
                controller: team4,
                maxLines: null,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  hintText: 'Enter name',
                ),
              ),
            ),
            SizedBox(
              height: 10,
            ),
            Container(
              decoration: BoxDecoration(border: Border.all()),
              child: TextField(
                controller: timeOn4,
                maxLines: null,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Enter time On',
                ),
              ),
            ),
            SizedBox(
              height: 10,
            ),
            Container(
              decoration: BoxDecoration(border: Border.all()),
              child: TextField(
                controller: timeOff4,
                maxLines: null,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Enter time Off',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
