import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';
import '../datasource/client_bloc.dart';
import '../models/connection_info.dart';

class ConnectionSettings extends StatefulWidget {
  ConnectionSettings({this.error});
  final Object error;
  @override
  _ConnectionSettingsState createState() =>
      _ConnectionSettingsState(error: error);
}

class _ConnectionSettingsState extends State<ConnectionSettings> {
  _ConnectionSettingsState({
    Object error,
  }) {
    if (error is TimeoutException)
      _errorMessage = 'timed out, wrong ip?';
    else if (error is PlatformException && error.code == connectionFailure) {
      if (error.message == errorAuth)
        _errorMessage = 'wrong password';
      else if (error.message == errorSessionDown)
        _errorMessage = 'lost connection';
      else
        _errorMessage = 'connection error, wrong ip or port?';
    } else
      _errorMessage = error?.toString() ?? '';
  }

  final _passphraseController = TextEditingController();
  final _adressController = TextEditingController();
  final _portController = TextEditingController();
  bool _hidePassphrase = true;
  bool autoconnect = true;
  final _formKey = GlobalKey<FormState>();
  String _passwordHintText = 'enter passphrase';
  String _passwordLabelText = 'passphrase';
  String _storedPassphrase;
  String _errorMessage;

  @override
  void initState() {
    setPrefs();
    super.initState();
  }

  void setPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _adressController.text = prefs.getString(adress_prefs_key) ?? '';
    _portController.text = '${prefs.getInt(port_prefs_key) ?? 22}';
    _storedPassphrase = prefs.getString(passphrase_sercure_key);
    if (_storedPassphrase != null) {
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final client = ClientProvider.of(context).client;
    return Scaffold(
      appBar: AppBar(title: Text('connection info')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Spacer(
                flex: 4,
              ),
              Text(_errorMessage,
                  style: Theme.of(context)
                      .textTheme
                      .bodyText2
                      .apply(color: Theme.of(context).errorColor)),
              Spacer(
                flex: 4,
              ),
              Row(
                children: <Widget>[
                  Expanded(
                    flex: 30,
                    child: TextFormField(
                      validator: (s) {
                        if (s.isEmpty) return 'must enter adress';
                        if (Uri.tryParse(s) == null)
                          return 'not a valid adress';
                        return null;
                      },
                      keyboardType: TextInputType.url,
                      controller: _adressController,
                      decoration: InputDecoration(labelText: 'adress'),
                    ),
                  ),
                  Spacer(
                    flex: 1,
                  ),
                  Expanded(
                    flex: 12,
                    child: TextFormField(
                      validator: (s) {
                        if (s.isEmpty) return 'must enter port';
                        int port = int.tryParse(s) ?? -1;
                        if (port < 0 || port > 65535) return 'not a valid port';
                        return null;
                      },
                      keyboardType: TextInputType.number,
                      controller: _portController,
                      decoration: InputDecoration(labelText: 'port'),
                    ),
                  ),
                ],
              ),
              Spacer(
                flex: 1,
              ),
              TextFormField(
                validator: (s) {
                  if (s.isEmpty && _storedPassphrase == null)
                    return 'must enter passphrase';
                  return null;
                },
                obscureText: _hidePassphrase,
                controller: _passphraseController,
                decoration: InputDecoration(
                  hintText: _passwordHintText,
                  suffixIcon: IconButton(
                    color: Theme.of(context).accentColor,
                    icon: Icon(
                        _hidePassphrase ? Icons.lock_outline : Icons.lock_open),
                    onPressed: () =>
                        setState(() => _hidePassphrase = !_hidePassphrase),
                  ),
                  labelText: _passwordLabelText,
                ),
              ),
              Spacer(
                flex: 1,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Switch(
                      value: autoconnect,
                      onChanged: (v) => setState(() => autoconnect = v)),
                  Text(
                    'auto connect',
                    style: Theme.of(context).primaryTextTheme.subtitle1,
                  ),
                ],
              ),
              Spacer(
                flex: 8,
              ),
              Container(
                height: 60,
              )
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.phonelink),
        onPressed: () async {
          if (_formKey.currentState.validate()) {
            final ip = _adressController.text;
            final port = int.tryParse(_portController.text) ?? 22;
            final inputPassphrase = _passphraseController.text;
            final passphrase =
                inputPassphrase.isEmpty ? _storedPassphrase : inputPassphrase;
            final sshkey = await DefaultAssetBundle.of(context)
                .loadString(private_key_path);

            final prefs = await SharedPreferences.getInstance();
            prefs.setInt(port_prefs_key, port);
            prefs.setString(adress_prefs_key, ip);
            prefs.setBool(autoconnect_prefs_key, autoconnect);
            if (passphrase != null) {
              prefs.setString(passphrase_sercure_key, passphrase);

              final cInfo = SSHConnectionInfo(
                  host: ip,
                  port: port,
                  privatekey: sshkey,
                  passphrase: passphrase);

              client.connectionInfoSink.add(cInfo);
              client.connectionEvents.add(ConnectionEvent.connect);
            }
          } else {
            setState(() => _errorMessage = '');
          }
        },
      ),
    );
  }
}
