// Covers SignaturePlacement's fraction -> points conversion, the one piece of
// Sign that has to stay byte-identical to apps/api's SignService._build_overlay
// and apps/web's PLACEMENT_BOX. The fractions measure `y` from the page top,
// PdfStampArea measures it from the bottom, and every assertion below pins the
// concrete numbers that flip produces so a silent sign-flip cannot slip in.

import 'package:doclyvo/features/sign/domain/models/signature_placement.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // A4 in PDF points, the same page size the web and api parity checks use.
  const a4Width = 595.276;
  const a4Height = 841.89;

  test('bottomRight carries the design box fractions unchanged', () {
    const placement = SignaturePlacement.bottomRight;

    expect(placement.x, 0.6);
    expect(placement.y, 0.78);
    expect(placement.width, 0.32);
    expect(placement.height, 0.1);
  });

  test('toStampArea converts the design box on an A4 page', () {
    final area = SignaturePlacement.bottomRight.toStampArea(
      pageWidth: a4Width,
      pageHeight: a4Height,
    );

    // 0.32 * 595.276 and 0.1 * 841.89.
    expect(area.width, closeTo(190.48832, 1e-6));
    expect(area.height, closeTo(84.189, 1e-6));
    // 0.6 * 595.276.
    expect(area.x, closeTo(357.1656, 1e-6));
    // 841.89 - 0.78 * 841.89 - 84.189.
    expect(area.y, closeTo(101.0268, 1e-6));
  });

  test('y is flipped from the top-origin fraction to a bottom-origin point', () {
    const placement = SignaturePlacement(
      x: 0,
      y: 0.25,
      width: 0.5,
      height: 0.5,
    );

    final area = placement.toStampArea(pageWidth: 100, pageHeight: 200);

    // Top edge at 50pt from the top, box 100pt tall => bottom edge 50pt up.
    expect(area.y, closeTo(50, 1e-9));
    expect(area.height, closeTo(100, 1e-9));
  });

  test('a full-page placement fills the page and sits at the origin', () {
    const placement = SignaturePlacement(x: 0, y: 0, width: 1, height: 1);

    final area = placement.toStampArea(
      pageWidth: a4Width,
      pageHeight: a4Height,
    );

    expect(area.x, 0);
    expect(area.y, closeTo(0, 1e-9));
    expect(area.width, a4Width);
    expect(area.height, a4Height);
  });

  test('a box flush with the page bottom converts to y == 0', () {
    // y (from top) + height == 1 means the box touches the bottom edge.
    const placement = SignaturePlacement(
      x: 0.1,
      y: 0.9,
      width: 0.2,
      height: 0.1,
    );

    final area = placement.toStampArea(pageWidth: 500, pageHeight: 1000);

    expect(area.y, closeTo(0, 1e-9));
  });

  test('a box flush with the page top converts to y == pageHeight - height', () {
    const placement = SignaturePlacement(
      x: 0,
      y: 0,
      width: 0.2,
      height: 0.1,
    );

    final area = placement.toStampArea(pageWidth: 500, pageHeight: 1000);

    expect(area.y, closeTo(900, 1e-9));
    expect(area.height, closeTo(100, 1e-9));
  });

  test('landscape and portrait pages of the same fractions differ', () {
    const placement = SignaturePlacement.bottomRight;

    final portrait = placement.toStampArea(
      pageWidth: a4Width,
      pageHeight: a4Height,
    );
    final landscape = placement.toStampArea(
      pageWidth: a4Height,
      pageHeight: a4Width,
    );

    expect(landscape.width, closeTo(a4Height * 0.32, 1e-6));
    expect(landscape.height, closeTo(a4Width * 0.1, 1e-6));
    expect(landscape.x, isNot(closeTo(portrait.x, 1)));
  });

  test('the converted box stays inside the page for the design fractions', () {
    final area = SignaturePlacement.bottomRight.toStampArea(
      pageWidth: a4Width,
      pageHeight: a4Height,
    );

    expect(area.x, greaterThanOrEqualTo(0));
    expect(area.y, greaterThanOrEqualTo(0));
    expect(area.x + area.width, lessThanOrEqualTo(a4Width));
    expect(area.y + area.height, lessThanOrEqualTo(a4Height));
  });
}
