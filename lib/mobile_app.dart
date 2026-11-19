import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';


class SiteMobileApp extends StatelessWidget {
  const SiteMobileApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'LoadSecure',
    debugShowCheckedModeBanner: false,
    theme: ThemeData.dark(useMaterial3: true).copyWith(
      scaffoldBackgroundColor: Colors.black,
      colorScheme: const ColorScheme.dark(primary: Color(0xffff001a)),
    ),
    home: const MobileSite(),
  );
}

class MobileSite extends StatefulWidget {
  const MobileSite({super.key});
  @override
  State<MobileSite> createState() => _MobileSiteState();
}

class _MobileSiteState extends State<MobileSite> {
  static const url = String.fromEnvironment(
    'LOADSECURE_SITE_URL',
    defaultValue:
        'https://loadsecure-flutter.lucashenriquesilvacp.chatgpt.site',
  );
  late final WebViewController controller;
  int progress = 0;
  bool failed = false;
  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) =>
              Uri.tryParse(request.url)?.scheme == 'https'
              ? NavigationDecision.navigate
              : NavigationDecision.prevent,
          onPageStarted: (_) {
            if (mounted) {
              setState(() {
                failed = false;
                progress = 0;
              });
            }
          },
          onProgress: (value) {
            if (mounted) setState(() => progress = value);
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame == true && mounted) {
              setState(() => failed = true);
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(url));
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, result) async {
      if (didPop) return;
      if (await controller.canGoBack()) {
        await controller.goBack();
      } else {
        SystemNavigator.pop();
      }
    },
    child: Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(child: WebViewWidget(controller: controller)),
            if (progress < 100 && !failed)
              Align(
                alignment: Alignment.topCenter,
                child: LinearProgressIndicator(
                  value: progress / 100,
                  color: const Color(0xffff001a),
                  backgroundColor: const Color(0xff181818),
                ),
              ),
            if (failed)
              Positioned.fill(
                child: Container(
                  color: Colors.black,
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset('assets/logo.png', height: 70),
                      const SizedBox(height: 24),
                      const Text(
                        'Não foi possível abrir o LoadSecure.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Confira sua conexão e tente novamente.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: () => controller.loadRequest(Uri.parse(url)),
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
