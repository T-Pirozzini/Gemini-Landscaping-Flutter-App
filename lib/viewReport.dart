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
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(border: Border.all()),
                    child: Text(widget.docid["info"]['date']),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Text(widget.docid["info"]["siteName"]),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(
                    widget.docid["names"]["name1"],
                  ),
                  Text(
                    "On: ${widget.docid["times"]?["timeOn1"] ?? ""}",
                  ),
                  Text(
                    "Off: ${widget.docid["times"]?["timeOff1"] ?? ""}",
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(
                    widget.docid["names"]["name2"],
                  ),
                  Text(
                    "On: ${widget.docid["times"]["timeOn2"]}",
                  ),
                  Text(
                    "Off: ${widget.docid["times"]["timeOff2"]}",
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(
                    widget.docid["names"]["name3"],
                  ),
                  Text(
                    "On: ${widget.docid["times"]["timeOn3"]}",
                  ),
                  Text(
                    "Off: ${widget.docid["times"]["timeOff3"]}",
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(
                    widget.docid["names"]["name4"],
                  ),
                  Text(
                    "On: ${widget.docid["times"]["timeOn4"]}",
                  ),
                  Text(
                    "Off: ${widget.docid["times"]["timeOff4"]}",
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
