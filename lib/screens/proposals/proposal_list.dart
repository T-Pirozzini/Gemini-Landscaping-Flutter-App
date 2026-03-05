import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gemini_landscaping_app/models/proposal.dart';
import 'package:gemini_landscaping_app/providers/proposal_provider.dart';
import 'package:gemini_landscaping_app/screens/proposals/create_proposal.dart';
import 'package:gemini_landscaping_app/screens/proposals/view_proposal.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ProposalList extends ConsumerStatefulWidget {
  const ProposalList({super.key});

  @override
  ConsumerState<ProposalList> createState() => _ProposalListState();
}

class _ProposalListState extends ConsumerState<ProposalList> {
  static const _darkGreen = Color.fromARGB(255, 59, 82, 73);
  static const _greenAccent = Color.fromARGB(255, 31, 182, 77);

  String _statusFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final proposalsAsync = ref.watch(proposalsStreamProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Column(
        children: [
          // Filter chips
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Row(
              children:
                  ['all', 'draft', 'sent', 'accepted', 'declined']
                      .map((f) => Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 2),
                              child: ChoiceChip(
                                label: SizedBox(
                                  width: double.infinity,
                                  child: Text(
                                    f[0].toUpperCase() + f.substring(1),
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.montserrat(
                                      fontSize: 10,
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
            child: proposalsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (proposals) {
                final filtered = _statusFilter == 'all'
                    ? proposals
                    : proposals
                        .where((p) => p.status == _statusFilter)
                        .toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.description,
                            size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 8),
                        Text('No proposals yet',
                            style: GoogleFonts.montserrat(
                                fontSize: 13,
                                color: Colors.grey.shade500)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) =>
                      _buildProposalTile(filtered[index]),
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
          MaterialPageRoute(builder: (_) => const CreateProposal()),
        ),
      ),
    );
  }

  Widget _buildProposalTile(Proposal proposal) {
    Color statusColor;
    IconData statusIcon;
    switch (proposal.status) {
      case 'sent':
        statusColor = Colors.blue;
        statusIcon = Icons.send;
        break;
      case 'accepted':
        statusColor = _greenAccent;
        statusIcon = Icons.check_circle;
        break;
      case 'declined':
        statusColor = Colors.red.shade400;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.edit_note;
        break;
    }

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ViewProposal(proposal: proposal)),
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(proposal.siteName,
                      style: GoogleFonts.montserrat(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _darkGreen),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(
                    '${proposal.contactName.isNotEmpty ? proposal.contactName : 'No contact'}${proposal.dueDate != null ? ' - Due ${DateFormat('MMM d').format(proposal.dueDate!)}' : ''}',
                    style: GoogleFonts.montserrat(
                        fontSize: 10, color: Colors.grey.shade600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${proposal.annualRate.toStringAsFixed(0)}/yr',
                  style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _darkGreen),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    proposal.status[0].toUpperCase() +
                        proposal.status.substring(1),
                    style: GoogleFonts.montserrat(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: statusColor),
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
