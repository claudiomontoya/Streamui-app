import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Servicio de reconocimiento de voz
class SpeechService extends ChangeNotifier {
  final SpeechToText _speech = SpeechToText();

  bool _isInitialized = false;
  bool _isListening = false;
  bool _isAvailable = false;
  String _lastWords = '';
  String _currentLocale = 'es_ES';
  double _confidence = 0.0;

  bool get isInitialized => _isInitialized;
  bool get isListening => _isListening;
  bool get isAvailable => _isAvailable;
  String get lastWords => _lastWords;
  String get currentLocale => _currentLocale;
  double get confidence => _confidence;

  /// Callback para cuando se detectan palabras
  Function(String text, bool isFinal)? onResult;

  /// Callback para errores
  Function(String error)? onError;

  /// Inicializa el servicio de voz
  Future<bool> initialize() async {
    if (_isInitialized) return _isAvailable;

    try {
      _isAvailable = await _speech.initialize(
        onStatus: _handleStatus,
        onError: _handleError,
        debugLogging: kDebugMode,
      );

      if (_isAvailable) {
        // Obtener locales disponibles
        final locales = await _speech.locales();

        // Buscar español o usar el predeterminado
        final spanishLocale = locales.firstWhere(
          (locale) => locale.localeId.startsWith('es'),
          orElse: () => locales.first,
        );
        _currentLocale = spanishLocale.localeId;
      }

      _isInitialized = true;
      notifyListeners();
      return _isAvailable;
    } catch (e) {
      debugPrint('Error al inicializar speech: $e');
      _isAvailable = false;
      _isInitialized = true;
      notifyListeners();
      return false;
    }
  }

  /// Inicia la escucha
  Future<void> startListening() async {
    if (!_isInitialized) {
      await initialize();
    }

    if (!_isAvailable || _isListening) return;

    _lastWords = '';
    _confidence = 0.0;

    try {
      await _speech.listen(
        onResult: _handleResult,
        localeId: _currentLocale,
        listenMode: ListenMode.dictation,
        cancelOnError: true,
        partialResults: true,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
      );

      _isListening = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error al iniciar escucha: $e');
      onError?.call('No se pudo iniciar el micrófono');
    }
  }

  /// Detiene la escucha
  Future<void> stopListening() async {
    if (!_isListening) return;

    await _speech.stop();
    _isListening = false;
    notifyListeners();
  }

  /// Cancela la escucha sin procesar
  Future<void> cancelListening() async {
    if (!_isListening) return;

    await _speech.cancel();
    _isListening = false;
    _lastWords = '';
    notifyListeners();
  }

  /// Cambia el idioma
  Future<void> setLocale(String localeId) async {
    _currentLocale = localeId;
    notifyListeners();
  }

  /// Obtiene los idiomas disponibles
  Future<List<LocaleName>> getAvailableLocales() async {
    if (!_isInitialized) {
      await initialize();
    }
    return _speech.locales();
  }

  void _handleResult(SpeechRecognitionResult result) {
    _lastWords = result.recognizedWords;
    _confidence = result.confidence;

    onResult?.call(_lastWords, result.finalResult);

    if (result.finalResult) {
      _isListening = false;
    }

    notifyListeners();
  }

  void _handleStatus(String status) {
    debugPrint('Speech status: $status');

    if (status == 'done' || status == 'notListening') {
      _isListening = false;
      notifyListeners();
    }
  }

  void _handleError(dynamic error) {
    debugPrint('Speech error: $error');
    _isListening = false;
    notifyListeners();
    onError?.call('Error de reconocimiento: $error');
  }

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }
}
