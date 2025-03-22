import 'package:flutter/material.dart';
import '../models/bank_account.dart';

class AccountCard extends StatelessWidget {
  final BankAccount account;

  const AccountCard({Key? key, required this.account}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: account.isDefault
            ? BorderSide(color: Theme.of(context).primaryColor, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      _getIconForAccountType(account.type),
                      color: _getColorForAccountType(account.type),
                      size: 28,
                    ),
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          account.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          account.bankName,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (account.isDefault)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star,
                          color: Theme.of(context).primaryColor,
                          size: 16,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Default',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      account.maskedAccountNumber,
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Balance',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '\$${account.balance.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: account.balance >= 0
                            ? Colors.green[700]
                            : Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              account.type.toDisplayString(),
              style: TextStyle(
                color: _getColorForAccountType(account.type),
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForAccountType(BankAccountType type) {
    switch (type) {
      case BankAccountType.checking:
        return Icons.account_balance;
      case BankAccountType.savings:
        return Icons.savings;
      case BankAccountType.investment:
        return Icons.trending_up;
      case BankAccountType.credit:
        return Icons.credit_card;
    }
  }

  Color _getColorForAccountType(BankAccountType type) {
    switch (type) {
      case BankAccountType.checking:
        return Colors.blue;
      case BankAccountType.savings:
        return Colors.green;
      case BankAccountType.investment:
        return Colors.purple;
      case BankAccountType.credit:
        return Colors.orange;
    }
  }
}
