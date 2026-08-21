import 'package:doclyvo/app/constants/responsive_constants.dart';
import 'package:doclyvo/app/extensions/build_context_extension.dart';
import 'package:doclyvo/app/theme/theme_service.dart';
import 'package:doclyvo/core/utils/constants/app_insets.dart';
import 'package:doclyvo/core/utils/constants/sizes.dart';
import 'package:doclyvo/generated/localization/lang/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

part 'home_header/_nav_link.dart';
part 'home_header/_nav_links.dart';
part 'home_header/_theme_toggle_button.dart';
part 'home_header/_wordmark.dart';

/// Sticky top bar of the home screen, in three tiers.
///
/// `design/Main.dc.html` and `design/MobileHome.dc.html` only draw the two ends
/// of the range: a wide header with five centered nav links, and a phone header
/// with just the logo and the theme toggle. Between them — roughly 700px to
/// 1080px, a resized desktop window or a landscape tablet — the desktop branch
/// used to render its nav links into a box too narrow for them and overflow, so
/// there is a middle tier: desktop paddings and type, mobile's slimmed-down
/// contents.
final class HomeHeader extends StatelessWidget {
  const HomeHeader({
    required this.tier,
    required this.themeService,
    super.key,
  });

  final ScreenTier tier;
  final ThemeService themeService;

  @override
  Widget build(BuildContext context) {
    final isMobile = tier == ScreenTier.mobile;
    // Nav links only fit the full desktop header; the tablet tier keeps the
    // slimmed-down contents, same as mobile.
    final showNavLinks = tier == ScreenTier.desktop;

    return Container(
      padding: isMobile
          ? AppInsets.symmetricH16.add(AppInsets.symmetricV12)
          : AppInsets.symmetricH24.add(
              const EdgeInsets.symmetric(vertical: Sizes.md + Sizes.xs),
            ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.surfaceBorderColor)),
      ),
      child: Row(
        children: [
          _Wordmark(isMobile: isMobile),
          if (showNavLinks) ...[
            const Spacer(),
            const _NavLinks(),
          ],
          const Spacer(),
          _ThemeToggleButton(themeService: themeService),
        ],
      ),
    );
  }
}
