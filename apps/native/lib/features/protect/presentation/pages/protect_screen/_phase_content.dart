part of '../protect_screen.dart';

/// The settings-panel content, switched on [ProtectState] — mirrors
/// `design/Protect.dc.html`'s `isIdle`/`isProcessing`/`isDone` branches, plus
/// an `Error` branch the design doesn't draw but every tool screen needs.
final class _PhaseContent extends StatelessWidget {
  const _PhaseContent({
    required this.tier,
    required this.state,
    required this.selectedFile,
    required this.passwordController,
    required this.isRevealed,
    required this.isPasswordLongEnough,
    required this.permissions,
    required this.canStart,
    required this.onPasswordChanged,
    required this.onToggleReveal,
    required this.onGeneratePassword,
    required this.onTogglePermission,
    required this.onStart,
    required this.onRetry,
    required this.onDownload,
    required this.onReset,
  });

  final ScreenTier tier;
  final ProtectState state;
  final PickedPdfFile? selectedFile;
  final TextEditingController passwordController;
  final bool isRevealed;
  final bool isPasswordLongEnough;
  final Set<ProtectPermission> permissions;
  final bool canStart;
  final ValueChanged<String> onPasswordChanged;
  final VoidCallback onToggleReveal;
  final VoidCallback onGeneratePassword;
  final ValueChanged<ProtectPermission> onTogglePermission;
  final VoidCallback onStart;
  final VoidCallback onRetry;
  final ValueChanged<Uint8List> onDownload;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (selectedFile == null) {
      return Text(
        LocaleKeys.protect_selectFileFirst.tr(),
        style: theme.textTheme.bodyMedium?.copyWith(
          color: context.textSoftColor,
        ),
      );
    }

    final currentState = state;
    if (currentState is ProtectLoading) {
      return ToolProgressIndicator(
        // `pdf_manipulator`'s `encrypt` exposes no progress callback (same as
        // every other Phase 3A operation, per the P0-11 Decisions log entry),
        // so this is an indeterminate/simulated state.
        progress: 60,
        label: LocaleKeys.protect_processingLabel.tr(),
        tier: tier,
      );
    }

    if (currentState is ProtectSuccess) {
      return ResultPanel(
        message: LocaleKeys.protect_resultMessage.tr(
          namedArgs: {'fileName': selectedFile!.name},
        ),
        fileName: 'protected.pdf',
        pageCount: currentState.pageCount,
        onDownload: () => onDownload(currentState.protectedBytes),
        secondaryActionLabel: LocaleKeys.protect_newOperation.tr(),
        onSecondaryAction: onReset,
        tier: tier,
      );
    }

    if (currentState is ProtectError) {
      return ErrorStateWidget(
        message: currentState.message,
        onRetry: onRetry,
        tier: tier,
      );
    }

    // ProtectInitial: password + permission settings and the start action,
    // matching the design's `isIdle` branch.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _SectionLabel(label: LocaleKeys.protect_passwordSectionTitle.tr()),
        const SizedBox(height: Sizes.sm),
        TextField(
          controller: passwordController,
          onChanged: onPasswordChanged,
          obscureText: !isRevealed,
          autocorrect: false,
          enableSuggestions: false,
          style: const TextStyle(fontFamily: 'monospace', letterSpacing: 1.5),
          decoration: InputDecoration(
            hintText: LocaleKeys.protect_passwordFieldHint.tr(),
            suffixIcon: IconButton(
              tooltip: LocaleKeys.protect_passwordRevealToggle.tr(),
              icon: Icon(
                isRevealed ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: onToggleReveal,
            ),
          ),
        ),
        if (!isPasswordLongEnough) ...[
          const SizedBox(height: Sizes.sm),
          Text(
            LocaleKeys.protect_passwordTooShort.tr(
              namedArgs: {'min': '${PasswordGenerator.minimumLength}'},
            ),
            style: theme.textTheme.labelMedium?.copyWith(
              color: context.textSoftColor,
            ),
          ),
        ],
        const SizedBox(height: Sizes.md),
        Align(
          alignment: Alignment.centerLeft,
          child: SecondaryButton(
            label: LocaleKeys.protect_passwordGenerate.tr(),
            onPressed: onGeneratePassword,
          ),
        ),
        const SizedBox(height: Sizes.xl),
        _SectionLabel(label: LocaleKeys.protect_permissionsSectionTitle.tr()),
        const SizedBox(height: Sizes.sm),
        for (final permission in ProtectPermission.values) ...[
          _PermissionCheckRow(
            label: permission.labelKey.tr(),
            isChecked: permissions.contains(permission),
            onTap: () => onTogglePermission(permission),
          ),
          const SizedBox(height: Sizes.sm),
        ],
        const SizedBox(height: Sizes.lg),
        SizedBox(
          width: double.infinity,
          child: PrimaryButton(
            label: LocaleKeys.protect_startAction.tr(),
            onPressed: canStart ? onStart : null,
          ),
        ),
      ],
    );
  }
}

/// The uppercase section caption above each settings group ("Şifre",
/// "İzinler") — same treatment the Watermark panel gives its section titles.
final class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: context.textSoftColor,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// One full-width permission row from the design: a square checkbox plus its
/// label, the whole row tappable and outlined in the accent color when the
/// restriction is on.
///
/// Not Material's `CheckboxListTile` — the design's row is a bordered card
/// whose border colour is the primary "on" signal, which that widget cannot
/// express without fighting its own theming.
final class _PermissionCheckRow extends StatelessWidget {
  const _PermissionCheckRow({
    required this.label,
    required this.isChecked,
    required this.onTap,
  });

  final String label;
  final bool isChecked;
  final VoidCallback onTap;

  static const double _boxSize = 18;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: AppInsets.symmetricH16.add(AppInsets.symmetricV12),
        decoration: BoxDecoration(
          color: isChecked ? context.accentSoftColor : null,
          borderRadius: BorderRadius.circular(Sizes.radiusButton),
          border: Border.all(
            color: isChecked ? accent : context.surfaceBorderColor,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: _boxSize,
              height: _boxSize,
              decoration: BoxDecoration(
                color: isChecked ? accent : null,
                borderRadius: BorderRadius.circular(Sizes.xs),
                border: Border.all(
                  color: isChecked ? accent : context.surfaceBorderColor,
                  width: 2,
                ),
              ),
              child: isChecked
                  ? Icon(
                      Icons.check,
                      size: _boxSize - 4,
                      color: theme.colorScheme.onPrimary,
                    )
                  : null,
            ),
            const SizedBox(width: Sizes.md),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
