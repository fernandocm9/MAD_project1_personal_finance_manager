import 'package:flutter/material.dart';
import 'finance_db.dart';
import 'package:fl_chart/fl_chart.dart';

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
            title: Center(child: Text('CashFlow')),
            backgroundColor: const Color.fromARGB(255, 112, 188, 250),
            bottom: TabBar(
              tabs: [
                Tab(text: 'Logs'),
                Tab(text: 'Graphs'),
              ],
              labelColor: Colors.black,
              unselectedLabelColor: const Color.fromARGB(255, 86, 86, 86),
              indicator: BoxDecoration(
                color: const Color.fromARGB(255, 112, 188, 250),
                border: Border(top: BorderSide(color: Colors.black), left: BorderSide(color: Colors.black), right: BorderSide(color: Colors.black), bottom: BorderSide(color: Colors.orange, width: 5)),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
            ),
          ),
          body: const TabBarView(
            children: [
              LogsPage(title: 'Logs'),
              GraphsPage(),
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
  late TextEditingController amountController;

  List<String> _categories = ['Paycheck', 'Refund', 'Dividends', 'Rent', 'Food', 'Entertainment', 'Bill'];
  String _selectedCategory = 'Paycheck';
  double total = 0;
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

  double _calculateTotal(List<Map<String, dynamic>> transactions) {
    double sum = 0;
    for (var transaction in transactions) {
      double amount = transaction['amount'];
      sum += amount;
    }
    return sum;
  }


  void _addTransaction() async {
    String name = nameController.text.trim();
    String category = _selectedCategory;
    double amount = double.tryParse(amountController.text) ?? 0;

    if (name.isEmpty || category.isEmpty || amount <= 0) return;

    if(category == 'Rent' || category == 'Food' || category == 'Entertainment' || category == 'Bill') {
      amount = -amount;
  }

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

void _updateRow(int id, String name, String category, double amount) async {
  Map<String, dynamic> row = {
    DatabaseHelper.columnId: id,
    DatabaseHelper.columnName: name,
    DatabaseHelper.columnCategory: category,
    DatabaseHelper.columnAmount: amount,
  };
  final rowsAffected = await dbHelper.update(row);
  nameController.clear();
  amountController.clear();

  print('Updated $rowsAffected row(s)');
  _fetchTransactions();
  }

  void _deleteRow(int id) async {
    final rowsDeleted = await dbHelper.delete(id);
    print('Deleted $rowsDeleted row(s): row $id');

    _fetchTransactions();
  }

  void _openEditTransactionDialog(Map<String, dynamic> transaction) {
    nameController.text = transaction['name'];
    amountController.text = transaction['amount'].abs().toString();
    _selectedCategory = transaction['category'];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Transaction'),
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
              child: const Text('Update'),
              onPressed: () {
                int id = transaction['_id'];
                String name = nameController.text.trim();
                String category = _selectedCategory;
                double amount = double.tryParse(amountController.text) ?? 0;

                if (category == 'Rent' || category == 'Food' || category == 'Entertainment' || category == 'Bill') {
                  amount = -amount;
                }

                _updateRow(id, name, category, amount);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }


  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Transaction'),
          content: const Text('Are you sure you want to delete this transaction?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () {
                _deleteRow(id);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(total < 0
              ? 'Total: -\$${(-total).toStringAsFixed(2)}'
              : 'Total: \$${total.toStringAsFixed(2)}'),
        ),
      ),
      body: ListView.builder(
        itemCount: transactions.length,
        itemBuilder: (context, index) {
          final transaction = transactions[index];
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: ListTile(
              title: Text(transaction['name']),
              subtitle: Text(transaction['category']),
              onLongPress: () {
                _confirmDelete(transaction['_id']);
              },
              onTap: () {
                _openEditTransactionDialog(transaction);
              },
              trailing: Text(
                '\$${transaction['amount'].toStringAsFixed(2)}',
                style: TextStyle(fontSize: 15),
              ),
              tileColor: transaction['amount'] < 0 ? Colors.red : Colors.green,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Colors.black, width: 1),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddTransactionDialog,
        tooltip: 'Add Transaction',
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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


// ==========================
// GRAPHS PAGE
// ==========================
class GraphsPage extends StatefulWidget {
  const GraphsPage({super.key});

  @override
  _GraphsPageState createState() => _GraphsPageState();
}

class _GraphsPageState extends State<GraphsPage> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> transactions = [];
  double totalBalance = 0;
  double goal = 100;

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    final data = await dbHelper.queryAllRows();
    setState(() {
      transactions = data;
      totalBalance = transactions.fold<double>(
        0, (sum, item) => sum + (item['amount'] as num).toDouble(),
      );
    });
  }

  void _editGoal() {
    TextEditingController goalController = TextEditingController(text: goal.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Goal"),
          content: TextField(
            controller: goalController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "Set New Goal"),
          ),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: const Text("Save"),
              onPressed: () {
                setState(() {
                  goal = double.tryParse(goalController.text) ?? goal;
                });
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  List<Color> incomeColors = [
    Colors.lightGreen,
    Colors.green,
    Color(0xFF006400), // ✅ this is dark green
    Colors.teal,
  ];

  List<Color> expenseColors = [
    Colors.redAccent,
    Colors.red,
    Colors.deepOrange,
    Colors.pink,
  ];

  List<PieChartSectionData> _generateChartData(String type) {
    Map<String, double> categoryTotals = {};

    for (var transaction in transactions) {
      if ((type == 'income' && transaction['amount'] > 0) ||
          (type == 'expense' && transaction['amount'] < 0)) {
        categoryTotals[transaction['category']] =
            (categoryTotals[transaction['category']] ?? 0) + transaction['amount'].abs();
      }
    }

    if (categoryTotals.isEmpty) {
      return [
        PieChartSectionData(
          value: 1,
          title: "No Data",
          color: Colors.grey,
          titleStyle: const TextStyle(color: Colors.white),
        )
      ];
    }

    int index = 0;
    return categoryTotals.entries.map((entry) {
      Color color = type == 'income'
          ? incomeColors[index % incomeColors.length]
          : expenseColors[index % expenseColors.length];
      index++;

      return PieChartSectionData(
        value: entry.value,
        title:
            "${entry.key}\n${((entry.value / totalBalance) * 100).toStringAsFixed(1)}%",
        color: color,
        radius: 60,
        titleStyle: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Graphs')),
      body: Column(
        children: [
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Set Goal: \$${goal.toStringAsFixed(0)}",
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 15),
              Text(
                "Remaining: \$${(goal - totalBalance).toStringAsFixed(2)}",
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _editGoal,
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[700]),
                child: const Text("Edit Goal",
                    style: TextStyle(color: Colors.white)),
              )
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: transactions.isEmpty
                ? const Center(child: Text("No transactions available"))
                : Column(
                    children: [
                      const Text("Income",
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      SizedBox(
                        height: 200,
                        child: PieChart(
                          PieChartData(
                            sections: _generateChartData('income'),
                            centerSpaceRadius: 40,
                            sectionsSpace: 2,
                            borderData: FlBorderData(show: false),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text("Expenses",
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      SizedBox(
                        height: 200,
                        child: PieChart(
                          PieChartData(
                            sections: _generateChartData('expense'),
                            centerSpaceRadius: 40,
                            sectionsSpace: 2,
                            borderData: FlBorderData(show: false),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}