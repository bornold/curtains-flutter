abstract class ConnectionInfo {
  final String host;
  final int port;
  const ConnectionInfo(this.host, this.port);
}

class RestfullConnectionInfo extends ConnectionInfo {
  const RestfullConnectionInfo(String host, int port) : super(host, port);
}

class SSHConnectionInfo extends ConnectionInfo {
  SSHConnectionInfo({
    required this.user,
    required String host,
    required int port,
    required this.privatekey,
    required this.passphrase,
  })  : assert(port > 0),
        assert(port < 65535),
        super(host, port);
  final String user, privatekey, passphrase;

  @override
  String toString() => '$user@$host:$port';
}
