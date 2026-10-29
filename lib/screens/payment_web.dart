// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';

int _nextPaymentViewId = 0;

Widget buildEmbeddedPayment(Uri paymentUrl) {
  final viewType = 'technologia-xendit-payment-${_nextPaymentViewId++}';
  ui_web.platformViewRegistry.registerViewFactory(viewType, (viewId) {
    final frame = html.IFrameElement()
      ..src = paymentUrl.toString()
      ..title = 'Xendit secure payment'
      ..allow = 'payment *'
      ..referrerPolicy = 'strict-origin-when-cross-origin'
      ..style.border = '0'
      ..style.width = '100%'
      ..style.height = '100%';
    return frame;
  });

  return HtmlElementView(viewType: viewType);
}
