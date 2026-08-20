import 'package:doclyvo/app/constants/route_constants.dart';
import 'package:doclyvo/app/utils/builders/transition_page_builder.dart';
import 'package:doclyvo/app/widgets/placeholder_screen.dart';
import 'package:go_router/go_router.dart';

final router = GoRouter(
  routes: [
    GoRoute(
      path: RouteConstants.home,
      pageBuilder: (_, _) => TransitionPageBuilder.fadeTransition(
        child: const PlaceholderScreen(title: 'Home'),
      ),
    ),
    GoRoute(
      path: RouteConstants.compress,
      pageBuilder: (_, _) => TransitionPageBuilder.fadeTransition(
        child: const PlaceholderScreen(title: 'Compress'),
      ),
    ),
    GoRoute(
      path: RouteConstants.merge,
      pageBuilder: (_, _) => TransitionPageBuilder.fadeTransition(
        child: const PlaceholderScreen(title: 'Merge'),
      ),
    ),
    GoRoute(
      path: RouteConstants.split,
      pageBuilder: (_, _) => TransitionPageBuilder.fadeTransition(
        child: const PlaceholderScreen(title: 'Split'),
      ),
    ),
    GoRoute(
      path: RouteConstants.rotate,
      pageBuilder: (_, _) => TransitionPageBuilder.fadeTransition(
        child: const PlaceholderScreen(title: 'Rotate'),
      ),
    ),
    GoRoute(
      path: RouteConstants.reorder,
      pageBuilder: (_, _) => TransitionPageBuilder.fadeTransition(
        child: const PlaceholderScreen(title: 'Reorder'),
      ),
    ),
    GoRoute(
      path: RouteConstants.watermark,
      pageBuilder: (_, _) => TransitionPageBuilder.fadeTransition(
        child: const PlaceholderScreen(title: 'Watermark'),
      ),
    ),
    GoRoute(
      path: RouteConstants.protect,
      pageBuilder: (_, _) => TransitionPageBuilder.fadeTransition(
        child: const PlaceholderScreen(title: 'Protect'),
      ),
    ),
    GoRoute(
      path: RouteConstants.sign,
      pageBuilder: (_, _) => TransitionPageBuilder.fadeTransition(
        child: const PlaceholderScreen(title: 'Sign'),
      ),
    ),
    GoRoute(
      path: RouteConstants.ocr,
      pageBuilder: (_, _) => TransitionPageBuilder.fadeTransition(
        child: const PlaceholderScreen(title: 'OCR'),
      ),
    ),
    GoRoute(
      path: RouteConstants.pdfToWord,
      pageBuilder: (_, _) => TransitionPageBuilder.fadeTransition(
        child: const PlaceholderScreen(title: 'PDF to Word'),
      ),
    ),
    GoRoute(
      path: RouteConstants.redact,
      pageBuilder: (_, _) => TransitionPageBuilder.fadeTransition(
        child: const PlaceholderScreen(title: 'Redact'),
      ),
    ),
  ],
);
