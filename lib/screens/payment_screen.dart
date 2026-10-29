import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'payment_web_stub.dart'
    if (dart.library.js_interop) 'payment_web.dart' as web_payment;
import 'main_shell.dart';

class PaymentScreen extends StatefulWidget {
  final Uri paymentUrl;

  const PaymentScreen({super.key, required this.paymentUrl});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late final Widget _webPayment;
  WebViewController? _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _webPayment = web_payment.buildEmbeddedPayment(widget.paymentUrl);
    _openPayment();
  }

  Future<void> _openPayment() async {
    try {
      if (kIsWeb) {
        return;
      }

      if (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS) {
        final controller = WebViewController();
        await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
        await controller.setNavigationDelegate(
          NavigationDelegate(
            onWebResourceError: (error) {
              if (!mounted || error.isForMainFrame == false) return;
              setState(
                  () => _error = 'Payment page error: ${error.description}');
            },
          ),
        );
        if (mounted) setState(() => _controller = controller);
        await controller.loadRequest(widget.paymentUrl);
        return;
      }

      if (mounted) {
        setState(() {
          _error = 'In-app payment is not available on this platform.';
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    }
  }

  void _exitToHome() {
    Navigator.of(context).popUntil((route) => route.isFirst);
    mainShellKey.currentState?.selectShop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Xendit payment'),
        actions: [
          TextButton.icon(
            onPressed: _exitToHome,
            icon: const Icon(Icons.home_outlined),
            label: const Text('Exit to home'),
          ),
        ],
      ),
      body: kIsWeb
          ? _webPayment
          : _controller != null
              ? WebViewWidget(controller: _controller!)
              : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_error!, textAlign: TextAlign.center),
                            const SizedBox(height: 12),
                            FilledButton(
                              onPressed: () => setState(() {
                                _error = null;
                                _openPayment();
                              }),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    )
                    : const Center(child: CircularProgressIndicator()),
    );
  }
}
