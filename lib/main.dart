import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Включаем удержание процессора, чтобы музыка не спала
  WakelockPlus.enable();
  
  // Инициализируем фоновый сервис Android
  await initializeService();
  
  runApp(const MyApp());
}

// Настройка фонового сервиса Android
Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true, // Говорим Android, что это важное фоновое приложение
      notificationChannelId: 'my_foreground',
      initialNotificationTitle: 'YouTube Background Player',
      initialNotificationContent: 'Приложение работает в фоновом режиме',
      foregroundServiceTypes: [AndroidForegroundServiceType.mediaPlayback],
    ),
    iosConfiguration: IosConfiguration(),
  );
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  
  // Этот код просто держит службу активной в фоне
  Timer.periodic(const Duration(seconds: 1), (timer) async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        service.setAsForegroundService();
      }
    }
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Background YouTube',
      theme: ThemeData.dark(),
      home: const YouTubeScreen(),
    );
  }
}

class YouTubeScreen extends StatefulWidget {
  const YouTubeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const YouTubeScreenStateful();
  }
}

class YouTubeScreenStateful extends StatefulWidget {
  const YouTubeScreenStateful({super.key});

  @override
  State<YouTubeScreenStateful> createState() => _YouTubeScreenState();
}

class _YouTubeScreenState extends State<YouTubeScreenStateful> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..clearCache()
      ..setUserAgent(
        "Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36"
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            // Обман плеера YouTube, чтобы он думал, что вкладка активна
            _controller.runJavaScript('''
              Object.defineProperty(document, 'hidden', {get: function() { return false; }, configurable: true});
              Object.defineProperty(document, 'visibilityState', {get: function() { return 'visible'; }, configurable: true});
              document.dispatchEvent(new Event('visibilitychange'));
            ''');
          },
        ),
      )
      ..loadRequest(Uri.parse('https://m.youtube.com'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            if (await _controller.canGoBack()) {
              await _controller.goBack();
            } else {
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            }
          },
          child: WebViewWidget(controller: _controller),
        ),
      ),
    );
  }
}