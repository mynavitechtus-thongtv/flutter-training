import 'package:flutter/material.dart';

import '../../../index.dart';

class AvatarView extends StatelessWidget {
  const AvatarView({
    required this.text,
    this.textStyle,
    this.isActive = false,
    super.key,
    this.width,
    this.height,
    this.backgroundColor,
  });

  final String text;
  final double? width;
  final double? height;
  final bool isActive;
  final Color? backgroundColor;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final width = this.width ?? 60;
    final height = this.height ?? 60;
    final borderRadius = BorderRadius.circular(width / 2);
    const activeBorderRadius = BorderRadius.all(Radius.circular(7));

    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: backgroundColor ?? color.black,
        borderRadius: borderRadius,
        border: Border.all(color: color.black),
      ),
      child: Stack(
        children: [
          Center(
            child: CommonText(
              text.trim().firstOrNull?.toUpperCase(),
              style: textStyle ??
                  style(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: color.white,
                  ),
            ),
          ),
          Visibility(
            visible: isActive,
            child: Align(
              alignment: Alignment.bottomRight,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: color.green1,
                  borderRadius: activeBorderRadius,
                  border: Border.all(color: color.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
