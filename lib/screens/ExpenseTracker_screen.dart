import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/gemini_http_service.dart';
import '../utils/expense_service.dart';

class ExpenseTrackerScreen extends StatefulWidget {
  const ExpenseTrackerScreen({super.key});

  @override
  State<ExpenseTrackerScreen> createState() => _ExpenseTrackerScreenState();
}

class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;

  const GradientButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isLoading
              ? [Colors.grey[400]!, Colors.grey[600]!]
              : [Colors.orange[300]!, Colors.orange[800]!],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: isLoading
            ? const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Processing',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              )
            : Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}

class _ExpenseTrackerScreenState extends State<ExpenseTrackerScreen> {
  final TextEditingController _salaryController = TextEditingController();
  final TextEditingController _expenseAmountController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final GeminiHttpService _aiService = GeminiHttpService();
  final ExpenseService _expenseService = ExpenseService();

  final List<String> _years = List.generate(10, (index) => (DateTime.now().year - index).toString());
  double? _scannedAmount;
  String? _scannedCategory;
  bool _showScannedDetails = false;
  String _selectedCategory = 'Food';
  bool _isLoading = false;
  String _selectedMonth = _months[DateTime.now().month - 1];
  String _selectedYear = DateTime.now().year.toString();
  double _totalSalary = 0.0;
  double _totalExpenses = 0.0;
  double _balance = 0.0;
  String _comparisonYear = (DateTime.now().year - 1).toString();
  bool _showYearComparison = false;
  
  Map<String, double> _yearlyTotals = {};
  Map<String, double> _yearlyExpenses = {};
  Map<String, double> _yearlySavings = {};
  
  final List<Map<String, dynamic>> _expenses = [];
  final List<String> _categories = [
    'Food', 'Travel', 'Entertainment', 'Other', 'shopping', 'rent', 'bill', 'grocery', 'fuel'
  ];
  static const List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  @override
  void initState() {
    super.initState();
    _loadDataFromFirestore();
  }

  @override
  void dispose() {
    _salaryController.dispose();
    _expenseAmountController.dispose();
    super.dispose();
  }

  Future<void> _scanBill() async {
    final XFile? imageFile = await _imagePicker.pickImage(source: ImageSource.camera);

    if (imageFile != null) {
      setState(() => _isLoading = true);
      try {
        final result = await _aiService.processImage(imageFile.path);
        if (result != null) {
          setState(() {
            _scannedAmount = result['amount'];
            _scannedCategory = result['category'] ?? _selectedCategory;
            _showScannedDetails = true;
          });
        } else {
          _showError('Could not detect amount from the bill.');
        }
      } catch (e) {
        _showError('Error processing image: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _loadDataFromFirestore() async {
    final doc = await _expenseService.getMonthData(_selectedMonth, _selectedYear);
    if (doc != null && doc.exists) {
      setState(() {
        _totalSalary = (doc['totalSalary'] as num?)?.toDouble() ?? 0.0;
        _totalExpenses = (doc['totalExpenses'] as num?)?.toDouble() ?? 0.0;
        _balance = (doc['balance'] as num?)?.toDouble() ?? 0.0;
        _expenses.removeWhere((e) => e['month'] == _selectedMonth && e['year'] == _selectedYear);
        if (doc['expenses'] is List) {
          for (var value in doc['expenses']) {
            _expenses.add(Map<String, dynamic>.from(value));
          }
        }
      });
    } else {
      setState(() {
        _totalSalary = 0.0;
        _totalExpenses = 0.0;
        _balance = 0.0;
        _expenses.removeWhere((e) => e['month'] == _selectedMonth && e['year'] == _selectedYear);
      });
    }
    _recalculateTotals();
  }

  void _recalculateTotals() {
    final filtered = _getFilteredExpenses();
    setState(() {
      _totalExpenses = filtered.fold(0.0, (sum, e) => sum + (e['amount'] as num).toDouble());
      _balance = _totalSalary - _totalExpenses;
    });
  }

  List<Map<String, dynamic>> _getFilteredExpenses() {
    return _expenses.where((e) => e['month'] == _selectedMonth && e['year'] == _selectedYear).toList();
  }

  void _addExpense() {
    final amount = double.tryParse(_expenseAmountController.text);
    if (amount != null && amount > 0) {
      if (amount > _balance) {
        _showError('Expense amount exceeds balance!');
      } else {
        setState(() {
          _expenses.add({
            'category': _selectedCategory,
            'amount': amount,
            'date': DateTime.now().toString(),
            'month': _selectedMonth,
            'year': _selectedYear,
          });
          _recalculateTotals();
        });
        _expenseAmountController.clear();
        _expenseService.saveExpenses(_selectedMonth, _selectedYear, _expenses, _totalExpenses, _balance);
      }
    }
  }

  void _deleteExpense(int index) {
    final filtered = _getFilteredExpenses();
    setState(() {
      _expenses.remove(filtered[index]);
      _recalculateTotals();
    });
    _expenseService.saveExpenses(_selectedMonth, _selectedYear, _expenses, _totalExpenses, _balance);
  }

  void _setSalary() {
    setState(() {
      _totalSalary = double.tryParse(_salaryController.text) ?? 0.0;
      _recalculateTotals();
    });
    _expenseService.saveSalary(_selectedMonth, _selectedYear, _totalSalary, _balance);
  }

  Future<void> _loadYearlyData() async {
    setState(() {
      _yearlyTotals.clear();
      _yearlyExpenses.clear();
      _yearlySavings.clear();
    });

    for (String year in _years) {
      double yearSalary = 0.0;
      double yearExpenses = 0.0;
      for (String month in _months) {
        final doc = await _expenseService.getMonthData(month, year);
        if (doc != null && doc.exists) {
          yearSalary += (doc['totalSalary'] as num?)?.toDouble() ?? 0.0;
          yearExpenses += (doc['totalExpenses'] as num?)?.toDouble() ?? 0.0;
        }
      }
      setState(() {
        _yearlyTotals[year] = yearSalary;
        _yearlyExpenses[year] = yearExpenses;
        _yearlySavings[year] = yearSalary - yearExpenses;
      });
    }
  }

  void _navigateMonth(bool isNext) {
    final currentIndex = _months.indexOf(_selectedMonth);
    int newIndex = isNext ? (currentIndex + 1) % 12 : (currentIndex - 1 + 12) % 12;
    setState(() {
      _selectedMonth = _months[newIndex];
      _loadDataFromFirestore();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildMonthNavigation(),
            _buildExpenseBreakdown(),
            const SizedBox(height: 20),
            GradientButton(
              text: _showYearComparison ? 'Hide Year Comparison' : 'Compare Years',
              onPressed: () {
                setState(() => _showYearComparison = !_showYearComparison);
                if (_showYearComparison) _loadYearlyData();
              },
            ),
            if (_showYearComparison) _buildYearlyComparison(),
            const SizedBox(height: 20),
            _buildSalaryBalanceSummary(),
            const SizedBox(height: 20),
            GradientButton(text: 'Set Salary', onPressed: () => _showSalaryDialog(context)),
            const SizedBox(height: 20),
            _buildAddExpenseSection(),
            const SizedBox(height: 20),
            if (_showScannedDetails) _buildScannedDetails(),
            _buildExpenseList(),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthNavigation() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(icon: const Icon(Icons.arrow_back_ios), onPressed: () => _navigateMonth(false)),
            Column(
              children: [
                Text(_selectedMonth, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange)),
                DropdownButton<String>(
                  value: _selectedYear,
                  underline: const SizedBox(),
                  onChanged: (val) {
                    setState(() {
                      _selectedYear = val!;
                      _showYearComparison = false;
                    });
                    _loadDataFromFirestore();
                  },
                  items: _years.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                ),
              ],
            ),
            IconButton(icon: const Icon(Icons.arrow_forward_ios), onPressed: () => _navigateMonth(true)),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseBreakdown() {
    final sections = _getFilteredExpenses().fold<Map<String, double>>({}, (map, e) {
      map[e['category']] = (map[e['category']] ?? 0) + (e['amount'] as num).toDouble();
      return map;
    }).entries.map((entry) {
      return PieChartSectionData(
        value: entry.value,
        color: _getColorForCategory(entry.key),
        title: entry.key,
        radius: 40,
        showTitle: entry.value > 10,
      );
    }).toList();

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('Expense Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            SizedBox(height: 200, child: PieChart(PieChartData(sections: sections, centerSpaceRadius: 40))),
          ],
        ),
      ),
    );
  }

  Widget _buildYearlyComparison() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Yearly Comparison', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                DropdownButton<String>(
                  value: _comparisonYear,
                  onChanged: (val) => setState(() => _comparisonYear = val!),
                  items: _years.where((y) => y != _selectedYear).map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                ),
              ],
            ),
            const SizedBox(height: 15),
            SizedBox(height: 250, child: BarChart(BarChartData(barGroups: _createYearComparisonData()))),
          ],
        ),
      ),
    );
  }

  List<BarChartGroupData> _createYearComparisonData() {
    List<BarChartGroupData> groups = [];
    void addGroup(String year, int xOffset, Color color, double value) {
       groups.add(BarChartGroupData(x: xOffset, barRods: [BarChartRodData(toY: value, color: color, width: 15)]));
    }
    if (_yearlyTotals.containsKey(_selectedYear)) {
      addGroup(_selectedYear, 0, Colors.blue, _yearlyTotals[_selectedYear]!);
      addGroup(_selectedYear, 2, Colors.red, _yearlyExpenses[_selectedYear]!);
      addGroup(_selectedYear, 4, Colors.green, _yearlySavings[_selectedYear]!);
    }
    if (_yearlyTotals.containsKey(_comparisonYear)) {
      addGroup(_comparisonYear, 1, Colors.blueGrey, _yearlyTotals[_comparisonYear]!);
      addGroup(_comparisonYear, 3, Colors.redAccent, _yearlyExpenses[_comparisonYear]!);
      addGroup(_comparisonYear, 5, Colors.lightGreen, _yearlySavings[_comparisonYear]!);
    }
    return groups;
  }

  Widget _buildSalaryBalanceSummary() {
    return Row(
      children: [
        Expanded(child: _buildSummaryCard('Total Salary', '$_totalSalary')),
        const SizedBox(width: 10),
        Expanded(child: _buildSummaryCard('Balance', '$_balance')),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontSize: 16, color: Colors.orange)),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange[100])),
          ],
        ),
      ),
    );
  }

  Widget _buildAddExpenseSection() {
    return Column(
      children: [
        TextField(
          controller: _expenseAmountController,
          decoration: const InputDecoration(labelText: 'Amount', border: OutlineInputBorder()),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: _selectedCategory,
          decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
          onChanged: (val) => setState(() => _selectedCategory = val!),
          items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: GradientButton(text: 'Add Expense', onPressed: _addExpense)),
            const SizedBox(width: 10),
            Expanded(child: GradientButton(text: 'Scan Bill', onPressed: _scanBill, isLoading: _isLoading)),
          ],
        ),
      ],
    );
  }

  Widget _buildScannedDetails() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('Scanned Details', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Amount: $_scannedAmount'),
            DropdownButtonFormField<String>(
              value: _scannedCategory,
              onChanged: (val) => setState(() => _scannedCategory = val),
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            ),
            Row(
              children: [
                Expanded(child: ElevatedButton(onPressed: () {
                  setState(() {
                    _expenseAmountController.text = _scannedAmount.toString();
                    _selectedCategory = _scannedCategory!;
                    _showScannedDetails = false;
                  });
                }, child: const Text('Confirm'))),
                const SizedBox(width: 10),
                Expanded(child: ElevatedButton(onPressed: () => setState(() => _showScannedDetails = false), child: const Text('Cancel'))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseList() {
    final filtered = _getFilteredExpenses();
    return Card(
      child: Column(
        children: [
          const Padding(padding: EdgeInsets.all(8.0), child: Text('Expenses', style: TextStyle(fontWeight: FontWeight.bold))),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final e = filtered[index];
              return ListTile(
                title: Text(e['category']),
                subtitle: Text('Rs ${e['amount']}'),
                trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteExpense(index)),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showSalaryDialog(BuildContext context) {
    final ctrl = TextEditingController(text: _salaryController.text);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Salary'),
        content: TextField(controller: ctrl, keyboardType: TextInputType.number),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () {
            _salaryController.text = ctrl.text;
            _setSalary();
            Navigator.pop(ctx);
          }, child: const Text('Set')),
        ],
      ),
    );
  }

  Color _getColorForCategory(String category) {
    switch (category) {
      case 'Food': return Colors.orange[300]!;
      case 'Travel': return Colors.orange[400]!;
      case 'Entertainment': return Colors.orange[500]!;
      case 'Other': return Colors.orange[600]!;
      case 'shopping': return Colors.orange[700]!;
      case 'rent': return Colors.orange[800]!;
      case 'bill': return Colors.orange[900]!;
      case 'grocery': return Colors.deepOrange[300]!;
      case 'fuel': return Colors.deepOrange[400]!;
      default: return Colors.grey;
    }
  }
}
