import 'dart:io';
import 'dart:isolate';
import 'dart:convert';

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

/// This is the entrance of the below Isolate

Future<Iterable> getHeroes() async {
  /// a receivePort is used inside an entrance, its a tunnel which will await
  /// the responses sent by it isolates main function. So ReceivePort has read/write access
  /// But sendPort is write only
  /// We know ReceivePort can also send Streams, but here we know it will send only one value

  final rp = ReceivePort();
  await Isolate.spawn(_getHeroes, rp.sendPort);
  return await rp.first;
}

/// This is the main function of the Isolate
void _getHeroes(SendPort sp) async {
  const String url = "http://127.0.0.1:5500/apis/people.json";
  final heroes = await HttpClient()
      .getUrl(Uri.parse(url))
      .then((req) => req.close())
      .then((response) => response.transform(utf8.decoder).join())
      .then((jsonString) => json.decode(jsonString) as List<dynamic>)
      .then((json) => json.map((map) => Heroes.fromJson(map)));

  // sp.send(heroes); -> this wouldn't close the entrace to this isolate so use
  Isolate.exit(sp, heroes);
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
        onPressed: () async {
          final heroes = await getHeroes();
          heroes.log();
        },
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
