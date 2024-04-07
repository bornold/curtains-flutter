import 'dart:async';

import 'package:curtains/datasource/bloc/curtains_cubit.dart';
import 'package:curtains/datasource/repositories/assets.dart';
import 'package:curtains/datasource/repositories/preferenses.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/connection_info.dart';

class ConnectionSettings extends StatefulWidget {
  static const connectionFailure = 'connection_failure',
      errorSessionDown = 'session is down',
      errorAuth = 'USERAUTH fail';

  const ConnectionSettings({this.error, super.key});
  final Object? error;
  @override
  State createState() => _ConnectionSettingsState();
}

class _ConnectionSettingsState extends State<ConnectionSettings> {
  String get _errorMessage {
    final error = widget.error;
    if (error is TimeoutException) {
      return 'timed out, wrong ip?';
    } else if (error is PlatformException &&
        error.code == ConnectionSettings.connectionFailure) {
      if (error.message == ConnectionSettings.errorAuth) {
        return 'wrong password';
      } else if (error.message == ConnectionSettings.errorSessionDown) {
        return 'lost connection';
      } else {
        debugPrint('$error');
        return 'connection error, wrong ip or port?';
      }
    } else {
      return error?.toString() ?? 'unknown error';
    }
  }

  final _passphraseController = TextEditingController();
  final _adressController = TextEditingController();
  final _portController = TextEditingController();
  final _nameController = TextEditingController();
  bool _hidePassphrase = true;
  bool autoconnect = true;
  final _formKey = GlobalKey<FormState>();
  String _passwordHintText = 'enter passphrase';
  String _passwordLabelText = 'passphrase';
  late String _storedPassphrase;

  @override
  void initState() {
    _setPrefs();
    super.initState();
  }

  void _setPrefs() async {
    final prefs = Preferences(await SharedPreferences.getInstance());
    _adressController.text = prefs.ip;
    _portController.text = '${prefs.port}';
    _nameController.text = prefs.username;
    _storedPassphrase = prefs.passphrase;
    if (_storedPassphrase.isEmpty) {
      setState(() {
        _passwordHintText = 'unchanged';
        _passwordLabelText = 'passphrase (empty for unchanged)';
      });
    }
  }

  @override
  void dispose() {
    _passphraseController.dispose();
    _adressController.dispose();
    _portController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('connection info')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Spacer(flex: 4),
              Text(
                _errorMessage,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.apply(color: Theme.of(context).colorScheme.error),
              ),
              const Spacer(flex: 4),
              Row(
                children: <Widget>[
                  Expanded(
                    flex: 30,
                    child: TextFormField(
                      validator: (s) {
                        if (s == null || s.isEmpty) return 'must enter adress';
                        if (Uri.tryParse(s) == null) {
                          return 'not a valid adress';
                        }
                        return null;
                      },
                      keyboardType: TextInputType.url,
                      controller: _adressController,
                      decoration: const InputDecoration(labelText: 'adress'),
                    ),
                  ),
                  const Spacer(flex: 1),
                  Expanded(
                    flex: 12,
                    child: TextFormField(
                      validator: (s) {
                        if (s == null || s.isEmpty) return 'must enter port';
                        int port = int.tryParse(s) ?? -1;
                        if (port < 0 || port > 65535) return 'not a valid port';
                        return null;
                      },
                      keyboardType: TextInputType.number,
                      controller: _portController,
                      decoration: const InputDecoration(labelText: 'port'),
                    ),
                  ),
                ],
              ),
              const Spacer(flex: 1),
              TextFormField(
                validator: (s) {
                  if (s == null || s.isEmpty) return 'must enter username';
                  return null;
                },
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'username'),
              ),
              const Spacer(flex: 1),
              TextFormField(
                validator: (s) {
                  if (s == null || s.isEmpty && _storedPassphrase.isEmpty) {
                    return 'must enter passphrase';
                  }
                  return null;
                },
                obscureText: _hidePassphrase,
                controller: _passphraseController,
                decoration: InputDecoration(
                  hintText: _passwordHintText,
                  suffixIcon: IconButton(
                    color: Theme.of(context).colorScheme.secondary,
                    icon: Icon(
                        _hidePassphrase ? Icons.lock_outline : Icons.lock_open),
                    onPressed: () =>
                        setState(() => _hidePassphrase = !_hidePassphrase),
                  ),
                  labelText: _passwordLabelText,
                ),
              ),
              const Spacer(flex: 1),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Switch(
                    value: autoconnect,
                    onChanged: (v) => setState(() => autoconnect = v),
                  ),
                  Text(
                    'auto connect',
                    style: Theme.of(context).primaryTextTheme.headlineSmall,
                  ),
                ],
              ),
              const Spacer(flex: 8),
              Container(height: 60)
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (!_formKey.currentState!.validate()) return;
          final ip = _adressController.text;
          final port = int.tryParse(_portController.text) ?? 22;
          final inputPassphrase = _passphraseController.text;
          final passphrase =
              inputPassphrase.isEmpty ? _storedPassphrase : inputPassphrase;
          final curtains = context.read<CurtainsCubit>();
          final sshkey = await Assets(DefaultAssetBundle.of(context)).sshkey;

          Preferences(await SharedPreferences.getInstance())
            ..port = port
            ..ip = ip
            ..autoconnect = autoconnect
            ..passphrase = passphrase
            ..username = _nameController.text;
          final cInfo = SSHConnectionInfo(
            user: _nameController.text,
            host: ip,
            port: port,
            privatekey: sshkey,
            passphrase: passphrase,
          );
          curtains.connect(cInfo);
        },
        child: const Icon(Icons.phonelink),
      ),
    );
  }
}
