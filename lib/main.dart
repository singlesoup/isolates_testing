import 'dart:isolate';

import 'package:flutter/material.dart';
import 'dart:developer' as dev_tools show log;

extension Log on Object {
  void log() => dev_tools.log(toString());
}

@immutable
class Heroes {
  final String name;
  final String quirk;

  const Heroes({required this.name, required this.quirk});

  Heroes.fromJson(Map<String, dynamic> json)
      : name = json["name"] as String,
        quirk = json["quirk"] as String;
}

/// this is the entrance of the isolate
Stream<String> getMessage() {
  final rp = ReceivePort();
  return Isolate.spawn(_getMessage, rp.sendPort)
      .asStream()
      .asyncExpand((_) => rp)

      /// this will change the data type of the stream back to that of the Receive Port
      .takeWhile((element) => element is String)

      /// since we are sending nothing at Isolate.exit(sp) 's 2nd param so it sends "null", this code will help us remove it
      .cast();
}

/// This is the main func or the main event loop

void _getMessage(SendPort sp) async {
  /// take() is used to define the no of times we want this stream to send us data
  await for (final now in Stream.periodic(
          const Duration(seconds: 1), (_) => DateTime.now().toIso8601String())
      .take(5)) {
    sp.send(now);
  }
  Isolate.exit(sp);

  /// [Note] : Here we have not send the 2nd parameter for the Iso late because we are sending our data via "sp.send()"
  /// if we do send anything for e.g :  Isolate.exit(sp,"Hello"); , then it will append that "Hello", at the end of the
  /// result sent by : sp.send(now)
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

void testIt() async {
  await for (final msg in getMessage()) {
    msg.log();
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text(
              'This is an example app for testing isolates',
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          testIt();
        },
        tooltip: 'Isolates with Stream',
        child: const Icon(Icons.add),
      ),
    );
  }
}
