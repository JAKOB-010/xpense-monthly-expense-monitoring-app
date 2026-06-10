import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ExpenseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _userId => _auth.currentUser?.uid ?? '';

  Future<void> saveSalary(String month, String year, double salary, double balance) async {
    if (_userId.isEmpty) return;
    await _firestore.collection('expenses').doc('$_userId-$month-$year').set({
      'totalSalary': salary,
      'balance': balance,
      'month': month,
      'year': year,
    }, SetOptions(merge: true));
  }

  Future<void> saveExpenses(String month, String year, List<Map<String, dynamic>> expenses, double totalExpenses, double balance) async {
    if (_userId.isEmpty) return;
    await _firestore.collection('expenses').doc('$_userId-$month-$year').set({
      'expenses': expenses,
      'totalExpenses': totalExpenses,
      'balance': balance,
      'month': month,
      'year': year,
    }, SetOptions(merge: true));
  }

  Future<DocumentSnapshot?> getMonthData(String month, String year) async {
    if (_userId.isEmpty) return null;
    return await _firestore.collection('expenses').doc('$_userId-$month-$year').get();
  }
}
