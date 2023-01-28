import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'main.dart';
import 'report.dart';
import 'sitereport.dart';

class editnote extends StatefulWidget {
  DocumentSnapshot docid;
  editnote({required this.docid});

  @override
  _editnoteState createState() => _editnoteState(docid: docid);
}

class _editnoteState extends State<editnote> {
  DocumentSnapshot docid;
  _editnoteState({required this.docid});
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

  @override
  void initState() {   
    date = TextEditingController(text: widget.docid.get('date'));
    siteName = TextEditingController(text: widget.docid.get('site name'));
    team1 = TextEditingController(text: widget.docid.get('team1'));
    timeOn1 = TextEditingController(text: widget.docid.get('timeOn1'));
    timeOff1 = TextEditingController(text: widget.docid.get('timeOff1'));
    team2 = TextEditingController(text: widget.docid.get('team2'));
    timeOn2 = TextEditingController(text: widget.docid.get('timeOn2'));
    timeOff2 = TextEditingController(text: widget.docid.get('timeOff2'));
    team3 = TextEditingController(text: widget.docid.get('team3'));
    timeOn3 = TextEditingController(text: widget.docid.get('timeOn3'));
    timeOff3 = TextEditingController(text: widget.docid.get('timeOff3'));
    team4 = TextEditingController(text: widget.docid.get('team4'));
    timeOn4 = TextEditingController(text: widget.docid.get('timeOn4'));
    timeOff4 = TextEditingController(text: widget.docid.get('timeOff4'));

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 0, 11, 133),
        actions: [
          MaterialButton(
            onPressed: () {
              Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (_) => Home()));
            },
            child: Text(
              "Back",
              style: TextStyle(
                fontSize: 20,
                color: Color.fromARGB(255, 251, 251, 251),
              ),
            ),
          ),
          MaterialButton(
            onPressed: () {
              widget.docid.reference.update({
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
            child: Text(
              "Save",
              style: TextStyle(
                fontSize: 20,
                color: Color.fromARGB(255, 251, 251, 251),
              ),
            ),
          ),
          MaterialButton(
            onPressed: () {
              widget.docid.reference.delete().whenComplete(() {
                Navigator.pushReplacement(
                    context, MaterialPageRoute(builder: (_) => Home()));
              });
            },
            child: Text(
              "Delete",
              style: TextStyle(
                fontSize: 20,
                color: Color.fromARGB(255, 251, 251, 251),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Container(
          child: Column(
            children: [
              SizedBox(
                height: 20,
              ),
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
              SizedBox(
                height: 20,
              ),
              MaterialButton(
                color: Color.fromARGB(255, 0, 11, 133),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SiteReport(
                        docid: docid,
                      ),
                    ),
                  );
                },
                child: Text(
                  "Make Report",
                  style: TextStyle(
                    fontSize: 20,
                    color: Color.fromARGB(255, 251, 251, 251),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
