import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hacki/cubits/translation/translation_cubit.dart';
import 'package:hacki/cubits/translation/translation_state.dart';
import 'package:hacki/extensions/context_extension.dart';
import 'package:hacki/l10n/l10n.dart';
import 'package:hacki/models/translation/translation_models.dart';
import 'package:hacki/styles/styles.dart';
import 'package:material_ui/material_ui.dart';

class TranslationSettingsScreen extends StatefulWidget {
  const TranslationSettingsScreen({super.key});

  @override
  State<TranslationSettingsScreen> createState() =>
      _TranslationSettingsScreenState();
}

class _TranslationSettingsScreenState extends State<TranslationSettingsScreen> {
  final TextEditingController _azureRegion = TextEditingController();
  final TextEditingController _azureKey = TextEditingController();
  final TextEditingController _aiBaseUrl = TextEditingController();
  final TextEditingController _aiModel = TextEditingController();
  final TextEditingController _aiKey = TextEditingController();

  bool _seeded = false;
  bool _testingAzure = false;
  bool _testingAi = false;

  @override
  void dispose() {
    _azureRegion.dispose();
    _azureKey.dispose();
    _aiBaseUrl.dispose();
    _aiModel.dispose();
    _aiKey.dispose();
    super.dispose();
  }

  void _seed(TranslationState state) {
    if (_seeded) return;
    _seeded = true;
    _azureRegion.text = state.settings.azure.region;
    _aiBaseUrl.text = state.settings.openAi.baseUrl;
    _aiModel.text = state.settings.openAi.model;
  }

  Future<void> _saveAzure(TranslationCubit cubit) async {
    final TranslationSettings settings = cubit.state.settings;
    final String region = _azureRegion.text.trim();
    await cubit.saveSettings(
      settings.copyWith(
        azure: settings.azure.copyWith(region: region),
      ),
    );
    final String key = _azureKey.text.trim();
    if (key.isNotEmpty) {
      await cubit.saveAzureKey(key);
      _azureKey.clear();
    }
    if (mounted) {
      context.showSnackBar(content: L10n.current.translationSettingsSaved);
    }
  }

  Future<void> _saveAi(TranslationCubit cubit) async {
    final TranslationSettings settings = cubit.state.settings;
    await cubit.saveSettings(
      settings.copyWith(
        openAi: settings.openAi.copyWith(
          baseUrl: _aiBaseUrl.text.trim(),
          model: _aiModel.text.trim(),
        ),
      ),
    );
    final String key = _aiKey.text.trim();
    if (key.isNotEmpty) {
      await cubit.saveOpenAiKey(key);
      _aiKey.clear();
    }
    if (mounted) {
      context.showSnackBar(content: L10n.current.translationSettingsSaved);
    }
  }

  Future<void> _testAzure(TranslationCubit cubit) async {
    setState(() => _testingAzure = true);
    try {
      final TranslationResult result = await cubit.testAzure(
        region: _azureRegion.text.trim(),
        apiKey: _azureKey.text.trim(),
      );
      if (mounted) {
        context.showSnackBar(
          content: L10n.current.translationConnectionSuccess(result.text),
        );
      }
    } on TranslationException catch (error) {
      if (mounted) context.showErrorSnackBar(error.localizedMessage);
    } catch (_) {
      if (mounted) {
        context.showErrorSnackBar(L10n.current.translationErrorUnknown);
      }
    } finally {
      if (mounted) setState(() => _testingAzure = false);
    }
  }

  Future<void> _testAi(TranslationCubit cubit) async {
    setState(() => _testingAi = true);
    try {
      final TranslationResult result = await cubit.testOpenAi(
        baseUrl: _aiBaseUrl.text.trim(),
        model: _aiModel.text.trim(),
        apiKey: _aiKey.text.trim(),
      );
      if (mounted) {
        context.showSnackBar(
          content: L10n.current.translationConnectionSuccess(result.text),
        );
      }
    } on TranslationException catch (error) {
      if (mounted) context.showErrorSnackBar(error.localizedMessage);
    } catch (_) {
      if (mounted) {
        context.showErrorSnackBar(L10n.current.translationErrorUnknown);
      }
    } finally {
      if (mounted) setState(() => _testingAi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TranslationCubit, TranslationState>(
      listener: (BuildContext context, TranslationState state) {
        if (!state.isLoadingSettings && !_seeded) {
          _seed(state);
          setState(() {});
        }
      },
      builder: (BuildContext context, TranslationState state) {
        if (state.isLoadingSettings) {
          return Scaffold(
            appBar: AppBar(title: Text(L10n.current.translationSettings)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (!_seeded) {
          _seed(state);
        }
        final TranslationCubit cubit = context.read<TranslationCubit>();
        return Scaffold(
          appBar: AppBar(title: Text(L10n.current.translationSettings)),
          body: ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: Dimens.pt16,
              vertical: Dimens.pt8,
            ),
            children: <Widget>[
              const _DisclosureCard(),
              const SizedBox(height: Dimens.pt12),
              _sectionTitle(context, L10n.current.translationLanguages),
              _languageDropdown(
                label: L10n.current.translationSourceLanguage,
                value: state.settings.sourceLanguage,
                options: const <String>[
                  TranslationSettings.sourceAuto,
                  TranslationSettings.sourceEnglish,
                  TranslationSettings.sourceSimplifiedChinese,
                ],
                onChanged: (String value) => cubit.saveSettings(
                  state.settings.copyWith(sourceLanguage: value),
                ),
              ),
              _languageDropdown(
                label: L10n.current.translationTargetLanguage,
                value: state.settings.targetLanguage,
                options: const <String>[
                  TranslationSettings.targetSimplifiedChinese,
                  TranslationSettings.targetEnglish,
                ],
                onChanged: (String value) => cubit.saveSettings(
                  state.settings.copyWith(targetLanguage: value),
                ),
              ),
              const Divider(),
              _sectionTitle(context, L10n.current.translationDefaultProvider),
              RadioGroup<TranslationProviderType>(
                groupValue: state.settings.defaultProvider,
                onChanged: (TranslationProviderType? provider) {
                  if (provider == null) return;
                  cubit.saveSettings(
                    state.settings.copyWith(defaultProvider: provider),
                  );
                },
                child: Column(
                  children: <Widget>[
                    RadioListTile<TranslationProviderType>(
                      value: TranslationProviderType.azure,
                      title: Text(L10n.current.translationAzureName),
                      subtitle: Text(
                        state.hasAzureKey
                            ? L10n.current.translationKeyStored
                            : L10n.current.translationKeyMissing,
                      ),
                    ),
                    RadioListTile<TranslationProviderType>(
                      value: TranslationProviderType.openAi,
                      title: Text(L10n.current.translationOpenAiName),
                      subtitle: Text(
                        state.hasOpenAiKey
                            ? L10n.current.translationKeyStored
                            : L10n.current.translationKeyMissing,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              _ProviderCard(
                title: L10n.current.translationAzureName,
                subtitle: L10n.current.translationAzureDescription,
                enabled: state.settings.azure.enabled,
                onEnabledChanged: (bool value) => cubit.saveSettings(
                  state.settings.copyWith(
                    azure: state.settings.azure.copyWith(enabled: value),
                  ),
                ),
                children: <Widget>[
                  TextField(
                    controller: _azureRegion,
                    autocorrect: false,
                    decoration: InputDecoration(
                      labelText: L10n.current.translationAzureRegion,
                      hintText: 'eastasia',
                    ),
                  ),
                  const SizedBox(height: Dimens.pt8),
                  TextField(
                    controller: _azureKey,
                    obscureText: true,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: InputDecoration(
                      labelText: L10n.current.translationApiKey,
                      hintText: state.hasAzureKey
                          ? L10n.current.translationKeyStoredHint
                          : L10n.current.translationKeyEnterHint,
                    ),
                  ),
                  const SizedBox(height: Dimens.pt8),
                  _actionRow(
                    testing: _testingAzure,
                    onTest: () => _testAzure(cubit),
                    onSave: () => _saveAzure(cubit),
                    onClear: () async {
                      await cubit.clearAzureKey();
                      if (mounted) setState(() {});
                    },
                    showClear: state.hasAzureKey,
                  ),
                ],
              ),
              const SizedBox(height: Dimens.pt12),
              _ProviderCard(
                title: L10n.current.translationOpenAiName,
                subtitle: L10n.current.translationOpenAiDescription,
                enabled: state.settings.openAi.enabled,
                onEnabledChanged: (bool value) => cubit.saveSettings(
                  state.settings.copyWith(
                    openAi: state.settings.openAi.copyWith(enabled: value),
                  ),
                ),
                children: <Widget>[
                  TextField(
                    controller: _aiBaseUrl,
                    autocorrect: false,
                    keyboardType: TextInputType.url,
                    decoration: InputDecoration(
                      labelText: L10n.current.translationBaseUrl,
                      hintText: 'https://api.openai.com/v1',
                    ),
                  ),
                  const SizedBox(height: Dimens.pt8),
                  TextField(
                    controller: _aiModel,
                    autocorrect: false,
                    decoration: InputDecoration(
                      labelText: L10n.current.translationModel,
                      hintText: 'gpt-4o-mini',
                    ),
                  ),
                  const SizedBox(height: Dimens.pt8),
                  TextField(
                    controller: _aiKey,
                    obscureText: true,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: InputDecoration(
                      labelText: L10n.current.translationApiKey,
                      hintText: state.hasOpenAiKey
                          ? L10n.current.translationKeyStoredHint
                          : L10n.current.translationKeyEnterHint,
                    ),
                  ),
                  const SizedBox(height: Dimens.pt8),
                  _actionRow(
                    testing: _testingAi,
                    onTest: () => _testAi(cubit),
                    onSave: () => _saveAi(cubit),
                    onClear: () async {
                      await cubit.clearOpenAiKey();
                      if (mounted) setState(() {});
                    },
                    showClear: state.hasOpenAiKey,
                  ),
                ],
              ),
              const SizedBox(height: Dimens.pt24),
            ],
          ),
        );
      },
    );
  }

  Widget _sectionTitle(BuildContext context, String title) => Padding(
    padding: const EdgeInsets.only(top: Dimens.pt8, bottom: Dimens.pt4),
    child: Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    ),
  );

  Widget _languageDropdown({
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String> onChanged,
  }) {
    final String safeValue = options.contains(value) ? value : options.first;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Dimens.pt4),
      child: DropdownButtonFormField<String>(
        key: ValueKey<String>('$label-$safeValue'),
        initialValue: safeValue,
        decoration: InputDecoration(labelText: label),
        items: options
            .map(
              (String code) => DropdownMenuItem<String>(
                value: code,
                child: Text(_languageName(code)),
              ),
            )
            .toList(),
        onChanged: (String? next) {
          if (next != null) onChanged(next);
        },
      ),
    );
  }

  String _languageName(String code) => switch (code) {
    TranslationSettings.sourceAuto => L10n.current.translationAutoDetect,
    TranslationSettings.targetEnglish => L10n.current.translationEnglish,
    _ => L10n.current.translationSimplifiedChinese,
  };

  Widget _actionRow({
    required bool testing,
    required VoidCallback onTest,
    required VoidCallback onSave,
    required VoidCallback onClear,
    required bool showClear,
  }) => Wrap(
    spacing: Dimens.pt8,
    runSpacing: Dimens.pt4,
    children: <Widget>[
      OutlinedButton.icon(
        onPressed: testing ? null : onTest,
        icon: testing
            ? const SizedBox(
                width: Dimens.pt14,
                height: Dimens.pt14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.wifi_tethering),
        label: Text(
          testing
              ? L10n.current.translationTesting
              : L10n.current.translationTestConnection,
        ),
      ),
      FilledButton(
        onPressed: onSave,
        child: Text(L10n.current.save),
      ),
      if (showClear)
        TextButton(
          onPressed: onClear,
          child: Text(L10n.current.translationClearKey),
        ),
    ],
  );
}

class _DisclosureCard extends StatelessWidget {
  const _DisclosureCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(Dimens.pt12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(
              Icons.cloud_upload_outlined,
              color: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
            const SizedBox(width: Dimens.pt8),
            Expanded(
              child: Text(
                L10n.current.translationDataDisclosure,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProviderCard extends StatelessWidget {
  const _ProviderCard({
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onEnabledChanged,
    required this.children,
  });

  final String title;
  final String subtitle;
  final bool enabled;
  final ValueChanged<bool> onEnabledChanged;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.only(bottom: Dimens.pt12),
        child: Column(
          children: <Widget>[
            SwitchListTile(
              title: Text(title),
              subtitle: Text(subtitle),
              value: enabled,
              onChanged: onEnabledChanged,
            ),
            if (enabled)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Dimens.pt16),
                child: Column(children: children),
              ),
          ],
        ),
      ),
    );
  }
}
