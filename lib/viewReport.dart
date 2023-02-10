import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gemini_landscaping_app/pages/home_page.dart';
import 'main.dart';
import 'sitereport.dart';

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
                  Text(
                    widget.docid["info"]["siteName"],
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(height: 15.0),
                ],
              ),
              Table(
                border: TableBorder.all(),
                children: [
                  TableRow(children: [
                    Container(
                      alignment: Alignment.center,
                      child: const Text(
                        'Name',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      alignment: Alignment.center,
                      child: const Text('On',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Container(
                      alignment: Alignment.center,
                      child: const Text('Off',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Container(
                      alignment: Alignment.center,
                      child: const Text('Hours',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ]),
                  TableRow(children: [
                    Container(
                      alignment: Alignment.center,
                      child: Text(widget.docid["names"]["name1"]),
                    ),
                    Container(
                      alignment: Alignment.center,
                      child: Text(widget.docid["times"]["timeOn1"]),
                    ),
                    Container(
                      alignment: Alignment.center,
                      child: Text(widget.docid["times"]["timeOff1"]),
                    ),
                    Container(
                      alignment: Alignment.center,
                      child: Text(
                          "${(Duration(hours: int.parse(widget.docid["times"]["timeOff1"].split(":")[0]), minutes: int.parse(widget.docid["times"]["timeOff1"].split(":")[1])) - Duration(hours: int.parse(widget.docid["times"]["timeOn1"].split(":")[0]), minutes: int.parse(widget.docid["times"]["timeOn1"].split(":")[1]))).toString().substring(0, 4)}"),
                    ),
                  ]),
                  TableRow(children: [
                    Container(
                      alignment: Alignment.center,
                      child: Text(widget.docid["names"]["name2"]),
                    ),
                    Container(
                      alignment: Alignment.center,
                      child: Text(widget.docid["times"]["timeOn2"]),
                    ),
                    Container(
                      alignment: Alignment.center,
                      child: Text(widget.docid["times"]["timeOff2"]),
                    ),
                    Container(
                      alignment: Alignment.center,
                      child: Text(
                          "${(Duration(hours: int.parse(widget.docid["times"]["timeOff2"].split(":")[0]), minutes: int.parse(widget.docid["times"]["timeOff2"].split(":")[1])) - Duration(hours: int.parse(widget.docid["times"]["timeOn2"].split(":")[0]), minutes: int.parse(widget.docid["times"]["timeOn2"].split(":")[1]))).toString().substring(0, 4)}"),
                    ),
                  ]),
                  TableRow(children: [
                    Container(
                      alignment: Alignment.center,
                      child: Text(widget.docid["names"]["name3"]),
                    ),
                    Container(
                      alignment: Alignment.center,
                      child: Text(widget.docid["times"]["timeOn3"]),
                    ),
                    Container(
                      alignment: Alignment.center,
                      child: Text(widget.docid["times"]["timeOff3"]),
                    ),
                    Container(
                      alignment: Alignment.center,
                      child: Text(
                          "${(Duration(hours: int.parse(widget.docid["times"]["timeOff3"].split(":")[0]), minutes: int.parse(widget.docid["times"]["timeOff3"].split(":")[1])) - Duration(hours: int.parse(widget.docid["times"]["timeOn3"].split(":")[0]), minutes: int.parse(widget.docid["times"]["timeOn3"].split(":")[1]))).toString().substring(0, 4)}"),
                    ),
                  ]),
                  TableRow(children: [
                    Container(
                      alignment: Alignment.center,
                      child: Text(widget.docid["names"]["name4"]),
                    ),
                    Container(
                      alignment: Alignment.center,
                      child: Text(widget.docid["times"]["timeOn4"]),
                    ),
                    Container(
                      alignment: Alignment.center,
                      child: Text(widget.docid["times"]["timeOff4"]),
                    ),
                    Container(
                      alignment: Alignment.center,
                      child: Text(
                          "${(Duration(hours: int.parse(widget.docid["times"]["timeOff4"].split(":")[0]), minutes: int.parse(widget.docid["times"]["timeOff4"].split(":")[1])) - Duration(hours: int.parse(widget.docid["times"]["timeOn4"].split(":")[0]), minutes: int.parse(widget.docid["times"]["timeOn4"].split(":")[1]))).toString().substring(0, 4)}"),
                    ),
                  ]),
                  TableRow(
                    children: [
                      Container(),
                      Container(),
                      Container(
                        alignment: Alignment.center,
                        child: const Text("Total",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      Container(
                        alignment: Alignment.center,
                        child: Text(
                            "${(((Duration(hours: int.parse(widget.docid["times"]["timeOff1"].split(":")[0]), minutes: int.parse(widget.docid["times"]["timeOff1"].split(":")[1])) - Duration(hours: int.parse(widget.docid["times"]["timeOn1"].split(":")[0]), minutes: int.parse(widget.docid["times"]["timeOn1"].split(":")[1])))) + (Duration(hours: int.parse(widget.docid["times"]["timeOff2"].split(":")[0]), minutes: int.parse(widget.docid["times"]["timeOff2"].split(":")[1])) - Duration(hours: int.parse(widget.docid["times"]["timeOn2"].split(":")[0]), minutes: int.parse(widget.docid["times"]["timeOn2"].split(":")[1]))) + (Duration(hours: int.parse(widget.docid["times"]["timeOff3"].split(":")[0]), minutes: int.parse(widget.docid["times"]["timeOff3"].split(":")[1])) - Duration(hours: int.parse(widget.docid["times"]["timeOn3"].split(":")[0]), minutes: int.parse(widget.docid["times"]["timeOn3"].split(":")[1]))) + (Duration(hours: int.parse(widget.docid["times"]["timeOff4"].split(":")[0]), minutes: int.parse(widget.docid["times"]["timeOff4"].split(":")[1])) - Duration(hours: int.parse(widget.docid["times"]["timeOn4"].split(":")[0]), minutes: int.parse(widget.docid["times"]["timeOn4"].split(":")[1])))).toString().substring(0, 5)}"),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 20),
              Table(
                // border: TableBorder.all(),
                children: [
                  TableRow(
                    children: [
                      Container(
                        child: const Text('Pick up loose garbage:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 15.0),
                        child: Container(
                          child: Column(
                            children: (widget.docid["service"]["garbage"]
                                    .whereType<String>()
                                    .toList() as List<String>)
                                .map((item) => Text(item))
                                .toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  TableRow(
                    children: [
                      Container(
                        child: const Text('Rake yard debris:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 15.0),
                        child: Container(
                          child: Column(
                            children: (widget.docid["service"]["debris"]
                                    .whereType<String>()
                                    .toList() as List<String>)
                                .map((item) => Text(item))
                                .toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  TableRow(
                    children: [
                      Container(
                        child: const Text('Lawn care:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 15.0),
                        child: Container(
                          child: Column(
                            children: (widget.docid["service"]["lawn"]
                                    .whereType<String>()
                                    .toList() as List<String>)
                                .map((item) => Text(item))
                                .toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  TableRow(
                    children: [
                      Container(
                        child: const Text('Gardens:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 15.0),
                        child: Container(
                          child: Column(
                            children: (widget.docid["service"]["garden"]
                                    .whereType<String>()
                                    .toList() as List<String>)
                                .map((item) => Text(item))
                                .toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  TableRow(
                    children: [
                      Container(
                        child: const Text('Trees:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 15.0),
                        child: Container(
                          child: Column(
                            children: (widget.docid["service"]["tree"]
                                    .whereType<String>()
                                    .toList() as List<String>)
                                .map((item) => Text(item))
                                .toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  TableRow(
                    children: [
                      Container(
                        child: const Text('Blow dust/debris:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 15.0),
                        child: Container(
                          child: Column(
                            children: (widget.docid["service"]["blow"]
                                    .whereType<String>()
                                    .toList() as List<String>)
                                .map((item) => Text(item))
                                .toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              MaterialButton(
                color: Color.fromARGB(255, 20, 177, 54),
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
                  "Generate Report",
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: const [
                    SizedBox(height: 100),
                    Text("Delete Report?"),
                    Icon(Icons.delete),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
