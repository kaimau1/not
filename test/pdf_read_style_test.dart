import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/presentation/viewers/bubble_layer.dart';
import 'package:notlar/features/notes/presentation/viewers/pdf_read_style.dart';
import 'package:notlar/features/notes/presentation/viewers/pdf_selection_bar.dart';
import 'package:notlar/features/notes/presentation/viewers/pdf_viewer_screen.dart';

/// F28.4: balonlu belge (pdfrx) sabit bölmeyle AYNI zemin / boşluk / gölge.
void main() {
  testWidgets('balonlu PdfViewerParams ortak okuma stilini kullanır', (
    tester,
  ) async {
    late PdfReadStyle style;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(colorScheme: const ColorScheme.light()),
        home: Builder(
          builder: (context) {
            style = PdfReadStyle.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    final selection = PdfSelectionState();
    final bubbles = BubbleController(initial: const [], onChanged: (_) {});
    addTearDown(selection.dispose);
    addTearDown(bubbles.dispose);
    final params = pdfLayerParams(
      style: style,
      selection: selection,
      bubbles: bubbles,
      editable: false,
    );
    expect(params.backgroundColor, style.background);
    expect(params.backgroundColor, isNot(Colors.grey));
    expect(params.margin, PdfReadStyle.pageGap);
    expect(params.pageDropShadow, isNull);
  });
}
