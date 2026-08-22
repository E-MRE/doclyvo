// Covers the CompressQuality → PdfEngineService.imageQuality mapping: it
// runs in the opposite direction from "compression strength" (low
// compression keeps a high imageQuality), which is easy to get backwards.

import 'package:doclyvo/features/compress/domain/models/compress_quality.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CompressQuality.imageQuality', () {
    test('low compression keeps the highest image quality', () {
      expect(CompressQuality.low.imageQuality, greaterThan(70));
    });

    test('high compression keeps the lowest image quality', () {
      expect(CompressQuality.high.imageQuality, lessThan(40));
    });

    test('recommended sits strictly between low and high', () {
      expect(
        CompressQuality.recommended.imageQuality,
        allOf(
          lessThan(CompressQuality.low.imageQuality),
          greaterThan(CompressQuality.high.imageQuality),
        ),
      );
    });

    test("every preset stays within the engine's 1-100 range", () {
      for (final quality in CompressQuality.values) {
        expect(quality.imageQuality, inInclusiveRange(1, 100));
      }
    });
  });

  test('every preset exposes non-empty title/hint keys', () {
    for (final quality in CompressQuality.values) {
      expect(quality.titleKey, isNotEmpty);
      expect(quality.hintKey, isNotEmpty);
    }
  });
}
