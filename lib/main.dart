import 'package:curtains/datasource/bloc/curtains_cubit.dart';
import 'package:curtains/theme.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'pages/alarm_page.dart';
import 'pages/connection_page.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const CurtainsApp());
}

class CurtainsApp extends StatelessWidget {
  const CurtainsApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'curtains',
      theme: theme,
      home: BlocProvider(
        create: (context) => CurtainsCubit(
          assetBundle: DefaultAssetBundle.of(context),
        )..checkConnection(),
        child: const MainPage(),
      ),
    );
  }
}

class MainPage extends StatelessWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CurtainsCubit>().state;
    if (state is CurtainsDisconnected) {
      return ConnectionSettings(error: state.error);
    } else if (state is CurtainsConnected) {
      return AlarmPage(state.alarms);
    }
    return Container(
      decoration:
          BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
