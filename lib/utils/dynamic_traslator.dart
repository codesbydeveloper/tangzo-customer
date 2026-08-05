// import 'dart:async';
// import 'dart:collection';
// import 'dart:convert';
// import 'dart:developer';

// import 'package:http/http.dart' as http;
// import 'package:google_mlkit_translation/google_mlkit_translation.dart';

// import '../constant/constant.dart';
// import 'translation_notifier.dart';

// class DynamicTranslator {
//   static final _cache = HashMap<String, String>();
//   static final _pending = HashSet<String>();
//   static final Map<String, OnDeviceTranslator> _mlKitTranslators = {};
//   static final Set<String> _downloadingModels = {};
//   static String _currentLang = "en";

//   static Timer? _notifyTimer;

//   static void setLanguage(String lang) {
//     if (_currentLang == lang) return;

//     _currentLang = lang;
//     Constant.currentLangCode = lang;

//     clearCache();

//     TranslationNotifier.refresh.value++;
//   }

//   static void clearCache() => _cache.clear();

//   static bool isRTL() {
//     return ["ar", "fa", "ur", "he"].contains(_currentLang);
//   }

//   static Future<String> translate(String text) async {
//     if (text.isEmpty || _currentLang == "en") return text;

//     final key = "$text|$_currentLang";

//     if (_cache.containsKey(key)) return _cache[key]!;

//     if (_pending.contains(key)) return text;

//     _pending.add(key);

//     try {
//       late final String translated;

//       if (Constant.localisationType == "AI/ML") {
//         translated = await _translateWithMLKit(text);
//       } else {
//         translated = await _translateWithDeepL(text);
//       }

//       _cache[key] = translated;
//       return translated;
//     } catch (e) {
//       log("⚠️ Translation failed: $e");
//       return text;
//     } finally {
//       _pending.remove(key);
//     }
//   }

//   static Future<String> _translateWithMLKit(String text) async {
//     final translator = await _getMLKitTranslator(_currentLang);
//     return await translator.translateText(text);
//   }

//   static Future<OnDeviceTranslator> _getMLKitTranslator(
//     String langCode,
//   ) async {
//     if (_mlKitTranslators.containsKey(langCode)) {
//       return _mlKitTranslators[langCode]!;
//     }

//     final targetLang = TranslateLanguage.values.firstWhere(
//       (e) => e.bcpCode == langCode,
//       orElse: () => TranslateLanguage.english,
//     );

//     final modelManager = OnDeviceTranslatorModelManager();

//     if (!_downloadingModels.contains(langCode)) {
//       final downloaded = await modelManager.isModelDownloaded(targetLang.bcpCode);

//       if (!downloaded) {
//         _downloadingModels.add(langCode);

//         log("⬇️ Downloading MLKit Model: $langCode");
//         await modelManager.downloadModel(targetLang.bcpCode, isWifiRequired: false);

//         _downloadingModels.remove(langCode);
//       }
//     }

//     final translator = OnDeviceTranslator(
//       sourceLanguage: TranslateLanguage.english,
//       targetLanguage: targetLang,
//     );

//     _mlKitTranslators[langCode] = translator;
//     return translator;
//   }

//   static Future<String> _translateWithDeepL(String text) async {
//     final response = await http.post(
//       Uri.parse("https://api.deepl.com/v2/translate"),
//       headers: {
//         "Authorization": "DeepL-Auth-Key ${Constant.apiKeyOfDeepl}",
//         "Content-Type": "application/x-www-form-urlencoded",
//       },
//       body: {
//         "text": text,
//         "target_lang": _currentLang.toUpperCase(),
//         "source_lang": "EN",
//       },
//     );

//     if (response.statusCode == 200) {
//       final data = json.decode(response.body);
//       return data["translations"][0]["text"];
//     }

//     throw Exception("DeepL Error: ${response.body}");
//   }

//   static String trSync(String text) {
//     if (_currentLang == "en") return text;

//     final key = "$text|$_currentLang";

//     /// Instant cache hit
//     if (_cache.containsKey(key)) return _cache[key]!;

//     /// Translate async but notify UI only once
//     translate(text).then((_) => _debouncedNotify());

//     return text;
//   }

//   /// Prevent rebuild spam
//   static void _debouncedNotify() {
//     _notifyTimer?.cancel();

//     _notifyTimer = Timer(
//       const Duration(milliseconds: 150),
//       () => TranslationNotifier.notify(),
//     );
//   }

//   static Future<void> preloadLanguage(String lang) async {
//     if (lang == "en") return;
//     await _getMLKitTranslator(lang);
//   }

//   static Future<void> dispose() async {
//     for (final translator in _mlKitTranslators.values) {
//       await translator.close();
//     }

//     _mlKitTranslators.clear();
//     _cache.clear();
//   }
// }

// extension DynamicTranslateExtension on String {
//   String get tr => DynamicTranslator.trSync(this);
// }
