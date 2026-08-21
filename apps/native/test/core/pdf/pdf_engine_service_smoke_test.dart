// P0-11 verification: round-trips real operations through PdfEngineService
// against real files on disk, with no network involved. This is the test that
// proves the prebuilt engine binary from P0-1 actually loads and works end to
// end — run it offline (airplane mode) to confirm.
//
// The fixture PDFs are created with the engine's own builder API, which is why
// this file imports `pdf_manipulator` directly. Test fixtures are the one
// exception to the "only pdf_manipulator_engine_service.dart may import it"
// rule — no feature or lib/ code does.
import 'dart:io';
import 'dart:typed_data';

import 'package:doclyvo/core/pdf/pdf_engine_service.dart';
import 'package:doclyvo/core/pdf/pdf_manipulator_engine_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_manipulator/io.dart';
import 'package:pdf_manipulator/pdf_manipulator.dart';

void main() {
  late Directory workspace;
  late PdfEngineService engine;
  late Pdf fixtureEngine;

  setUpAll(() async {
    workspace = await Directory.systemTemp.createTemp('doclyvo_pdf_smoke_');
    fixtureEngine = Pdf();
    engine = PdfManipulatorEngineService();
    await engine.initialize();
  });

  tearDownAll(() async {
    await engine.dispose();
    await fixtureEngine.dispose();
    await workspace.delete(recursive: true);
  });

  /// Writes a real single-page PDF to disk and returns its bytes.
  Future<Uint8List> createPdfFile(String name, String heading) async {
    final file = File('${workspace.path}/$name');
    final sink = await FileSink.create(file);
    final builder = await fixtureEngine.build();
    final page = await builder.addA4Page();
    await page.heading(1, heading);
    await page.done();
    await builder.save(sink);
    await builder.dispose();
    await sink.close();

    expect(file.existsSync(), isTrue);
    return file.readAsBytes();
  }

  test('merges two real PDF files into one two-page document', () async {
    final first = await createPdfFile('first.pdf', 'Doclyvo first page');
    final second = await createPdfFile('second.pdf', 'Doclyvo second page');

    final merged = await engine.merge(documents: [first, second]);

    expect(merged, isNotEmpty);

    final mergedFile = File('${workspace.path}/merged.pdf');
    await mergedFile.writeAsBytes(merged);

    final info = await engine.readDocumentInfo(
      bytes: await mergedFile.readAsBytes(),
    );

    expect(info.pageCount, 2);
    expect(info.pages, hasLength(2));
    expect(info.pages.first.effectiveWidth, greaterThan(0));
    expect(info.isEncrypted, isFalse);
  });

  test('renders a page thumbnail as PNG bytes', () async {
    final source = await createPdfFile('thumbnail.pdf', 'Thumbnail me');

    final thumbnails = await engine
        .renderThumbnails(bytes: source, maxSize: 120)
        .toList();

    expect(thumbnails, hasLength(1));

    final thumbnail = thumbnails.single;
    expect(thumbnail.pageIndex, 0);
    expect(thumbnail.width, greaterThan(0));
    expect(thumbnail.height, greaterThan(0));
    // PNG magic number — confirms real image bytes came back.
    expect(thumbnail.pngBytes.take(4), [0x89, 0x50, 0x4E, 0x47]);
  });

  test('splits a merged document back into one file per page', () async {
    final first = await createPdfFile('split_a.pdf', 'Page A');
    final second = await createPdfFile('split_b.pdf', 'Page B');
    final merged = await engine.merge(documents: [first, second]);

    final parts = await engine.split(bytes: merged);

    expect(parts, hasLength(2));
    for (final part in parts) {
      final info = await engine.readDocumentInfo(bytes: part);
      expect(info.pageCount, 1);
    }
  });
}
