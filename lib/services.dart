import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static final _auth = FirebaseAuth.instance;
  static final _db = FirebaseFirestore.instance;

  static User? get currentUser => _auth.currentUser;

  static Future<UserCredential> signIn(String email, String password) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  static Future<UserCredential> signUp({
    required String name,
    required String phone,
    required String email,
    required String password,
    required String address,
    required String packageName,
    required int packagePrice,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _db.collection('users').doc(cred.user!.uid).set({
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'package': packageName,
      'packagePrice': packagePrice,
      'status': 'active',
      'dueAmount': packagePrice,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return cred;
  }

  static Future<void> signOut() => _auth.signOut();

  static Future<Map<String, dynamic>?> getUserData() async {
    final user = currentUser;
    if (user == null) return null;
    final doc = await _db.collection('users').doc(user.uid).get();
    return doc.data();
  }

  static Future<void> submitPayment({
    required String trxId,
    required int amount,
    required String method,
  }) async {
    final user = currentUser;
    if (user == null) return;
    await _db.collection('payments').add({
      'userId': user.uid,
      'trxId': trxId,
      'amount': amount,
      'method': method,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Stream<QuerySnapshot> myPayments() {
    final user = currentUser;
    return _db
        .collection('payments')
        .where('userId', isEqualTo: user?.uid ?? '')
        .snapshots();
  }

  static Stream<QuerySnapshot> notices() {
    return _db.collection('notices').snapshots();
  }
}

class AppInfo {
  static const String appName = 'JAJ Net';
  static const String tagline = 'তৈরি হোক নিরবিচ্ছিন্ন সম্পর্ক';
  static const String bkashNumber = '01639482397';
  static const String helpline = '01639482397';
  static const String whatsapp = '8801639482397';
  static const String mapSearch = 'Jibon IT Support';
  static const List<String> areas = [
    'পদহারবাইদ',
    'হারবাইদ',
    'পুবাইল',
    'গাজীপুর সদর',
    'গাজীপুর',
  ];
  static const List<Map<String, dynamic>> packages = [
  {'name': 'Starter', 'speed': '20 Mbps', 'price': 525},
  {'name': 'Basic', 'speed': '30 Mbps', 'price': 650},
  {'name': 'Elite', 'speed': '40 Mbps', 'price': 750},
  {'name': 'Premium', 'speed': '50 Mbps', 'price': 850},
];

  static Stream<QuerySnapshot> get packagesStream {
    return FirebaseFirestore.instance
        .collection('packages')
        .where('isActive', isEqualTo: true)
        .orderBy('order')
        .snapshots();
  }

  static Future<List<Map<String, dynamic>>> fetchPackages() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('packages')
          .where('isActive', isEqualTo: true)
          .get();
      final list = snap.docs.map((d) {
        final m = d.data();
        return <String, dynamic>{
          'id': d.id,
          'name': (m['name'] ?? '').toString(),
          'price': (m['price'] ?? 0) as int,
          'order': (m['order'] ?? 0) as int,
        };
      }).toList();
      list.sort((a, b) => (a['order'] as int).compareTo(b['order'] as int));
      return list;
    } catch (e) {
      return [];
    }
  }

}
