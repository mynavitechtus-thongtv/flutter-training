import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';

class CommonText extends StatelessWidget {
  // ignore: prefer_named_parameters
  const CommonText(
    this.text, {
    required this.style,
    super.key,
    this.onTap,
    this.maxLines,
    this.overflow,
    this.textAlign,
    this.enableLinkify = false,
    this.onOpenLink,
  });

  final String? text;
  final VoidCallback? onTap;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;
  final bool enableLinkify;
  final void Function(String)? onOpenLink;

  /// Factory constructor for linkified text (text with clickable URLs)
  // ignore: prefer_named_parameters
  factory CommonText.linkify(
    String? text, {
    required TextStyle? style,
    required void Function(String) onOpenLink,
    Key? key,
    int? maxLines,
    TextOverflow? overflow,
    TextAlign? textAlign,
  }) {
    return CommonText(
      text,
      key: key,
      style: style,
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
      enableLinkify: true,
      onOpenLink: onOpenLink,
    );
  }

  /// Factory constructor for tappable text
  // ignore: prefer_named_parameters
  factory CommonText.canTap(
    String? text, {
    required TextStyle? style,
    required VoidCallback onTap,
    Key? key,
    int? maxLines,
    TextOverflow? overflow,
    TextAlign? textAlign,
  }) {
    return CommonText(
      text,
      key: key,
      style: style,
      onTap: onTap,
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
    );
  }

  @override
  Widget build(BuildContext context) {
    final textWidget = enableLinkify
        ? Linkify(
            text: text ?? (kDebugMode ? '' : ''),
            style: style,
            maxLines: maxLines,
            overflow: overflow ?? TextOverflow.clip,
            textAlign: textAlign ?? TextAlign.start,
            onOpen: (link) => onOpenLink,
            options: const LinkifyOptions(looseUrl: true),
          )
        // ignore: prefer_common_widgets
        : Text(
            text ?? '',
            style: style,
            maxLines: maxLines,
            overflow: overflow,
            textAlign: textAlign,
          );

    return onTap != null
        ? GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.translucent,
            child: textWidget,
          )
        : textWidget;
  }
}
