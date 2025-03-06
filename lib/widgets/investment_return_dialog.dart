import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/investment.dart';
import '../providers/finance_provider.dart';
import '../providers/currency_provider.dart';

class InvestmentReturnDialog extends StatefulWidget {
  final Investment investment;

  const InvestmentReturnDialog({
    Key? key,
    required this.investment,
  }) : super(key: key);

  @override
  State<InvestmentReturnDialog> createState() => _InvestmentReturnDialogState();
}

class _InvestmentReturnDialogState extends State<InvestmentReturnDialog> {
  final _formKey = GlobalKey<FormState>();
  final _returnAmountController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _returnAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currencyProvider = Provider.of<CurrencyProvider>(context, listen: false);
    final financeProvider = Provider.of<FinanceProvider>(context, listen: false);

    return AlertDialog(
      title: Text(
        'Investment Return',
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
        ),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Investment: ${widget.investment.title}',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Original Amount: ${financeProvider.formatInvestmentAmount(widget.investment, currencyProvider)}',
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Original investment: ${currencyProvider.formatAmount(widget.investment.amount)}',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter the amount you received when selling this investment. If you made a profit, the difference will be added to your balance. If you made a loss, the difference will be deducted.',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Enter the return amount you received from this investment:',
              style: const TextStyle(
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _returnAmountController,
              decoration: InputDecoration(
                labelText: 'Return Amount',
                prefixText: currencyProvider.selectedSymbol,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a return amount';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'Please enter a valid amount greater than zero';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isProcessing
              ? null
              : () {
                  if (_formKey.currentState!.validate()) {
                    setState(() {
                      _isProcessing = true;
                    });

                    try {
                      final returnAmount = double.parse(_returnAmountController.text);
                      final originalAmount = widget.investment.amount;
                      final profitOrLoss = returnAmount - originalAmount;
                      final isProfitable = profitOrLoss >= 0;

                      // Add the return to the finance provider
                      financeProvider.addInvestmentReturn(
                        widget.investment.id,
                        returnAmount,
                      );

                      if (mounted) {
                        Navigator.of(context).pop(true);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isProfitable
                                  ? 'Profit of ${currencyProvider.formatAmount(profitOrLoss)} added to your balance!'
                                  : 'Loss of ${currencyProvider.formatAmount(profitOrLoss.abs())} deducted from your balance.',
                            ),
                            backgroundColor: isProfitable ? Colors.green : Colors.red,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: ${e.toString()}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } finally {
                      if (mounted) {
                        setState(() {
                          _isProcessing = false;
                        });
                      }
                    }
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
          ),
          child: _isProcessing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Add Return'),
        ),
      ],
    );
  }
}
