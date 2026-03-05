import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hand_signature/signature.dart';

/// Full-screen signature capture. Returns base64-encoded PNG on confirm.
class SignatureScreen extends StatefulWidget {
  const SignatureScreen({super.key});

  @override
  State<SignatureScreen> createState() => _SignatureScreenState();
}

class _SignatureScreenState extends State<SignatureScreen> {
  static const _darkGreen = Color.fromARGB(255, 59, 82, 73);

  final HandSignatureControl _control = HandSignatureControl();

  @override
  void dispose() {
    _control.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_control.isFilled) {
      final ByteData? byteData = await _control.toImage(
        color: Colors.black,
        background: Colors.white,
        fit: true,
      );
      if (byteData != null && mounted) {
        final bytes = byteData.buffer.asUint8List();
        Navigator.pop(context, base64Encode(bytes));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _darkGreen,
        toolbarHeight: 44,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Client Signature',
          style: GoogleFonts.montserrat(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo, color: Colors.white, size: 20),
            onPressed: () => _control.stepBack(),
            tooltip: 'Undo',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                color: Colors.white, size: 20),
            onPressed: () => _control.clear(),
            tooltip: 'Clear',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox.expand(
                  child: HandSignature(
                    control: _control,
                  ),
                ),
              ),
            ),
          ),
          // Instruction
          Text(
            'Sign above to approve',
            style: GoogleFonts.montserrat(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 12),
          // Confirm button
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _confirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _darkGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Confirm Signature',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
