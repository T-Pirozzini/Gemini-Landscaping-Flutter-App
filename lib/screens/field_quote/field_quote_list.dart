import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gemini_landscaping_app/models/field_quote.dart';
import 'package:gemini_landscaping_app/providers/field_quote_provider.dart';
import 'package:gemini_landscaping_app/screens/field_quote/create_field_quote.dart';
import 'package:gemini_landscaping_app/screens/field_quote/view_field_quote.dart';
import 'package:google_fonts/google_fonts.dart';

class FieldQuoteList extends ConsumerStatefulWidget {
  const FieldQuoteList({super.key});

  @override
  ConsumerState<FieldQuoteList> createState() => _FieldQuoteListState();
}

class _FieldQuoteListState extends ConsumerState<FieldQuoteList> {
  static const _darkGreen = Color.fromARGB(255, 59, 82, 73);
  static const _greenAccent = Color.fromARGB(255, 31, 182, 77);

  String _statusFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final quotesAsync = ref.watch(fieldQuotesStreamProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Column(
        children: [
          // Filter chips
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Row(
              children: ['all', 'created', 'signed', 'completed']
                  .map((f) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: ChoiceChip(
                            label: SizedBox(
                              width: double.infinity,
                              child: Text(
                                f[0].toUpperCase() + f.substring(1),
                                textAlign: TextAlign.center,
                                style: GoogleFonts.montserrat(
                                  fontSize: 11,
                                  fontWeight: _statusFilter == f
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: _statusFilter == f
                                      ? Colors.white
                                      : _darkGreen,
                                ),
                              ),
                            ),
                            selected: _statusFilter == f,
                            selectedColor: _darkGreen,
                            backgroundColor: Colors.white,
                            side: BorderSide(
                              color: _statusFilter == f
                                  ? _darkGreen
                                  : Colors.grey.shade300,
                            ),
                            onSelected: (_) =>
                                setState(() => _statusFilter = f),
                            showCheckmark: false,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
          Expanded(
            child: quotesAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (quotes) {
                final filtered = _statusFilter == 'all'
                    ? quotes
                    : quotes
                        .where((q) => q.status == _statusFilter)
                        .toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long,
                            size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 8),
                        Text(
                          'No quotes yet',
                          style: GoogleFonts.montserrat(
                              fontSize: 13, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) =>
                      _buildQuoteTile(filtered[index]),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _darkGreen,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateFieldQuote()),
        ),
      ),
    );
  }

  Widget _buildQuoteTile(FieldQuote quote) {
    Color statusColor;
    IconData statusIcon;
    switch (quote.status) {
      case 'signed':
        statusColor = _greenAccent;
        statusIcon = Icons.draw;
        break;
      case 'completed':
        statusColor = Colors.blueGrey;
        statusIcon = Icons.check_circle;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
    }

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ViewFieldQuote(quote: quote)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Status icon
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(statusIcon, size: 18, color: statusColor),
            ),
            const SizedBox(width: 10),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    quote.siteName,
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _darkGreen,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${quote.clientName} - ${quote.date}',
                    style: GoogleFonts.montserrat(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Total
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${quote.total.toStringAsFixed(2)}',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _darkGreen,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    quote.status[0].toUpperCase() + quote.status.substring(1),
                    style: GoogleFonts.montserrat(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
