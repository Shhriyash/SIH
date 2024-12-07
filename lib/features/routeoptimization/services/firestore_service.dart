// lib/services/firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> updateDeliveryStatus(String postId, String postOfficeName) async {
    try {
      DocumentReference docRef = _firestore.collection('post_details').doc(postId);

      DocumentSnapshot docSnapshot = await docRef.get();
      if (!docSnapshot.exists) {
        throw Exception("Post ID not found in database.");
      }

      await docRef.update({
        'curr_post_office_name': postOfficeName,
        'status': 'in transit',
        'updated_at': FieldValue.serverTimestamp(),
      });

      print('Delivery status updated for post_id: $postId');
    } catch (e) {
      print('Error updating delivery status: $e');
      rethrow;
    }
  }
}
