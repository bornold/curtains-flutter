import 'package:curtains/constants.dart';
import 'package:curtains/datasource/client_bloc.dart';
import 'package:curtains/models/connection_info.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ConnectionSettings extends StatefulWidget {
  ConnectionSettings({this.error});
  final Exception error;
  @override
  _ConnectionSettingsState createState() =>
      _ConnectionSettingsState(error: error);
}

class _ConnectionSettingsState extends State<ConnectionSettings> {
  _ConnectionSettingsState({this.error});
  Exception error;
  final _passphraseController = TextEditingController();
  final _adressController = TextEditingController();
  final _portController = TextEditingController();
  bool _hidePassphrase = true;
  bool autoconnect = true;
  final _formKey = GlobalKey<FormState>();
  final _storage = FlutterSecureStorage();
  String _passwordHintText = 'enter passphrase';
  String _passwordLabelText = 'passphrase';
  String _storedPassphrase;

  @override
  void initState() {
    setPrefs();
    super.initState();
  }

  void setPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _adressController.text =
        prefs.getString(adress_prefs_key) ?? '192.168.1.227';
    _portController.text = '${prefs.getInt(port_prefs_key) ?? 22}';
    _storedPassphrase = await _storage.read(key: passphrase_sercure_key);
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
      appBar: AppBar(title: Text('connection Info')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Spacer(
                flex: 5,
              ),
              Text(error?.toString() ?? '',
                  style: Theme.of(context)
                      .textTheme
                      .body1
                      .apply(color: Colors.red)),
              Spacer(
                flex: 5,
              ),
              TextFormField(
                validator: (s) {
                  if (s.isEmpty && _storedPassphrase == null)
                    return 'must enter passphrase';
                },
                obscureText: _hidePassphrase,
                controller: _passphraseController,
                decoration: InputDecoration(
                  hintText: _passwordHintText,
                  suffixIcon: IconButton(
                    color: Theme.of(context).accentColor,
                    icon: Icon(
                        _hidePassphrase ? Icons.lock_open : Icons.lock_outline),
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
                children: <Widget>[
                  Expanded(
                    flex: 30,
                    child: TextFormField(
                      validator: (s) {
                        if (s.isEmpty) return "must enter adress";
                        try {
                          Uri.parseIPv4Address(s);
                        } catch (e) {
                          return "not a valid uri";
                        }
                      },
                      keyboardType: TextInputType.number,
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
                        if (s.isEmpty) return "must enter port";
                        int port = int.tryParse(s) ?? -1;
                        if (port < 0 || port > 65535) {
                          return "not a valid port";
                        }
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Switch(
                      value: autoconnect,
                      onChanged: (v) => setState(() => autoconnect = v)),
                  Text(
                    'auto connect',
                    style: Theme.of(context).primaryTextTheme.subhead,
                  ),
                ],
              ),
              Spacer(
                flex: 14,
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
                await _storage.write(
                    key: passphrase_sercure_key, value: passphrase);
              }
              

              final cInfo = ConnectionInfo(
                  host: ip,
                  port: port,
                  privatekey: sshkey,
                  passphrase: passphrase);

              client.connectionInfoSink.add(cInfo);
              client.connectionEvents.add(ConnectionEvent.connect);
            }
          }),
    );
  }
}
