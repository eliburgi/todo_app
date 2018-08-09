import 'package:flutter/material.dart';

// Custom circular check box with custom animations.
class AnimatedCheckBox extends StatefulWidget {
  AnimatedCheckBox({
    this.value = false,
    @required this.onValueChanged,
    this.duration = const Duration(milliseconds: 200),
    this.checkedColor = Colors.black87,
    this.uncheckedColor = const Color(0xFFE0E0E0),
    this.borderWidth = 1.5,
  });

  final bool value;
  final ValueChanged<bool> onValueChanged;
  final Duration duration;
  final Color checkedColor;
  final Color uncheckedColor;
  final double borderWidth;

  @override
  _AnimatedCheckBoxState createState() => _AnimatedCheckBoxState();
}

class _AnimatedCheckBoxState extends State<AnimatedCheckBox> {
  @override
  Widget build(BuildContext context) {
    final size = widget.value ? 18.0 : 0.0;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Stack(
        alignment: AlignmentDirectional.center,
        children: [
          AnimatedContainer(
            duration: widget.duration,
            curve: Curves.decelerate,
            width: 18.0,
            height: 18.0,
            decoration: BoxDecoration(
              border: _buildBorder(),
              shape: BoxShape.circle,
            ),
          ),
          AnimatedContainer(
            duration: widget.duration,
            curve: Curves.decelerate,
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: widget.checkedColor,
              shape: BoxShape.circle,
            ),
          )
        ],
      ),
    );
  }

  _buildBorder() {
    return widget.value
        ? null
        : Border.all(
            color: widget.uncheckedColor,
            width: widget.borderWidth,
          );
  }
}

// This may not even be a checkbox, more an animated dot.
// When the animation starts, the checkbox will play checked animation
// and then immediately after that it will start shrinking until
// it is no longer visible.
class OneShotCheckbox extends StatelessWidget {
  OneShotCheckbox({@required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) => CustomPaint(
              painter: _OneShotPainter(animation),
              size: Size.square(18.0),
            ),
      ),
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
    final borderPaint = Paint();
    borderPaint.color = const Color(0xFFE0E0E0);
    borderPaint.style = PaintingStyle.stroke;
    borderPaint.strokeWidth = 1.5;

    final solidPaint = Paint();
    solidPaint.color = Colors.black87;
    solidPaint.style = PaintingStyle.fill;

    final radius = size.shortestSide / 2;
    final center = size.center(Offset.zero);
    canvas.drawCircle(center, radius, borderPaint);
    canvas.drawCircle(center, radius * progress, solidPaint);
  }

  _paintCollapse(Canvas canvas, Size size, double progress) {
    final solidPaint = Paint();
    solidPaint.color = Colors.black87;
    solidPaint.style = PaintingStyle.fill;

    final radius = size.shortestSide / 2;
    final center = size.center(Offset.zero);
    canvas.drawCircle(center, radius * (1 - progress), solidPaint);
  }
}
