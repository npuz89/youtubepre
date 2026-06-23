import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:media_kit/media_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  
  // Запрос разрешений
  await _requestPermissions();
  
  runApp(const MyApp());
}

Future<void> _requestPermissions() async {
  await [
    Permission.storage,
    Permission.ignoreBatteryOptimizations,
  ].request();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Background YouTube',
          theme: ThemeData.dark().copyWith(
            primaryColor: Colors.red,
            colorScheme: const ColorScheme.dark(
              primary: Colors.red,
              secondary: Colors.redAccent,
            ),
            scaffoldBackgroundColor: Colors.black,
          ),
          home: const YouTubeScreen(),
        );
      },
    );
  }
}

class YouTubeScreen extends StatefulWidget {
  const YouTubeScreen({super.key});

  @override
  State<YouTubeScreen> createState() => _YouTubeScreenState();
}

class _YouTubeScreenState extends State<YouTubeScreen> with WidgetsBindingObserver {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _isConnected = true;
  String? _errorMessage;
  double _progress = 0.0;
  bool _isFullScreen = false;
  bool _isDarkMode = true;
  List<String> _history = [];
  double _volume = 1.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadHistory();
    _checkConnectivity();
    _initializeWebView();
    _keepScreenOn();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    WakelockPlus.disable();
    _saveHistory();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkConnectivity();
      _injectYouTubeScripts();
    }
  }

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _history = prefs.getStringList('history') ?? [];
    } catch (e) {
      debugPrint('Error loading history: $e');
    }
  }

  Future<void> _saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('history', _history);
    } catch (e) {
      debugPrint('Error saving history: $e');
    }
  }

  Future<void> _checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      _isConnected = connectivityResult != ConnectivityResult.none;
    });
  }

  void _keepScreenOn() {
    WakelockPlus.enable();
  }

  Future<void> _initializeWebView() async {
    try {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0x00000000))
        ..clearCache()
        ..setUserAgent(
          "Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36"
        )
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              setState(() {
                _isLoading = true;
                _errorMessage = null;
              });
            },
            onPageFinished: (String url) {
              setState(() {
                _isLoading = false;
              });
              
              // Добавляем URL в историю
              if (url.isNotEmpty && !_history.contains(url)) {
                setState(() {
                  _history.insert(0, url);
                  if (_history.length > 50) _history.removeLast();
                });
                _saveHistory();
              }
              
              _injectYouTubeScripts();
              _applyVolume();
              _applyDarkMode();
            },
            onWebResourceError: (WebResourceError error) {
              setState(() {
                _isLoading = false;
                _errorMessage = 'Ошибка загрузки: ${error.description}';
              });
              debugPrint('WebView Error: ${error.description}');
            },
            onHttpError: (HttpResponseError error) {
              setState(() {
                _errorMessage = 'HTTP Ошибка: ${error.response?.statusCode}';
              });
            },
            onProgress: (int progress) {
              setState(() {
                _progress = progress / 100;
              });
            },
          ),
        )
        ..loadRequest(
          Uri.parse('https://m.youtube.com'),
          headers: {
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
            'Accept-Language': 'ru-RU,ru;q=0.8,en-US;q=0.5,en;q=0.3',
            'Cache-Control': 'max-age=3600',
          },
        );
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка инициализации: $e';
        _isLoading = false;
      });
    }
  }

  void _injectYouTubeScripts() {
    _controller.runJavaScript('''
      // 1. Обход ограничений видимости
      const originalHidden = Object.getOwnPropertyDescriptor(Document.prototype, 'hidden');
      const originalVisibilityState = Object.getOwnPropertyDescriptor(Document.prototype, 'visibilityState');
      
      Object.defineProperty(Document.prototype, 'hidden', {
        get: function() { return false; },
        configurable: true
      });
      
      Object.defineProperty(Document.prototype, 'visibilityState', {
        get: function() { return 'visible'; },
        configurable: true
      });
      
      document.dispatchEvent(new Event('visibilitychange'));
      
      // 2. Блокировка автоматической паузы
      const originalPause = HTMLMediaElement.prototype.pause;
      HTMLMediaElement.prototype.pause = function() {
        if (this.src && this.src.includes('googlevideo')) {
          console.log('Блокировка паузы для видео');
          return;
        }
        return originalPause.call(this);
      };
      
      // 3. Автовосстановление воспроизведения
      setInterval(function() {
        const videos = document.querySelectorAll('video');
        videos.forEach(function(video) {
          if (video && video.paused && video.src && video.src.includes('googlevideo')) {
            console.log('Возобновление видео');
            video.play().catch(function(e) {
              console.log('Не удалось возобновить видео:', e);
            });
          }
        });
      }, 3000);
      
      // 4. Сбор статистики воспроизведения
      document.addEventListener('play', function(e) {
        if (e.target && e.target.tagName === 'VIDEO') {
          console.log('Видео начато:', e.target.src);
          // Можно отправлять статистику на сервер
        }
      }, true);
      
      // 5. Управление полноэкранным режимом
      document.addEventListener('fullscreenchange', function() {
        window.flutter_inappwebview?.callHandler('onFullscreenChange', document.fullscreenElement !== null);
      });
      
      // 6. Сохранение состояния видео
      setInterval(function() {
        const videos = document.querySelectorAll('video');
        videos.forEach(function(video, index) {
          if (video.duration > 0) {
            localStorage.setItem('video_time_' + index, video.currentTime);
            localStorage.setItem('video_paused_' + index, video.paused);
          }
        });
      }, 5000);
    ''');
  }

  void _applyVolume() {
    _controller.runJavaScript('''
      const videos = document.querySelectorAll('video');
      videos.forEach(function(video) {
        video.volume = $_volume;
      });
    ''');
  }

  void _applyDarkMode() {
    if (_isDarkMode) {
      _controller.runJavaScript('''
        document.body.style.backgroundColor = '#000000';
        document.body.style.color = '#FFFFFF';
        const elements = document.querySelectorAll('*');
        elements.forEach(function(el) {
          if (el.style.backgroundColor && !el.style.backgroundColor.includes('transparent')) {
            el.style.backgroundColor = '#1a1a1a';
          }
          if (el.style.color) {
            el.style.color = '#ffffff';
          }
        });
      ''');
    }
  }

  Future<void> _refreshPage() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    await _controller.reload();
  }

  Future<void> _goHome() async {
    await _controller.loadRequest(Uri.parse('https://m.youtube.com'));
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            return Container(
              padding: EdgeInsets.all(20.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Заголовок
                  Text(
                    'Настройки',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  
                  // Громкость
                  ListTile(
                    leading: const Icon(Icons.volume_up, color: Colors.red),
                    title: const Text('Громкость'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.volume_down),
                          onPressed: () {
                            setState(() {
                              _volume = (_volume - 0.1).clamp(0.0, 1.0);
                            });
                            _applyVolume();
                          },
                        ),
                        Text('${(_volume * 100).toInt()}%'),
                        IconButton(
                          icon: const Icon(Icons.volume_up),
                          onPressed: () {
                            setState(() {
                              _volume = (_volume + 0.1).clamp(0.0, 1.0);
                            });
                            _applyVolume();
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  // Темная тема
                  SwitchListTile(
                    title: const Text('Темная тема'),
                    value: _isDarkMode,
                    onChanged: (value) {
                      setStateSheet(() {
                        _isDarkMode = value;
                      });
                      setState(() {
                        _isDarkMode = value;
                      });
                      _applyDarkMode();
                    },
                    secondary: const Icon(Icons.dark_mode, color: Colors.red),
                  ),
                  
                  // Очистить историю
                  ListTile(
                    leading: const Icon(Icons.history, color: Colors.red),
                    title: const Text('Очистить историю'),
                    trailing: Text('${_history.length}'),
                    onTap: () {
                      setState(() {
                        _history.clear();
                      });
                      _saveHistory();
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('История очищена')),
                      );
                    },
                  ),
                  
                  SizedBox(height: 10.h),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: PopScope(
          canPop: false,
          onPopInvoked: (bool didPop) async {
            if (!didPop) {
              if (await _controller.canGoBack()) {
                await _controller.goBack();
              } else {
                _showExitDialog();
              }
            }
          },
          child: Stack(
            children: [
              // WebView
              WebViewWidget(controller: _controller),
              
              // Индикатор загрузки с прогрессом
              if (_isLoading)
                Container(
                  color: Colors.black54,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                        ),
                        SizedBox(height: 20.h),
                        Container(
                          width: 200.w,
                          child: LinearProgressIndicator(
                            value: _progress,
                            backgroundColor: Colors.grey[800],
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
                          ),
                        ),
                        SizedBox(height: 10.h),
                        Text(
                          'Загрузка ${(_progress * 100).toInt()}%',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              
              // Сообщение об отсутствии интернета
              if (!_isConnected && !_isLoading)
                Center(
                  child: Container(
                    padding: EdgeInsets.all(20.w),
                    margin: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: Colors.red.shade300),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.wifi_off,
                          color: Colors.red.shade300,
                          size: 48.sp,
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          'Нет подключения к интернету',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Проверьте подключение и попробуйте снова',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14.sp,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16.h),
                        ElevatedButton(
                          onPressed: _refreshPage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Попробовать снова'),
                        ),
                      ],
                    ),
                  ),
                ),
              
              // Сообщение об ошибке
              if (_errorMessage != null && _isConnected)
                Center(
                  child: Container(
                    padding: EdgeInsets.all(20.w),
                    margin: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: Colors.red.shade300),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red.shade300,
                          size: 48.sp,
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.sp,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: _refreshPage,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Обновить'),
                            ),
                            SizedBox(width: 10.w),
                            ElevatedButton(
                              onPressed: _goHome,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[800],
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('На главную'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              
              // Панель управления внизу
              Positioned(
                bottom: 10.h,
                left: 10.w,
                right: 10.w,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.home, color: Colors.white),
                        onPressed: _goHome,
                        tooltip: 'На главную',
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        onPressed: _refreshPage,
                        tooltip: 'Обновить',
                      ),
                      IconButton(
                        icon: const Icon(Icons.history, color: Colors.white),
                        onPressed: () {
                          _showHistoryDialog();
                        },
                        tooltip: 'История',
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings, color: Colors.white),
                        onPressed: _showSettings,
                        tooltip: 'Настройки',
                      ),
                      IconButton(
                        icon: const Icon(Icons.fullscreen, color: Colors.white),
                        onPressed: () {
                          setState(() {
                            _isFullScreen = !_isFullScreen;
                          });
                          // Здесь можно добавить логику полноэкранного режима
                        },
                        tooltip: 'Полный экран',
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

  void _showHistoryDialog() {
    if (_history.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('История пуста')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'История просмотров',
            style: TextStyle(color: Colors.white),
          ),
          content: Container(
            width: double.maxFinite,
            height: 300.h,
            child: ListView.builder(
              itemCount: _history.length,
              itemBuilder: (context, index) {
                final url = _history[index];
                return ListTile(
                  title: Text(
                    url.length > 50 ? '${url.substring(0, 50)}...' : url,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  leading: const Icon(Icons.history, color: Colors.red, size: 16),
                  onTap: () {
                    Navigator.pop(context);
                    _controller.loadRequest(Uri.parse(url));
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _history.clear();
                });
                _saveHistory();
                Navigator.pop(context);
              },
              child: const Text('Очистить', style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Закрыть', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'Выход',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Вы уверены, что хотите выйти из приложения?',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена', style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.of(context).pop();
              },
              child: const Text('Выйти', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}