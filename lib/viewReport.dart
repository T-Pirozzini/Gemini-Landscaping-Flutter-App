import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'main.dart';

class ViewReport extends StatefulWidget {
  DocumentSnapshot docid;
  ViewReport({required this.docid});

  @override
  State<ViewReport> createState() => _ViewReportState(docid: docid);
}

CollectionReference ref =
    FirebaseFirestore.instance.collection('SiteReports2023');

class _ViewReportState extends State<ViewReport> {
  DocumentSnapshot docid;
  _ViewReportState({required this.docid});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 31, 182, 77),
        leading: MaterialButton(
          onPressed: () {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => Home()));
          },
          child: Row(
            children: const [
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
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Column(
                // mainAxisAlignment: MainAxisAlignment.center,
                // crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(border: Border.all()),
                    child: Text(widget.docid.get('date')),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Text(widget.docid.get("siteName")),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(
                    widget.docid.get("name1"),
                  ),
                  Text(
                    "On: " + widget.docid.get("timeOn1"),
                  ),
                  Text(
                    "Off: " + widget.docid.get("timeOff1"),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(
                    widget.docid.get("name2"),
                  ),
                  Text(
                    "On: " + widget.docid.get("timeOn2"),
                  ),
                  Text(
                    "Off: " + widget.docid.get("timeOff2"),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(
                    widget.docid.get("name3"),
                  ),
                  Text(
                    "On: " + widget.docid.get("timeOn3"),
                  ),
                  Text(
                    "Off: " + widget.docid.get("timeOff3"),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(
                    widget.docid.get("name4"),
                  ),
                  Text(
                    "On: " + widget.docid.get("timeOn4"),
                  ),
                  Text(
                    "Off: " + widget.docid.get("timeOff4"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
