import 'package:cloud_firestore/cloud_firestore.dart';

class SiteReport {
  const SiteReport({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.imageUrl,    
  });

  final String id;
  final String title;
  final String description;
  final String date;
  final String imageUrl;
  
}
