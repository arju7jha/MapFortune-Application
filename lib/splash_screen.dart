
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:permission_handler/permission_handler.dart';
//import 'package:untitled/neu_circle.dart';

// void main() => runApp(MyApp());

class Splash extends StatefulWidget {
  const Splash({Key? key}) : super(key: key);

  @override
  _SplashState createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  bool _hasPermissions = false;

  @override
  void initState() {
    super.initState();
    _fetchPermissionStatus();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.brown[600],
        body: Padding(
          padding: EdgeInsets.only(top: 180.0),
          child: _hasPermissions ? _buildCompass() : _buildPermissionSheet(),
        ),
      ),
    );
  }

  Widget _buildCompass() {
    return StreamBuilder<CompassEvent>(
      stream: FlutterCompass.events,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Error reading heading: ${snapshot.error}'),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }

        double? direction = snapshot.data?.heading;

        if (direction == null) {
          return Center(
            child: Text("Device does not have sensors!"),
          );
        }

        return Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/background.png'),
              fit: BoxFit.fill,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.rotate(
                angle: (direction * (math.pi / 180) * -1),
                child: Image.asset(
                  'assets/compass.png',
                  color: Colors.black87,
                  fit: BoxFit.fill,
                ),
              ),
              Positioned(
                top: 100.0,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(
                    '${direction.toStringAsFixed(2)}°',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPermissionSheet() {
    return Center(
      child: ElevatedButton(
        child: const Text('Request Permissions'),
        onPressed: () {
          Permission.locationWhenInUse.request().then((ignored) {
            _fetchPermissionStatus();
          });
        },
      ),
    );
  }

  void _fetchPermissionStatus() {
    Permission.locationWhenInUse.status.then((status) {
      if (mounted) {
        setState(() {
          _hasPermissions = status == PermissionStatus.granted;
        });
      }
    });
  }
}


