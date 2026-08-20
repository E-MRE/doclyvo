import 'package:flutter/material.dart';

import 'sizes.dart';

final class AppInsets {
  const AppInsets._();

  // Symmetric horizontal/vertical
  static const EdgeInsets symmetricH4 = EdgeInsets.symmetric(horizontal: Sizes.xs);
  static const EdgeInsets symmetricH8 = EdgeInsets.symmetric(horizontal: Sizes.sm);
  static const EdgeInsets symmetricH12 = EdgeInsets.symmetric(horizontal: Sizes.md);
  static const EdgeInsets symmetricH16 = EdgeInsets.symmetric(horizontal: Sizes.lg);
  static const EdgeInsets symmetricH24 = EdgeInsets.symmetric(horizontal: Sizes.xl);
  static const EdgeInsets symmetricH32 = EdgeInsets.symmetric(horizontal: Sizes.xxl);

  static const EdgeInsets symmetricV4 = EdgeInsets.symmetric(vertical: Sizes.xs);
  static const EdgeInsets symmetricV8 = EdgeInsets.symmetric(vertical: Sizes.sm);
  static const EdgeInsets symmetricV12 = EdgeInsets.symmetric(vertical: Sizes.md);
  static const EdgeInsets symmetricV16 = EdgeInsets.symmetric(vertical: Sizes.lg);
  static const EdgeInsets symmetricV24 = EdgeInsets.symmetric(vertical: Sizes.xl);
  static const EdgeInsets symmetricV32 = EdgeInsets.symmetric(vertical: Sizes.xxl);

  // All sides
  static const EdgeInsets all4 = EdgeInsets.all(Sizes.xs);
  static const EdgeInsets all8 = EdgeInsets.all(Sizes.sm);
  static const EdgeInsets all12 = EdgeInsets.all(Sizes.md);
  static const EdgeInsets all16 = EdgeInsets.all(Sizes.lg);
  static const EdgeInsets all24 = EdgeInsets.all(Sizes.xl);
  static const EdgeInsets all32 = EdgeInsets.all(Sizes.xxl);

  // Only sides
  static const EdgeInsets onlyLeft4 = EdgeInsets.only(left: Sizes.xs);
  static const EdgeInsets onlyLeft8 = EdgeInsets.only(left: Sizes.sm);
  static const EdgeInsets onlyLeft16 = EdgeInsets.only(left: Sizes.lg);

  static const EdgeInsets onlyRight4 = EdgeInsets.only(right: Sizes.xs);
  static const EdgeInsets onlyRight8 = EdgeInsets.only(right: Sizes.sm);
  static const EdgeInsets onlyRight16 = EdgeInsets.only(right: Sizes.lg);

  static const EdgeInsets onlyTop4 = EdgeInsets.only(top: Sizes.xs);
  static const EdgeInsets onlyTop8 = EdgeInsets.only(top: Sizes.sm);
  static const EdgeInsets onlyTop16 = EdgeInsets.only(top: Sizes.lg);

  static const EdgeInsets onlyBottom4 = EdgeInsets.only(bottom: Sizes.xs);
  static const EdgeInsets onlyBottom8 = EdgeInsets.only(bottom: Sizes.sm);
  static const EdgeInsets onlyBottom16 = EdgeInsets.only(bottom: Sizes.lg);
}
