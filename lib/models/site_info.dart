import 'package:cloud_firestore/cloud_firestore.dart';

class SiteInfo {
  const SiteInfo({
    required this.address,
    required this.imageUrl,
    required this.management,
    required this.name,
    required this.status,    
  });

  final String address;
  final String imageUrl;
  final String management;
  final String name;
  final bool status;
  
}