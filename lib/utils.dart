import 'dart:math';

import 'package:flutter/material.dart';

class Margin extends Padding {
  Margin({
    double top = 0.0,
    double right = 0.0,
    double bottom = 0.0,
    double left = 0.0,
  }) : super(
          padding: EdgeInsets.only(
            top: top,
            right: right,
            bottom: bottom,
            left: left,
          ),
        );
}

class HorizontalLine extends StatelessWidget {
  HorizontalLine({
    this.color = Colors.grey,
    this.height = 1.0,
    this.width = double.infinity,
  });

  final Color color;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: color,
    );
  }
}

Widget buildHeroText({tag, Text text}) {
  // it is necessary to wrap the text with a Material widget
  // otherwise there will be a visual bug when the hero animation is playing
  // there is an issue about that problem somewhere on flutter´s github
  return Hero(
    tag: tag,
    child: Material(
      color: Colors.transparent,
      child: text,
    ),
  );
}

Size calculateTextSize(Text text) {
  final tp = TextPainter(
    text: TextSpan(
      text: text.data,
      style: text.style,
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  return Size(tp.width, tp.height);
}

class Overshoot extends Curve {
  @override
  double transform(double t) => 3 * pow(t - 1, 3) + 2 * pow(t - 1, 2) + 1;
}
