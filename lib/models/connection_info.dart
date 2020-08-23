import 'package:meta/meta.dart';

abstract class ConnectionInfo {
  final String host;
  final int port;
  const ConnectionInfo(this.host, this.port);
}

class RestfullConnectionInfo extends ConnectionInfo {
  const RestfullConnectionInfo(String host, int port) : super(host, port);
}

class SSHConnectionInfo extends ConnectionInfo {
  SSHConnectionInfo(
      {this.user = 'pi',
      @required String host,
      @required int port,
      @required this.privatekey,
      @required this.passphrase})
      : assert(user != null),
        assert(host != null),
        assert(privatekey != null),
        assert(passphrase != null),
        assert(port > 0),
        assert(port < 65535),
        super(host, port);
  final String user, privatekey, passphrase;

  @override
  String toString() => '$user@$host:$port';
}
