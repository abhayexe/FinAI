import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/bank_transfer.dart';
import '../providers/bank_account_provider.dart';

class TransferHistoryScreen extends StatefulWidget {
  static const routeName = '/transfer-history';

  const TransferHistoryScreen({Key? key}) : super(key: key);

  @override
  State<TransferHistoryScreen> createState() => _TransferHistoryScreenState();
}

class _TransferHistoryScreenState extends State<TransferHistoryScreen> {
  bool _isInit = false;
  bool _isLoading = false;

  @override
  void didChangeDependencies() {
    if (!_isInit) {
      setState(() {
        _isLoading = true;
      });

      Provider.of<BankAccountProvider>(context, listen: false)
          .loadTransfers()
          .then((_) {
        setState(() {
          _isLoading = false;
        });
      }).catchError((error) {
        // Show a more helpful error message if the table doesn't exist
        String errorMessage = 'Failed to load transfers: ${error.toString()}';
        if (error.toString().contains('404')) {
          errorMessage =
              'The bank_transfers table needs to be set up in Supabase. Please visit the Accounts screen for setup instructions.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
        setState(() {
          _isLoading = false;
        });
      });

      _isInit = true;
    }
    super.didChangeDependencies();
  }

  Future<void> _refreshTransfers(BuildContext context) async {
    await Provider.of<BankAccountProvider>(context, listen: false)
        .loadTransfers();
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final transferDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (transferDate == today) {
      return 'Today, ${DateFormat.jm().format(dateTime)}';
    } else if (transferDate == today.subtract(Duration(days: 1))) {
      return 'Yesterday, ${DateFormat.jm().format(dateTime)}';
    } else if (now.difference(transferDate).inDays < 7) {
      return '${DateFormat.EEEE().format(dateTime)}, ${DateFormat.jm().format(dateTime)}';
    } else {
      return DateFormat.yMMMd().add_jm().format(dateTime);
    }
  }

  Color _getStatusColor(TransferStatus status) {
    switch (status) {
      case TransferStatus.completed:
        return Colors.green;
      case TransferStatus.pending:
        return Colors.orange;
      case TransferStatus.failed:
        return Colors.red;
      case TransferStatus.cancelled:
        return Colors.grey;
    }
  }

  String _getStatusIcon(TransferStatus status) {
    switch (status) {
      case TransferStatus.completed:
        return '✓';
      case TransferStatus.pending:
        return '⏱️';
      case TransferStatus.failed:
        return '✗';
      case TransferStatus.cancelled:
        return '⊘';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Transfer History'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => _refreshTransfers(context),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Consumer<BankAccountProvider>(
              builder: (ctx, provider, _) {
                final transfers = provider.transfers;

                if (transfers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No transfer history yet',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Your transfers between accounts will appear here',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => _refreshTransfers(context),
                  child: ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: transfers.length,
                    itemBuilder: (ctx, i) {
                      final transfer = transfers[i];
                      return Card(
                        margin: EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        child: ListTile(
                          contentPadding: EdgeInsets.all(16),
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                transfer.status.toDisplayString(),
                                style: TextStyle(
                                  color: _getStatusColor(transfer.status),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    '\$${transfer.amount.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(transfer.status)
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      _getStatusIcon(transfer.status),
                                      style: TextStyle(
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.arrow_upward,
                                    size: 16,
                                    color: Colors.red[400],
                                  ),
                                  SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      'From: ${transfer.sourceAccountName ?? 'Unknown Account'}',
                                      style: TextStyle(color: Colors.red[400]),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.arrow_downward,
                                    size: 16,
                                    color: Colors.green[600],
                                  ),
                                  SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      'To: ${transfer.destinationAccountName ?? 'Unknown Account'}',
                                      style:
                                          TextStyle(color: Colors.green[600]),
                                    ),
                                  ),
                                ],
                              ),
                              if (transfer.description != null &&
                                  transfer.description!.isNotEmpty) ...[
                                SizedBox(height: 8),
                                Text(
                                  transfer.description!,
                                  style: TextStyle(
                                    fontStyle: FontStyle.italic,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                              SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatDateTime(transfer.createdAt),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  if (transfer.completedAt != null)
                                    Text(
                                      'Completed: ${_formatDateTime(transfer.completedAt)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
