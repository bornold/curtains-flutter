import 'package:flutter/services.dart';

class Assets {
  static const privateKeyPath = 'assets/.ssh/curt';
  final AssetBundle assetBundle;

  Assets(this.assetBundle);
  Future<String> get sshkey => assetBundle.loadString(privateKeyPath);
}
