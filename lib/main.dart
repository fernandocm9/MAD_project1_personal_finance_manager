import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
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
            backgroundColor: const Color.fromARGB(255, 112, 188, 250),
            bottom: TabBar(
              tabs: const [
                Tab(text: 'Logs'),
                Tab(text: 'Graphs'),
              ],
              labelColor: Colors.black,
              unselectedLabelColor: const Color.fromARGB(255, 86, 86, 86),
              indicator: const BoxDecoration(
                color: Color.fromARGB(255, 112, 188, 250),
                border: Border(
                  top: BorderSide(color: Colors.black),
                  left: BorderSide(color: Colors.black),
                  right: BorderSide(color: Colors.black),
                  bottom: BorderSide(color: Colors.orange, width: 5),
                ),
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

// ==========================
// LOGS PAGE
// ==========================
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
  List<Map<String, dynamic>> transactions = [];
  String _selectedCategory = 'Paycheck';
  double total = 0;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    amountController = TextEditingController();
    _fetchTransactions();
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
      total = transactions.fold(0, (sum, item) => sum + (item['amount'] as num).toDouble());
    });
  }

  void _addTransaction() async {
    String name = nameController.text.trim();
    double amount = double.tryParse(amountController.text) ?? 0;

    if (name.isEmpty || amount == 0) return;
    if (['Rent', 'Food', 'Entertainment', 'Bill'].contains(_selectedCategory)) {
      amount = -amount;
    }

    await dbHelper.insert({'name': name, 'category': _selectedCategory, 'amount': amount});
    _fetchTransactions();
    nameController.clear();
    amountController.clear();
  }

  void _deleteTransaction(int id) async {
    await dbHelper.delete(id);
    _fetchTransactions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Center(child: Text("Total: \$${total.toStringAsFixed(2)}"))),
      body: ListView.builder(
        itemCount: transactions.length,
        itemBuilder: (context, index) {
          final transaction = transactions[index];
          return ListTile(
            title: Text(transaction['name']),
            subtitle: Text(transaction['category']),
            trailing: Text(
              '\$${transaction['amount'].toStringAsFixed(2)}',
              style: TextStyle(fontSize: 15, color: transaction['amount'] < 0 ? Colors.red : Colors.green),
            ),
            tileColor: transaction['amount'] < 0 ? Colors.red[100] : Colors.green[100],
            onLongPress: () => _deleteTransaction(transaction['_id']),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTransaction,
        tooltip: 'Add Transaction',
        child: const Icon(Icons.add),
      ),
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
    print("Transactions fetched: ${transactions.length}");
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
      return [PieChartSectionData(value: 1, title: "No Data", color: Colors.grey)];
    }

    return categoryTotals.entries.map((entry) {
      return PieChartSectionData(
        value: entry.value,
        title: "${entry.key}\n${((entry.value / totalBalance) * 100).toStringAsFixed(1)}%",
        color: type == 'income' ? Colors.lightGreenAccent : Colors.redAccent,
        radius: 50,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black),
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
                "Goal: ${goal.toInt()}",
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _editGoal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                ),
                child: const Text("Edit Goal", style: TextStyle(fontSize: 14, color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: transactions.isEmpty
                ? const Center(child: Text("No transactions available"))
                : Column(
                    children: [
                      const Text("Income", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
                      const Text("Expenses", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
