import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:xml/xml.dart';
import 'package:flutter_body_part_selector/flutter_body_part_selector.dart' as fbps;
import '../theme/app_theme.dart';

/// Renders a human body silhouette with custom heat-map style opacity per muscle.
/// Uses the raw SVG assets from flutter_body_part_selector package internally.
class BodyPartHeatmap extends StatelessWidget {
  final bool isFront;
  final Map<fbps.Muscle, double> intensities;
  final Color baseColor;
  final Color outlineColor;
  final double? width;
  final double? height;

  const BodyPartHeatmap({
    super.key,
    required this.isFront,
    required this.intensities,
    this.baseColor = AppTheme.primary,
    this.outlineColor = AppTheme.textSecondary,
    this.width,
    this.height,
  });

  // Self-contained mapping to avoid relying on internal, non-exported package mappers
  static const Map<fbps.Muscle, String> _muscleToSvgId = {
    fbps.Muscle.trapsLeft: 'traps_left',
    fbps.Muscle.trapsRight: 'traps_right',
    fbps.Muscle.deltsLeft: 'delts_left',
    fbps.Muscle.deltsRight: 'delts_right',
    fbps.Muscle.chestLeft: 'chest_left',
    fbps.Muscle.chestRight: 'chest_right',
    fbps.Muscle.abs: 'abs',
    fbps.Muscle.tricepsLeft: 'triceps_left',
    fbps.Muscle.tricepsRight: 'triceps_right',
    fbps.Muscle.bicepsLeft: 'biceps_left',
    fbps.Muscle.bicepsRight: 'biceps_right',
    fbps.Muscle.forearmsLeft: 'forearms_left',
    fbps.Muscle.forearmsRight: 'forearms_right',
    fbps.Muscle.quadsLeft: 'quads_left',
    fbps.Muscle.quadsRight: 'quads_right',
    fbps.Muscle.calvesLeft: 'calves_left',
    fbps.Muscle.calvesRight: 'calves_right',
    fbps.Muscle.latsBackLeft: 'lats_left',
    fbps.Muscle.latsBackRight: 'lats_right',
    fbps.Muscle.lowerLatsBackLeft: 'lowerlats_back_left',
    fbps.Muscle.lowerLatsBackRight: 'lowerlats_back_right',
    fbps.Muscle.glutesLeft: 'glutes_left',
    fbps.Muscle.glutesRight: 'glutes_right',
    fbps.Muscle.hamstringsLeft: 'hamstrings_left',
    fbps.Muscle.hamstringsRight: 'hamstrings_right',
  };

  static final Set<String> _validSvgIds = _muscleToSvgId.values.toSet();

  Future<String> _loadAndProcessSvg() async {
    final assetPath = isFront
        ? 'packages/flutter_body_part_selector/assets/svg/body_front.svg'
        : 'packages/flutter_body_part_selector/assets/svg/body_back.svg';

    final svgString = await rootBundle.loadString(assetPath);
    final document = XmlDocument.parse(svgString);

    // Modify the SVG nodes
    _processXml(document.rootElement);

    return document.toXmlString();
  }

  void _processXml(XmlNode node) {
    if (node is XmlElement) {
      final id = node.getAttribute('id');
      if (id == 'front_body' || id == 'back_body') {
        // Outer body silhouette outline
        node.removeAttribute('style');
        node.setAttribute('fill', 'none');
        node.setAttribute('stroke', _colorToHex(outlineColor));
        node.setAttribute('stroke-width', '1.0');
      } else if (id != null && _validSvgIds.contains(id)) {
        final muscle = _muscleToSvgId.entries
            .firstWhere((entry) => entry.value == id)
            .key;
        final intensity = intensities[muscle] ?? 0.0;
        // Map intensity (0.0 to 1.0) to opacity range (40% to 100%)
        final opacity = 0.4 + 0.6 * intensity;
        _applyColorToElement(node, baseColor, opacity);
        return; // Colored group/element, skip children recursion
      }

      for (final child in node.children) {
        _processXml(child);
      }
    }
  }

  void _applyColorToElement(XmlElement element, Color color, double opacity) {
    element.removeAttribute('style');
    element.setAttribute('fill', _colorToHex(color));
    element.setAttribute('fill-opacity', opacity.toString());

    if (element.localName == 'path') {
      element.setAttribute('fill', _colorToHex(color));
      element.setAttribute('fill-opacity', opacity.toString());
      element.setAttribute('stroke', '#1C1C1E'); // Contrast boundary lines
      element.setAttribute('stroke-width', '0.5');
    }

    for (final child in element.children) {
      if (child is XmlElement) {
        _applyColorToElement(child, color, opacity);
      }
    }
  }

  String _colorToHex(Color color) {
    // Mask off alpha channel and convert the rest to a 6-character hex string.
    // This avoids accessing deprecated red/green/blue getters or modern r/g/b getters.
    final rgb = color.toARGB32() & 0x00FFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _loadAndProcessSvg(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
              ),
            ),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Icon(Icons.error_outline, color: AppTheme.primary),
          );
        }
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        return SvgPicture.string(
          snapshot.data!,
          fit: BoxFit.contain,
          width: width,
          height: height,
        );
      },
    );
  }
}
