import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class FirebaseService extends GetxService {
  late FirebaseFirestore _firestore;
  FirebaseFirestore get db => _firestore;

  Future<FirebaseService> init() async {
    _firestore = FirebaseFirestore.instance;
    return this;
  }
}
