import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Color(0xFF07090E),
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF07090E),
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const GuitarStudioApp());
}

class GuitarStudioApp extends StatelessWidget {
  const GuitarStudioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Guitar Studio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF07090E),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFFB300),
          surface: Color(0xFF07090E),
        ),
      ),
      home: const GuitarStudioHome(),
    );
  }
}

class GuitarStudioHome extends StatefulWidget {
  const GuitarStudioHome({super.key});

  @override
  State<GuitarStudioHome> createState() => _GuitarStudioHomeState();
}

class _GuitarStudioHomeState extends State<GuitarStudioHome> {
  static const MethodChannel _platform = MethodChannel('com.leadingnote.guitar_studio/server');
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _errorMessage;
  String? _localUrl;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    // 1. Request microphone permission on startup for guitar audio detection
    await Permission.microphone.request();

    // 2. Query local embedded server URL from Android native layer
    try {
      final String url = await _platform.invokeMethod('getServerUrl');
      debugPrint('GuitarStudio: Local server URL is $url');
      setState(() => _localUrl = url);
      _setupWebView(url);
    } catch (e) {
      debugPrint('GuitarStudio: Failed to get server URL: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to start local server: $e';
      });
    }
  }

  void _setupWebView(String url) {
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is AndroidWebViewPlatform) {
      params = AndroidWebViewControllerCreationParams();
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final WebViewController controller = WebViewController.fromPlatformCreationParams(params);

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF07090E))
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36 GuitarStudioNative',
      )
      ..setOnConsoleMessage((JavaScriptConsoleMessage message) {
        debugPrint('JS [${message.level.name}]: ${message.message}');
      })
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (u) {
            debugPrint('GuitarStudio: Page started: $u');
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (u) {
            debugPrint('GuitarStudio: Page finished: $u');
            if (mounted) setState(() => _isLoading = false);
          },
          onWebResourceError: (error) {
            debugPrint('GuitarStudio: WebResourceError: ${error.description} on ${error.url}');
            if (mounted) {
              setState(() {
                _isLoading = false;
                _errorMessage = 'Error loading resource: ${error.description}';
              });
            }
          },
        ),
      );

    // Enable Android WebChromeClient permission requests for Web Audio / Mic
    if (controller.platform is AndroidWebViewController) {
      final androidController = controller.platform as AndroidWebViewController;
      androidController.setMediaPlaybackRequiresUserGesture(false);
      androidController.setOnPlatformPermissionRequest((request) async {
        request.grant();
      });
    }

    controller.loadRequest(Uri.parse(url));
    _controller = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07090E),
      body: SafeArea(
        top: true,
        bottom: true,
        child: Stack(
          children: [
            if (_localUrl != null)
              WebViewWidget(controller: _controller),

            if (_isLoading)
              Container(
                color: const Color(0xFF07090E),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        color: Color(0xFFFFB300),
                        strokeWidth: 3,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Starting Guitar Studio...',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            if (_errorMessage != null)
              Container(
                color: const Color(0xFF07090E),
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, color: Color(0xFFFF5252), size: 48),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFB300),
                          foregroundColor: Colors.black,
                        ),
                        onPressed: () {
                          setState(() {
                            _errorMessage = null;
                            _isLoading = true;
                          });
                          _initApp();
                        },
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
