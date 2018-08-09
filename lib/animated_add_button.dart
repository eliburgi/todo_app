import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:todo_app/utils.dart';

class AnimatedAddButton extends StatefulWidget {
  AnimatedAddButton({
    this.height = 60.0,
    this.widthCollapsed = 200.0,
    this.widthExpanded = 300.0,
    this.colorCollapsed = Colors.black87,
    this.colorExpanded = Colors.white,
    this.textCollapsed = "Add item",
    this.textColorCollapsed = Colors.white,
    this.borderColorCollapsed = Colors.black87,
    this.borderColorExpanded = const Color(0xFFE0E0E0),
    this.borderWidth = 0.6,
    this.borderRadius = 100.0,
    this.iconColorCollapsed = Colors.white,
    this.iconColorExpanded = Colors.black87,
    @required this.onSubmit,
    this.onClick,
  })  : assert(height > 0.0),
        assert(widthCollapsed > 0.0),
        assert(widthExpanded >= widthCollapsed),
        assert(borderWidth > 0.0),
        assert(onSubmit != null);

  final double height;
  final double widthCollapsed;
  final double widthExpanded;
  final Color colorCollapsed;
  final Color colorExpanded;
  final String textCollapsed;
  final Color textColorCollapsed;
  final Color borderColorCollapsed;
  final Color borderColorExpanded;
  final double borderWidth;
  final double borderRadius;
  final Color iconColorCollapsed;
  final Color iconColorExpanded;
  final ValueChanged<String> onSubmit;
  final VoidCallback onClick;

  @override
  _AnimatedAddButtonState createState() => _AnimatedAddButtonState();
}

class _AnimatedAddButtonState extends State<AnimatedAddButton>
    with TickerProviderStateMixin {
  bool _isExpanded = false;
  AnimationController _controller;
  Animation<double> _widthAnim;
  Animation<double> _textOpacityAnim;
  Animation<HSVColor> _colorAnim;
  Animation<HSVColor> _borderColorAnim;

  AnimationController _addCancelController;
  Animation<double> _addCancelRotationAnim;

  String _input = '';

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _controller.addStatusListener((status) {
      print(status);
      if (status == AnimationStatus.completed) {
        setState(() {
          _isExpanded = true;
        });
      } else if (status == AnimationStatus.dismissed) {
        setState(() {
          _isExpanded = false;
        });
        _submit();
      }
    });
    _controller.addListener(() {
      setState(() {});
    });

    _widthAnim = _animationWithCurve(
      tween: Tween<double>(
        begin: widget.widthCollapsed,
        end: widget.widthExpanded,
      ),
      curve: Decelerate(),
    );
    _textOpacityAnim = _animationWithCurve(
      tween: Tween<double>(begin: 1.0, end: 0.0),
      curve: Decelerate(),
    );
    _colorAnim = _animationWithCurve(
        tween: HSVColorTween(
          begin: HSVColor.fromColor(widget.colorCollapsed),
          end: HSVColor.fromColor(widget.colorExpanded),
        ),
        curve: Decelerate());
    _borderColorAnim = _animationWithCurve(
      tween: HSVColorTween(
        begin: HSVColor.fromColor(widget.borderColorCollapsed),
        end: HSVColor.fromColor(widget.borderColorExpanded),
      ),
      curve: Decelerate(),
    );

    _addCancelController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );

    _addCancelRotationAnim = Tween<double>(
      begin: 0.125,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _addCancelController,
      curve: Overshoot(),
    ));
  }

  _animationWithCurve({@required Tween tween, @required Curve curve}) =>
      tween.animate(CurvedAnimation(parent: _controller, curve: curve));

  @override
  void dispose() {
    _controller.dispose();
    _addCancelController.dispose();
    super.dispose();
  }

  _expand() {
    if (_controller.isAnimating) return;
    _controller.forward();
  }

  _collapse() {
    if (_controller.isAnimating) return;
    _controller.reverse();
  }

  _onInputChanged(String value) {
    if (_input.isEmpty && value.isNotEmpty) {
      _addCancelController.forward();
    } else if (_input.isNotEmpty && value.isEmpty) {
      _addCancelController.reverse();
    }
    setState(() {
      _input = value;
    });
  }

  _submit() {
    if (_input == null || _input.isEmpty) return;
    widget.onSubmit(_input);
    // clear input
    _input = '';
    _addCancelController.reset();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller.isAnimating) {
      return _buildAnimation();
    } else if (_isExpanded) {
      return _buildInput();
    } else {
      return _buildButton();
    }
  }

  _buildButton() {
    return SizedBox(
      height: widget.height,
      width: widget.widthCollapsed,
      child: FlatButton(
        onPressed: _expand,
        color: widget.colorCollapsed,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: widget.borderColorCollapsed,
            width: widget.borderWidth,
          ),
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.add,
              size: 20.0,
              color: widget.iconColorCollapsed,
            ),
            Padding(
                padding: const EdgeInsets.only(
              left: 8.0,
            )),
            Text(
              widget.textCollapsed,
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.w400,
                color: widget.textColorCollapsed,
              ),
            ),
          ],
        ),
      ),
    );
  }

  _buildInput() {
    print(_addCancelRotationAnim.value);
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: widget.widthExpanded,
      ),
      child: Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: widget.colorExpanded,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(
            color: widget.borderColorExpanded,
            width: widget.borderWidth,
          ),
        ),
        padding: const EdgeInsets.symmetric(
          vertical: 8.0,
          horizontal: 24.0,
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                decoration: null,
                onChanged: _onInputChanged,
                autofocus: true,
              ),
            ),
            RotationTransition(
              turns: _addCancelRotationAnim,
              child: IconButton(
                icon: Icon(
                  Icons.add,
                  color: widget.iconColorExpanded,
                ),
                onPressed: _collapse,
              ),
            ),
          ],
        ),
      ),
    );
  }

  _buildAnimation() {
    return Container(
      height: widget.height,
      width: _widthAnim.value,
      decoration: BoxDecoration(
        color: _colorAnim.value.toColor(),
        border: Border.all(
          color: _borderColorAnim.value.toColor(),
          width: widget.borderWidth,
        ),
        borderRadius: BorderRadius.circular(widget.borderRadius),
        shape: BoxShape.rectangle,
      ),
    );
  }
}

class Decelerate extends Curve {
  @override
  double transform(double t) => 1 - pow(1 - t, 2 * 1.5);
}

class HSVColorTween extends Tween<HSVColor> {
  HSVColorTween({HSVColor begin, HSVColor end}) : super(begin: begin, end: end);

  @override
  HSVColor lerp(double t) => HSVColor.lerp(begin, end, t);
}
