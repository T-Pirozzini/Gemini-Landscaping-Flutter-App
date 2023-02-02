import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'main.dart';
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

  TextEditingController timeOn1temp = TextEditingController();
  TextEditingController timeOff1temp = TextEditingController();
  TextEditingController timeOn2 = TextEditingController();
  TextEditingController timeOff2 = TextEditingController();
  TextEditingController timeOn3 = TextEditingController();
  TextEditingController timeOff3 = TextEditingController();
  TextEditingController timeOn4 = TextEditingController();
  TextEditingController timeOff4 = TextEditingController();

  @override
  void initState() {
    date = TextEditingController(text: widget.docid.get('date'));
    siteName = TextEditingController(text: widget.docid.get('siteName'));
    team1 = TextEditingController(text: widget.docid.get('team1'));
    timeOn1temp = TextEditingController(text: widget.docid.get('timeOn1'));
    timeOff1temp = TextEditingController(text: widget.docid.get('timeOff1'));
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
        backgroundColor: const Color.fromARGB(255, 31, 182, 77),
        actions: [
          MaterialButton(
            onPressed: () {
              Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (_) => Home()));
            },
            child: const Text(
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
                'siteName': siteName.text,
                'team1': team1.text,
                'team2': team1.text,
                'team3': team1.text,
                'team4': team1.text,
                'timeOn1temp': timeOn1temp.text,
                'timeOff1temp': timeOff1temp.text,
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
            child: const Text(
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
            child: const Text(
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
              const SizedBox(
                height: 20,
              ),
              Container(
                decoration: BoxDecoration(border: Border.all()),
                child: TextField(
                  controller: date,
                  decoration: const InputDecoration(
                    hintText: 'Enter date',
                  ),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Container(
                decoration: BoxDecoration(border: Border.all()),
                child: TextField(
                  controller: siteName,
                  maxLines: null,
                  keyboardType: TextInputType.text,
                  decoration: const InputDecoration(
                    hintText: 'Enter site name',
                  ),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Container(
                decoration: BoxDecoration(border: Border.all()),
                child: TextField(
                  controller: team1,
                  maxLines: null,
                  keyboardType: TextInputType.text,
                  decoration: const InputDecoration(
                    hintText: 'Enter crew leader name',
                  ),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Container(
                decoration: BoxDecoration(border: Border.all()),
                child: TextField(
                  controller: timeOn1temp,
                  maxLines: null,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'Enter time On',
                  ),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Container(
                decoration: BoxDecoration(border: Border.all()),
                child: TextField(
                  controller: timeOff1temp,
                  maxLines: null,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
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
                  decoration: const InputDecoration(
                    hintText: 'Enter name',
                  ),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Container(
                decoration: BoxDecoration(border: Border.all()),
                child: TextField(
                  controller: timeOn2,
                  maxLines: null,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'Enter time On',
                  ),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Container(
                decoration: BoxDecoration(border: Border.all()),
                child: TextField(
                  controller: timeOff2,
                  maxLines: null,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
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
                  decoration: const InputDecoration(
                    hintText: 'Enter name',
                  ),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Container(
                decoration: BoxDecoration(border: Border.all()),
                child: TextField(
                  controller: timeOn3,
                  maxLines: null,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'Enter time On',
                  ),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Container(
                decoration: BoxDecoration(border: Border.all()),
                child: TextField(
                  controller: timeOff3,
                  maxLines: null,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
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
                  decoration: const InputDecoration(
                    hintText: 'Enter name',
                  ),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Container(
                decoration: BoxDecoration(border: Border.all()),
                child: TextField(
                  controller: timeOn4,
                  maxLines: null,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'Enter time On',
                  ),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Container(
                decoration: BoxDecoration(border: Border.all()),
                child: TextField(
                  controller: timeOff4,
                  maxLines: null,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'Enter time Off',
                  ),
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              MaterialButton(
                color: const Color.fromARGB(255, 31, 182, 77),
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
                child: const Text(
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
