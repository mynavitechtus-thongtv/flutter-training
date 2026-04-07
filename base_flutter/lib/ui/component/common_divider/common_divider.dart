import 'package:flutter/material.dart';

class CommonDivider extends StatelessWidget {
  const CommonDivider({
    super.key,
    this.direction = DividerDirection.horizontal,
    this.dividerColor,
    this.thickness,
    this.indent,
    this.endIndent,
  });

  final DividerDirection direction;
  final Color? dividerColor;
  final double? thickness;
  final double? indent;
  final double? endIndent;

  @override
  Widget build(BuildContext context) {
    return direction == DividerDirection.horizontal
        ? SizedBox(
            height: 1,
            // ignore: prefer_common_widgets
            child: Divider(
              height: thickness,
              color: dividerColor,
              indent: indent,
              endIndent: endIndent,
            ),
          )
        : SizedBox(
            width: 1,
            // ignore: prefer_common_widgets
            child: VerticalDivider(
              width: thickness,
              color: dividerColor,
              indent: indent,
              endIndent: endIndent,
            ),
          );
  }
}

enum DividerDirection {
  vertical,
  horizontal,
}
