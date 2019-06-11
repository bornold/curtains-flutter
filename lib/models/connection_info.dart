import 'package:meta/meta.dart';

class ConnectionInfo {
  ConnectionInfo(
      {this.user = 'pi',
      @required this.host,
      @required this.port,
      @required this.privatekey,
      @required this.passphrase})
      : assert(user != null),
        assert(host != null),
        assert(privatekey != null),
        assert(passphrase != null),
        assert(port > 0),
        assert(port < 65535);
  final String user, host, privatekey, passphrase;
  final int port;
  @override
  String toString() => '$user@$host:$port';
}
