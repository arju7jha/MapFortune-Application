import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_custom_clippers/flutter_custom_clippers.dart';
import 'getting_intersection_points.dart';
 import 'final_page.dart';
// import 'compass.dart';

import 'dart:math' as math;
import 'package:flutter_compass/flutter_compass.dart';
import 'package:permission_handler/permission_handler.dart';

import 'final_page.dart';
import 'getting_intersection_points.dart';
//import 'compass_circle.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ImageGalleryScreen(),
    );
  }
}

class ImageGalleryScreen extends StatefulWidget {
  const ImageGalleryScreen({super.key});

  @override
  State<ImageGalleryScreen> createState() => _ImageGalleryScreenState();
}

class _ImageGalleryScreenState extends State<ImageGalleryScreen> {

  File? _selectedImage;
  List<Offset> _points = [];
  bool _drawingEnabled = false;

  Future<void> _pickImage() async {
    final pickedImage =
    await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _selectedImage = File(pickedImage.path);
        _points.clear();
        _drawingEnabled = true;
      });
    }
  }


  void _onImageTap(TapUpDetails details) {
    if (!_drawingEnabled) {
      _storeTouchedPoint(details.localPosition);
      return;
    }

    final RenderBox imageBox = context.findRenderObject() as RenderBox;
    final Offset imageOffset = imageBox.localToGlobal(Offset.zero);

    setState(() {
      _points.add(details.localPosition - imageOffset);
    });

    if (_points.length > 2 &&
        (_points.first - (_points.last)).distance <= 20.0) {
      // Polygon closed, perform any desired action here
      print('Polygon Closed');
      _drawingEnabled = false;
      _showNewPageButton();
    }
  }

  void _showNewPageButton() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Polygon Closed"),
        content: Text("The polygon is closed."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _startPointSelection();
            },
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

  void _startPointSelection() {
    setState(() {
      _drawingEnabled = false;
    });
  }

  void _storeTouchedPoint(Offset point) {
    final center = _calculateCenterOfArea();
    print('vertices: $_points');
    List<double> areas = find_areas_of_sectors(_points, center, point);
    List<Offset> intersections =
    findallintersectionpoints(_points, center, point);
    print('Intersection points: $intersections');
    print('area: $areas');

    if (_points.length > 2 &&
        (_points.first - (_points.last)).distance <= 20.0) {
      _drawingEnabled = false;
      _showNewPageButton();
      _navigateToFinalPage(areas);
    }
  }

  Offset _calculateCenterOfArea() {
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = -double.infinity;
    double maxY = -double.infinity;

    for (final point in _points) {
      if (point.dx < minX) {
        minX = point.dx;
      }
      if (point.dy < minY) {
        minY = point.dy;
      }
      if (point.dx > maxX) {
        maxX = point.dx;
      }
      if (point.dy > maxY) {
        maxY = point.dy;
      }
    }

    final centerX = (minX + maxX) / 2;
    final centerY = (minY + maxY) / 2;

    return Offset(centerX, centerY);
  }

  void _navigateToFinalPage(List<double> areas) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FinalPage(areas: areas),
      ),
    );
  }

  Widget _buildImageWithPoints() {
    final center = _calculateCenterOfArea();

    return GestureDetector(
      onTapUp: _onImageTap,
      child: Stack(
        children: [
          if (_selectedImage != null)
            Image.file(
              _selectedImage!,
              fit: BoxFit.contain,
            ),
          CustomPaint(
            painter: PolygonPainter(_points, _drawingEnabled),
          ),
          if (_points.length >= 3)
            Positioned(
              left: center.dx,
              top: center.dy,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.yellow,
                ),
              ),
            ),
        ],
      ),
    );
  }


  double xPosition = 0;
  double yPosition = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Map Fortune'),
      ),
      body: Stack(
        children: [

          Expanded(
            flex: 2,
            child: Center(
              child: _selectedImage == null
                  ? Text('No image selected')
                  : _buildImageWithPoints(),
            ),
          ),

          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.only(left: 150.0,top: 600,),
              child: Container(
                child: Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        //Overlay.of(context).insert(_getEntry(context));
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => Compass()));
                      },
                      child: Text('COMPASS'),

                    ),
                  ],
                  //children: [ElevatedButton(onPressed: (){}, child: Text('COMPASS'))],
                ),
              ),
            ),
          ),

          Positioned(
            left: xPosition,
            top: yPosition,
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  xPosition += details.delta.dx;
                  yPosition += details.delta.dy;
                });
              },
              child: Container(
                width: 200,
                height: 200,
                color: Colors.transparent,
                child: Center(
                  child: Compass(),
                ),
              ),
            ),
          ),

        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickImage,
        child: Icon(Icons.image),
      ),
    );
  }
}

class PolygonPainter extends CustomPainter {
  final List<Offset> points;
  final bool drawingEnabled;

  PolygonPainter(this.points, this.drawingEnabled);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    if (points.length >= 2) {
      final path = Path();
      path.moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        if (i == points.length - 1 && drawingEnabled) {
          // Only draw line to the last point if drawing is enabled
          canvas.drawLine(
            points[i - 1],
            points[i],
            paint,
          );
        }
        path.lineTo(points[i].dx, points[i].dy);
      }
      if (points.length > 2) {
        path.lineTo(points.first.dx, points.first.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(PolygonPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.drawingEnabled != drawingEnabled;
  }
}

class Compass extends StatefulWidget {
  const Compass({super.key});

  @override
  State<Compass> createState() => _CompassState();
}

class _CompassState extends State<Compass> {
  bool _hasPermissions = false;

  void initState() {
    super.initState();
    _fetchPermissionStatus();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.transparent, // brown[600],
        body: Padding(
          padding: EdgeInsets.only(
            top: 0,
            left: 0,
          ),
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
          // decoration: BoxDecoration(
          //   image: DecorationImage(
          //     image: AssetImage('assets/background.png'),
          //     fit: BoxFit.fill,
          //   ),
          // ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.rotate(
                angle: (direction * (math.pi / 180) * -1),
                child: Image.asset(
                  'assets/compass.png',
                  color: Colors.pink,
                  fit: BoxFit.fill,
                ),
              ),
              Positioned(
                top: 100.0,
                child: Container(
                  padding:
                  EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(
                    '${direction.toStringAsFixed(2)}°',
                    style: TextStyle(
                      color: Colors.yellow,
                      fontSize: 22,
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



// class DraggableWidget extends StatefulWidget {
//   @override
//   _DraggableWidgetState createState() => _DraggableWidgetState();
// }
//
// class _DraggableWidgetState extends State<DraggableWidget> {
//
//
//   File? _selectedImage;
//   List<Offset> _points = [];
//   bool _drawingEnabled = false;
//
//   Future<void> _pickImage() async {
//     final pickedImage =
//     await ImagePicker().pickImage(source: ImageSource.gallery);
//     if (pickedImage != null) {
//       setState(() {
//         _selectedImage = File(pickedImage.path);
//         _points.clear();
//         _drawingEnabled = true;
//       });
//     }
//   }
//
//   void _onImageTap(TapUpDetails details) {
//     if (!_drawingEnabled) {
//       _storeTouchedPoint(details.localPosition);
//       return;
//     }
//
//     final RenderBox imageBox = context.findRenderObject() as RenderBox;
//     final Offset imageOffset = imageBox.localToGlobal(Offset.zero);
//
//     setState(() {
//       _points.add(details.localPosition - imageOffset);
//     });
//
//     if (_points.length > 2 &&
//         (_points.first - (_points.last)).distance <= 20.0) {
//       // Polygon closed, perform any desired action here
//       print('Polygon Closed');
//       _drawingEnabled = false;
//       _showNewPageButton();
//     }
//   }
//
//   void _showNewPageButton() {
//     showDialog(
//       context: context,
//       builder: (context) =>
//           AlertDialog(
//             title: Text("Polygon Closed"),
//             content: Text("The polygon is closed."),
//             actions: [
//               TextButton(
//                 onPressed: () {
//                   Navigator.of(context).pop();
//                   _startPointSelection();
//                 },
//                 child: Text("OK"),
//               ),
//             ],
//           ),
//     );
//   }
//
//   void _startPointSelection() {
//     setState(() {
//       _drawingEnabled = false;
//     });
//   }
//
//   void _storeTouchedPoint(Offset point) {
//     final center = _calculateCenterOfArea();
//     print('vertices: $_points');
//     List<double> areas = find_areas_of_sectors(_points, center, point);
//     List<Offset> intersections =
//     findallintersectionpoints(_points, center, point);
//     print('Intersection points: $intersections');
//     print('area: $areas');
//
//     if (_points.length > 2 &&
//         (_points.first - (_points.last)).distance <= 20.0) {
//       _drawingEnabled = false;
//       _showNewPageButton();
//       _navigateToFinalPage(areas);
//     }
//   }
//
//   Offset _calculateCenterOfArea() {
//     double minX = double.infinity;
//     double minY = double.infinity;
//     double maxX = -double.infinity;
//     double maxY = -double.infinity;
//
//     for (final point in _points) {
//       if (point.dx < minX) {
//         minX = point.dx;
//       }
//       if (point.dy < minY) {
//         minY = point.dy;
//       }
//       if (point.dx > maxX) {
//         maxX = point.dx;
//       }
//       if (point.dy > maxY) {
//         maxY = point.dy;
//       }
//     }
//
//     final centerX = (minX + maxX) / 2;
//     final centerY = (minY + maxY) / 2;
//
//     return Offset(centerX, centerY);
//   }
//
//   void _navigateToFinalPage(List<double> areas) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => FinalPage(areas: areas),
//       ),
//     );
//   }
//
//   @override
//   Future<Widget> _buildImageWithPoints() async {
//     final center = _calculateCenterOfArea();
//
//     GestureDetector(
//       onTapUp: _onImageTap,
//       child: Stack(
//         children: [
//           if (_selectedImage != null)
//             Image.file(
//               _selectedImage!,
//               fit: BoxFit.contain,
//             ),
//           CustomPaint(
//             painter: PolygonPainter(_points, _drawingEnabled),
//           ),
//           if (_points.length >= 3)
//             Positioned(
//               left: center.dx,
//               top: center.dy,
//               child: Container(
//                 width: 10,
//                 height: 10,
//                 decoration: BoxDecoration(
//                   shape: BoxShape.circle,
//                   color: Colors.yellow,
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//
//
//     double xPosition = 0;
//     double yPosition = 0;
//
//     @override
//     Widget build(BuildContext context) {
//       return Scaffold(
//         appBar: AppBar(
//           title: Text('Draggable Widget'),
//         ),
//         body: Stack(
//           children: [
//             Positioned(
//               left: xPosition,
//               top: yPosition,
//               child: GestureDetector(
//                 onPanUpdate: (details) {
//                   setState(() {
//                     xPosition += details.delta.dx;
//                     yPosition += details.delta.dy;
//                   });
//                 },
//                 child: Container(
//                   width: 200,
//                   height: 200,
//                   color: Colors.pinkAccent,
//                   child: Center(
//                     child: Compass(),
//                   ),
//                 ),
//               ),
//             ),
//
//             Expanded(
//               flex: 3,
//               child: Center(
//                 child: _selectedImage == null
//                     ? Text('No image selected')
//                     : _buildImageWithPoints(),
//               ),
//             ),
//           ],
//         ),
//         floatingActionButton: FloatingActionButton(
//           onPressed: _pickImage,
//           child: Icon(Icons.image),
//         ),
//       );
//     }
//   }
// }
















//
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/rendering.dart';
// // import 'package:flutter_longpressdraggable_dem/splash_screen.dart';
// import 'splash_screen.dart';
//
// void main() => runApp(MyApp());
//
// class MyApp extends StatelessWidget {
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       home: LongPressDraggableDemo(),
//     );
//   }
// }
//
// class LongPressDraggableDemo extends StatefulWidget {
//
//   @override
//   _LongPressDraggableDemoState createState() => _LongPressDraggableDemoState();
// }
//
// class _LongPressDraggableDemoState extends State<LongPressDraggableDemo> {
//
//   Offset _offset = Offset(100,250);
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         automaticallyImplyLeading: false,
//         title: Text('Flutter LongPressDraggable Demo '),
//       ),
//       body: Center(
//         child:
//         LayoutBuilder(
//           builder: (context, constraints) {
//             return Stack(
//               children: [
//                 Positioned(
//                   left: _offset.dx,
//                   top: _offset.dy,
//                   child: LongPressDraggable(
//                     feedback: Splash(),
//                     child: Splash(),
//                     onDragEnd: (details) {
//                       setState(() {
//                         final adjustment = MediaQuery.of(context).size.height -
//                             constraints.maxHeight;
//                         _offset = Offset(
//                             details.offset.dx, details.offset.dy - adjustment);
//                       });
//                     },
//                   ),
//                 ),
//               ],
//             );
//           },
//         ),
//       ),
//     );
//   }
//}

// import 'package:flutter/material.dart';
//
// void main() => runApp(MyApp());
// class MyApp extends StatefulWidget {
//   const MyApp({super.key});
//
//   @override
//   State<MyApp> createState() => _MyAppState();
// }
//
// class _MyAppState extends State<MyApp> {
//   //Offset _offset = const Offset(200, 250);
//   Offset offset = const Offset(200, 250);
//
//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: LayoutBuilder(
//         builder: (context, constraints)=> Stack(
//             alignment: AlignmentDirectional.topCenter,
//             children: [
//               Positioned(
//
//                 left: offset.dx,
//                 right: offset.dy,
//                 child: LongPressDraggable(
//                   feedback: Image.asset(
//                     "assets/background.jpg"
//                     //height: 200,
//                    // colorBlendMode: BlendMode.colorBurn,
//
//                   ),
//                   child: Image.asset(
//                       "assets/background.jpg"
//                     //height: 200,
//                   ),
//                   onDragEnd: (details){
//                     setState(() {
//                       double adjustment = MediaQuery.of(context).size.height - constraints.maxHeight;
//                       offset = Offset(details.offset.dx, details.offset.dy- adjustment);
//                     });
//                   },
//               ),
//               ),
//             ],
//           ),
//       ),
//     );
//   }
// }



























//
// import 'dart:math' as math;
// import 'package:flutter/material.dart';
// import 'package:flutter_compass/flutter_compass.dart';
// import 'package:permission_handler/permission_handler.dart';
// //import 'package:untitled/neu_circle.dart';
//
// void main() => runApp(MyApp());
//
// class MyApp extends StatefulWidget {
//   const MyApp({Key? key}) : super(key: key);
//
//   @override
//   _MyAppState createState() => _MyAppState();
// }
//
// class _MyAppState extends State<MyApp> {
//   bool _hasPermissions = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchPermissionStatus();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       home: Scaffold(
//         backgroundColor: Colors.brown[600],
//         body: Padding(
//           padding: EdgeInsets.only(top: 180.0),
//           child: _hasPermissions ? _buildCompass() : _buildPermissionSheet(),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildCompass() {
//     return StreamBuilder<CompassEvent>(
//       stream: FlutterCompass.events,
//       builder: (context, snapshot) {
//         if (snapshot.hasError) {
//           return Center(
//             child: Text('Error reading heading: ${snapshot.error}'),
//           );
//         }
//
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return Center(
//             child: CircularProgressIndicator(),
//           );
//         }
//
//         double? direction = snapshot.data?.heading;
//
//         if (direction == null) {
//           return Center(
//             child: Text("Device does not have sensors!"),
//           );
//         }
//
//         return Container(
//           decoration: BoxDecoration(
//             image: DecorationImage(
//               image: AssetImage('assets/background.png'),
//               fit: BoxFit.fill,
//             ),
//           ),
//           child: Stack(
//             alignment: Alignment.center,
//             children: [
//               Transform.rotate(
//                 angle: (direction * (math.pi / 180) * -1),
//                 child: Image.asset(
//                   'assets/compass.png',
//                   color: Colors.black87,
//                   fit: BoxFit.fill,
//                 ),
//               ),
//               Positioned(
//                 top: 100.0,
//                 child: Container(
//                   padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
//                   decoration: BoxDecoration(
//                     color: Colors.black.withOpacity(0.5),
//                     borderRadius: BorderRadius.circular(8.0),
//                   ),
//                   child: Text(
//                     '${direction.toStringAsFixed(2)}°',
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 24.0,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
//
//   Widget _buildPermissionSheet() {
//     return Center(
//       child: ElevatedButton(
//         child: const Text('Request Permissions'),
//         onPressed: () {
//           Permission.locationWhenInUse.request().then((ignored) {
//             _fetchPermissionStatus();
//           });
//         },
//       ),
//     );
//   }
//
//   void _fetchPermissionStatus() {
//     Permission.locationWhenInUse.status.then((status) {
//       if (mounted) {
//         setState(() {
//           _hasPermissions = status == PermissionStatus.granted;
//         });
//       }
//     });
//   }
// }
//
//
