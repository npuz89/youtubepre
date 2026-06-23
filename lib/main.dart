import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
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
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..clearCache() // Очистка кэша от прошлых ошибок
      ..setUserAgent(
          "Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36")
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            // Обман плеера для фонового режима
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
        // Используем новый PopScope вместо устаревшего WillPopScope
        child: PopScope(
          canPop: false, // Блокируем автоматическое закрытие приложения
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;

            // Проверяем, можно ли вернуться назад внутри истории YouTube
            if (await _controller.canGoBack()) {
              await _controller.goBack(); // Возвращаемся назад на сайт
            } else {
              // Если идти назад больше некуда, закрываем приложение
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
