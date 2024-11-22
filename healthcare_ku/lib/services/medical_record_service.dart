import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/medical_record_model.dart';

class MedicalRecordService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage storage = FirebaseStorage.instance;
  final String collection = 'medical_records';

  // Create a new medical record
  Future<String> createMedicalRecord(MedicalRecord record) async {
    try {
      DocumentReference docRef = await _firestore.collection(collection).add(
            record.toFirestore(),
          );
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create medical record: $e');
    }
  }

  // Get all medical records for a patient
  Stream<List<MedicalRecord>> getPatientMedicalRecords(String patientId) {
    return _firestore
        .collection(collection)
        .where('patientId', isEqualTo: patientId)
        .orderBy('dateCreated', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MedicalRecord.fromFirestore(doc))
            .toList());
  }

  // Get all medical records created by a doctor
  Stream<List<MedicalRecord>> getDoctorMedicalRecords(String doctorId) {
    return _firestore
        .collection(collection)
        .where('doctorId', isEqualTo: doctorId)
        .orderBy('dateCreated', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MedicalRecord.fromFirestore(doc))
            .toList());
  }

  // Get a single medical record by ID
  Future<MedicalRecord?> getMedicalRecord(String recordId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection(collection).doc(recordId).get();
      if (doc.exists) {
        return MedicalRecord.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get medical record: $e');
    }
  }

  // Update a medical record
  Future<void> updateMedicalRecord(
      String recordId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection(collection).doc(recordId).update(updates);
    } catch (e) {
      throw Exception('Failed to update medical record: $e');
    }
  }

  // Delete a medical record
  Future<void> deleteMedicalRecord(String recordId) async {
    try {
      // Get the record first to check for attachments
      MedicalRecord? record = await getMedicalRecord(recordId);
      if (record != null) {
        // Delete all attachments from storage
        for (String attachmentUrl in record.attachmentUrls) {
          try {
            Reference ref = storage.refFromURL(attachmentUrl);
            await ref.delete();
          } catch (e) {
            print('Error deleting attachment: $e');
          }
        }
      }
      // Delete the record document
      await _firestore.collection(collection).doc(recordId).delete();
    } catch (e) {
      throw Exception('Failed to delete medical record: $e');
    }
  }

  // Upload an attachment
  Future<String> uploadAttachment(String recordId, File file) async {
    try {
      String fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      Reference storageRef =
          storage.ref().child('medical_records/$recordId/$fileName');

      UploadTask uploadTask = storageRef.putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      // Add the attachment URL to the record
      await _firestore.collection(collection).doc(recordId).update({
        'attachmentUrls': FieldValue.arrayUnion([downloadUrl]),
        'lastUpdated': Timestamp.now(),
      });

      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload attachment: $e');
    }
  }

  // Delete an attachment
  Future<void> deleteAttachment(String recordId, String attachmentUrl) async {
    try {
      // Delete from storage
      Reference ref = storage.refFromURL(attachmentUrl);
      await ref.delete();

      // Remove URL from record
      await _firestore.collection(collection).doc(recordId).update({
        'attachmentUrls': FieldValue.arrayRemove([attachmentUrl]),
        'lastUpdated': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to delete attachment: $e');
    }
  }

  // Search medical records
  Future<List<MedicalRecord>> searchMedicalRecords({
    String? patientId,
    String? doctorId,
    DateTime? startDate,
    DateTime? endDate,
    String? diagnosis,
  }) async {
    Query query = _firestore.collection(collection);

    if (patientId != null) {
      query = query.where('patientId', isEqualTo: patientId);
    }
    if (doctorId != null) {
      query = query.where('doctorId', isEqualTo: doctorId);
    }
    if (startDate != null) {
      query = query.where('dateCreated',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }
    if (endDate != null) {
      query = query.where('dateCreated',
          isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    }
    if (diagnosis != null) {
      query = query.where('diagnosis', isEqualTo: diagnosis);
    }

    QuerySnapshot querySnapshot = await query.get();
    return querySnapshot.docs
        .map((doc) => MedicalRecord.fromFirestore(doc))
        .toList();
  }
}
