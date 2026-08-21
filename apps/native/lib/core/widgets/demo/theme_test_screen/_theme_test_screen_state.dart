part of '../theme_test_screen.dart';

final class _ThemeTestScreenState extends State<ThemeTestScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Theme Test'),
      ),
      body: SingleChildScrollView(
        padding: AppInsets.all16,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Display Large',
              style: theme.textTheme.displayLarge,
            ),
            const SizedBox(height: Sizes.md),
            Text(
              'Heading 1',
              style: theme.textTheme.headlineLarge,
            ),
            const SizedBox(height: Sizes.md),
            Text(
              'Heading 2',
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: Sizes.md),
            Text(
              'Body text should appear here with regular weight and size',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: Sizes.lg),
            Text(
              'Colors',
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: Sizes.md),
            Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(Sizes.radiusCard),
                  ),
                  child: Center(
                    child: Text(
                      'Primary',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: Sizes.md),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    border: Border.all(
                      color: theme.colorScheme.outline,
                    ),
                    borderRadius: BorderRadius.circular(Sizes.radiusCard),
                  ),
                  child: Center(
                    child: Text(
                      'Surface',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Sizes.lg),
            Text(
              'Card Example',
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: Sizes.md),
            Card(
              child: Padding(
                padding: AppInsets.all16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'This is a card',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: Sizes.md),
                    ElevatedButton(
                      onPressed: () {},
                      child: const Text('Button'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
