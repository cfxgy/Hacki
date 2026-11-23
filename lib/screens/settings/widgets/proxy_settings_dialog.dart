import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/extensions/extensions.dart';
import 'package:hacki/l10n/l10n.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/styles/styles.dart';
import 'package:hacki/utils/utils.dart';
import 'package:material_ui/material_ui.dart';

/// Lets the user choose the proxy every connection of the app goes through.
class ProxySettingsDialog extends StatefulWidget {
  const ProxySettingsDialog({super.key});

  @override
  State<ProxySettingsDialog> createState() => _ProxySettingsDialogState();
}

class _ProxySettingsDialogState extends State<ProxySettingsDialog> {
  final TextEditingController _hostController = TextEditingController();
  final TextEditingController _portController = TextEditingController();
  bool _isEnabled = false;
  bool _isSaving = false;
  String? _hostError;
  String? _portError;

  @override
  void initState() {
    super.initState();

    final NetworkProxy proxy = context.read<NetworkProxyCubit>().state.proxy;
    _isEnabled = proxy.isEnabled;
    _hostController.text = proxy.host;
    _portController.text = proxy.port?.toString() ?? '';
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).colorScheme.primary;

    return AlertDialog(
      title: Text(L10n.current.proxy),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(L10n.current.useProxy),
              value: _isEnabled,
              activeThumbColor: primaryColor,
              onChanged: (bool val) {
                HapticFeedbackUtils.light();
                setState(() {
                  _isEnabled = val;
                  _hostError = null;
                  _portError = null;
                });
              },
            ),
            TextField(
              controller: _hostController,
              cursorColor: primaryColor,
              autocorrect: false,
              enableSuggestions: false,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: L10n.current.host,
                hintText: '127.0.0.1',
                errorText: _hostError,
              ),
            ),
            SizedBoxes.pt12,
            TextField(
              controller: _portController,
              cursorColor: primaryColor,
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(5),
              ],
              onSubmitted: (_) => _onSaveTapped(),
              decoration: InputDecoration(
                labelText: L10n.current.port,
                hintText: '8080',
                errorText: _portError,
              ),
            ),
            SizedBoxes.pt16,
            Text(
              L10n.current.proxyDescription,
              style: const TextStyle(
                color: Palette.grey,
                fontSize: TextDimens.pt12,
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(onPressed: context.pop, child: Text(L10n.current.cancel)),
        TextButton(
          onPressed: _isSaving ? null : _onSaveTapped,
          child: Text(L10n.current.save),
        ),
      ],
    );
  }

  Future<void> _onSaveTapped() async {
    final String host = NetworkProxy.normalizeHost(_hostController.text);
    final int? port = int.tryParse(_portController.text.trim());

    if (_isEnabled) {
      final String? hostError = NetworkProxy.isValidHost(host)
          ? null
          : L10n.current.proxyHostError;
      final String? portError = NetworkProxy.isValidPort(port)
          ? null
          : L10n.current.proxyPortError('${NetworkProxy.maxPort}');

      if (hostError != null || portError != null) {
        setState(() {
          _hostError = hostError;
          _portError = portError;
        });
        return;
      }
    }

    setState(() => _isSaving = true);

    final NetworkProxyCubit cubit = context.read<NetworkProxyCubit>();
    await cubit.update(
      NetworkProxy(isEnabled: _isEnabled, host: host, port: port),
    );

    if (!mounted) return;

    HapticFeedbackUtils.success();
    final NetworkProxyState state = cubit.state;
    context
      ..pop()
      ..showSnackBar(
        content: !state.proxy.isActive
            ? L10n.current.proxyOff
            : state.isAppliedToWebViews
            ? L10n.current.proxyOn(state.proxy.address)
            : L10n.current.proxyOnExceptWebViews(state.proxy.address),
      );
  }
}
