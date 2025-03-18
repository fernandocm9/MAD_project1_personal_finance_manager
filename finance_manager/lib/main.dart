import 'package:flutter/material.dart';
import 'finance_db.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Personal Finance Manager',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: const Center(child: Text('CashFlow')),
            bottom: const TabBar(
              tabs: [
                Tab(text: 'Logs'),
                Tab(text: 'Graphs'),
              ],
            ),
          ),
          body: const TabBarView(
            children: [
              LogsPage(title: 'Logs'),
              GraphsPage(title: 'Graphs'),
            ],
          ),
        ),
      ),
    );
  }
}

class LogsPage extends StatefulWidget {
  const LogsPage({super.key, required this.title});
  final String title;

  @override
  State<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends State<LogsPage> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  late TextEditingController nameController;
  late TextEditingController categoryController;
  late TextEditingController amountController;

  List<String> _categories = ['Paycheck', 'Refund', 'Dividends', 'Rent', 'Food', 'Entertainment', 'Bill'];
  String _selectedCategory = 'Paycheck';
  int total = 0;
  List<Map<String, dynamic>> transactions = [];

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    amountController = TextEditingController();
    
    _fetchTransactions(); // Load transactions from DB
  }

  @override
  void dispose() {
    nameController.dispose();
    categoryController.dispose();
    amountController.dispose();
    super.dispose();
  }

  void _fetchTransactions() async {
  final data = await dbHelper.queryAllRows();
  
  setState(() {
    transactions = data;
    total = _calculateTotal(data);
  });
}

  int _calculateTotal(List<Map<String, dynamic>> transactions) {
    int sum = 0;
    for (var transaction in transactions) {
      int amount = transaction['amount'];
      if (transaction['category'] == 'Paycheck' ||
          transaction['category'] == 'Refund' ||
          transaction['category'] == 'Dividends') {
        sum += amount;
      } else {
        sum -= amount;
      }
    }
    return sum;
  }


  void _addTransaction() async {
  String name = nameController.text.trim();
  String category = _selectedCategory;
  int amount = int.tryParse(amountController.text) ?? 0;

  if (name.isEmpty || category.isEmpty || amount <= 0) return;

  // Insert into SQLite database
  Map<String, dynamic> row = {
    'name': name,
    'category': category,
    'amount': amount,
  };

  await dbHelper.insert(row);

  // Refresh transaction list from database
  _fetchTransactions();

  // Clear text fields after adding
  nameController.clear();
  amountController.clear();
}


  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppBar(
          title: Center(child: Text('Total: $total')),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final transaction = transactions[index];
              return ListTile(
                title: Text(transaction['name']),
                subtitle: Text(transaction['category']),
                trailing: Text('\$${transaction['amount']}'),
              );
            },
          ),
        ),
        FloatingActionButton(
          onPressed: _openAddTransactionDialog,
          tooltip: 'Add Transaction',
          child: const Icon(Icons.add),
        ),
      ],
    );
  }

  Future<void> _openAddTransactionDialog() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Transaction'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: _categories.map((category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedCategory = newValue;
                      });
                    }
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(labelText: 'Amount'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () {
                _addTransaction();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}


class GraphsPage extends StatelessWidget {
  const GraphsPage({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Graphs Placeholder',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
    );
  }
}
