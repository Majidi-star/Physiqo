import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../theme/app_theme.dart';
import '../../widgets/physiqo_header.dart';
import '../../l10n/translations.dart';
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

    try {
      final frontFile = File(_frontPhoto!.path);
      final backFile = File(_backPhoto!.path);

      // Perform the AI analysis API call stub
      await uploadScanForAnalysis(frontFile, backFile);

      if (mounted) {
        // Navigate to the analysis screen and replace this flow in the stack
        Navigator.of(context).pushReplacementNamed('/analysis');
      }
    } catch (e) {
      debugPrint('Physiqo Camera: Error uploading or analyzing scan: $e');
      if (mounted) {
        setState(() {
          // Fallback to back preview if analysis fails
          _step = CaptureStep.backPreview;
        });
      }
    }
  }

  /// Stub function for actual AI API call.
  /// Replace this with actual endpoint request implementation when ready.
  Future<AnalysisResult> uploadScanForAnalysis(File front, File back) async {
    debugPrint('Physiqo Camera: Stub - Uploading front: ${front.path}, back: ${back.path}');
    await Future.delayed(const Duration(seconds: 4)); // Mock analysis duration
    return const AnalysisResult(
      status: 'success',
      message: 'تحلیل با موفقیت انجام شد',
    );
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
