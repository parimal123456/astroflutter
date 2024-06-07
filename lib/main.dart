import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' show Matrix4, Vector3;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'XYZ Axes',
      home: AxesPage(),
    );
  }
}

class AxesPage extends StatefulWidget {
  @override
  _AxesPageState createState() => _AxesPageState();
}

class _AxesPageState extends State<AxesPage> {
  double _angleX = 0.0;
  double _angleY = 0.0;
  TransformationController _transformationController = TransformationController();

  void resetAxes() {
    setState(() {
      _angleX = 0.0;
      _angleY = 0.0;
      _transformationController.value = Matrix4.identity();
    });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Model Earth',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.grey[900],
      ),
      body: Container(
        color: Colors.black,
        child: Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.96,
            height: MediaQuery.of(context).size.height * 0.96,
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  _angleX += details.delta.dy * 0.01;
                  _angleY += details.delta.dx * 0.01;
                });
              },
              child: InteractiveViewer(
                transformationController: _transformationController,
                boundaryMargin: EdgeInsets.all(50),
                minScale: 0.5,
                maxScale: 5.0,
                child: CustomPaint(
                  painter: AxesPainter(_angleX, _angleY),
                  foregroundPainter: StarPainter(random: math.Random()),
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: resetAxes,
        child: Icon(Icons.refresh),
      ),
    );
  }
}

class AxesPainter extends CustomPainter {
  final double angleX;
  final double angleY;

  AxesPainter(this.angleX, this.angleY);

  @override
  void paint(Canvas canvas, Size size) {
    final double axisLength = size.width / 1.4;
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;
    canvas.translate(centerX, centerY);

    // Initial rotation matrix for the Z-axis
    final initialRotationMatrixZ = Matrix4.rotationX(math.pi / 2);
    final rotationMatrixX = Matrix4.rotationX(angleX);
    final rotationMatrixY = Matrix4.rotationY(angleY);

    // Combine the rotations
    final transformMatrix = initialRotationMatrixZ.clone()
      ..multiply(rotationMatrixX)
      ..multiply(rotationMatrixY);

    // Draw the axes and the sphere
    _drawAxes(canvas, axisLength, transformMatrix);
    _drawSphere(canvas, size, transformMatrix);

    final double sphereRadius = size.width / 1;
    // Draw Earth, Moon, and Sun
    _drawEarth(canvas, Offset.zero, sphereRadius, 0, 0, transformMatrix);
    _drawMoon(canvas, Offset.zero, sphereRadius, -45, 45, transformMatrix);
    _drawSun(canvas, Offset.zero, sphereRadius, 70, 225, transformMatrix);
  }

  void _drawAxes(Canvas canvas, double axisLength, Matrix4 transformMatrix) {
    final axisPaint = Paint()
      ..color = const Color.fromARGB(221, 252, 252, 252)
      ..strokeWidth = 2.5;

    final xAxisEnd = Vector3(axisLength, 0, 0);
    final yAxisEnd = Vector3(0, axisLength, 0);
    final zAxisEnd = Vector3(0, 0, axisLength);
    final negXAxisEnd = Vector3(-axisLength, 0, 0);
    final negYAxisEnd = Vector3(0, -axisLength, 0);
    final negZAxisEnd = Vector3(0, 0, -axisLength);

    _drawAxisLine(canvas, axisPaint, transformMatrix, xAxisEnd, 'X');
    _drawAxisLine(canvas, axisPaint, transformMatrix, yAxisEnd, 'Y');
    _drawAxisLine(canvas, axisPaint, transformMatrix, zAxisEnd, 'Z');
    _drawAxisLine(canvas, axisPaint, transformMatrix, negXAxisEnd, '-X');
    _drawAxisLine(canvas, axisPaint, transformMatrix, negYAxisEnd, '-Y');
    _drawAxisLine(canvas, axisPaint, transformMatrix, negZAxisEnd, '-Z');
  }

  void _drawAxisLine(Canvas canvas, Paint paint, Matrix4 transformMatrix,
      Vector3 axisEnd, String label) {
    final transformedAxisEnd = transformMatrix.transform3(axisEnd);
    canvas.drawLine(
      Offset(0, 0),
      Offset(transformedAxisEnd.x, transformedAxisEnd.y),
      paint,
    );
    _drawText(canvas, label, Offset(transformedAxisEnd.x, transformedAxisEnd.y),
        Colors.red);
  }

  void _drawText(Canvas canvas, String text, Offset position, Color color) {
    final TextSpan span = TextSpan(
      style: TextStyle(color: color),
      text: text,
    );
    final TextPainter tp = TextPainter(
      text: span,
      textAlign: TextAlign.left,
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, position);
  }

  void _drawSphere(Canvas canvas, Size size, Matrix4 transformMatrix) {
    final double sphereRadius = size.width / 1;
    final Paint spherePaint = Paint()..color = Colors.blue.withOpacity(0.5);
    final transformedCenter = transformMatrix.getTranslation();
    final offsetCenter = Offset(transformedCenter.x, transformedCenter.y);
    canvas.drawCircle(offsetCenter, sphereRadius, spherePaint);

    // Draw latitude and longitude lines
    for (double lat = -90; lat <= 90; lat += 10) {
      _drawLatitude(canvas, offsetCenter, sphereRadius, lat, transformMatrix);
    }

    for (double lon = -180; lon <= 180; lon += 10) {
      _drawLongitude(canvas, offsetCenter, sphereRadius, lon, transformMatrix);
    }
  }

  void _drawLatitude(Canvas canvas, Offset center, double radius,
      double latitude, Matrix4 transformMatrix) {
    final Paint paint = Paint()..color = Colors.blue.withOpacity(0.5);
    final double angle = latitude * math.pi / 180;
    final double offsetY = radius * math.sin(angle);

    for (double lon = -180; lon <= 180; lon += 5) {
      final double angleLon = lon * math.pi / 180;
      final double offsetX = radius * math.cos(angle) * math.cos(angleLon);
      final double offsetZ = radius * math.cos(angle) * math.sin(angleLon);

      final transformedPoint =
      transformMatrix.transform3(Vector3(offsetX, offsetY, offsetZ));
      final point = Offset(transformedPoint.x, transformedPoint.y);

      canvas.drawCircle(point, 2, paint);
    }
  }

  void _drawLongitude(Canvas canvas, Offset center, double radius,
      double longitude, Matrix4 transformMatrix) {
    final Paint paint = Paint()..color = Colors.blue.withOpacity(0.7);
    final double angle = longitude * math.pi / 180;

    final List<Vector3> points = [];
    final int segments = 50;

    for (int i = 0; i <= segments; i++) {
      final double latAngle = (i / segments) * math.pi - (math.pi / 2);
      final double x = radius * math.cos(latAngle) * math.cos(angle);
      final double y = radius * math.sin(latAngle);
      final double z = radius * math.cos(latAngle) * math.sin(angle);
      final transformedPoint = transformMatrix.transform3(Vector3(x, y, z));
      points.add(transformedPoint);
    }

    for (int i = 0; i < points.length - 1; i++) {
      final startPoint = points[i];
      final endPoint = points[i + 1];
      _drawLineOnSphere(canvas, paint, startPoint, endPoint);
    }
  }

  void _drawLineOnSphere(
      Canvas canvas, Paint paint, Vector3 start, Vector3 end) {
    final startPoint = Offset(start.x, start.y);
    final endPoint = Offset(end.x, end.y);
    canvas.drawLine(startPoint, endPoint, paint);
  }

  void _drawEarth(Canvas canvas, Offset center, double radius, double latitude,
      double longitude, Matrix4 transformMatrix) {
    final Paint paint = Paint()..color = Colors.green;

    final double latRadians = latitude * math.pi / 180;
    final double lonRadians = longitude * math.pi / 180;

    final double x = 0*math.cos(latRadians) * math.cos(lonRadians);
    final double y = 0*math.sin(latRadians);
    final double z = 0*math.cos(latRadians) * math.sin(lonRadians);

    final transformedPoint = transformMatrix.transform3(Vector3(x, y, z));

    final point = Offset(transformedPoint.x, transformedPoint.y);
    canvas.drawCircle(point, radius*0.1, paint);
  }

  void _drawMoon(Canvas canvas, Offset center, double radius, double latitude,
      double longitude, Matrix4 transformMatrix) {
    final Paint paint = Paint()..color = Colors.white;

    final double latRadians = latitude * math.pi / 180;
    final double lonRadians = longitude * math.pi / 180;

    final double x = 0.3*radius * math.cos(latRadians) * math.cos(lonRadians);
    final double y = 0.3*radius * math.sin(latRadians);
    final double z = 0.3*radius * math.cos(latRadians) * math.sin(lonRadians);

    final transformedPoint = transformMatrix.transform3(Vector3(x, y, z));

    final point = Offset(transformedPoint.x, transformedPoint.y);
    canvas.drawCircle(point, 0.07*radius, paint);
  }

  void _drawSun(Canvas canvas, Offset center, double radius, double latitude,
      double longitude, Matrix4 transformMatrix) {
    final Paint paint = Paint()..color = Colors.red;

    final double latRadians = latitude * math.pi / 180;
    final double lonRadians = longitude * math.pi / 180;

    final double x = 0.5*radius * math.cos(latRadians) * math.cos(lonRadians);
    final double y = 0.5*radius * math.sin(latRadians);
    final double z = 0.5*radius * math.cos(latRadians) * math.sin(lonRadians);

    final transformedPoint = transformMatrix.transform3(Vector3(x, y, z));

    final point = Offset(transformedPoint.x, transformedPoint.y);
    canvas.drawCircle(point, 0.15*radius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class StarPainter extends CustomPainter {
  final int numStars;
  final math.Random random;

  StarPainter({this.numStars = 10, required this.random});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;

    for (int i = 0; i < numStars; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 2;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}