import 'package:curtains/datasource/client_bloc.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const String 
  adress_prefs_key = 'adress_prefs_key',
  port_prefs_key = 'port_prefs_key',
  passphrase_sercure_key = 'passphrase_sercure_key',
  ssh_sercure_key = 'ssh_sercure_key';

class ConnectionInfo extends StatefulWidget {
  @override
  _ConnectionInfoState createState() => _ConnectionInfoState();
}

class _ConnectionInfoState extends State<ConnectionInfo> {

  final _passphraseController = TextEditingController();
  final _adressController = TextEditingController();
  final _portController = TextEditingController();
  bool _hidePassphrase = true;
  final _formKey = GlobalKey<FormState>();
  final storage = FlutterSecureStorage();

  @override
  void initState() {
    setPrefs();
    super.initState();
  }

  void setPrefs() async {
      final prefs = await SharedPreferences.getInstance();
      _adressController.text = prefs.getString(adress_prefs_key) ?? '192.168.1.227';
      _portController.text = '${prefs.getInt(port_prefs_key) ?? 22}';
      _passphraseController.text = await storage.read(key: passphrase_sercure_key);
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
    return StreamBuilder<SshState>(
      stream: client.connection,
      initialData: SshState.connecting,
      builder: (context, snapshot) {
            return Scaffold(
              appBar: AppBar(title: Text('connection Info')),
              body: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(  
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Spacer(flex: 2,),
                        TextFormField(
                          validator: (s) {
                            if (s.isEmpty) return "must enter passphrase";
                          },
                          obscureText: _hidePassphrase,
                          controller: _passphraseController,
                          decoration: InputDecoration(
                            suffixIcon: IconButton(
                              icon: Icon(_hidePassphrase ? Icons.lock_open : Icons.lock_outline), 
                              onPressed: () => setState(() => _hidePassphrase = !_hidePassphrase),
                            ),
                            labelText: 'passphrase',
                          ),
                        ),
                        Spacer(flex: 1,),
                        Row(children: <Widget>[
                          Expanded(
                            flex: 30,
                            child: TextFormField(
                              validator: (s) {
                                if (s.isEmpty) return "must enter adress";
                                try {
                                  Uri.parseIPv4Address(s);
                                }
                                catch (e) {
                                  return "not a valid uri";
                                }
                              },
                              keyboardType: TextInputType.number,
                              controller:  _adressController,
                              decoration: InputDecoration(
                                labelText: 'adress'
                              ),
                            ),
                          ),
                          Spacer(flex: 1,),
                          Expanded(
                            flex: 12,
                            child: TextFormField(
                              validator: (s) {
                                if (s.isEmpty) return "must enter port";
                                int port = int.tryParse(s) ?? -1;
                                if (port < 0 || port > 65535){
                                  return "not a valid port";
                                }
                              },
                              keyboardType: TextInputType.number,
                              controller: _portController,
                              decoration: InputDecoration(
                                labelText: 'port'
                              ),
                            ),
                          ),
                        ],
                        ),
                        Spacer(flex: 5,),
                      ],
                  ),
                ),
              ),
              floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
              floatingActionButton: FloatingActionButton(
                child: Icon(Icons.phonelink),
                onPressed: () async {
                    if (_formKey.currentState.validate()) {
                      final prefs = await SharedPreferences.getInstance();
                      prefs.setString(adress_prefs_key, _adressController.text);
                      int port = int.tryParse(_portController.text) ?? -1;
                      if (port > 0) prefs.setInt(port_prefs_key, port);
                      await storage.write(key: passphrase_sercure_key, value: _passphraseController.text);                      
                      client.connectionEvents.add(ConnectionEvents.connect);
                    }
                } 
              ),
            );
          }
    );
  }
}