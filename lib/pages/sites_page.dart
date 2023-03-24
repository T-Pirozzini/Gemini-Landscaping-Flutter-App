// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';

// class SitesPage extends StatefulWidget {
//   const SitesPage({Key? key});  

//   @override
//   State<SitesPage> createState() => _SitesPageState();
// }

// class _SitesPageState extends State<SitesPage> {
//   List<CollectionReference> sitesCollection = [];

//   Future<List<QueryDocumentSnapshot>> Collections() async {
//   List<QueryDocumentSnapshot> collections = [];

  // Get all the root-level collections in the Firestore database
// QuerySnapshot snapshot = await FirebaseFirestore.instance.listCollections();
  
// Loop through each document snapshot in the query snapshot
// for (QueryDocumentSnapshot doc in snapshot.docs) {
//   collections.add(doc);
// }

// return collections;
// }
  
//   @override
// void initState() {    
//   super.initState();
//   getCollections().then((value) {
//     setState(() {
//       sitesCollection = value;
//     });
//   });
// }


//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: ListView.builder(
//         itemCount: sitesCollection.length,
//         itemBuilder: (context, index) {
//           return ListTile(
//             title: Text(sitesCollection[index].id),
//             onTap: () {
//               // Navigate to a screen that displays the documents in the selected collection
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (_) => DocumentList(collection: sitesCollection[index]),
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }

// class DocumentList extends StatelessWidget {
//   final CollectionReference collection;

//   const DocumentList({Key? key, required this.collection}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(collection.id),
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: collection.snapshots(),
//         builder: (context, snapshot) {
//           if (!snapshot.hasData) {
//             return CircularProgressIndicator();
//           }
//           return ListView.builder(
//             itemCount: snapshot.data!.docs.length,
//             itemBuilder: (context, index) {
//               // Display the document ID and data as a ListTile
//               return ListTile(
//                 title: Text(snapshot.data!.docs[index].id),
//                 subtitle: Text(snapshot.data!.docs[index].data().toString()),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }
