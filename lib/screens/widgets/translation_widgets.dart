import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hacki/cubits/translation/translation_cubit.dart';
import 'package:hacki/cubits/translation/translation_state.dart';
import 'package:hacki/extensions/context_extension.dart';
import 'package:hacki/l10n/l10n.dart';
import 'package:hacki/models/translation/translation_models.dart';
import 'package:hacki/styles/styles.dart';
import 'package:material_ui/material_ui.dart';

String translationProviderName(TranslationProviderType type) => switch (type) {
  TranslationProviderType.azure => L10n.current.translationAzureName,
  TranslationProviderType.openAi => L10n.current.translationOpenAiName,
};

/// Rebuilds its child with the translated text when a translation is visible.
///
/// If no [TranslationCubit] is available (for example in isolated widget
/// tests), the original text is rendered unchanged.
class TranslationAwareText extends StatelessWidget {
  const TranslationAwareText({
    required this.translationKey,
    required this.originalText,
    required this.builder,
    super.key,
  });

  final String translationKey;
  final String originalText;
  final Widget Function(BuildContext context, String text) builder;

  @override
  Widget build(BuildContext context) {
    final TranslationCubit? cubit = context.tryRead<TranslationCubit>();
    if (cubit == null) return builder(context, originalText);
    return BlocBuilder<TranslationCubit, TranslationState>(
      buildWhen: (TranslationState previous, TranslationState current) {
        final TranslationEntry? a = previous.entryFor(translationKey);
        final TranslationEntry? b = current.entryFor(translationKey);
        return a?.translated != b?.translated ||
            a?.showOriginal != b?.showOriginal ||
            a?.status != b?.status;
      },
      builder: (BuildContext context, TranslationState state) =>
          builder(context, state.displayText(translationKey, originalText)),
    );
  }
}

class TranslationToggleButton extends StatelessWidget {
  const TranslationToggleButton({
    required this.translationKey,
    required this.text,
    super.key,
  });

  final String translationKey;
  final String text;

  @override
  Widget build(BuildContext context) {
    final TranslationCubit? cubit = context.tryRead<TranslationCubit>();
    if (cubit == null) return const SizedBox.shrink();
    return BlocBuilder<TranslationCubit, TranslationState>(
      buildWhen: (TranslationState previous, TranslationState current) {
        final TranslationEntry? a = previous.entryFor(translationKey);
        final TranslationEntry? b = current.entryFor(translationKey);
        return a?.status != b?.status ||
            a?.showOriginal != b?.showOriginal ||
            a?.translated != b?.translated ||
            previous.settings.defaultProvider !=
                current.settings.defaultProvider ||
            previous.hasAzureKey != current.hasAzureKey ||
            previous.hasOpenAiKey != current.hasOpenAiKey ||
            previous.isLoadingSettings != current.isLoadingSettings;
      },
      builder: (BuildContext context, TranslationState state) {
        if (state.isLoadingSettings) return const SizedBox.shrink();
        final TranslationProviderType provider = state.settings.defaultProvider;
        if (!state.settings.isEnabled(provider)) {
          return const SizedBox.shrink();
        }
        final TranslationEntry? entry = state.entryFor(translationKey);
        if (entry?.status == TranslationEntryStatus.loading) {
          return const Padding(
            padding: EdgeInsets.all(Dimens.pt6),
            child: SizedBox(
              width: Dimens.pt16,
              height: Dimens.pt16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        final bool translated = entry?.hasTranslation ?? false;
        final bool showingTranslation =
            translated && entry != null && !entry.showOriginal;
        return IconButton(
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.all(Dimens.pt4),
          constraints: const BoxConstraints(
            minWidth: Dimens.pt32,
            minHeight: Dimens.pt32,
          ),
          tooltip: showingTranslation
              ? L10n.current.translationShowOriginal
              : L10n.current.translationTranslate,
          icon: Icon(
            showingTranslation ? Icons.article_outlined : Icons.translate,
            size: Dimens.pt18,
            color: entry?.status == TranslationEntryStatus.failure
                ? Theme.of(context).colorScheme.error
                : null,
          ),
          onPressed: () => _onPressed(context, cubit, state, entry, provider),
        );
      },
    );
  }

  Future<void> _onPressed(
    BuildContext context,
    TranslationCubit cubit,
    TranslationState state,
    TranslationEntry? entry,
    TranslationProviderType provider,
  ) async {
    if (entry?.hasTranslation ?? false) {
      cubit.toggle(translationKey);
      return;
    }

    if (!state.isAcknowledged(provider)) {
      final bool? accepted = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: Text(L10n.current.translationDataSharingTitle),
          content: Text(
            L10n.current.translationDataSharingBody(
              translationProviderName(provider),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(L10n.current.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(L10n.current.translationContinue),
            ),
          ],
        ),
      );
      if (accepted != true) return;
      await cubit.acknowledgeDataSharing(provider);
      if (!context.mounted) return;
    }

    try {
      await cubit.translate(key: translationKey, text: text);
    } on TranslationException catch (error) {
      if (!context.mounted) return;
      context.showErrorSnackBar(error.localizedMessage);
    } catch (_) {
      if (!context.mounted) return;
      context.showErrorSnackBar(L10n.current.translationErrorUnknown);
    }
  }
}
