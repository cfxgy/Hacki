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

String translationErrorMessage(TranslationErrorType type) => switch (type) {
  TranslationErrorType.invalidConfiguration =>
    L10n.current.translationErrorConfiguration,
  TranslationErrorType.authentication =>
    L10n.current.translationErrorAuthentication,
  TranslationErrorType.permission => L10n.current.translationErrorPermission,
  TranslationErrorType.rateLimited => L10n.current.translationErrorRateLimited,
  TranslationErrorType.network => L10n.current.translationErrorNetwork,
  TranslationErrorType.server => L10n.current.translationErrorServer,
  TranslationErrorType.parsing => L10n.current.translationErrorParsing,
  TranslationErrorType.contentRejected => L10n.current.translationErrorContent,
  TranslationErrorType.unknown => L10n.current.translationErrorUnknown,
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
    this.autoTranslate = false,
    super.key,
  });

  final String translationKey;
  final String originalText;
  final Widget Function(BuildContext context, String text) builder;
  final bool autoTranslate;

  @override
  Widget build(BuildContext context) {
    final TranslationCubit? cubit = context.tryRead<TranslationCubit>();
    if (cubit == null) return builder(context, originalText);
    final Widget child = BlocBuilder<TranslationCubit, TranslationState>(
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
    if (!autoTranslate) return child;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        AutoTranslationRequest(
          translationKey: translationKey,
          text: originalText,
        ),
        child,
      ],
    );
  }
}

/// Schedules a translation for content that is actually mounted. It does
/// nothing unless automatic translation, provider configuration and the
/// privacy acknowledgement are all in place.
class AutoTranslationRequest extends StatefulWidget {
  const AutoTranslationRequest({
    required this.translationKey,
    required this.text,
    super.key,
  });

  final String translationKey;
  final String text;

  @override
  State<AutoTranslationRequest> createState() => _AutoTranslationRequestState();
}

class _AutoTranslationRequestState extends State<AutoTranslationRequest> {
  String? _scheduledText;

  @override
  void didUpdateWidget(AutoTranslationRequest oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.translationKey != widget.translationKey ||
        oldWidget.text != widget.text) {
      _scheduledText = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final TranslationCubit? cubit = context.tryRead<TranslationCubit>();
    if (cubit == null) return const SizedBox.shrink();
    return BlocBuilder<TranslationCubit, TranslationState>(
      buildWhen: (TranslationState previous, TranslationState current) {
        final TranslationEntry? a = previous.entryFor(widget.translationKey);
        final TranslationEntry? b = current.entryFor(widget.translationKey);
        return a?.status != b?.status ||
            previous.canAutoTranslate != current.canAutoTranslate;
      },
      builder: (BuildContext context, TranslationState state) {
        final TranslationEntry? entry = state.entryFor(widget.translationKey);
        final bool needsTranslation =
            entry == null || entry.status == TranslationEntryStatus.idle;
        if (state.canAutoTranslate &&
            needsTranslation &&
            _scheduledText != widget.text) {
          _scheduledText = widget.text;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            cubit.queueAutoTranslate(
              key: widget.translationKey,
              text: widget.text,
            );
          });
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class TranslationPageActions extends StatelessWidget {
  const TranslationPageActions({required this.itemId, super.key});

  final int itemId;

  @override
  Widget build(BuildContext context) {
    final TranslationCubit? cubit = context.tryRead<TranslationCubit>();
    if (cubit == null) return const SizedBox.shrink();
    return BlocBuilder<TranslationCubit, TranslationState>(
      buildWhen: (TranslationState previous, TranslationState current) =>
          previous.entries != current.entries,
      builder: (BuildContext context, TranslationState state) {
        final List<String> keys = state.entries.keys
            .where(
              (String key) =>
                  key.startsWith('comment_') ||
                  key == 'story_$itemId' ||
                  key == 'story_body_$itemId',
            )
            .where((String key) => state.entries[key]?.hasTranslation ?? false)
            .toList();
        if (keys.isEmpty) return const SizedBox.shrink();
        return PopupMenuButton<String>(
          icon: const Icon(Icons.language),
          tooltip: L10n.current.translationPageActions,
          onSelected: (String action) {
            cubit.setAll(showOriginal: action == 'original', keys: keys);
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            PopupMenuItem<String>(
              value: 'original',
              child: Text(L10n.current.translationShowAllOriginal),
            ),
            PopupMenuItem<String>(
              value: 'translated',
              child: Text(L10n.current.translationRestoreAll),
            ),
          ],
        );
      },
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
          tooltip: entry?.status == TranslationEntryStatus.failure
              ? translationErrorMessage(
                  entry?.errorType ?? TranslationErrorType.unknown,
                )
              : showingTranslation
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
