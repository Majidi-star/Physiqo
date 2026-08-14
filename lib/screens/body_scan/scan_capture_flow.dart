import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_body_part_selector/flutter_body_part_selector.dart' as fbps;
import '../../theme/app_theme.dart';
import '../../widgets/physiqo_header.dart';
import '../../l10n/translations.dart';
import '../../services/ai_service.dart';
import '../../models/chat_message.dart';
import 'package:image_picker/image_picker.dart';

/// Represents the result of the body scan analysis.
class AnalysisResult {
  final String status;
  final String message;

  const AnalysisResult({required this.status, required this.message});
}

enum CaptureStep {
  frontCapture,
  frontPreview,
  backCapture,
  backPreview,
  analyzing,
}

class ScanCaptureFlow extends StatefulWidget {
  const ScanCaptureFlow({super.key});

  @override
  State<ScanCaptureFlow> createState() => _ScanCaptureFlowState();
}

class _ScanCaptureFlowState extends State<ScanCaptureFlow> {
  CaptureStep _step = CaptureStep.frontCapture;
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _hasPermission = false;
  bool _isCheckingPermission = true;

  XFile? _frontPhoto;
  XFile? _backPhoto;

  @override
  void initState() {
    super.initState();
    _checkAndRequestPermission();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _checkAndRequestPermission() async {
    setState(() {
      _isCheckingPermission = true;
    });

    final status = await Permission.camera.status;
    if (status.isGranted) {
      setState(() {
        _hasPermission = true;
        _isCheckingPermission = false;
      });
      await _initializeCamera();
    } else {
      final requestStatus = await Permission.camera.request();
      setState(() {
        _hasPermission = requestStatus.isGranted;
        _isCheckingPermission = false;
      });
      if (requestStatus.isGranted) {
        await _initializeCamera();
      }
    }
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        debugPrint('Physiqo Camera: No cameras found on device.');
        if (mounted) {
          setState(() {}); // Trigger rebuild to show "no camera" fallback
        }
        return;
      }

      // Use the back camera by default
      final backCamera = _cameras!.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );

      final controller = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      _controller = controller;
      await controller.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Physiqo Camera: Error initializing camera: $e');
    }
  }

  Future<void> _takePhoto() async {
    if (_cameras != null && _cameras!.isEmpty) {
      // Mock photo logic for emulators without a camera
      setState(() {
        if (_step == CaptureStep.frontCapture) {
          _frontPhoto = XFile('mock_front');
          _step = CaptureStep.frontPreview;
        } else if (_step == CaptureStep.backCapture) {
          _backPhoto = XFile('mock_back');
          _step = CaptureStep.backPreview;
        }
      });
      return;
    }

    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      final photo = await _controller!.takePicture();
      if (mounted) {
        setState(() {
          if (_step == CaptureStep.frontCapture) {
            _frontPhoto = photo;
            _step = CaptureStep.frontPreview;
          } else if (_step == CaptureStep.backCapture) {
            _backPhoto = photo;
            _step = CaptureStep.backPreview;
          }
        });
      }
    } catch (e) {
      debugPrint('Physiqo Camera: Error taking photo: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null && mounted) {
        setState(() {
          if (_step == CaptureStep.frontCapture) {
            _frontPhoto = image;
            _step = CaptureStep.frontPreview;
          } else if (_step == CaptureStep.backCapture) {
            _backPhoto = image;
            _step = CaptureStep.backPreview;
          }
        });
      }
    } catch (e) {
      debugPrint('Physiqo Gallery: Error picking photo: $e');
    }
  }

  void _confirmPhoto() {
    setState(() {
      if (_step == CaptureStep.frontPreview) {
        _step = CaptureStep.backCapture;
      } else if (_step == CaptureStep.backPreview) {
        _step = CaptureStep.analyzing;
        _startAnalysis();
      }
    });
  }

  void _retakePhoto() {
    setState(() {
      if (_step == CaptureStep.frontPreview) {
        _frontPhoto = null;
        _step = CaptureStep.frontCapture;
      } else if (_step == CaptureStep.backPreview) {
        _backPhoto = null;
        _step = CaptureStep.backCapture;
      }
    });
  }

  Future<void> _startAnalysis() async {
    if (_frontPhoto == null || _backPhoto == null) return;

    final aiService = AiService();
    final isConfigured = await aiService.isProviderConfigured();
    final isFa = Localizations.localeOf(context).languageCode == 'fa';

    if (!isConfigured) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isFa
                  ? 'لطفاً ابتدا کلید API هوش مصنوعی را در تنظیمات پیکربندی کنید.'
                  : 'Please configure the AI API Key in settings first.',
              style: AppTheme.bodyMd.copyWith(color: AppTheme.onPrimary),
            ),
            backgroundColor: AppTheme.error,
          ),
        );
        setState(() {
          _step = CaptureStep.backPreview;
        });
      }
      return;
    }

    try {
      final frontFile = File(_frontPhoto!.path);
      final backFile = File(_backPhoto!.path);

      // 1. Build localized prompts for front and back images
      final frontPrompt = isFa
          ? '''شما یک مربی بدنسازی و متخصص بینایی ماشین هستید. تصویر جلو از بدن کاربر را تحلیل کنید.
عضلات جلو را بررسی کرده و ارزیابی کنید کدام عضلات توسعه‌یافته و قوی هستند (امتیاز بین 0.7 تا 1.0) و کدام عضلات ضعیف‌تر بوده و نیاز به کار دارند (امتیاز بین 0.3 تا 0.69).
لیست عضلات برای ارزیابی:
- chest (سینه)
- biceps (جلوبازو)
- abs (شکم)
- quads (چهارسر ران)
- calves (ساق پا)
- delts (سرشانه)
- traps (کول)
- forearms (ساعد)

پاسخ خود را دقیقاً در قالب JSON زیر ارسال کنید و هیچ توضیح اضافی خارج از بلاک JSON ننویسید:
{
  "chest": 0.85,
  "biceps": 0.80,
  "abs": 0.62,
  "quads": 0.58,
  "calves": 0.58,
  "delts": 0.70,
  "traps": 0.70,
  "forearms": 0.80,
  "description": "یک خلاصه کوتاه ۲ الی ۳ جمله‌ای به زبان فارسی درباره وضعیت کلی عضلات جلو و عدم تقارن‌ها یا نقاط قوت و ضعف بنویسید."
}'''
          : '''You are a professional fitness coach and computer vision expert. Analyze the front view image of the user's body.
Assess the front muscle groups: identify which are strong and developed (score 0.7 to 1.0) and which need work (score 0.3 to 0.69).
Muscles to assess:
- chest
- biceps
- abs
- quads
- calves
- delts
- traps
- forearms

Return your response strictly in the following JSON format. Do not write any text outside the JSON block:
{
  "chest": 0.85,
  "biceps": 0.80,
  "abs": 0.62,
  "quads": 0.58,
  "calves": 0.58,
  "delts": 0.70,
  "traps": 0.70,
  "forearms": 0.80,
  "description": "A short 2-3 sentence summary in English describing the overall condition of the front muscles, their symmetry, strengths, and weaknesses."
}''';

      final backPrompt = isFa
          ? '''شما یک مربی بدنسازی و متخصص بینایی ماشین هستید. تصویر پشت از بدن کاربر را تحلیل کنید.
عضلات پشت را بررسی کرده و ارزیابی کنید کدام عضلات توسعه‌یافته و قوی هستند (امتیاز بین 0.7 تا 1.0) و کدام عضلات ضعیف‌تر بوده و نیاز به کار دارند (امتیاز بین 0.3 تا 0.69).
لیست عضلات برای ارزیابی:
- latsBack (زیربغل/پشت)
- lowerLatsBack (پایین کمر/فیله)
- glutes (باستن/سرینی)
- hamstrings (همسترینگ/پشت پا)
- triceps (پشت‌بازو)
- delts (سرشانه)
- traps (کول)

پاسخ خود را دقیقاً در قالب JSON زیر ارسال کنید و هیچ توضیح اضافی خارج از بلاک JSON ننویسید:
{
  "latsBack": 0.85,
  "lowerLatsBack": 0.80,
  "glutes": 0.62,
  "hamstrings": 0.58,
  "triceps": 0.58,
  "delts": 0.70,
  "traps": 0.70,
  "description": "یک خلاصه کوتاه ۲ الی ۳ جمله‌ای به زبان فارسی درباره وضعیت کلی عضلات پشت و عدم تقارن‌ها یا نقاط قوت و ضعف بنویسید."
}'''
          : '''You are a professional fitness coach and computer vision expert. Analyze the back view image of the user's body.
Assess the back muscle groups: identify which are strong and developed (score 0.7 to 1.0) and which need work (score 0.3 to 0.69).
Muscles to assess:
- latsBack
- lowerLatsBack
- glutes
- hamstrings
- triceps
- delts
- traps

Return your response strictly in the following JSON format. Do not write any text outside the JSON block:
{
  "latsBack": 0.85,
  "lowerLatsBack": 0.80,
  "glutes": 0.62,
  "hamstrings": 0.58,
  "triceps": 0.58,
  "delts": 0.70,
  "traps": 0.70,
  "description": "A short 2-3 sentence summary in English describing the overall condition of the back muscles, their symmetry, strengths, and weaknesses."
}''';

      // 2. Submit front and back images to the vision model separately
      final frontMsg = ChatMessage(
        id: 'vision_front_${DateTime.now().millisecondsSinceEpoch}',
        role: ChatMessageRole.user,
        content: frontPrompt,
        timestamp: DateTime.now(),
        images: [frontFile.path],
      );

      final backMsg = ChatMessage(
        id: 'vision_back_${DateTime.now().millisecondsSinceEpoch}',
        role: ChatMessageRole.user,
        content: backPrompt,
        timestamp: DateTime.now(),
        images: [backFile.path],
      );

      // Execute front and back vision requests concurrently
      final responses = await Future.wait([
        aiService.sendMessage([frontMsg], isInternal: true),
        aiService.sendMessage([backMsg], isInternal: true),
      ]);

      final frontResponse = responses[0];
      final backResponse = responses[1];

      final frontJson = _parseVisionResponse(frontResponse.text);
      final backJson = _parseVisionResponse(backResponse.text);

      double getVal(Map<String, dynamic> json, String key, double defaultVal) {
        final val = json[key];
        if (val is num) return val.toDouble();
        return defaultVal;
      }

      // Merge muscle intensities (default fallbacks if missing)
      final Map<fbps.Muscle, double> intensities = {
        fbps.Muscle.chestLeft: getVal(frontJson, 'chest', 0.85),
        fbps.Muscle.chestRight: getVal(frontJson, 'chest', 0.85),
        fbps.Muscle.bicepsLeft: getVal(frontJson, 'biceps', 0.80),
        fbps.Muscle.bicepsRight: getVal(frontJson, 'biceps', 0.80),
        fbps.Muscle.abs: getVal(frontJson, 'abs', 0.62),
        fbps.Muscle.quadsLeft: getVal(frontJson, 'quads', 0.58),
        fbps.Muscle.quadsRight: getVal(frontJson, 'quads', 0.58),
        fbps.Muscle.calvesLeft: getVal(frontJson, 'calves', 0.58),
        fbps.Muscle.calvesRight: getVal(frontJson, 'calves', 0.58),
        fbps.Muscle.deltsLeft: (getVal(frontJson, 'delts', 0.70) + getVal(backJson, 'delts', 0.70)) / 2,
        fbps.Muscle.deltsRight: (getVal(frontJson, 'delts', 0.70) + getVal(backJson, 'delts', 0.70)) / 2,
        fbps.Muscle.trapsLeft: (getVal(frontJson, 'traps', 0.70) + getVal(backJson, 'traps', 0.70)) / 2,
        fbps.Muscle.trapsRight: (getVal(frontJson, 'traps', 0.70) + getVal(backJson, 'traps', 0.70)) / 2,
        fbps.Muscle.forearmsLeft: getVal(frontJson, 'forearms', 0.80),
        fbps.Muscle.forearmsRight: getVal(frontJson, 'forearms', 0.80),
        
        fbps.Muscle.latsBackLeft: getVal(backJson, 'latsBack', 0.50),
        fbps.Muscle.latsBackRight: getVal(backJson, 'latsBack', 0.50),
        fbps.Muscle.lowerLatsBackLeft: getVal(backJson, 'lowerLatsBack', 0.50),
        fbps.Muscle.lowerLatsBackRight: getVal(backJson, 'lowerLatsBack', 0.50),
        fbps.Muscle.glutesLeft: getVal(backJson, 'glutes', 0.58),
        fbps.Muscle.glutesRight: getVal(backJson, 'glutes', 0.58),
        fbps.Muscle.hamstringsLeft: getVal(backJson, 'hamstrings', 0.58),
        fbps.Muscle.hamstringsRight: getVal(backJson, 'hamstrings', 0.58),
        fbps.Muscle.tricepsLeft: getVal(backJson, 'triceps', 0.80),
        fbps.Muscle.tricepsRight: getVal(backJson, 'triceps', 0.80),
      };

      // Calculate dynamic overall score
      final avgIntensity = intensities.values.reduce((a, b) => a + b) / intensities.length;
      final int overallScore = (avgIntensity * 100).round();

      // Aggregate descriptions
      final frontDesc = frontJson['description']?.toString() ?? 
          (isFa ? 'تحلیل تصویر جلو ناموفق بود.' : 'Front view analysis failed.');
      final backDesc = backJson['description']?.toString() ?? 
          (isFa ? 'تحلیل تصویر پشت ناموفق بود.' : 'Back view analysis failed.');

      final Map<String, dynamic> analysisData = {
        'intensities': intensities,
        'overallScore': overallScore,
        'frontDescription': frontDesc,
        'backDescription': backDesc,
        'rawMuscles': {
          'chest': getVal(frontJson, 'chest', 0.85),
          'biceps': getVal(frontJson, 'biceps', 0.80),
          'abs': getVal(frontJson, 'abs', 0.62),
          'quads': getVal(frontJson, 'quads', 0.58),
          'calves': getVal(frontJson, 'calves', 0.58),
          'delts': (getVal(frontJson, 'delts', 0.70) + getVal(backJson, 'delts', 0.70)) / 2,
          'traps': (getVal(frontJson, 'traps', 0.70) + getVal(backJson, 'traps', 0.70)) / 2,
          'forearms': getVal(frontJson, 'forearms', 0.80),
          'latsBack': getVal(backJson, 'latsBack', 0.50),
          'lowerLatsBack': getVal(backJson, 'lowerLatsBack', 0.50),
          'glutes': getVal(backJson, 'glutes', 0.58),
          'hamstrings': getVal(backJson, 'hamstrings', 0.58),
          'triceps': getVal(backJson, 'triceps', 0.80),
        }
      };

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/analysis', arguments: analysisData);
      }
    } catch (e) {
      debugPrint('Physiqo Camera: Error uploading or analyzing scan: $e');
      if (mounted) {
        final errMessage = e.toString();
        final isTimeout = errMessage.contains('TimeoutException') || errMessage.contains('timed out');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isFa
                  ? (isTimeout 
                      ? 'زمان پاسخ‌گویی سرور به پایان رسید. لطفاً زمان تایم‌اوت را در تنظیمات هوش مصنوعی افزایش دهید.\nجزئیات: $e' 
                      : 'خطایی در ارتباط با سرور رخ داد: $e\nبرنامه به صورت پیش‌فرض نتایج آفلاین را بارگذاری می‌کند.')
                  : (isTimeout 
                      ? 'API request timed out. Try increasing the timeout in AI settings.\nDetails: $e'
                      : 'API request failed: $e\nLoading offline fallback values.'),
              style: AppTheme.bodyMd.copyWith(color: AppTheme.onPrimary),
            ),
            backgroundColor: AppTheme.error,
            duration: const Duration(seconds: 8),
          ),
        );
        // Fallback navigation with mock/null values
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/analysis', arguments: null);
        }
      }
    }
  }

  Map<String, dynamic> _parseVisionResponse(String? text) {
    if (text == null || text.trim().isEmpty) return {};
    try {
      var cleaned = text.trim();
      if (cleaned.startsWith('```json')) {
        cleaned = cleaned.substring(7);
      } else if (cleaned.startsWith('```')) {
        cleaned = cleaned.substring(3);
      }
      if (cleaned.endsWith('```')) {
        cleaned = cleaned.substring(0, cleaned.length - 3);
      }
      cleaned = cleaned.trim();

      final start = cleaned.indexOf('{');
      final end = cleaned.lastIndexOf('}');
      if (start != -1 && end != -1 && end >= start) {
        cleaned = cleaned.substring(start, end + 1);
        return jsonDecode(cleaned) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Error parsing vision response: $e');
    }
    return {};
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: Directionality.of(context),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.backgroundGradient,
          ),
          child: SafeArea(
            child: _buildMainContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    if (_isCheckingPermission) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }

    if (!_hasPermission) {
      return _buildPermissionDenialView();
    }

    switch (_step) {
      case CaptureStep.frontCapture:
        return _buildCaptureView(
          title: context.tr('scan_front_capture'),
          isFront: true,
        );
      case CaptureStep.frontPreview:
        return _buildPreviewView(
          title: context.tr('scan_front_preview'),
          photo: _frontPhoto!,
        );
      case CaptureStep.backCapture:
        return _buildCaptureView(
          title: context.tr('scan_back_capture'),
          isFront: false,
        );
      case CaptureStep.backPreview:
        return _buildPreviewView(
          title: context.tr('scan_back_preview'),
          photo: _backPhoto!,
        );
      case CaptureStep.analyzing:
        return _buildAnalyzingView();
    }
  }

  Widget _buildPermissionDenialView() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.gutter),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.camera_alt_outlined,
            color: AppTheme.textSecondary,
            size: 64,
          ),
          const SizedBox(height: AppTheme.spacingLg),
          Text(
            'دسترسی به دوربین داده نشده است',
            style: AppTheme.headlineMd,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Text(
            context.tr('scan_camera_permission_desc'),
            style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingXl),
          GestureDetector(
            onTap: openAppSettings,
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              alignment: Alignment.center,
              child: Text(
                context.tr('action_open_settings'),
                style: AppTheme.bodyLg.copyWith(
                  color: AppTheme.onPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          GestureDetector(
            onTap: _checkAndRequestPermission,
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(color: AppTheme.outline),
              ),
              alignment: Alignment.center,
              child: Text(
                context.tr('action_retry_permission'),
                style: AppTheme.bodyLg.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaptureView({required String title, required bool isFront}) {
    return Column(
      children: [
        PhysiqoHeader.back(
          title: title,
          onBackTap: () {
            if (_step == CaptureStep.backCapture) {
              setState(() {
                _step = CaptureStep.frontPreview;
              });
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: AppTheme.gutter),
              decoration: AppTheme.cardDecoration(),
              child: Stack(
                children: [
                  // Camera preview
                  Positioned.fill(
                    child: _buildCameraPreviewWidget(),
                  ),
                  // Transparent Body Guideline Overlay
                  Positioned.fill(
                    child: Center(
                      child: FractionallySizedBox(
                        widthFactor: 0.75,
                        heightFactor: 0.75,
                        child: Opacity(
                          opacity: 0.35,
                          child: SvgPicture.asset(
                            isFront
                                ? 'packages/flutter_body_part_selector/assets/svg/body_front.svg'
                                : 'packages/flutter_body_part_selector/assets/svg/body_back.svg',
                            colorFilter: const ColorFilter.mode(
                              AppTheme.textPrimary,
                              BlendMode.srcIn,
                            ),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(width: 56), // balance space
              GestureDetector(
                onTap: _takePhoto,
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.textPrimary, width: 4),
                  ),
                  padding: const EdgeInsets.all(6),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              IconButton(
                icon: const Icon(Icons.photo_library, size: 32, color: AppTheme.textPrimary),
                onPressed: _pickFromGallery,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCameraPreviewWidget() {
    if (_cameras != null && _cameras!.isEmpty) {
      return Center(
        child: Text(
          'دوربینی یافت نشد.\nبرای شبیه‌سازی روی دکمه عکس ضربه بزنید.',
          style: AppTheme.bodyLg.copyWith(color: AppTheme.textSecondary),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (_controller == null || !_isCameraInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        // Flip aspect ratio calculation for portrait mode camera logic
        final scale = size.aspectRatio * _controller!.value.aspectRatio;

        return ClipRect(
          child: OverflowBox(
            alignment: Alignment.center,
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: size.width,
                height: size.height / (scale > 0 ? scale : 1.0),
                child: CameraPreview(_controller!),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPreviewView({required String title, required XFile photo}) {
    return Column(
      children: [
        PhysiqoHeader.back(
          title: title,
          onBackTap: _retakePhoto,
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: AppTheme.gutter),
            decoration: AppTheme.cardDecoration(),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              child: photo.path.startsWith('mock_') 
                ? Container(
                    color: AppTheme.surfaceHigh, 
                    child: const Center(child: Icon(Icons.person, size: 100, color: AppTheme.textSecondary))
                  )
                : Image.file(
                    File(photo.path),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _retakePhoto,
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      border: Border.all(color: AppTheme.outline),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      context.tr('action_retry'),
                      style: AppTheme.bodyLg.copyWith(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              Expanded(
                child: GestureDetector(
                  onTap: _confirmPhoto,
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      context.tr('confirm'),
                      style: AppTheme.bodyLg.copyWith(
                        color: AppTheme.onPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyzingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppTheme.primary),
          const SizedBox(height: AppTheme.spacingLg),
          Text(
            context.tr('scan_analyzing'),
            style: AppTheme.headlineMd.copyWith(color: AppTheme.primary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
