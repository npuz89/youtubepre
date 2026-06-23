import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Удерживаем процессор от засыпания
  WakelockPlus.enable();
  
  // Запускаем фоновый сервис системы
  await initializeService();
  
  runApp(const MyApp());
}

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: 'my_foreground',
      initialNotificationTitle: 'YouTube Background Player',
      initialNotificationContent: 'Воспроизведение активно в фоне',
      foregroundServiceTypes: [AndroidForegroundServiceType.mediaPlayback],
    ),
    iosConfiguration: IosConfiguration(),
  );
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
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
  State<YouTubeScreen> createState() => _YouTubeScreenState();
}

class _YouTubeScreenState extends State<YouTubeScreen> {
  InAppWebViewController? webViewController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            if (webViewController != null && await webViewController!.canGoBack()) {
              await webViewController!.goBack();
            } else {
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            }
          },
          child: InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri("https://m.youtube.com")),
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              domStorageEnabled: true,
              mediaPlaybackRequiresUserGesture: false, // Разрешаем автоплей
              
              // КРИТИЧЕСКИ ВАЖНЫЕ НАСТРОЙКИ ДЛЯ ФОНА:
              allowsBackgroundMediaPlayback: true, // Разрешаем играть в фоне на уровне движка
              useShouldOverrideUrlLoading: true,
              userAgent: "Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36"
            ),
            onWebViewCreated: (controller) {
              webViewController = controller;
            },
            onLoadStop: (controller, url) async {
              // Внедряем JS-скрипт, обманывающий Visibility API самого YouTube
              await controller.evaluateJavascript(source: '''
                Object.defineProperty(document, 'hidden', {get: function() { return false; }, configurable: true});
                Object.defineProperty(document, 'visibilityState', {get: function() { return 'visible'; }, configurable: true});
                document.dispatchEvent(new Event('visibilitychange'));
              ''');
            },
          ),
        ),
      ),
    );
  }
}