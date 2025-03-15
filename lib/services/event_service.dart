import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';

class EventService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final uuid = const Uuid();
  
  List<Map<String, dynamic>> _events = [];
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get events => _events;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchEvents() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final snapshot = await _firestore.collection('events')
          .orderBy('date', descending: false)
          .get();
      
      _events = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      print('Error fetching events: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getEventsByDate(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day, 0, 0, 0);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final snapshot = await _firestore.collection('events')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      print('Error getting events by date: $e');
      return [];
    }
  }

  Future<String?> createEvent(Map<String, dynamic> eventData, List<File>? images) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 'User not authenticated';

      // Add creator info
      eventData['creatorId'] = user.uid;
      eventData['creatorName'] = user.displayName ?? 'Anonymous';
      eventData['createdAt'] = FieldValue.serverTimestamp();
      eventData['participants'] = [user.uid]; // Creator is automatically a participant
      eventData['tasks'] = eventData['tasks'] ?? [];
      eventData['photoUrls'] = [];

      // Upload images if provided
      if (images != null && images.isNotEmpty) {
        List<String> photoUrls = [];
        for (var image in images) {
          final imageId = uuid.v4();
          final storageRef = _storage.ref().child('event_images/$imageId');
          await storageRef.putFile(image);
          final downloadUrl = await storageRef.getDownloadURL();
          photoUrls.add(downloadUrl);
        }
        eventData['photoUrls'] = photoUrls;
      }

      // Save to Firestore
      final docRef = await _firestore.collection('events').add(eventData);
      
      // Add event to user's events list
      await _firestore.collection('users').doc(user.uid).update({
        'events': FieldValue.arrayUnion([docRef.id]),
      });

      await fetchEvents(); // Refresh events list
      return docRef.id;
    } catch (e) {
      print('Error creating event: $e');
      return e.toString();
    }
  }

  Future<bool> joinEvent(String eventId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Add user to event participants
      await _firestore.collection('events').doc(eventId).update({
        'participants': FieldValue.arrayUnion([user.uid]),
      });

      // Add event to user's events
      await _firestore.collection('users').doc(user.uid).update({
        'events': FieldValue.arrayUnion([eventId]),
      });

      await fetchEvents(); // Refresh events list
      return true;
    } catch (e) {
      print('Error joining event: $e');
      return false;
    }
  }

  Future<bool> leaveEvent(String eventId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Remove user from event participants
      await _firestore.collection('events').doc(eventId).update({
        'participants': FieldValue.arrayRemove([user.uid]),
      });

      // Remove event from user's events
      await _firestore.collection('users').doc(user.uid).update({
        'events': FieldValue.arrayRemove([eventId]),
      });

      await fetchEvents(); // Refresh events list
      return true;
    } catch (e) {
      print('Error leaving event: $e');
      return false;
    }
  }

  Future<bool> addTaskToEvent(String eventId, Map<String, dynamic> task) async {
    try {
      task['id'] = uuid.v4();
      task['completed'] = false;
      task['assignedTo'] = task['assignedTo'] ?? [];
      task['createdAt'] = FieldValue.serverTimestamp();

      await _firestore.collection('events').doc(eventId).update({
        'tasks': FieldValue.arrayUnion([task]),
      });

      await fetchEvents(); // Refresh events list
      return true;
    } catch (e) {
      print('Error adding task: $e');
      return false;
    }
  }

  Future<bool> updateTaskStatus(String eventId, String taskId, bool completed) async {
    try {
      // Get the current event data
      final eventDoc = await _firestore.collection('events').doc(eventId).get();
      if (!eventDoc.exists) return false;
      
      final eventData = eventDoc.data()!;
      final tasks = List<Map<String, dynamic>>.from(eventData['tasks'] ?? []);
      
      // Find and update the specific task
      final taskIndex = tasks.indexWhere((task) => task['id'] == taskId);
      if (taskIndex == -1) return false;
      
      // Remove old task
      final oldTask = tasks.removeAt(taskIndex);
      
      // Create updated task
      final updatedTask = {...oldTask, 'completed': completed};
      
      // Add updated task
      tasks.insert(taskIndex, updatedTask);
      
      // Update the event with the modified tasks list
      await _firestore.collection('events').doc(eventId).update({
        'tasks': tasks,
      });

      await fetchEvents(); // Refresh events list
      return true;
    } catch (e) {
      print('Error updating task status: $e');
      return false;
    }
  }

  Future<bool> addPhotoToEvent(String eventId, File image) async {
    try {
      final imageId = uuid.v4();
      final storageRef = _storage.ref().child('event_images/$imageId');
      await storageRef.putFile(image);
      final downloadUrl = await storageRef.getDownloadURL();

      await _firestore.collection('events').doc(eventId).update({
        'photoUrls': FieldValue.arrayUnion([downloadUrl]),
      });

      await fetchEvents(); // Refresh events list
      return true;
    } catch (e) {
      print('Error adding photo: $e');
      return false;
    }
  }
}