import 'dart:isolate';
import 'dart:io';
import 'dart:convert';

import 'package:async/async.dart' show StreamGroup;
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

  @override
  String toString() => "Hero's (name: $name and quirk:$quirk";
}

@immutable
class Request {
  final SendPort sendPort;
  final Uri uri;

  const Request(this.sendPort, this.uri);

  Request.from(HeroesRequest request)
      : sendPort = request.receivePort.sendPort,
        uri = request.uri;
}

/// The whole point of creating this class was since that we can't send ReceivePort diretcly through SendPort
/// we created a class which will make the conversion for us to send the Receive port
@immutable
class HeroesRequest {
  final ReceivePort receivePort;
  final Uri uri;
  const HeroesRequest(this.receivePort, this.uri);

  static Iterable<HeroesRequest> all() sync* {
    for (final i in Iterable.generate(3, (i) => i)) {
      yield HeroesRequest(
        ReceivePort(),
        Uri.parse("http://127.0.0.1:5500/apis/people${i + 1}.json"),
      );
    }
  }
}

/// This is the entrance to the main()
Stream<Iterable<Heroes>> getHeroes() {
  final streams = HeroesRequest.all().map((req) =>
      Isolate.spawn(_getHeroes, Request.from(req))
          .asStream()
          .asyncExpand((_) => req.receivePort)
          .takeWhile((element) => element is Iterable<Heroes>)
          .cast());

  /// To merge all the responses we get from all the apis we will use stream group
  return StreamGroup.merge(streams).cast();
}

/// This is the main func or the main event loop
void _getHeroes(Request request) async {
  final heroes = await HttpClient()
      .getUrl(request.uri)
      .then((req) => req.close())
      .then((response) => response.transform(utf8.decoder).join())
      .then((jsonString) => json.decode(jsonString) as List<dynamic>)
      .then((json) => json.map((map) => Heroes.fromJson(map)));

  // request.sendPort.send(heroes); or
  Isolate.exit(request.sendPort, heroes);
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
  await for (final msg in getHeroes()) {
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
