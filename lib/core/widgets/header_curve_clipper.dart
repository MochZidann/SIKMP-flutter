import 'package:flutter/material.dart';

/// Clipper untuk background melengkung di bagian atas dashboard di semua role
class HeaderCurveClipper extends CustomClipper<Path> {
  final double curveDepth;

  const HeaderCurveClipper({this.curveDepth = 38.0});

  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - curveDepth);
    // Lengkungan tegas, proporsional, dan dinamis di tengah agak ke atas card
    path.quadraticBezierTo(
      size.width / 2,
      size.height,
      size.width,
      size.height - curveDepth,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant HeaderCurveClipper oldClipper) =>
      oldClipper.curveDepth != curveDepth;
}
