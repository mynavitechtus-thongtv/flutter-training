import 'package:flutter/material.dart';

import '../../../index.dart';

class PrimaryTextField extends StatefulWidget {
  const PrimaryTextField({
    required this.title,
    required this.hintText,
    this.onEyeIconPressed,
    this.suffixIcon,
    this.controller,
    this.onChanged,
    this.keyboardType = TextInputType.text,
    super.key,
  });

  final String title;
  final String hintText;
  final Widget? suffixIcon;
  final void Function(String)? onChanged;
  final TextInputType keyboardType;
  final TextEditingController? controller;
  final void Function(bool)? onEyeIconPressed;

  @override
  State<PrimaryTextField> createState() => _PrimaryTextFieldState();
}

class _PrimaryTextFieldState extends State<PrimaryTextField>
    with WidgetsBindingObserver, RefocusOnResumeMixin<PrimaryTextField> {
  late FocusNode _focusNode;
  bool _obscureText = true;

  @override
  bool get canManageFocus => true;

  @override
  FocusNode? get focusNode => _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _obscureText = widget.keyboardType == TextInputType.visiblePassword;
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  bool get _isPassword => widget.keyboardType == TextInputType.visiblePassword;

  @override
  Widget build(BuildContext context) {
    // ignore: missing_expanded_or_flexible
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: CommonText(
            widget.title,
            style: style(
              fontSize: 14,
              color: color.black,
            ),
          ),
        ),
        TextField(
          focusNode: _focusNode,
          onChanged: widget.onChanged,
          controller: widget.controller,
          style: style(
            fontSize: 14,
            color: color.black,
          ),
          decoration: InputDecoration(
            hintStyle: style(
              fontSize: 14,
              color: color.grey1,
            ),
            hintText: widget.hintText,
            suffixIcon: _isPassword
                ? GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                      widget.onEyeIconPressed?.call(_obscureText);
                    },
                    child: _obscureText
                        ? CommonImage.iconData(iconData: Icons.visibility_off)
                        : CommonImage.iconData(iconData: Icons.visibility),
                  )
                : widget.suffixIcon,
          ),
          keyboardType: widget.keyboardType,
          obscureText: _isPassword ? _obscureText : false,
        ),
      ],
    );
  }
}
