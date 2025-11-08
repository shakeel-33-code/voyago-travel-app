import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/trip_model.dart';
import '../../models/expense_model.dart';
import '../../services/firestore_service.dart';
import '../../services/firebase_auth_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_indicator.dart';

class AddExpenseScreen extends StatefulWidget {
  final Trip trip;
  final Expense? expense; // If provided, this is an edit operation

  const AddExpenseScreen({
    super.key,
    required this.trip,
    this.expense,
  });

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuthService _authService = FirebaseAuthService();

  ExpenseCategory _selectedCategory = ExpenseCategory.food;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.expense != null;
    
    if (_isEditing) {
      _populateForm();
    }
  }

  /// Populate form fields when editing an existing expense
  void _populateForm() {
    final expense = widget.expense!;
    _titleController.text = expense.title;
    _amountController.text = expense.amount.toString();
    _notesController.text = expense.notes ?? '';
    _selectedCategory = expense.category;
    _selectedDate = expense.date.toDate();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LoadingIndicator(
      isLoading: _isLoading,
      message: _isEditing ? 'Updating expense...' : 'Adding expense...',
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Edit Expense' : 'Add Expense'),
          centerTitle: true,
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Trip info card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.travel_explore,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Adding expense to:',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              widget.trip.title,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Title field
              CustomTextField(
                controller: _titleController,
                labelText: 'Expense Title',
                hintText: 'e.g., Lunch at cafe, Train tickets',
                prefixIcon: Icons.receipt,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an expense title';
                  }
                  if (value.trim().length < 2) {
                    return 'Title must be at least 2 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Amount field
              CustomTextField(
                controller: _amountController,
                labelText: 'Amount (₹)',
                hintText: '0.00',
                prefixIcon: Icons.currency_rupee,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an amount';
                  }
                  final amount = double.tryParse(value.trim());
                  if (amount == null) {
                    return 'Please enter a valid amount';
                  }
                  if (amount <= 0) {
                    return 'Amount must be greater than 0';
                  }
                  if (amount > 999999) {
                    return 'Amount is too large';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category selection
              Text(
                'Category',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildCategorySelector(),
              const SizedBox(height: 16),

              // Date selection
              Text(
                'Date',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildDateSelector(),
              const SizedBox(height: 16),

              // Notes field (optional)
              CustomTextField(
                controller: _notesController,
                labelText: 'Notes (Optional)',
                hintText: 'Add any additional details...',
                prefixIcon: Icons.note,
                maxLines: 3,
                validator: (value) {
                  if (value != null && value.trim().length > 500) {
                    return 'Notes must be less than 500 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Save button
              CustomButton(
                onPressed: _saveExpense,
                text: _isEditing ? 'Update Expense' : 'Save Expense',
                icon: _isEditing ? Icons.update : Icons.save,
              ),
              
              // Cancel button
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the category selector with chips
  Widget _buildCategorySelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ExpenseCategory.values.map((category) {
        final isSelected = _selectedCategory == category;
        return FilterChip(
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _selectedCategory = category;
            });
          },
          avatar: Icon(
            category.icon,
            size: 18,
            color: isSelected ? Colors.white : category.color,
          ),
          label: Text(category.displayName),
          selectedColor: category.color,
          checkmarkColor: Colors.white,
          backgroundColor: category.color.withOpacity(0.1),
          side: BorderSide(
            color: isSelected ? category.color : category.color.withOpacity(0.3),
          ),
        );
      }).toList(),
    );
  }

  /// Builds the date selector
  Widget _buildDateSelector() {
    return Card(
      child: ListTile(
        leading: Icon(
          Icons.calendar_today,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(
          _formatDate(_selectedDate),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(
          _getRelativeDateDescription(_selectedDate),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: const Icon(Icons.arrow_drop_down),
        onTap: _selectDate,
      ),
    );
  }

  /// Format date for display
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Get relative date description
  String _getRelativeDateDescription(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays == -1) {
      return 'Tomorrow';
    } else if (difference.inDays < 0) {
      return 'In ${-difference.inDays} days';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return 'On ${_formatDate(date)}';
    }
  }

  /// Show date picker
  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: widget.trip.startDate.subtract(const Duration(days: 30)),
      lastDate: widget.trip.endDate.add(const Duration(days: 30)),
      helpText: 'Select expense date',
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  /// Save the expense
  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('You must be logged in to add expenses');
      }

      final amount = double.parse(_amountController.text.trim());
      
      final expense = Expense(
        id: _isEditing ? widget.expense!.id : null,
        tripId: widget.trip.id!,
        title: _titleController.text.trim(),
        amount: amount,
        category: _selectedCategory,
        date: Timestamp.fromDate(_selectedDate),
        paidByUserId: currentUser.uid,
        notes: _notesController.text.trim().isEmpty 
            ? null 
            : _notesController.text.trim(),
        createdAt: _isEditing ? widget.expense!.createdAt : null,
      );

      if (_isEditing) {
        await _firestoreService.updateExpense(widget.trip.id!, expense);
      } else {
        await _firestoreService.addExpense(widget.trip.id!, expense);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing 
                  ? 'Expense updated successfully!' 
                  : 'Expense added successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing 
                  ? 'Failed to update expense: $e' 
                  : 'Failed to add expense: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}