import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/trip_model.dart';
import '../../models/expense_model.dart';
import '../../services/firestore_service.dart';
import '../../services/firebase_auth_service.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/custom_button.dart';
import 'add_expense_screen.dart';

class ExpenseTrackerScreen extends StatefulWidget {
  final Trip trip;

  const ExpenseTrackerScreen({
    super.key,
    required this.trip,
  });

  @override
  State<ExpenseTrackerScreen> createState() => _ExpenseTrackerScreenState();
}

class _ExpenseTrackerScreenState extends State<ExpenseTrackerScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuthService _authService = FirebaseAuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Expenses: ${widget.trip.title}'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => _showExpenseAnalytics(context),
            icon: const Icon(Icons.analytics),
            tooltip: 'Analytics',
          ),
        ],
      ),
      body: StreamBuilder<List<Expense>>(
        stream: _firestoreService.getExpenses(widget.trip.id!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: LoadingIndicator(message: 'Loading expenses...'),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading expenses',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final expenses = snapshot.data ?? [];

          return Column(
            children: [
              // Summary Card
              _buildSummaryCard(expenses),
              
              // Expense List
              Expanded(
                child: _buildExpenseList(expenses),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addExpense,
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
      ),
    );
  }

  /// Builds the summary card showing total spent and cost per person
  Widget _buildSummaryCard(List<Expense> expenses) {
    final totalSpent = ExpenseAnalytics.calculateTotal(expenses);
    final numParticipants = (widget.trip.collaboratorIds?.length ?? 0) + 1; // owner + collaborators
    final costPerPerson = ExpenseAnalytics.calculateCostPerPerson(expenses, numParticipants);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Trip Summary',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (expenses.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.receipt_long,
                      size: 48,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No expenses logged yet',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap the + button to add your first expense',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: [
                  _buildSummaryRow(
                    'Total Spent',
                    '₹${totalSpent.toStringAsFixed(2)}',
                    Icons.account_balance_wallet,
                    Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 8),
                  _buildSummaryRow(
                    'Participants',
                    '$numParticipants',
                    Icons.people,
                    Theme.of(context).colorScheme.secondary,
                  ),
                  const SizedBox(height: 8),
                  _buildSummaryRow(
                    'Cost Per Person',
                    '₹${costPerPerson.toStringAsFixed(2)}',
                    Icons.person,
                    Theme.of(context).colorScheme.tertiary,
                  ),
                  const SizedBox(height: 12),
                  
                  // Quick category breakdown
                  if (expenses.isNotEmpty) _buildQuickCategoryBreakdown(expenses),
                ],
              ),
          ],
        ),
      ),
    );
  }

  /// Builds a summary row with icon, label, and value
  Widget _buildSummaryRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  /// Builds a quick breakdown of expenses by category
  Widget _buildQuickCategoryBreakdown(List<Expense> expenses) {
    final categoryTotals = ExpenseAnalytics.calculateByCategory(expenses);
    final nonZeroCategories = categoryTotals.entries
        .where((entry) => entry.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (nonZeroCategories.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top Categories',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: nonZeroCategories.take(3).map((entry) {
            final category = entry.key;
            final amount = entry.value;
            return Chip(
              avatar: Icon(
                category.icon,
                size: 16,
                color: category.color,
              ),
              label: Text(
                '${category.displayName}: ₹${amount.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 12),
              ),
              backgroundColor: category.color.withOpacity(0.1),
              side: BorderSide(color: category.color.withOpacity(0.3)),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Builds the list of expenses
  Widget _buildExpenseList(List<Expense> expenses) {
    if (expenses.isEmpty) {
      return const SizedBox.shrink();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: expenses.length,
      itemBuilder: (context, index) {
        final expense = expenses[index];
        return _buildExpenseListTile(expense);
      },
    );
  }

  /// Builds a single expense list tile
  Widget _buildExpenseListTile(Expense expense) {
    final isCurrentUser = expense.paidByUserId == _authService.currentUser?.uid;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: expense.category.color.withOpacity(0.2),
          child: Icon(
            expense.category.icon,
            color: expense.category.color,
            size: 20,
          ),
        ),
        title: Text(
          expense.title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${expense.category.displayName} • ${expense.relativeDateDescription}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (expense.hasNotes)
              Text(
                expense.notes!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            if (isCurrentUser)
              Text(
                'Paid by you',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              expense.formattedAmount,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        onTap: () => _showExpenseDetails(expense),
        onLongPress: () => _showExpenseOptions(expense),
      ),
    );
  }

  /// Shows expense details in a dialog
  void _showExpenseDetails(Expense expense) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(expense.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Amount', expense.formattedAmount),
            _buildDetailRow('Category', expense.category.displayName),
            _buildDetailRow('Date', expense.formattedDateTime),
            if (expense.hasNotes) _buildDetailRow('Notes', expense.notes!),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Builds a detail row for the expense details dialog
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  /// Shows options for an expense (edit/delete)
  void _showExpenseOptions(Expense expense) {
    final isCurrentUser = expense.paidByUserId == _authService.currentUser?.uid;
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.visibility),
            title: const Text('View Details'),
            onTap: () {
              Navigator.pop(context);
              _showExpenseDetails(expense);
            },
          ),
          if (isCurrentUser) ...[
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Expense'),
              onTap: () {
                Navigator.pop(context);
                _editExpense(expense);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Expense'),
              textColor: Colors.red,
              onTap: () {
                Navigator.pop(context);
                _deleteExpense(expense);
              },
            ),
          ],
        ],
      ),
    );
  }

  /// Shows expense analytics
  void _showExpenseAnalytics(BuildContext context) {
    // This will be implemented as a detailed analytics screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Analytics feature coming soon!'),
      ),
    );
  }

  /// Navigate to add expense screen
  void _addExpense() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddExpenseScreen(trip: widget.trip),
      ),
    );
  }

  /// Navigate to edit expense screen
  void _editExpense(Expense expense) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddExpenseScreen(
          trip: widget.trip,
          expense: expense,
        ),
      ),
    );
  }

  /// Delete an expense with confirmation
  void _deleteExpense(Expense expense) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense'),
        content: Text('Are you sure you want to delete "${expense.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _firestoreService.deleteExpense(widget.trip.id!, expense.id!);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Expense deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete expense: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );
  }
}