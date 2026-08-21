import 'package:doclyvo/app/widgets/buttons/primary_button.dart';
import 'package:doclyvo/app/widgets/buttons/secondary_button.dart';
import 'package:doclyvo/app/widgets/cards/app_card.dart';
import 'package:doclyvo/app/widgets/errors/base_error_container.dart';
import 'package:doclyvo/app/widgets/inputs/app_text_field.dart';
import 'package:doclyvo/core/utils/constants/app_insets.dart';
import 'package:doclyvo/core/utils/constants/sizes.dart';
import 'package:flutter/material.dart';

final class BaseWidgetsTestScreen extends StatelessWidget {
  const BaseWidgetsTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Base Widgets Test')),
      body: SingleChildScrollView(
        padding: AppInsets.all16,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PrimaryButton(label: 'Primary', onPressed: () {}),
            const SizedBox(height: Sizes.md),
            const PrimaryButton(label: 'Disabled', onPressed: null),
            const SizedBox(height: Sizes.md),
            SecondaryButton(label: 'Secondary', onPressed: () {}),
            const SizedBox(height: Sizes.lg),
            const AppCard(
              child: Text('This is an AppCard'),
            ),
            const SizedBox(height: Sizes.lg),
            const AppTextField(labelText: 'Label', hintText: 'Hint'),
            const SizedBox(height: Sizes.lg),
            BaseErrorContainer(
              message: 'Bir hata oluştu',
              buttonText: 'Tekrar Dene',
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}
