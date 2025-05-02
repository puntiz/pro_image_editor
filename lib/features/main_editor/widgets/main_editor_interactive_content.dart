import 'dart:async';

import 'package:flutter/material.dart';

import '/core/models/editor_callbacks/pro_image_editor_callbacks.dart';
import '/core/models/editor_configs/pro_image_editor_configs.dart';
import '/features/crop_rotate_editor/widgets/crop_layer_painter.dart';
import '/features/main_editor/controllers/main_editor_controllers.dart';
import '/features/main_editor/services/layer_interaction_manager.dart';
import '/shared/controllers/video_controller.dart';
import '/shared/services/content_recorder/widgets/content_recorder.dart';
import '/shared/widgets/extended/extended_interactive_viewer.dart';
import '/shared/widgets/video/video_editor_configurable.dart';
import '/shared/widgets/video/video_editor_controls_widget.dart';
import '../main_editor.dart';
import '../services/sizes_manager.dart';
import '../services/state_manager.dart';
import 'main_editor_font_preloader.dart';

/// A widget representing the interactive content area of the main editor,
/// including layers, helper lines, and editing interactions.
class MainEditorInteractiveContent extends StatelessWidget {
  /// Creates a `MainEditorInteractiveContent` widget with the provided
  /// builders, managers, configurations, and callbacks.
  ///
  /// - [buildImage]: A builder function to create the image widget.
  /// - [buildVideo]: A builder function to create the video widget.
  /// - [buildLayers]: A builder function to create the layer widgets.
  /// - [buildHelperLines]: A builder function to create the helper lines
  ///   widget.
  /// - [buildRemoveArea]: A builder function to create the remove area widget.
  /// - [stateManager]: Manages the state of the editor.
  /// - [sizesManager]: Handles size-related settings and adjustments.
  /// - [state]: Represents the current state of the editor.
  /// - [configs]: Configuration settings for the editor.
  /// - [callbacks]: Provides callbacks for editor interactions.
  /// - [controllers]: Manages the main editor's controllers.
  /// - [layerInteractionManager]: Handles interactions with editor layers.
  /// - [rebuildController]: A stream controller for triggering UI rebuilds.
  /// - [interactiveViewerKey]: A key for managing the interactive viewer state.
  /// - [selectedLayerIndex]: The index of the currently selected layer.
  /// - [processFinalImage]: Indicates whether the final image is being
  ///   processed.
  const MainEditorInteractiveContent({
    super.key,
    required this.buildImage,
    required this.buildVideo,
    required this.buildLayers,
    required this.buildHelperLines,
    required this.buildRemoveArea,
    required this.callbacks,
    required this.sizesManager,
    required this.configs,
    required this.layerInteractionManager,
    required this.controllers,
    required this.selectedLayerIndex,
    required this.processFinalImage,
    required this.rebuildController,
    required this.stateManager,
    required this.interactiveViewerKey,
    required this.state,
    required this.isVideoEditor,
    required this.videoController,
  });

  /// A builder function to create the image widget.
  final Widget Function() buildImage;

  /// A builder function to create the video widget.
  final Widget Function() buildVideo;

  /// A builder function to create the layer widgets.
  final Widget Function() buildLayers;

  /// A builder function to create the helper lines widget.
  final Widget Function() buildHelperLines;

  /// A builder function to create the remove icon widget.
  final Widget Function() buildRemoveArea;

  /// Manages the state of the editor.
  final StateManager stateManager;

  /// Handles size-related settings and adjustments.
  final SizesManager sizesManager;

  /// Represents the current state of the editor.
  final ProImageEditorState state;

  /// Configuration settings for the editor.
  final ProImageEditorConfigs configs;

  /// Provides callbacks for editor interactions.
  final ProImageEditorCallbacks callbacks;

  /// Manages the main editor's controllers.
  final MainEditorControllers controllers;

  /// Handles interactions with editor layers.
  final LayerInteractionManager layerInteractionManager;

  /// A stream controller for triggering UI rebuilds.
  final StreamController<void> rebuildController;

  /// A key for managing the interactive viewer state.
  final GlobalKey<ExtendedInteractiveViewerState> interactiveViewerKey;

  /// The index of the currently selected layer.
  final int selectedLayerIndex;

  /// Indicates whether the final image is being processed.
  final bool processFinalImage;

  /// Indicates whether the image or video editor is active.
  final bool isVideoEditor;

  /// Manages video-related functionalities within the main editor.
  final ProVideoController? videoController;

  @override
  Widget build(BuildContext context) {
    bool isLayerSelected = selectedLayerIndex >= 0;

    return Center(
      child: Stack(
        children: [
          //  MainEditorFontPreloader(emojiEditorConfigs: configs.emojiEditor),
          Padding(
            padding: isLayerSelected &&
                    configs.layerInteraction.hideToolbarOnInteraction
                ? EdgeInsets.only(
                    top: sizesManager.appBarHeight,
                    bottom: sizesManager.bottomBarHeight,
                  )
                : EdgeInsets.zero,
            child: _buildInteractiveViewer(),
          ),

          /// Build crop area overlay
          if (configs.imageGeneration.cropToImageBounds)
            _buildCropAreaOverlay(),

          /// Build video controls
          if (isVideoEditor)
            AnimatedSwitcher(
              duration: configs.layerInteraction.videoControlsSwitchDuration,
              child: isLayerSelected
                  ? const SizedBox.shrink()
                  : VideoEditorConfigurable(
                      controller: videoController!,
                      child: const VideoEditorControlsWidget(),
                    ),
            ),

          /// Build helper content
          if (!processFinalImage) ...[
            buildHelperLines(),
            if (selectedLayerIndex >= 0) buildRemoveArea(),
          ],

          /// Build custom body items
          if (configs.mainEditor.widgets.bodyItems != null)
            ...configs.mainEditor.widgets.bodyItems!(
              state,
              rebuildController.stream,
            ),
        ],
      ),
    );
  }

  Widget _buildInteractiveViewer() {
    var mainConfigs = configs.mainEditor;
    var paintConfigs = configs.paintEditor;
    return ExtendedInteractiveViewer(
      key: interactiveViewerKey,
      zoomConfigs: mainConfigs,
      onInteractionStart: (details) {
        callbacks.mainEditorCallbacks?.onEditorZoomScaleStart?.call(details);
        layerInteractionManager.freeStyleHighPerformanceEditorZoom =
            (paintConfigs.enableFreeStyleHighPerformanceMoving ?? !isDesktop) ||
                (paintConfigs.enableFreeStyleHighPerformanceScaling ??
                    !isDesktop);

        controllers.uiLayerCtrl.add(null);
      },
      onInteractionUpdate: (details) {
        callbacks.mainEditorCallbacks?.onEditorZoomScaleUpdate?.call(details);
        controllers.cropLayerPainterCtrl.add(null);
      },
      onInteractionEnd: (details) {
        callbacks.mainEditorCallbacks?.onEditorZoomScaleEnd?.call(details);
        layerInteractionManager.freeStyleHighPerformanceEditorZoom = false;
        controllers.uiLayerCtrl.add(null);
        controllers.cropLayerPainterCtrl.add(null);
      },
      onMatrix4Change: (value) {
        controllers.cropLayerPainterCtrl.add(null);
        callbacks.mainEditorCallbacks?.onEditorZoomMatrix4Change?.call(value);
      },
      child: isVideoEditor
          ? Stack(
              alignment: Alignment.center,
              fit: StackFit.expand,
              children: [
                buildVideo(),
                _buildContentRecorder(),
              ],
            )
          : _buildContentRecorder(),
    );
  }

  Widget _buildContentRecorder() {
    return ContentRecorder(
      key: const ValueKey('main-editor-content-recorder'),
      autoDestroyController: false,
      controller: controllers.screenshot,
      child: Stack(
        alignment: Alignment.center,
        fit: StackFit.expand,
        children: [
          buildImage(),
          buildLayers(),
          if (configs.mainEditor.widgets.bodyItemsRecorded != null)
            ...configs.mainEditor.widgets.bodyItemsRecorded!(
                state, rebuildController.stream),
        ],
      ),
    );
  }

  Widget _buildCropAreaOverlay() {
    return Hero(
      tag: 'crop_layer_painter_hero',
      child: StreamBuilder(
        stream: controllers.cropLayerPainterCtrl.stream,
        builder: (context, snapshot) {
          return CustomPaint(
            foregroundPainter: configs.imageGeneration.cropToImageBounds
                ? CropLayerPainter(
                    opacity:
                        configs.mainEditor.style.outsideCaptureAreaLayerOpacity,
                    backgroundColor: configs.mainEditor.style.background,
                    imgRatio: stateManager.transformConfigs.isNotEmpty
                        ? stateManager
                            .transformConfigs.cropRect.size.aspectRatio
                        : sizesManager.decodedImageSize.aspectRatio,
                    isRoundCropper: configs.cropRotateEditor.enableRoundCropper,
                    is90DegRotated:
                        stateManager.transformConfigs.is90DegRotated,
                    interactiveViewerScale:
                        interactiveViewerKey.currentState?.scaleFactor ?? 1.0,
                    interactiveViewerOffset:
                        interactiveViewerKey.currentState?.offset ??
                            Offset.zero,
                  )
                : null,
            child: const SizedBox.expand(),
          );
        },
      ),
    );
  }
}
