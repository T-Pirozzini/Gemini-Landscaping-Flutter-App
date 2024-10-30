import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class InactiveSitesScreen extends StatelessWidget {
  const InactiveSitesScreen({Key? key}) : super(key: key);

  Future<void> _setSiteToActive(BuildContext context, String siteId) async {
    await FirebaseFirestore.instance.collection('SiteList').doc(siteId).update({
      'status': true,
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Site reactivated')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Inactive Sites'),
        backgroundColor: Colors.green,
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('SiteList')
            .where('status', isEqualTo: false) // Fetch inactive sites
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No inactive sites found.'));
          }
          final inactiveSites = snapshot.data!.docs;

          return ListView.builder(
            itemCount: inactiveSites.length,
            itemBuilder: (context, index) {
              final site = inactiveSites[index];
              final siteName = site['name'];

              return ListTile(
                title: Text(siteName),
                trailing: IconButton(
                  icon: const Icon(Icons.restore, color: Colors.blue),
                  onPressed: () {
                    _setSiteToActive(context, site.id);
                  },
                  tooltip: 'Reactivate Site',
                ),
              );
            },
          );
        },
      ),
    );
  }
}
