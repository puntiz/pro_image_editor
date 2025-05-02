import 'package:flutter/material.dart';

import '/core/models/editor_configs/pro_image_editor_configs.dart';
import '/core/models/editor_image.dart';
import '/features/filter_editor/widgets/filter_generator.dart';
import '/shared/widgets/auto_image.dart';
import '/shared/widgets/transform/transformed_content_generator.dart';
import '../../filter_editor/widgets/filtered_widget.dart';
import '../services/sizes_manager.dart';
import '../services/state_manager.dart';

/// A widget for displaying the background image in the main editor,
/// supporting color filters and size configurations.
class MainEditorBackgroundImage extends StatelessWidget {
  /// Creates a `MainEditorBackgroundImage` with the provided configurations
  /// and dependencies.
  ///
  /// - [stateManager]: Manages the state of the editor.
  /// - [sizesManager]: Handles size configurations and adjustments.
  /// - [configs]: The editor's configuration settings.
  /// - [editorImage]: The main image being edited.
  /// - [backgroundImageColorFilterKey]: A key for applying color filters
  ///   to the background image.
  /// - [isInitialized]: Indicates whether the editor has been fully
  ///   initialized.
  const MainEditorBackgroundImage({
    super.key,
    required this.stateManager,
    required this.sizesManager,
    required this.configs,
    required this.editorImage,
    required this.backgroundImageColorFilterKey,
    required this.isInitialized,
    required this.heroTag,
  });

  /// The main image being edited in the editor.
  final EditorImage editorImage;

  /// Manages the state of the editor.
  final StateManager stateManager;

  /// Handles size configurations and adjustments.
  final SizesManager sizesManager;

  /// Configuration settings for the editor.
  final ProImageEditorConfigs configs;

  /// A key for managing the color filter applied to the background image.
  final GlobalKey<ColorFilterGeneratorState> backgroundImageColorFilterKey;

  /// Indicates whether the editor has been fully initialized.
  final bool isInitialized;

  /// A unique hero tag for the Image Editor widget.
  final String heroTag;

  @override
  Widget build(BuildContext context) {
    return Hero(
        tag: heroTag,
        createRectTween: (begin, end) => RectTween(begin: begin, end: end),
        // child: !isInitialized?
        child: AutoImage(
          editorImage,
          fit: BoxFit.contain,
          width: sizesManager.decodedImageSize.width,
          height: sizesManager.decodedImageSize.height,
          configs: configs,
        )
        // : TransformedContentGenerator(
        //     transformConfigs: stateManager.transformConfigs,
        //     configs: configs,
        //     child: FilteredWidget(
        //       filterKey: backgroundImageColorFilterKey,
        //       width: sizesManager.decodedImageSize.width,
        //       height: sizesManager.decodedImageSize.height,
        //       configs: configs,
        //       image: editorImage,
        //       filters: stateManager.activeFilters,
        //       tuneAdjustments: stateManager.activeTuneAdjustments,
        //       blurFactor: stateManager.activeBlur,
        //     ),
        //   ),
        );
  }
}
