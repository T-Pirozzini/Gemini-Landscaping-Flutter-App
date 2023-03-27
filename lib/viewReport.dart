import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gemini_landscaping_app/pages/home_page.dart';
import 'sitereport.dart';

// ignore: must_be_immutable
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
      backgroundColor: Colors.grey.shade200,
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
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(2),
                  decoration: BoxDecoration(border: Border.all()),
                  child: Text(widget.docid["info"]['date']),
                ),
                const SizedBox(
                  height: 10,
                ),
                Text(
                  widget.docid["info"]["siteName"].toUpperCase(),
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15.0),
              ],
            ),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
              ),
              child: Table(
                border: TableBorder.all(
                  color: Color.fromARGB(255, 31, 182, 77),
                ),
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
                      child: widget.docid["names"]["name2"] == ""
                          ? Text("")
                          : Text(widget.docid["times"]["timeOn2"]),
                    ),
                    Container(
                      alignment: Alignment.center,
                      child: widget.docid["names"]["name2"] == ""
                          ? Text("")
                          : Text(widget.docid["times"]["timeOff2"]),
                    ),
                    Container(
                      alignment: Alignment.center,
                      child: widget.docid["names"]["name2"] == ""
                          ? Text("")
                          : Text(
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
                      child: widget.docid["names"]["name3"] == ""
                          ? Text("")
                          : Text(widget.docid["times"]["timeOn3"]),
                    ),
                    Container(
                      alignment: Alignment.center,
                      child: widget.docid["names"]["name3"] == ""
                          ? Text("")
                          : Text(widget.docid["times"]["timeOff3"]),
                    ),
                    Container(
                      alignment: Alignment.center,
                      child: widget.docid["names"]["name3"] == ""
                          ? Text("")
                          : Text(
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
                      child: widget.docid["names"]["name4"] == ""
                          ? Text("")
                          : Text(widget.docid["times"]["timeOn4"]),
                    ),
                    Container(
                      alignment: Alignment.center,
                      child: widget.docid["names"]["name4"] == ""
                          ? Text("")
                          : Text(widget.docid["times"]["timeOff4"]),
                    ),
                    Container(
                      alignment: Alignment.center,
                      child: widget.docid["names"]["name4"] == ""
                          ? Text("")
                          : Text(
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
                            "${(((Duration(hours: int.parse(widget.docid["times"]["timeOff1"].split(":")[0]), minutes: int.parse(widget.docid["times"]["timeOff1"].split(":")[1])) - Duration(hours: int.parse(widget.docid["times"]["timeOn1"].split(":")[0]), minutes: int.parse(widget.docid["times"]["timeOn1"].split(":")[1])))) + (Duration(hours: int.parse(widget.docid["times"]["timeOff2"].split(":")[0]), minutes: int.parse(widget.docid["times"]["timeOff2"].split(":")[1])) - Duration(hours: int.parse(widget.docid["times"]["timeOn2"].split(":")[0]), minutes: int.parse(widget.docid["times"]["timeOn2"].split(":")[1]))) + (Duration(hours: int.parse(widget.docid["times"]["timeOff3"].split(":")[0]), minutes: int.parse(widget.docid["times"]["timeOff3"].split(":")[1])) - Duration(hours: int.parse(widget.docid["times"]["timeOn3"].split(":")[0]), minutes: int.parse(widget.docid["times"]["timeOn3"].split(":")[1]))) + (Duration(hours: int.parse(widget.docid["times"]["timeOff4"].split(":")[0]), minutes: int.parse(widget.docid["times"]["timeOff4"].split(":")[1])) - Duration(hours: int.parse(widget.docid["times"]["timeOn4"].split(":")[0]), minutes: int.parse(widget.docid["times"]["timeOn4"].split(":")[1])))).toString().substring(0, 4)}"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: 6, // number of rows
                itemBuilder: (context, index) {
                  String label;
                  List<String> items;
                  switch (index) {
                    case 0:
                      label = 'Pick up loose garbage:';
                      items = widget.docid["service"]["garbage"]
                          .whereType<String>()
                          .toList() as List<String>;
                      break;
                    case 1:
                      label = 'Rake yard debris:';
                      items = widget.docid["service"]["debris"]
                          .whereType<String>()
                          .toList() as List<String>;
                      break;
                    case 2:
                      label = 'Lawn care:';
                      items = widget.docid["service"]["lawn"]
                          .whereType<String>()
                          .toList() as List<String>;
                      break;
                    case 3:
                      label = 'Gardens:';
                      items = widget.docid["service"]["garden"]
                          .whereType<String>()
                          .toList() as List<String>;
                      break;
                    case 4:
                      label = 'Trees:';
                      items = widget.docid["service"]["tree"]
                          .whereType<String>()
                          .toList() as List<String>;
                      break;
                    case 5:
                      label = 'Blow dust/debris:';
                      items = widget.docid["service"]["blow"]
                          .whereType<String>()
                          .toList() as List<String>;
                      break;
                    default:
                      label = '';
                      items = [];
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 15.0),
                    child: Container(
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Color.fromARGB(255, 31, 182, 77),
                          )),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: 20,
                            child: Text(
                              label.toUpperCase(),
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w500),
                            ),
                          ),
                          ...items
                              .map((item) =>
                                  Text(item, style: TextStyle(fontSize: 14)))
                              .toList(),
                        ],
                      ),
                    ),
                  );
                },
              ),
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
    );
  }
}
