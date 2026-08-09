import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:xml/xml.dart';

// Reusing domain entities and SVG data sources from the package
import 'package:flutter_body_part_selector/feature/flutter_body_part_selector/domain/entities/muscle.dart';
import 'package:flutter_body_part_selector/feature/flutter_body_part_selector/data/mappers/muscle_mapper.dart';
import 'package:flutter_body_part_selector/feature/flutter_body_part_selector/data/datasources/svg_asset_datasource.dart';
import 'package:flutter_body_part_selector/core/utils/svg_utils.dart';

// Reusing helper helpers but hiding ElementState, ColorConfig and SvgIds to customize them
import 'package:flutter_body_part_selector/core/constants/svg_helpers.dart' hide ElementState, ColorConfig, SvgIds;


/// Customized ColorConfig for Physiqo theme mapping.
class ColorConfig {
  final String highlightHex;
  final String disabledHex;
  final String selectedStrokeWidth;
  final String unselectedStrokeWidth;

  const ColorConfig({
    required this.highlightHex,
    required this.disabledHex,
    required this.selectedStrokeWidth,
    required this.unselectedStrokeWidth,
  });
}

/// Customized SvgIds.
class SvgIds {
  final Set<String> selected;
  final Set<String> disabled;

  const SvgIds({
    required this.selected,
    required this.disabled,
  });
}

/// Customized ElementState that overrides the hardcoded body scan outline/linework color.
class ElementState {
  final String? id;
  final bool isSelected;
  final bool isDisabled;
  final bool isMuscleElement;
  final bool isBodyOutline;
  final bool isPath;
  final bool isGroup;

  ElementState({
    required this.id,
    required this.isSelected,
    required this.isDisabled,
    required this.isMuscleElement,
    required this.isBodyOutline,
    required this.isPath,
    required this.isGroup,
  });

  factory ElementState.from(String? id, SvgIds svgIds) {
    final isSelected = id != null && svgIds.selected.contains(id);
    final isDisabled = id != null && svgIds.disabled.contains(id);
    final isMuscleElement = id != null && MuscleMapper.isValidSvgId(id);
    final isBodyOutline = id == 'front_body' || id == 'back_body';

    return ElementState(
      id: id,
      isSelected: isSelected,
      isDisabled: isDisabled,
      isMuscleElement: isMuscleElement,
      isBodyOutline: isBodyOutline,
      isPath: (isMuscleElement || isBodyOutline),
      isGroup: isMuscleElement,
    );
  }

  String fillColor(ColorConfig config) {
    if (isSelected) return config.highlightHex;
    if (isDisabled) return config.disabledHex;
    return 'none';
  }

  String strokeColor(ColorConfig config) {
    if (isSelected) return config.highlightHex;
    if (isDisabled) return config.disabledHex;
    // Muted mid-gray outline to avoid competing with accent colors
    if (isBodyOutline) return '#8E8E93';
    return 'none';
  }

  String strokeWidth(ColorConfig config) {
    return isSelected ? config.selectedStrokeWidth : config.unselectedStrokeWidth;
  }
}

/// A customized interactive SVG body diagram for Physiqo with muted gray linework.
class PhysiqoInteractiveBodySvg extends StatefulWidget {
  final String? asset;
  final bool isFront;
  final Set<Muscle>? selectedMuscles;
  final Set<Muscle>? disabledMuscles;
  final Function(Muscle)? onMuscleTap;
  final Color? highlightColor;
  final Color? disabledColor;
  final double selectedStrokeWidth;
  final double unselectedStrokeWidth;
  final bool enableSelection;
  final BoxFit fit;
  final double hitTestPadding;
  final double? width;
  final double? height;
  final Alignment alignment;
  final Function(Muscle)? onMuscleTapDisabled;
  final Function(Muscle)? onMuscleLongPress;
  final HitTestBehavior hitTestBehavior;
  final Widget Function(BuildContext context, Widget child, Muscle muscle)? onSelectAnimationBuilder;
  final String? Function(Muscle muscle)? tooltipBuilder;
  final String? Function(Muscle muscle)? semanticLabelBuilder;
  final bool isInitialSelection;

  const PhysiqoInteractiveBodySvg({
    super.key,
    this.asset,
    this.isFront = true,
    this.selectedMuscles,
    this.disabledMuscles,
    this.onMuscleTap,
    this.highlightColor,
    this.disabledColor,
    this.selectedStrokeWidth = 2.0,
    this.unselectedStrokeWidth = 1.0,
    this.enableSelection = true,
    this.fit = BoxFit.contain,
    this.hitTestPadding = 2.0,
    this.width,
    this.height,
    this.alignment = Alignment.center,
    this.onMuscleTapDisabled,
    this.onMuscleLongPress,
    this.hitTestBehavior = HitTestBehavior.deferToChild,
    this.onSelectAnimationBuilder,
    this.tooltipBuilder,
    this.semanticLabelBuilder,
    this.isInitialSelection = false,
  });

  String get _effectiveAsset {
    if (asset != null) {
      return asset!;
    }
    final dataSource = SvgAssetDataSource();
    return dataSource.getAssetPath(isFront);
  }

  @override
  State<PhysiqoInteractiveBodySvg> createState() => _PhysiqoInteractiveBodySvgState();
}

class _PhysiqoInteractiveBodySvgState extends State<PhysiqoInteractiveBodySvg> {
  static const double _pathBoundsMargin = 2.0;
  static const double _disabledOpacity = 0.4;
  static const double _hitTestPadding = 1.0;

  String? _modifiedSvg;
  bool _isLoading = true;
  bool _isProcessing = false;
  bool _isWidgetReady = false;
  String? _loadError;

  Map<String, Rect>? _muscleBounds;
  Map<String, List<Rect>>? _groupPathBounds;
  Map<String, String>? _musclePathData;
  Map<String, List<String>>? _groupPathData;
  List<String>? _orderedPathIds;
  List<String>? _orderedGroupIds;
  Size? _svgSize;
  Offset? _viewBoxOffset;
  String? _lastBoundsAsset;

  Set<Muscle>? _previousSelectedMuscles;
  Set<Muscle>? _previousDisabledMuscles;

  Set<Muscle> get _selectedMuscles => widget.selectedMuscles ?? {};
  Set<Muscle> get _disabledMuscles => widget.disabledMuscles ?? {};

  @override
  void initState() {
    super.initState();
    _loadError = null;
    _loadAndModifySvg();
    _scheduleWidgetReady();
  }

  @override
  void didUpdateWidget(PhysiqoInteractiveBodySvg oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_shouldReload(oldWidget)) {
      _updatePreviousSelections();
      if (!_isProcessing && mounted) {
        _loadAndModifySvg();
      }
    }
  }

  void _scheduleWidgetReady() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _isWidgetReady = true);
      }
    });
  }

  bool _shouldReload(PhysiqoInteractiveBodySvg oldWidget) {
    return oldWidget._effectiveAsset != widget._effectiveAsset ||
        oldWidget.highlightColor != widget.highlightColor ||
        oldWidget.disabledColor != widget.disabledColor ||
        oldWidget.selectedStrokeWidth != widget.selectedStrokeWidth ||
        oldWidget.unselectedStrokeWidth != widget.unselectedStrokeWidth ||
        !setsEqual(_previousSelectedMuscles, _selectedMuscles) ||
        !setsEqual(_previousDisabledMuscles, _disabledMuscles);
  }

  void _updatePreviousSelections() {
    _previousSelectedMuscles = Set.from(_selectedMuscles);
    _previousDisabledMuscles = Set.from(_disabledMuscles);
  }

  Future<void> _loadAndModifySvg() async {
    if (_isProcessing) return;
    _isProcessing = true;

    final isFirstLoad = _modifiedSvg == null;
    if (isFirstLoad && mounted) {
      setState(() => _isLoading = true);
    }

    try {
      if (!mounted) return;

      await Future.delayed(Duration.zero);
      if (!mounted) return;

      final dataSource = SvgAssetDataSource();
      final effectiveAsset = widget._effectiveAsset;
      final List<String> assetPathsToTry = [
        effectiveAsset,
        dataSource.getAssetPathDirect(widget.isFront),
      ];
      
      Exception? lastException;
      String? svgString;
      
      for (final assetPath in assetPathsToTry) {
        try {
          try {
            svgString = await rootBundle.loadString(assetPath);
            break;
          } catch (e) {
            if (mounted) {
              try {
                final assetBundle = DefaultAssetBundle.of(context);
                svgString = await assetBundle.loadString(assetPath);
                break;
              } catch (e2) {
                lastException = e2 is Exception ? e2 : Exception(e2.toString());
              }
            } else {
              lastException = e is Exception ? e : Exception(e.toString());
            }
          }
        } catch (e) {
          lastException = e is Exception ? e : Exception(e.toString());
        }
      }
      
      if (svgString == null) {
        throw lastException ?? Exception('Failed to load SVG asset from any path');
      }
      
      final document = XmlDocument.parse(svgString);
      _extractSvgMetadata(document);

      final colorConfig = _createColorConfig();
      final svgIds = _getSvgIds();

      if (_shouldExtractBounds(effectiveAsset)) {
        _muscleBounds = _extractMuscleBounds(document);
      }

      _processSvgElements(document, svgIds, colorConfig);

      if (!mounted) return;

      final finalSvg = document.toXmlString(pretty: false);
      _updateSvgState(finalSvg, document);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadError ??= e.toString();
        });
      }
    } finally {
      _isProcessing = false;
    }
  }

  void _extractSvgMetadata(XmlDocument document) {
    final svgElement = document.findAllElements('svg').firstOrNull;
    final viewBox = svgElement?.getAttribute('viewBox');
    if (viewBox != null) {
      final values = viewBox.split(' ').map(double.parse).toList();
      if (values.length >= 4) {
        _viewBoxOffset = Offset(values[0], values[1]);
        _svgSize = Size(values[2], values[3]);
      }
    }
  }

  bool _shouldExtractBounds(String effectiveAsset) {
    return _lastBoundsAsset != effectiveAsset ||
        _muscleBounds == null ||
        _svgSize == null ||
        _viewBoxOffset == null;
  }

  ColorConfig _createColorConfig() {
    final highlightColor = widget.highlightColor ?? Colors.blue.withValues(alpha: 0.6);
    final disabledColor = widget.disabledColor ?? Colors.grey.withValues(alpha: 0.5);

    return ColorConfig(
      highlightHex: colorToHex(highlightColor),
      disabledHex: colorToHex(disabledColor),
      selectedStrokeWidth: widget.selectedStrokeWidth.toString(),
      unselectedStrokeWidth: widget.unselectedStrokeWidth.toString(),
    );
  }

  SvgIds _getSvgIds() {
    return SvgIds(
      selected: _selectedMuscles
          .map((m) => MuscleMapper.muscleToSvgId(m))
          .whereType<String>()
          .toSet(),
      disabled: _disabledMuscles
          .map((m) => MuscleMapper.muscleToSvgId(m))
          .whereType<String>()
          .toSet(),
    );
  }

  void _updateSvgState(String finalSvg, XmlDocument document) {
    _ensureBoundsReady(document);
    
    setState(() {
      _modifiedSvg = finalSvg;
      _isLoading = false;
      _isWidgetReady = true;
    });
  }

  void _ensureBoundsReady(XmlDocument document) {
    _muscleBounds ??= _extractMuscleBounds(document);
    if (_svgSize == null) {
      _extractSvgMetadata(document);
    }
  }

  void _processSvgElements(XmlDocument document, SvgIds svgIds, ColorConfig config) {
    _processElement(
      document.rootElement,
      svgIds,
      config,
    );
  }

  void _processElement(
    XmlElement element,
    SvgIds svgIds,
    ColorConfig config,
  ) {
    final id = element.getAttribute('id');
    final elementState = ElementState.from(id, svgIds);

    if (elementState.isPath) {
      _processPathElement(element, elementState, config);
    } else if (elementState.isGroup) {
      _processGroupElement(element, elementState, config);
      return;
    }

    for (final child in element.children) {
      if (child is XmlElement) {
        _processElement(child, svgIds, config);
      }
    }
  }

  void _processPathElement(XmlElement element, ElementState state, ColorConfig config) {
    element.removeAttribute('style');
    element.setAttribute('fill', state.fillColor(config));
    element.setAttribute('stroke', state.strokeColor(config));
    element.setAttribute('stroke-width', state.strokeWidth(config));

    if (state.isDisabled) {
      element.setAttribute('opacity', _disabledOpacity.toString());
    } else {
      element.removeAttribute('opacity');
    }
  }

  void _processGroupElement(XmlElement element, ElementState state, ColorConfig config) {
    for (final child in element.children) {
      if (child is XmlElement && child.localName == 'path') {
        final childId = child.getAttribute('id');
        if (childId == null || !MuscleMapper.isValidSvgId(childId)) {
          child.removeAttribute('style');
          child.setAttribute('fill', state.fillColor(config));
          child.setAttribute('stroke', 'none');
          child.setAttribute('stroke-width', '0');
          
          if (state.isDisabled) {
            child.setAttribute('opacity', _disabledOpacity.toString());
          } else {
            child.removeAttribute('opacity');
          }

          child.removeAttribute('stroke-linejoin');
          child.removeAttribute('stroke-linecap');
          child.removeAttribute('stroke-miterlimit');
        }
      }
    }
  }

  Map<String, Rect> _extractMuscleBounds(XmlDocument document) {
    _resetBoundsData();
    final bounds = <String, Rect>{};
    final pathIds = <String>[];
    final groupIds = <String>[];

    _extractPathBounds(document, bounds, pathIds);
    _extractGroupBounds(document, bounds, groupIds);

    _orderedPathIds = pathIds;
    _orderedGroupIds = groupIds;
    _lastBoundsAsset = widget._effectiveAsset;

    return bounds;
  }

  void _resetBoundsData() {
    _groupPathBounds = <String, List<Rect>>{};
    _musclePathData = <String, String>{};
    _groupPathData = <String, List<String>>{};
    _orderedPathIds = null;
    _orderedGroupIds = null;
  }

  void _extractPathBounds(
    XmlDocument document,
    Map<String, Rect> bounds,
    List<String> pathIds,
  ) {
    for (final path in document.findAllElements('path')) {
      final id = path.getAttribute('id');
      if (id == null || !MuscleMapper.isValidSvgId(id)) continue;

      final pathData = path.getAttribute('d');
      if (pathData == null) continue;

      final rect = _parsePathBounds(pathData);
      if (rect != null) {
        bounds[id] = rect;
        _musclePathData![id] = pathData;
        pathIds.add(id);
      }
    }
  }

  void _extractGroupBounds(
    XmlDocument document,
    Map<String, Rect> bounds,
    List<String> groupIds,
  ) {
    for (final group in document.findAllElements('g')) {
      final id = group.getAttribute('id');
      if (id == null || !MuscleMapper.isValidSvgId(id)) continue;

      final groupData = _extractGroupData(group);
      if (groupData != null) {
        bounds[id] = groupData.bounds;
        _groupPathBounds![id] = groupData.pathBounds;
        _groupPathData![id] = groupData.pathDataList;
        groupIds.add(id);
      }
    }
  }

  GroupData? _extractGroupData(XmlElement group) {
    final groupPaths = group.findAllElements('path');
    final pathBounds = <Rect>[];
    final pathDataList = <String>[];
    Rect? groupRect;

    for (final path in groupPaths) {
      final pathData = path.getAttribute('d');
      if (pathData == null) continue;

      final rect = _parsePathBounds(pathData);
      if (rect != null) {
        pathBounds.add(rect);
        pathDataList.add(pathData);
        groupRect = groupRect == null
            ? rect
            : expandRect(groupRect, rect);
      }
    }

    if (groupRect == null) return null;

    return GroupData(
      bounds: groupRect,
      pathBounds: pathBounds,
      pathDataList: pathDataList,
    );
  }

  Rect? _parsePathBounds(String pathData) {
    final numbers = RegExp(r'-?\d+\.?\d*')
        .allMatches(pathData)
        .map((m) => double.tryParse(m.group(0) ?? ''))
        .where((n) => n != null)
        .cast<double>()
        .toList();

    if (numbers.isEmpty) return null;

    final coordinates = extractCoordinates(numbers);
    if (coordinates.isEmpty) return null;

    return calculateBounds(coordinates, margin: _pathBoundsMargin);
  }

  Muscle? _findMuscleAtPoint(Offset localPosition) {
    if (!_isWidgetReady ||
        _muscleBounds == null ||
        _svgSize == null ||
        _viewBoxOffset == null ||
        _musclePathData == null) {
      return null;
    }

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize || renderBox.size.isEmpty) {
      return null;
    }

    final renderedRect = _getRenderedRect(
      renderBox.size,
      _svgSize!,
      widget.fit,
      widget.alignment,
    );

    if (!renderedRect.contains(localPosition)) {
      return null;
    }

    final tapPoint = _transformToSvgCoordinates(localPosition, renderedRect);
    final tappedMuscleId = _findTappedMuscleId(tapPoint);

    return tappedMuscleId != null
        ? MuscleMapper.svgIdToMuscle(tappedMuscleId)
        : null;
  }

  Offset _transformToSvgCoordinates(Offset localPosition, Rect renderedRect) {
    final relativeX = localPosition.dx - renderedRect.left;
    final relativeY = localPosition.dy - renderedRect.top;

    final scaleX = _svgSize!.width / renderedRect.width;
    final scaleY = _svgSize!.height / renderedRect.height;

    final svgX = relativeX * scaleX;
    final svgY = relativeY * scaleY;

    return Offset(
      svgX + _viewBoxOffset!.dx,
      svgY + _viewBoxOffset!.dy,
    );
  }

  String? _findTappedMuscleId(Offset tapPoint) {
    final pathId = _findTappedPathId(tapPoint);
    if (pathId != null) return pathId;

    return _findTappedGroupId(tapPoint);
  }

  String? _findTappedPathId(Offset tapPoint) {
    if (_orderedPathIds == null) return null;

    for (final pathId in _orderedPathIds!.reversed) {
      final bounds = _muscleBounds![pathId];
      if (bounds == null) continue;

      if (!_isPointInRect(tapPoint, bounds, padding: _hitTestPadding)) {
        continue;
      }

      final pathData = _musclePathData![pathId];
      if (pathData != null && _isPointInPath(tapPoint, pathData)) {
        return pathId;
      }
    }

    return null;
  }

  String? _findTappedGroupId(Offset tapPoint) {
    if (_groupPathBounds == null ||
        _groupPathData == null ||
        _orderedGroupIds == null) {
      return null;
    }

    for (final groupId in _orderedGroupIds!.reversed) {
      final overallBounds = _muscleBounds![groupId];
      if (overallBounds == null) continue;

      if (!_isPointInRect(tapPoint, overallBounds, padding: _hitTestPadding)) {
        continue;
      }

      final pathDataList = _groupPathData![groupId];
      final pathBounds = _groupPathBounds![groupId];

      if (pathDataList == null || pathBounds == null) continue;

      for (int i = pathDataList.length - 1; i >= 0; i--) {
        if (!_isPointInRect(tapPoint, pathBounds[i], padding: _hitTestPadding)) {
          continue;
        }

        if (_isPointInPath(tapPoint, pathDataList[i])) {
          return groupId;
        }
      }
    }

    return null;
  }

  bool _isPointInRect(Offset point, Rect rect, {double? padding}) {
    final paddingValue = padding ?? widget.hitTestPadding;
    final expandedRect = Rect.fromLTRB(
      rect.left - paddingValue,
      rect.top - paddingValue,
      rect.right + paddingValue,
      rect.bottom + paddingValue,
    );
    return expandedRect.contains(point);
  }

  bool _isPointInPath(Offset point, String pathData) {
    try {
      final points = _parseSvgPathToPoints(pathData);
      if (points.length < 3) return false;

      return _rayCastingTest(point, points);
    } catch (e) {
      return false;
    }
  }

  bool _rayCastingTest(Offset point, List<Offset> points) {
    int intersections = 0;
    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];

      if ((p1.dy > point.dy) != (p2.dy > point.dy)) {
        final dyDiff = (p2.dy - p1.dy).abs();
        if (dyDiff > 0.0001) {
          final xIntersect =
              (point.dy - p1.dy) * (p2.dx - p1.dx) / (p2.dy - p1.dy) + p1.dx;
          if (point.dx < xIntersect) {
            intersections++;
          }
        }
      }
    }

    return intersections % 2 == 1;
  }

  List<Offset> _parseSvgPathToPoints(String pathData) {
    if (pathData.isEmpty) return [];

    final tokens = RegExp(r'[MmLlHhVvCcSsQqTtZz]|-?\d+\.?\d*')
        .allMatches(pathData)
        .map((m) => m.group(0)!)
        .toList();

    if (tokens.isEmpty) return [];

    return PathParser(tokens).parse();
  }

  Rect _getRenderedRect(
    Size outputSize,
    Size inputSize,
    BoxFit fit,
    Alignment alignment,
  ) {
    if (inputSize.isEmpty || outputSize.isEmpty) {
      return Rect.zero;
    }

    final fittedSize = _calculateFittedSize(outputSize, inputSize, fit);
    final position = _calculatePosition(outputSize, fittedSize, alignment);

    return Rect.fromLTWH(
      position.dx,
      position.dy,
      fittedSize.width,
      fittedSize.height,
    );
  }

  Size _calculateFittedSize(Size outputSize, Size inputSize, BoxFit fit) {
    switch (fit) {
      case BoxFit.contain:
        final scale = (outputSize.width / inputSize.width)
            .clamp(0.0, outputSize.height / inputSize.height);
        return Size(inputSize.width * scale, inputSize.height * scale);

      case BoxFit.cover:
        final scale = (outputSize.width / inputSize.width)
            .clamp(outputSize.height / inputSize.height, double.infinity);
        return Size(inputSize.width * scale, inputSize.height * scale);

      case BoxFit.fill:
        return outputSize;

      case BoxFit.fitWidth:
        final scale = outputSize.width / inputSize.width;
        return Size(outputSize.width, inputSize.height * scale);

      case BoxFit.fitHeight:
        final scale = outputSize.height / inputSize.height;
        return Size(inputSize.width * scale, outputSize.height);

      case BoxFit.none:
        return inputSize;

      case BoxFit.scaleDown:
        final scale = (outputSize.width / inputSize.width)
            .clamp(0.0, outputSize.height / inputSize.height);
        return scale < 1.0
            ? Size(inputSize.width * scale, inputSize.height * scale)
            : inputSize;
    }
  }

  Offset _calculatePosition(Size outputSize, Size fittedSize, Alignment alignment) {
    final dx = alignment.x * (outputSize.width - fittedSize.width) / 2;
    final dy = alignment.y * (outputSize.height - fittedSize.height) / 2;

    return Offset(
      outputSize.width / 2 + dx - fittedSize.width / 2,
      outputSize.height / 2 + dy - fittedSize.height / 2,
    );
  }

  void _handleTap(TapDownDetails details) {
    final muscle = _findMuscleAtPoint(details.localPosition);
    if (muscle == null) return;

    if (_disabledMuscles.contains(muscle)) {
      widget.onMuscleTapDisabled?.call(muscle);
      return;
    }

    if (widget.enableSelection) {
      if (!widget.isInitialSelection) {
        widget.onMuscleTap?.call(muscle);
      }
    } else {
      widget.onMuscleTapDisabled?.call(muscle);
    }
  }

  void _handleLongPress(LongPressStartDetails details) {
    final muscle = _findMuscleAtPoint(details.localPosition);
    if (muscle == null) return;

    widget.onMuscleLongPress?.call(muscle);

    if (widget.tooltipBuilder != null && mounted) {
      final tooltipText = widget.tooltipBuilder!(muscle);
      if (tooltipText != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tooltipText),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget svgWidget = _buildSvgWidget();
    
    if (widget.width != null || widget.height != null) {
      svgWidget = SizedBox(
        width: widget.width,
        height: widget.height,
        child: svgWidget,
      );
    }

    if (widget.enableSelection) {
      svgWidget = GestureDetector(
        behavior: widget.hitTestBehavior,
        onTapDown: _handleTap,
        onLongPressStart: _handleLongPress,
        child: svgWidget,
      );
    }

    final semanticLabel = _buildSemanticLabel();
    if (semanticLabel != null) {
      svgWidget = Semantics(
        label: semanticLabel,
        button: widget.enableSelection,
        child: svgWidget,
      );
    }

    return svgWidget;
  }

  Widget _buildSvgWidget() {
    if (_loadError != null && !_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            const Text('Failed to load SVG', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _loadError!,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }
    
    if (_isLoading ||
        _modifiedSvg == null ||
        _svgSize == null ||
        !_isWidgetReady) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_modifiedSvg!.trim().startsWith('<svg')) {
      return const Center(
        child: Text('Invalid SVG format', style: TextStyle(color: Colors.red)),
      );
    }
    
    return RepaintBoundary(
      child: Builder(
        builder: (context) {
          try {
            try {
              XmlDocument.parse(_modifiedSvg!);
            } catch (parseError) {
              return Center(
                child: Text('Invalid SVG XML: $parseError', style: const TextStyle(color: Colors.red)),
              );
            }
            
            return SvgPicture.string(
              _modifiedSvg!,
              fit: widget.fit,
              alignment: widget.alignment,
              width: widget.width,
              height: widget.height,
            );
          } catch (e) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  const Text('SVG Rendering Error', style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      e.toString(),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  String? _buildSemanticLabel() {
    if (widget.semanticLabelBuilder == null) return null;

    if (_selectedMuscles.isNotEmpty) {
      final labels = _selectedMuscles
          .map((m) => widget.semanticLabelBuilder!(m))
          .whereType<String>()
          .join(', ');
      return labels.isNotEmpty ? labels : null;
    }

    return 'Interactive body diagram. Tap to select muscles.';
  }
}
