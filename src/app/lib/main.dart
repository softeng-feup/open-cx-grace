import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flame/flame.dart';

import 'board-game.dart';

void main() async {
  // Force landscape device left orientation
  await SystemChrome.setPreferredOrientations(
      [DeviceOrientation.landscapeLeft]);

  // Hide status bar
  await SystemChrome.setEnabledSystemUIOverlays([]);

  /*SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Color.fromRGBO(3, 44, 115, 1), // status bar color
  ));
*/
  Flame.images.loadAll(<String>[
    'joystick_background.png',
    'joystick_knob.png',
    'grace.png',
  ]);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Grace',
      theme: ThemeData(
        primaryColor: Color.fromRGBO(3, 44, 115, 1),
      ),
      initialRoute: '/',
      routes: {
        "/": (context) => HomePage(),
        "/grace_controller": (context) => MyJoystick(),
        "/grace_call": (context) => GraceCall(),
      },
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          color: Color.fromRGBO(3, 44, 115, 1),
          child: Stack(
            children: <Widget>[
              Center(
                  child: Text("Grace",
                      style: TextStyle(fontSize: 32, color: Colors.white))),
              MyButton(
                  x: 14,
                  y: 60,
                  title: "Call",
                  onPressed: () {
                    Navigator.of(context).pushNamed("/grace_call");
                  }),
              MyButton(
                  x: 70,
                  y: 60,
                  title: "Control",
                  onPressed: () {
                    Navigator.of(context).pushNamed("/grace_controller");
                  }),
            ],
          ),
        ),
      ),
    );
  }
}

class MyButton extends StatelessWidget {
  MyButton({this.x, this.y, this.title, this.onPressed});

  final int x;
  final int y;
  final String title;
  final Function onPressed;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: (x / 100) * MediaQuery.of(context).size.width,
      top: (y / 100) * MediaQuery.of(context).size.height,
      width: 100,
      height: 70,
      child: FloatingActionButton(
        onPressed: onPressed,
        backgroundColor: Colors.white,
        child: Text(
          title,
          style: TextStyle(color: Colors.black),
        ),
        heroTag: title,
      ),
    );
  }
}

class GraceCall extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Grace Call"),
      ),
      body: Center(
        child: Text("You are calling Grace!"),
      ),
    );
  }
}

class MyJoystick extends StatelessWidget {
  final BoardGame game = BoardGame();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Container(
        decoration: BoxDecoration(color: Colors.white),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: game.onPanStart,
          onPanUpdate: game.onPanUpdate,
          onPanEnd: game.onPanEnd,
          child: game.widget,
        ),
      ),
    );
  }
}

class MySwitch extends StatefulWidget {
  createState() => MySwitchState();
}

class MySwitchState extends State<MySwitch> {
  bool isSwitched = true;
  bool isChecked = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Switch Check',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: Scaffold(
          appBar: AppBar(
            title: Text("Switch Check"),
          ),
          body: Center(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Switch(
                    value: isSwitched,
                    onChanged: (value) {
                      setState(() {
                        isSwitched = value;
                      });
                    },
                    activeTrackColor: Colors.lightGreenAccent,
                    activeColor: Colors.green,
                  ),
                  Checkbox(
                    value: isChecked,
                    onChanged: (value) {
                      setState(() {
                        isChecked = value;
                      });
                    },
                  )
                ]),
          ),
        ));
  }
}
