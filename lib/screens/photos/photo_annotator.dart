import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';

/// Annotation tool mode.
enum AnnotationTool { freehand, arrow, circle }

/// A single drawn annotation.
class _Annotation {
  final AnnotationTool tool;
  final Color color;
  final double strokeWidth;
  final List<Offset> points; // freehand: all points; arrow/circle: [start, end]

  _Annotation({
    required this.tool,
    required this.color,
    required this.strokeWidth,
    required this.points,
  });
}

/// Full-screen photo annotation editor.
/// Returns the annotated image as a [File] path, or null if cancelled.
class PhotoAnnotator extends StatefulWidget {
  final String imageUrl;

  const PhotoAnnotator({super.key, required this.imageUrl});

  @override
  State<PhotoAnnotator> createState() => _PhotoAnnotatorState();
}

class _PhotoAnnotatorState extends State<PhotoAnnotator> {
  final GlobalKey _repaintKey = GlobalKey();
  final List<_Annotation> _annotations = [];
  List<Offset> _currentPoints = [];

  AnnotationTool _tool = AnnotationTool.freehand;
  Color _color = Colors.red;
  final double _strokeWidth = 3.0;
  bool _saving = false;

  void _onPanStart(DragStartDetails details) {
    _currentPoints = [details.localPosition];
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      if (_tool == AnnotationTool.freehand) {
        _currentPoints = [..._currentPoints, details.localPosition];
      } else {
        // For arrow/circle, keep only start and current end
        _currentPoints = [_currentPoints.first, details.localPosition];
      }
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_currentPoints.length < 2) return;
    setState(() {
      _annotations.add(_Annotation(
        tool: _tool,
        color: _color,
        strokeWidth: _strokeWidth,
        points: List.from(_currentPoints),
      ));
      _currentPoints = [];
    });
  }

  void _undo() {
    if (_annotations.isNotEmpty) {
      setState(() => _annotations.removeLast());
    }
  }

  void _clear() {
    setState(() => _annotations.clear());
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final boundary = _repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/annotated_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());

      if (mounted) Navigator.pop(context, file.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('Annotate',
            style: GoogleFonts.montserrat(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            )),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo, color: Colors.white, size: 20),
            tooltip: 'Undo',
            onPressed: _undo,
          ),
          IconButton(
            icon:
                const Icon(Icons.delete_outline, color: Colors.white, size: 20),
            tooltip: 'Clear All',
            onPressed: _clear,
          ),
          IconButton(
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.check, color: Colors.white, size: 22),
            tooltip: 'Save',
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
      body: Column(
        children: [
          // Tool & color bar
          Container(
            color: Colors.grey[900],
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                _toolButton(AnnotationTool.freehand, Icons.brush, 'Draw'),
                const SizedBox(width: 8),
                _toolButton(
                    AnnotationTool.arrow, Icons.arrow_forward, 'Arrow'),
                const SizedBox(width: 8),
                _toolButton(
                    AnnotationTool.circle, Icons.circle_outlined, 'Circle'),
                const SizedBox(width: 16),
                _colorDot(Colors.red),
                const SizedBox(width: 6),
                _colorDot(Colors.yellow),
                const SizedBox(width: 6),
                _colorDot(Colors.green),
                const SizedBox(width: 6),
                _colorDot(Colors.blue),
                const SizedBox(width: 6),
                _colorDot(Colors.white),
              ],
            ),
          ),
          // Canvas
          Expanded(
            child: GestureDetector(
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              child: RepaintBoundary(
                key: _repaintKey,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: widget.imageUrl,
                      fit: BoxFit.contain,
                      placeholder: (_, __) => const Center(
                          child: CircularProgressIndicator(
                              color: Colors.white)),
                    ),
                    CustomPaint(
                      painter: _AnnotationPainter(
                        annotations: _annotations,
                        currentTool: _tool,
                        currentColor: _color,
                        currentStrokeWidth: _strokeWidth,
                        currentPoints: _currentPoints,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _toolButton(AnnotationTool tool, IconData icon, String label) {
    final selected = _tool == tool;
    return GestureDetector(
      onTap: () => setState(() => _tool = tool),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? Colors.white24 : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected ? Colors.white54 : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 4),
            Text(label,
                style: GoogleFonts.montserrat(
                    fontSize: 10, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _colorDot(Color color) {
    final selected = _color == color;
    return GestureDetector(
      onTap: () => setState(() => _color = color),
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? Colors.white : Colors.transparent,
            width: 2,
          ),
        ),
      ),
    );
  }
}

/// Custom painter for annotations overlay.
class _AnnotationPainter extends CustomPainter {
  final List<_Annotation> annotations;
  final AnnotationTool currentTool;
  final Color currentColor;
  final double currentStrokeWidth;
  final List<Offset> currentPoints;

  _AnnotationPainter({
    required this.annotations,
    required this.currentTool,
    required this.currentColor,
    required this.currentStrokeWidth,
    required this.currentPoints,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw completed annotations
    for (final ann in annotations) {
      _drawAnnotation(canvas, ann.tool, ann.color, ann.strokeWidth, ann.points);
    }
    // Draw in-progress annotation
    if (currentPoints.length >= 2) {
      _drawAnnotation(
          canvas, currentTool, currentColor, currentStrokeWidth, currentPoints);
    }
  }

  void _drawAnnotation(Canvas canvas, AnnotationTool tool, Color color,
      double strokeWidth, List<Offset> points) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    switch (tool) {
      case AnnotationTool.freehand:
        if (points.length < 2) return;
        final path = Path()..moveTo(points.first.dx, points.first.dy);
        for (int i = 1; i < points.length; i++) {
          path.lineTo(points[i].dx, points[i].dy);
        }
        canvas.drawPath(path, paint);
        break;

      case AnnotationTool.arrow:
        if (points.length < 2) return;
        final start = points.first;
        final end = points.last;
        canvas.drawLine(start, end, paint);
        // Draw arrowhead
        final angle = atan2(end.dy - start.dy, end.dx - start.dx);
        const headLen = 15.0;
        const headAngle = 0.5;
        canvas.drawLine(
          end,
          Offset(
            end.dx - headLen * cos(angle - headAngle),
            end.dy - headLen * sin(angle - headAngle),
          ),
          paint,
        );
        canvas.drawLine(
          end,
          Offset(
            end.dx - headLen * cos(angle + headAngle),
            end.dy - headLen * sin(angle + headAngle),
          ),
          paint,
        );
        break;

      case AnnotationTool.circle:
        if (points.length < 2) return;
        final start = points.first;
        final end = points.last;
        final center = Offset(
            (start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
        final radius = (end - start).distance / 2;
        canvas.drawCircle(center, radius, paint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _AnnotationPainter oldDelegate) => true;
}
