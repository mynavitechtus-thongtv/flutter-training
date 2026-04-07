import 'package:flutter/material.dart';

/// Base abstract class for all popups in the app
/// Each popup widget should implement this and provide its own unique id
abstract class BasePopup extends StatelessWidget {
  const BasePopup({required this.popupId, super.key});

  final String popupId;
  Widget buildPopup(BuildContext context);

  @override
  Widget build(BuildContext context) {
    return buildPopup(context);
  }
}
