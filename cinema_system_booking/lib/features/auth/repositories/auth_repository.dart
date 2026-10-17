import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../../shared/models/app_user.dart';

class AuthRepository {
  FirebaseAuth? _auth;
  FirebaseFirestore? _firestore;

  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth,
        _firestore = firestore;

  FirebaseAuth get _authInstance {
    _auth ??= FirebaseAuth.instance;
    return _auth!;
  }

  FirebaseFirestore get _firestoreInstance {
    _firestore ??= FirebaseFirestore.instance;
    return _firestore!;
  }

  Stream<User?> get authStateChanges {
    try {
      return _authInstance.authStateChanges();
    } catch (_) {
      return const Stream.empty();
    }
  }

  User? get currentFirebaseUser {
    try {
      return _authInstance.currentUser;
    } catch (_) {
      return null;
    }
  }

  Future<AppUser?> getUserProfile(String uid) async {
    try {
      final doc = await _firestoreInstance.collection('users').doc(uid).get();
      if (!doc.exists) return null;
      return AppUser.fromFirestore(doc);
    } catch (_) {
      return null;
    }
  }

  Stream<AppUser?> userProfileStream(String uid) {
    try {
      return _firestoreInstance
          .collection('users')
          .doc(uid)
          .snapshots()
          .map((doc) {
        if (!doc.exists) return null;
        return AppUser.fromFirestore(doc);
      });
    } catch (_) {
      return const Stream.empty();
    }
  }

  Future<AppUser> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final cred = await _authInstance.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final uid = cred.user!.uid;
    final profile = await getUserProfile(uid);

    if (profile == null) {
      await _authInstance.signOut();
      throw StateError('Không tìm thấy dữ liệu người dùng trên hệ thống');
    }

    if (profile.isLocked) {
      await _authInstance.signOut();
      throw StateError('Tài khoản đã bị khóa');
    }

    return profile;
  }

  Future<AppUser> registerCustomer({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    final cred = await _authInstance.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final uid = cred.user!.uid;
    final newUser = AppUser(
      uid: uid,
      fullName: fullName.trim(),
      email: email.trim(),
      phone: phone.trim(),
      role: UserRole.customer,
      cinemaId: null,
      isLocked: false,
      createdAt: DateTime.now(),
    );

    await _firestoreInstance
        .collection('users')
        .doc(uid)
        .set(newUser.toFirestore());
    return newUser;
  }

  /// Kỹ thuật khởi tạo người dùng nội bộ (Staff/Manager) bằng FirebaseApp phụ
  /// để tránh làm đăng xuất tài khoản quản trị hiện tại (DATA.md mục 6.4)
  Future<String> createSecondaryUser({
    required String email,
    required String password,
  }) async {
    final app = await Firebase.initializeApp(
      name: 'secondary-${DateTime.now().millisecondsSinceEpoch}',
      options: Firebase.app().options,
    );
    try {
      final secondaryAuth = FirebaseAuth.instanceFor(app: app);
      final cred = await secondaryAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return cred.user!.uid;
    } finally {
      await FirebaseAuth.instanceFor(app: app).signOut();
      await app.delete();
    }
  }

  Future<void> updateProfile({
    required String uid,
    required String fullName,
    required String phone,
  }) async {
    await _firestoreInstance.collection('users').doc(uid).update({
      'fullName': fullName.trim(),
      'phone': phone.trim(),
    });
  }

  Future<void> signOut() async {
    try {
      await _authInstance.signOut();
    } catch (_) {}
  }
}
