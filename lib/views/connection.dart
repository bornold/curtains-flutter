import 'package:curtains/datasource/client_bloc.dart';
import 'package:flutter/material.dart';

class ConnectionInfo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final client = ClientProvider.of(context).client;
    return StreamBuilder<SshState>(
      stream: client.connection,
      initialData: SshState.connecting,
      builder: (context, snapshot) {
            return Scaffold(
              appBar: AppBar(title: Text('Connection Info')),
              body: Center(child: Text('Nothing here yet')),
              floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
              floatingActionButton: FloatingActionButton(
                child: Icon(Icons.phonelink),
                onPressed: client.connect,
                ),
              );
          }
    );
  }
}
