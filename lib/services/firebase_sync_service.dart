import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import 'storage_service.dart';

class FirebaseSyncService {
  static final FirebaseSyncService _instance = FirebaseSyncService._internal();
  factory FirebaseSyncService() => _instance;
  FirebaseSyncService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  bool get isSignedIn => _auth.currentUser != null;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign in with Google. Returns null if user cancelled.
  Future<User?> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    return userCredential.user;
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // --- Firestore paths ---

  DocumentReference _userDoc() =>
      _firestore.collection('users').doc(currentUser!.uid);

  CollectionReference _sessionsCol() => _userDoc().collection('sessions');
  CollectionReference _medsCol() => _userDoc().collection('meds');
  CollectionReference _settingsCol() => _userDoc().collection('settings');
  DocumentReference _metadataDoc() =>
      _userDoc().collection('metadata').doc('backup_info');

  // --- Backup ---

  /// Upload all local Hive data to Firestore.
  /// Returns the number of documents written.
  Future<int> backup() async {
    if (!isSignedIn) throw StateError('Not signed in');

    final storage = StorageService();
    int docCount = 0;

    // 1. Sessions
    final sessions = storage.getAllSessions();
    for (final chunk in _chunked(sessions, 400)) {
      final batch = _firestore.batch();
      for (final session in chunk) {
        batch.set(_sessionsCol().doc(session.id), session.toJson());
        docCount++;
      }
      await batch.commit();
    }

    // 2. Meds
    final meds = storage.getAllMeds();
    for (final chunk in _chunked(meds.entries.toList(), 400)) {
      final batch = _firestore.batch();
      for (final entry in chunk) {
        batch.set(_medsCol().doc(entry.key), entry.value.toJson());
        docCount++;
      }
      await batch.commit();
    }

    // 3. Settings
    final settings = storage.settings;
    await _settingsCol().doc('userSettings').set(settings.toJson());
    docCount++;

    // 4. Metadata
    await _metadataDoc().set({
      'lastBackupAt': FieldValue.serverTimestamp(),
      'sessionCount': sessions.length,
      'medCount': meds.length,
    });

    return docCount;
  }

  /// Get the last backup timestamp, or null if never backed up.
  Future<DateTime?> getLastBackupDate() async {
    if (!isSignedIn) return null;
    try {
      final snap = await _metadataDoc().get();
      if (!snap.exists) return null;
      final data = snap.data() as Map<String, dynamic>?;
      final ts = data?['lastBackupAt'] as Timestamp?;
      return ts?.toDate();
    } catch (e) {
      debugPrint('Error fetching backup metadata: $e');
      return null;
    }
  }

  // --- Restore ---

  /// Download all data from Firestore and overwrite local Hive boxes.
  /// Returns the number of documents restored.
  Future<int> restore() async {
    if (!isSignedIn) throw StateError('Not signed in');

    final storage = StorageService();
    int docCount = 0;

    // 1. Sessions
    final sessionsSnap = await _sessionsCol().get();
    await storage.clearAllSessions();
    for (final doc in sessionsSnap.docs) {
      final session =
          SessionRecord.fromJson(doc.data() as Map<String, dynamic>);
      await storage.putSession(session);
      docCount++;
    }

    // 2. Meds
    final medsSnap = await _medsCol().get();
    await storage.clearAllMeds();
    for (final doc in medsSnap.docs) {
      final med = MedRecord.fromJson(doc.data() as Map<String, dynamic>);
      await storage.putMed(doc.id, med);
      docCount++;
    }

    // 3. Settings
    final settingsSnap = await _settingsCol().doc('userSettings').get();
    if (settingsSnap.exists) {
      final settings =
          UserSettings.fromJson(settingsSnap.data() as Map<String, dynamic>);
      await storage.saveSettings(settings);
      docCount++;
    }

    return docCount;
  }

  // --- Helpers ---

  List<List<T>> _chunked<T>(List<T> list, int size) {
    final chunks = <List<T>>[];
    for (var i = 0; i < list.length; i += size) {
      chunks.add(list.sublist(i, (i + size).clamp(0, list.length)));
    }
    return chunks;
  }
}
