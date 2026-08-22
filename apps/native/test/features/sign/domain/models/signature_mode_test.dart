// Covers SignatureMode: the three modes the design's tabs need, in the same
// order as apps/web's SignMode, each carrying a distinct non-empty LocaleKeys
// entry so no tab can ship with a raw or duplicated label.

import 'package:doclyvo/features/sign/domain/models/signature_mode.dart';
import 'package:doclyvo/generated/localization/lang/locale_keys.g.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('exposes exactly draw, type and upload, in the design order', () {
    expect(SignatureMode.values, const [
      SignatureMode.draw,
      SignatureMode.type,
      SignatureMode.upload,
    ]);
  });

  test('each mode maps to its LocaleKeys label entry', () {
    expect(SignatureMode.draw.labelKey, LocaleKeys.sign_modeDraw);
    expect(SignatureMode.type.labelKey, LocaleKeys.sign_modeType);
    expect(SignatureMode.upload.labelKey, LocaleKeys.sign_modeUpload);
  });

  test('every label key is non-empty and unique', () {
    final keys = SignatureMode.values.map((mode) => mode.labelKey).toList();

    for (final key in keys) {
      expect(key, isNotEmpty);
    }
    expect(keys.toSet(), hasLength(SignatureMode.values.length));
  });
}
