import 'package:flutter/material.dart';
import 'package:todo_app/utils.dart';

// Renders animated strike-through text.
// If value changes from false to true:
//    -> renders strike-through animation on top of the given text
// I value changes from true to false:
//    -> renders reverse strike-through animation on top of the given text
class AnimatedText extends StatefulWidget {
  AnimatedText({
    @required this.text,
    this.value = false,
  });

  final bool value;
  final Text text;

  @override
  _AnimatedTextState createState() => _AnimatedTextState();
}

class _AnimatedTextState extends State<AnimatedText> {
  double textWidth;

  @override
  void initState() {
    super.initState();
    textWidth = calculateTextSize(widget.text).width + 5;
  }

  @override
  Widget build(BuildContext context) {
    var width = widget.value ? textWidth : 0.0;
    return Stack(
      alignment: AlignmentDirectional.centerStart,
      children: <Widget>[
        widget.text,
        AnimatedContainer(
          alignment: AlignmentDirectional.center,
          duration: Duration(milliseconds: 300),
          curve: Curves.decelerate,
          width: width,
          height: 1.5,
          color: Colors.black87,
        )
      ],
    );
  }
}

// Will only animate text strike-through once from left to right.
class OneShotAnimatedText extends StatelessWidget {
  OneShotAnimatedText({
    @required this.text,
    @required this.animation,
  }) : size = calculateTextSize(text);

  final Text text;
  final Animation<double> animation;
  final Size size;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        text,
        AnimatedBuilder(
          animation: animation,
          builder: (context, child) => CustomPaint(
                painter: _OneShotPainter(animation),
                size: size,
              ),
        ),
      ],
    );
  }
}

class _OneShotPainter extends CustomPainter {
  _OneShotPainter(this.animation);

  final Animation<double> animation;

  @override
  void paint(Canvas canvas, Size size) {
    if (animation.value <= 0.5) {
      _paintExpand(canvas, size, animation.value / 0.5);
    } else {
      _paintCollapse(canvas, size, (animation.value - 0.5) / 0.5);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;

  _paintExpand(Canvas canvas, Size size, double progress) {
    final strokePaint = Paint();
    strokePaint.color = Colors.black87;
    strokePaint.style = PaintingStyle.stroke;
    strokePaint.strokeWidth = 1.5;

    final leftPoint = size.centerLeft(Offset.zero);
    final rightPoint = leftPoint + Offset(size.width * progress, 0.0);
    canvas.drawLine(leftPoint, rightPoint, strokePaint);
  }

  _paintCollapse(Canvas canvas, Size size, double progress) {
    final strokePaint = Paint();
    strokePaint.color = Colors.black87;
    strokePaint.style = PaintingStyle.stroke;
    strokePaint.strokeWidth = 1.5;

    final rightPoint = size.centerRight(Offset.zero);
    final leftPoint =
        size.centerLeft(Offset.zero) + Offset(size.width * progress, 0.0);
    canvas.drawLine(leftPoint, rightPoint, strokePaint);
  }
}
