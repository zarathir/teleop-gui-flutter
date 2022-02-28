import 'dart:math';
import 'package:flutter/material.dart';
import 'package:grpc/grpc.dart';
import 'package:teleop_gui_flutter/models/teleop.pbgrpc.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Teleop Turtlebot',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.lime,
      ),
      home: const MyHomePage(title: 'Teleop Turtlebot'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const turtlebotMaxLinVel = 0.22;
  static const turtlebotMaxAngVel = 2.84;

  static const linearVelStepSize = 0.01;
  static const angularVelStepSize = 0.1;

  double targetLinearVel = 0;
  double targetAngularVel = 0;
  double controlLinearVel = 0;
  double controlAngularVel = 0;

  ClientChannel channel = ClientChannel('127.0.0.1',
      port: 50051,
      options: const ChannelOptions(
          credentials: ChannelCredentials.insecure(),
          idleTimeout: Duration(minutes: 1)));

  final SizedBox _box = const SizedBox(
    height: 5,
    width: 5,
  );

  double makeSimpleProfile(double output, double input, double slop) {
    if (input > output) {
      output = min(input, output + slop);
    } else if (input < output) {
      output = max(input, output - slop);
    } else {
      output = input;
    }

    return output;
  }

  double constrain(double input, double low, double high) {
    if (input < low) {
      input = low;
    } else if (input > high) {
      input = high;
    }

    return input;
  }

  double checkLinearLimitVelocity(double vel) {
    return constrain(vel, -turtlebotMaxLinVel, turtlebotMaxLinVel);
  }

  double checkAngualarLimitVelocity(double vel) {
    return constrain(vel, -turtlebotMaxAngVel, turtlebotMaxAngVel);
  }

  void sendCommand(TeleopClient stub) {
    controlLinearVel = makeSimpleProfile(
        controlLinearVel, targetLinearVel, (linearVelStepSize / 2.0));

    controlAngularVel = makeSimpleProfile(
        controlAngularVel, targetAngularVel, (angularVelStepSize / 2.0));

    var linear = Vector3(x: controlLinearVel, y: 0, z: 0);
    var angular = Vector3(x: 0, y: 0, z: controlAngularVel);

    stub.sendCommand(CommandRequest(linear: linear, angular: angular));
  }

  Future<void> _accelerate() async {
    var stub = TeleopClient(channel);

    targetLinearVel =
        checkLinearLimitVelocity(targetLinearVel + linearVelStepSize);

    sendCommand(stub);
  }

  Future<void> _decelerate() async {
    var stub = TeleopClient(channel);

    targetLinearVel =
        checkLinearLimitVelocity(targetLinearVel - linearVelStepSize);

    sendCommand(stub);
  }

  Future<void> _leftwards() async {
    var stub = TeleopClient(channel);

    targetAngularVel =
        checkAngualarLimitVelocity(targetAngularVel + angularVelStepSize);

    sendCommand(stub);
  }

  Future<void> _rightwards() async {
    var stub = TeleopClient(channel);

    targetAngularVel =
        checkAngualarLimitVelocity(targetAngularVel - angularVelStepSize);

    sendCommand(stub);
  }

  Future<void> _stop() async {
    var stub = TeleopClient(channel);

    targetLinearVel = 0;
    controlLinearVel = 0;
    targetAngularVel = 0;
    controlAngularVel = 0;

    sendCommand(stub);
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () async => _accelerate(),
              child: const Icon(Icons.arrow_upward),
            ),
            _box,
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () async => _leftwards(),
                  child: const Icon(Icons.arrow_back),
                ),
                _box,
                ElevatedButton(
                    onPressed: () async => _stop(),
                    child: const Icon(Icons.cancel_outlined)),
                _box,
                ElevatedButton(
                    onPressed: () async => _rightwards(),
                    child: const Icon(Icons.arrow_forward))
              ],
            ),
            _box,
            ElevatedButton(
              onPressed: () async => _decelerate(),
              child: const Icon(Icons.arrow_downward),
            ),
            _box,
          ],
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}