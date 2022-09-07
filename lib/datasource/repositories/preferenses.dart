import 'package:shared_preferences/shared_preferences.dart';

class Preferences {
  static const adressPrefsKey = 'adress_prefs_key',
      portPrefsKey = 'port_prefs_key',
      passphraseSercureKey = 'passphrase_sercure_key',
      sshSercureKey = 'ssh_sercure_key',
      autoconnectPrefsKey = 'auto_connect_prefs_key';
  final SharedPreferences sharedPreferences;

  Preferences(this.sharedPreferences);

  String get ip => sharedPreferences.getString(adressPrefsKey) ?? '';
  set ip(String ip) => sharedPreferences.setString(adressPrefsKey, ip);
  int get port => sharedPreferences.getInt(portPrefsKey) ?? 22;
  set port(int port) => sharedPreferences.setInt(portPrefsKey, port);
  String get passphrase =>
      sharedPreferences.getString(passphraseSercureKey) ?? '';
  set passphrase(String passPhrase) =>
      sharedPreferences.setString(passphraseSercureKey, passPhrase);
  bool get autoconnect =>
      sharedPreferences.getBool(autoconnectPrefsKey) ?? false;
  set autoconnect(bool autoconnect) =>
      sharedPreferences.setBool(autoconnectPrefsKey, autoconnect);
}
