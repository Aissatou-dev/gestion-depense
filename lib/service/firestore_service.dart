import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// ----- expenses -----
  CollectionReference get _expenses => _db.collection('expenses');

  Future<DocumentReference> addExpense(Map<String, dynamic> data) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return _expenses.add({
      ...data,
      'userId': uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> userExpenses() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return _expenses.where('userId', isEqualTo: uid).orderBy('createdAt', descending: true).snapshots();
  }

  Future<void> updateExpense(String id, Map<String, dynamic> data) {
    return _expenses.doc(id).update(data);
  }

  Future<void> deleteExpense(String id) {
    return _expenses.doc(id).delete();
  }

  /// ----- incomes -----
  CollectionReference get _incomes => _db.collection('incomes');

  Future<DocumentReference> addIncome(Map<String, dynamic> data) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return _incomes.add({
      ...data,
      'userId': uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> userIncomes() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return _incomes.where('userId', isEqualTo: uid).orderBy('createdAt', descending: true).snapshots();
  }

  Future<void> updateIncome(String id, Map<String, dynamic> data) {
    return _incomes.doc(id).update(data);
  }

  Future<void> deleteIncome(String id) {
    return _incomes.doc(id).delete();
  }

  /// ----- categories -----
  CollectionReference get _categories => _db.collection('categories');

  Stream<QuerySnapshot> categories() {
    return _categories.orderBy('name').snapshots();
  }

  Future<void> addCategory(Map<String, dynamic> data) {
    return _categories.add({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateCategory(String id, Map<String, dynamic> data) {
    return _categories.doc(id).update(data);
  }

  Future<void> deleteCategory(String id) {
    return _categories.doc(id).delete();
  }

  /// ----- aggregates -----
  Future<double> totalExpenses() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    var snap = await _expenses.where('userId', isEqualTo: uid).get();
    double sum = 0;
    for (var doc in snap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      sum += (data['amount'] ?? 0) as num;
    }
    return sum;
  }

  Future<double> totalIncomes() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    var snap = await _incomes.where('userId', isEqualTo: uid).get();
    double sum = 0;
    for (var doc in snap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      sum += (data['amount'] ?? 0) as num;
    }
    return sum;
  }
}
