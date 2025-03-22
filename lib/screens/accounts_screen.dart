import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/bank_account.dart';
import '../providers/bank_account_provider.dart';
import '../widgets/account_card.dart';
import '../widgets/add_account_dialog.dart';

class AccountsScreen extends StatefulWidget {
  static const routeName = '/accounts';

  const AccountsScreen({Key? key}) : super(key: key);

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  bool _isInit = false;
  bool _isLoading = false;

  @override
  void didChangeDependencies() {
    if (!_isInit) {
      setState(() {
        _isLoading = true;
      });

      Provider.of<BankAccountProvider>(context, listen: false)
          .loadAccounts()
          .then((_) {
        setState(() {
          _isLoading = false;
        });
      }).catchError((error) {
        // Show a more helpful error message if the table doesn't exist
        String errorMessage = 'Failed to load accounts: ${error.toString()}';
        if (error.toString().contains('404')) {
          errorMessage =
              'The bank_accounts table needs to be set up in Supabase. Please check the documentation for setup instructions.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Setup Help',
              textColor: Colors.white,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text('Database Setup Required'),
                    content: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              'To fix this issue, you need to create the required database tables in Supabase:'),
                          SizedBox(height: 16),
                          Text('1. Go to the Supabase dashboard'),
                          Text('2. Open the SQL Editor'),
                          Text('3. Paste and run the following SQL code:'),
                          SizedBox(height: 8),
                          Container(
                            padding: EdgeInsets.all(8),
                            color: Colors.grey[200],
                            child: SelectableText(
                                'create or replace function create_bank_accounts_table_if_not_exists()\n'
                                'returns void as \$\$\n'
                                '-- Check SQL code in SupabaseService.getBankAccountsTableCreationSQL()\n'
                                '\$\$ language plpgsql;'),
                          ),
                          SizedBox(height: 16),
                          Text('4. Run the function to create the tables:'),
                          Container(
                            padding: EdgeInsets.all(8),
                            color: Colors.grey[200],
                            child: SelectableText(
                                'select create_bank_accounts_table_if_not_exists();'),
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('Close'),
                      ),
                    ],
                  ),
                );
              },
            ),
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

  Future<void> _refreshAccounts(BuildContext context) async {
    await Provider.of<BankAccountProvider>(context, listen: false)
        .loadAccounts();
  }

  Future<void> _showAddAccountDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (ctx) => const AddAccountDialog(),
    );
  }

  Future<void> _showAccountOptionsDialog(
      BuildContext context, BankAccount account) async {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Manage Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.edit),
              title: Text('Edit Account'),
              onTap: () {
                Navigator.of(ctx).pop();
                // TODO: Implement edit account dialog
              },
            ),
            if (!account.isDefault)
              ListTile(
                leading: Icon(Icons.star),
                title: Text('Set as Default'),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  try {
                    await Provider.of<BankAccountProvider>(context,
                            listen: false)
                        .setDefaultAccount(account.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Default account updated')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Failed to update default account: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
              ),
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red),
              title:
                  Text('Delete Account', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.of(ctx).pop();
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text('Confirm Deletion'),
                    content: Text(
                        'Are you sure you want to delete this account? This action cannot be undone.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child:
                            Text('Delete', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  try {
                    await Provider.of<BankAccountProvider>(context,
                            listen: false)
                        .deleteAccount(account.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Account deleted')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text('Failed to delete account: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bank Accounts'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => _refreshAccounts(context),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Consumer<BankAccountProvider>(
              builder: (ctx, accountsProvider, _) {
                final accounts = accountsProvider.accounts;
                final totalBalance = accountsProvider.totalBalance;

                if (accounts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.account_balance,
                            size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No accounts added yet',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        SizedBox(height: 16),
                        ElevatedButton.icon(
                          icon: Icon(Icons.add),
                          label: Text('Add Account'),
                          onPressed: () => _showAddAccountDialog(context),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => _refreshAccounts(context),
                  child: Column(
                    children: [
                      // Total balance card
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Card(
                          elevation: 3,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Balance',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        color: Colors.grey[700],
                                      ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  '\$${totalBalance.toStringAsFixed(2)}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Accounts list
                      Expanded(
                        child: ListView.builder(
                          padding: EdgeInsets.all(16),
                          itemCount: accounts.length,
                          itemBuilder: (ctx, i) {
                            final account = accounts[i];
                            return GestureDetector(
                              onTap: () =>
                                  accountsProvider.selectAccount(account.id),
                              onLongPress: () =>
                                  _showAccountOptionsDialog(context, account),
                              child: AccountCard(account: account),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () => _showAddAccountDialog(context),
      ),
    );
  }
}
