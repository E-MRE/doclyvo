// Covers PasswordGenerator: output length matches PasswordGenerator.length,
// every character comes from PasswordGenerator.charset, the charset excludes
// the visually ambiguous characters, an injected seeded Random makes the
// output reproducible, and Random.secure() output is not a constant.

import 'dart:math';

import 'package:doclyvo/features/protect/domain/services/password_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('generate() returns a string of PasswordGenerator.length characters', () {
    const generator = PasswordGenerator();

    final password = generator.generate();

    expect(password.length, PasswordGenerator.length);
  });

  test('every character is drawn from PasswordGenerator.charset', () {
    const generator = PasswordGenerator();

    final password = generator.generate();

    for (final char in password.split('')) {
      expect(PasswordGenerator.charset.contains(char), isTrue);
    }
  });

  test('the charset excludes the visually ambiguous characters', () {
    for (final ambiguous in const ['0', 'O', 'I', 'l', '1']) {
      expect(PasswordGenerator.charset.contains(ambiguous), isFalse);
    }
  });

  test('an injected seeded Random makes the output reproducible', () {
    final first = PasswordGenerator(Random(42)).generate();
    final second = PasswordGenerator(Random(42)).generate();

    expect(first, second);
  });

  test('two successive generate() calls with Random.secure() differ', () {
    const generator = PasswordGenerator();

    final first = generator.generate();
    final second = generator.generate();

    expect(first, isNot(second));
  });
}
