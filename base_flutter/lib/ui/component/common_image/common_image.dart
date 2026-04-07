// ignore_for_file: avoid_using_unsafe_cast, avoid_hard_coded_strings
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cached_network_image_platform_interface/cached_network_image_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../index.dart';

class CommonImage extends StatelessWidget {
  const CommonImage._({
    required this.imageInputType,
    required this.source,
    required this.style,
    super.key,
  });

  CommonImage.svg({
    required String path,
    Key? key,
    double? width,
    double? height,
    Color? foregroundColor,
    BlendMode? colorBlendMode,
    BoxFit? fit,
    Alignment? alignment,
    bool? matchTextDirection,
    bool? allowDrawingOutsideViewBox,
    Widget Function(BuildContext context)? placeholderBuilder,
    Clip? clipBehavior,
    VoidCallback? onTap,
  }) : this._(
          imageInputType: ImageInputType.svg,
          source: path,
          style: _CommonSvgImageStyle(
            width: width,
            height: height,
            foregroundColor: foregroundColor,
            colorBlendMode: colorBlendMode,
            fit: fit,
            alignment: alignment,
            matchTextDirection: matchTextDirection,
            allowDrawingOutsideViewBox: allowDrawingOutsideViewBox,
            placeholderBuilder: placeholderBuilder,
            clipBehavior: clipBehavior,
            onTap: onTap,
          ),
          key: key,
        );

  CommonImage.asset({
    required String path,
    Key? key,
    double? width,
    double? height,
    Color? foregroundColor,
    ImageFrameBuilder? frameBuilder,
    Widget Function(BuildContext context, Object error)? errorBuilder,
    BlendMode? colorBlendMode,
    BoxFit? fit,
    Alignment? alignment,
    ImageRepeat? repeat,
    Rect? centerSlice,
    bool? matchTextDirection,
    bool? gaplessPlayback,
    bool? isAntiAlias,
    FilterQuality? filterQuality,
    VoidCallback? onTap,
  }) : this._(
          imageInputType: ImageInputType.asset,
          source: path,
          style: _CommonAssetImageStyle(
            width: width,
            height: height,
            foregroundColor: foregroundColor,
            frameBuilder: frameBuilder,
            errorBuilder: errorBuilder,
            colorBlendMode: colorBlendMode,
            fit: fit,
            alignment: alignment,
            repeat: repeat,
            centerSlice: centerSlice,
            matchTextDirection: matchTextDirection,
            gaplessPlayback: gaplessPlayback,
            isAntiAlias: isAntiAlias,
            filterQuality: filterQuality,
            onTap: onTap,
          ),
          key: key,
        );

  CommonImage.iconData({
    required IconData? iconData,
    Key? key,
    double? size,
    Color? foregroundColor,
    VoidCallback? onTap,
  }) : this._(
          imageInputType: ImageInputType.iconData,
          source: iconData,
          style: _CommonIconDataImageStyle(
            size: size,
            foregroundColor: foregroundColor,
            onTap: onTap,
          ),
          key: key,
        );

  CommonImage.file({
    required File file,
    Key? key,
    double? width,
    double? height,
    Color? foregroundColor,
    ImageFrameBuilder? frameBuilder,
    Animation<double>? opacity,
    BlendMode? colorBlendMode,
    Rect? centerSlice,
    bool? isAntiAlias,
    int? cacheHeight,
    int? cacheWidth,
    double? scale,
    Widget Function(BuildContext context, Object error)? errorBuilder,
    BoxFit? fit,
    Alignment? alignment,
    ImageRepeat? repeat,
    FilterQuality? filterQuality,
    bool? matchTextDirection,
    bool? gaplessPlayback,
    VoidCallback? onTap,
  }) : this._(
          imageInputType: ImageInputType.file,
          source: file,
          style: _CommonFileImageStyle(
            width: width,
            height: height,
            foregroundColor: foregroundColor,
            frameBuilder: frameBuilder,
            opacity: opacity,
            colorBlendMode: colorBlendMode,
            centerSlice: centerSlice,
            isAntiAlias: isAntiAlias,
            cacheHeight: cacheHeight,
            cacheWidth: cacheWidth,
            scale: scale,
            errorBuilder: errorBuilder,
            fit: fit,
            alignment: alignment,
            repeat: repeat,
            filterQuality: filterQuality,
            matchTextDirection: matchTextDirection,
            gaplessPlayback: gaplessPlayback,
            onTap: onTap,
          ),
          key: key,
        );

  CommonImage.memory({
    required Uint8List bytes,
    Key? key,
    double? width,
    double? height,
    Color? foregroundColor,
    ImageFrameBuilder? frameBuilder,
    Animation<double>? opacity,
    BlendMode? colorBlendMode,
    Rect? centerSlice,
    bool? isAntiAlias,
    int? cacheHeight,
    int? cacheWidth,
    double? scale,
    Widget Function(BuildContext context, Object error)? errorBuilder,
    BoxFit? fit,
    Alignment? alignment,
    ImageRepeat? repeat,
    FilterQuality? filterQuality,
    bool? matchTextDirection,
    bool? gaplessPlayback,
    VoidCallback? onTap,
  }) : this._(
          imageInputType: ImageInputType.memory,
          source: bytes,
          style: _CommonMemoryImageStyle(
            width: width,
            height: height,
            foregroundColor: foregroundColor,
            frameBuilder: frameBuilder,
            opacity: opacity,
            colorBlendMode: colorBlendMode,
            centerSlice: centerSlice,
            isAntiAlias: isAntiAlias,
            cacheHeight: cacheHeight,
            cacheWidth: cacheWidth,
            scale: scale,
            errorBuilder: errorBuilder,
            fit: fit,
            alignment: alignment,
            repeat: repeat,
            filterQuality: filterQuality,
            matchTextDirection: matchTextDirection,
            gaplessPlayback: gaplessPlayback,
            onTap: onTap,
          ),
          key: key,
        );

  CommonImage.network({
    required String? url,
    Key? key,
    double? width,
    double? height,
    Color? foregroundColor,
    Widget Function(BuildContext context)? placeholderBuilder,
    // ignore: avoid_dynamic
    Widget Function(BuildContext context, dynamic error)? errorBuilder,
    Widget Function(BuildContext context)? loadingBuilder,
    Alignment? alignment,
    ImageRepeat? repeat,
    FilterQuality? filterQuality,
    bool? matchTextDirection,
    BlendMode? colorBlendMode,
    String? cacheKey,
    ProgressIndicatorBuilder? progressIndicatorBuilder,
    Duration? placeholderFadeInDuration,
    Duration? fadeOutDuration,
    Curve? fadeOutCurve,
    Duration? fadeInDuration,
    Curve? fadeInCurve,
    int? memCacheWidth,
    int? memCacheHeight,
    int? maxWidthDiskCache,
    int? maxHeightDiskCache,
    ImageWidgetBuilder? imageBuilder,
    Map<String, String>? httpHeaders,
    bool? useOldImageOnUrlChange,
    ImageRenderMethodForWeb? imageRenderMethodForWeb,
    BaseCacheManager? cacheManager,
    VoidCallback? onTap,
    BoxFit? fit = BoxFit.cover,
    bool enableCache = false,
  }) : this._(
          imageInputType: ImageInputType.network,
          source: url,
          style: _CommonNetworkImageStyle(
            useCachedNetworkImage: enableCache,
            fit: fit,
            width: width,
            height: height,
            foregroundColor: foregroundColor,
            placeholderBuilder: placeholderBuilder,
            errorBuilder: errorBuilder,
            alignment: alignment,
            repeat: repeat,
            filterQuality: filterQuality,
            matchTextDirection: matchTextDirection,
            colorBlendMode: colorBlendMode,
            cacheKey: cacheKey,
            progressIndicatorBuilder: progressIndicatorBuilder,
            placeholderFadeInDuration: placeholderFadeInDuration,
            fadeOutDuration: fadeOutDuration,
            fadeOutCurve: fadeOutCurve,
            fadeInDuration: fadeInDuration,
            fadeInCurve: fadeInCurve,
            memCacheWidth: memCacheWidth,
            memCacheHeight: memCacheHeight,
            maxWidthDiskCache: maxWidthDiskCache,
            maxHeightDiskCache: maxHeightDiskCache,
            imageBuilder: imageBuilder,
            loadingBuilder: loadingBuilder,
            httpHeaders: httpHeaders,
            useOldImageOnUrlChange: useOldImageOnUrlChange,
            imageRenderMethodForWeb: imageRenderMethodForWeb,
            cacheManager: cacheManager,
            onTap: onTap,
          ),
          key: key,
        );

  final _CommonImageStyle style;
  final Object? source;
  final ImageInputType imageInputType;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final devicePixelRatio = mediaQuery.devicePixelRatio;

    late final Widget image;
    switch (imageInputType) {
      case ImageInputType.svg:
        final _style = style as _CommonSvgImageStyle;
        image = SizedBox(
          width: _style.width,
          height: _style.height,
          child: (source as String).toSvgGenImage.svg(
                width: _style.width,
                height: _style.height,
                colorFilter: _style.foregroundColor
                    ?.let((it) => ColorFilter.mode(it, _style.colorBlendMode ?? BlendMode.srcIn)),
                fit: _style.fit ?? BoxFit.contain,
                alignment: _style.alignment ?? Alignment.center,
                matchTextDirection: _style.matchTextDirection ?? false,
                clipBehavior: _style.clipBehavior ?? Clip.hardEdge,
                allowDrawingOutsideViewBox: _style.allowDrawingOutsideViewBox ?? false,
                placeholderBuilder: _style.placeholderBuilder,
              ),
        );
        break;
      case ImageInputType.asset:
        final _style = style as _CommonAssetImageStyle;
        image = (source as String).toAssetGenImage.image(
              width: _style.width,
              height: _style.height,
              color: _style.foregroundColor,
              frameBuilder: _style.frameBuilder,
              errorBuilder: _style.errorBuilder != null
                  ? (context, error, _) => _style.errorBuilder!.call(context, error)
                  : null,
              colorBlendMode: _style.colorBlendMode,
              fit: _style.fit,
              alignment: _style.alignment ?? Alignment.center,
              repeat: _style.repeat ?? ImageRepeat.noRepeat,
              centerSlice: _style.centerSlice,
              matchTextDirection: _style.matchTextDirection ?? false,
              gaplessPlayback: _style.gaplessPlayback ?? false,
              isAntiAlias: _style.isAntiAlias ?? false,
              filterQuality: _style.filterQuality ?? FilterQuality.low,
            );
        break;
      case ImageInputType.network:
        final _style = style as _CommonNetworkImageStyle;
        final imageUrl = (source as String?) ?? '';
        if (_style.useCachedNetworkImage) {
          final maxWidth = min(screenWidth, _style.width ?? screenWidth);
          final maxHeight = min(screenHeight, _style.height ?? screenHeight);
          final memCacheWidth = _style.memCacheWidth ??
              (_style.width != null ? maxWidth.times(devicePixelRatio).toInt() : null);
          final memCacheHeight = _style.memCacheHeight ??
              (_style.height != null ? maxHeight.times(devicePixelRatio).toInt() : null);
          // ignore: prefer_common_widgets
          image = CachedNetworkImage(
            imageUrl: imageUrl,
            width: _style.width,
            height: _style.height,
            color: _style.foregroundColor,
            errorWidget: _style.errorBuilder != null
                // ignore:avoid_dynamic
                ? (context, url, dynamic error) => _style.errorBuilder!.call(context, error)
                : null,
            colorBlendMode: _style.colorBlendMode,
            fit: _style.fit,
            alignment: _style.alignment ?? Alignment.center,
            repeat: _style.repeat ?? ImageRepeat.noRepeat,
            matchTextDirection: _style.matchTextDirection ?? false,
            filterQuality: _style.filterQuality ?? FilterQuality.low,
            cacheKey: _style.cacheKey,
            fadeInCurve: _style.fadeInCurve ?? Curves.easeIn,
            fadeInDuration: _style.fadeInDuration ?? const Duration(milliseconds: 500),
            fadeOutCurve: _style.fadeOutCurve ?? Curves.easeOut,
            fadeOutDuration: _style.fadeOutDuration,
            imageBuilder: _style.imageBuilder,
            maxWidthDiskCache: _style.maxWidthDiskCache,
            maxHeightDiskCache: _style.maxHeightDiskCache,
            memCacheWidth: memCacheWidth,
            memCacheHeight: memCacheHeight,
            placeholder: _style.placeholderBuilder != null
                ? (context, url) => _style.placeholderBuilder!(context)
                : null,
            placeholderFadeInDuration: _style.placeholderFadeInDuration,
            progressIndicatorBuilder: _style.progressIndicatorBuilder,
            useOldImageOnUrlChange: _style.useOldImageOnUrlChange ?? false,
            httpHeaders: _style.httpHeaders,
            imageRenderMethodForWeb:
                _style.imageRenderMethodForWeb ?? ImageRenderMethodForWeb.HtmlImage,
            cacheManager: _style.cacheManager,
          );
        } else {
          // ignore: prefer_common_widgets
          image = _RetryNetworkImage(
            imageUrl: imageUrl,
            width: _style.width,
            height: _style.height,
            color: _style.foregroundColor,
            errorBuilder: _style.errorBuilder != null
                // ignore:avoid_dynamic
                ? (context, error, stackTrace) => _style.errorBuilder!.call(context, error)
                : null,
            colorBlendMode: _style.colorBlendMode,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return _showProgressIndicator(_style);
            },
            fit: _style.fit,
            alignment: _style.alignment ?? Alignment.center,
            repeat: _style.repeat ?? ImageRepeat.noRepeat,
            matchTextDirection: _style.matchTextDirection ?? false,
            filterQuality: _style.filterQuality ?? FilterQuality.low,
            headers: _style.httpHeaders,
            cacheWidth: _style.width?.isInfinite == false && _style.width?.isNaN == false
                ? _style.width?.times(devicePixelRatio).toInt()
                : screenWidth.times(devicePixelRatio).toInt(),
          );
        }

        break;
      case ImageInputType.iconData:
        final _style = style as _CommonIconDataImageStyle;
        image = Icon(source as IconData?, color: _style.foregroundColor, size: _style.size);
        break;
      case ImageInputType.memory:
        final _style = style as _CommonMemoryImageStyle;
        // ignore: prefer_common_widgets
        image = Image.memory(
          source as Uint8List,
          width: _style.width,
          height: _style.height,
          color: _style.foregroundColor,
          frameBuilder: _style.frameBuilder,
          opacity: _style.opacity,
          colorBlendMode: _style.colorBlendMode,
          centerSlice: _style.centerSlice,
          isAntiAlias: _style.isAntiAlias ?? false,
          cacheHeight: _style.cacheHeight,
          cacheWidth: _style.cacheWidth,
          scale: _style.scale ?? 1.0,
          errorBuilder: _style.errorBuilder != null
              ? (context, error, _) => _style.errorBuilder!.call(context, error)
              : null,
          fit: _style.fit,
          alignment: _style.alignment ?? Alignment.center,
          repeat: _style.repeat ?? ImageRepeat.noRepeat,
          filterQuality: _style.filterQuality ?? FilterQuality.low,
          matchTextDirection: _style.matchTextDirection ?? false,
          gaplessPlayback: _style.gaplessPlayback ?? false,
        );
        break;
      case ImageInputType.file:
        final _style = style as _CommonFileImageStyle;
        // ignore: prefer_common_widgets
        image = Image.file(
          source as File,
          width: _style.width,
          height: _style.height,
          color: _style.foregroundColor,
          frameBuilder: _style.frameBuilder,
          opacity: _style.opacity,
          colorBlendMode: _style.colorBlendMode,
          centerSlice: _style.centerSlice,
          isAntiAlias: _style.isAntiAlias ?? false,
          cacheHeight: _style.cacheHeight,
          cacheWidth: _style.cacheWidth,
          scale: _style.scale ?? 1.0,
          errorBuilder: _style.errorBuilder != null
              ? (context, error, _) => _style.errorBuilder!.call(context, error)
              : null,
          fit: _style.fit,
          alignment: _style.alignment ?? Alignment.center,
          repeat: _style.repeat ?? ImageRepeat.noRepeat,
          filterQuality: _style.filterQuality ?? FilterQuality.low,
          matchTextDirection: _style.matchTextDirection ?? false,
          gaplessPlayback: _style.gaplessPlayback ?? false,
        );
        break;
    }

    return style.onTap != null
        ? GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: style.onTap,
            child: image,
          )
        : image;
  }
}

enum ImageInputType {
  svg,
  asset,
  network,
  iconData,
  memory,
  file,
}

abstract class _CommonImageStyle {
  const _CommonImageStyle({required this.onTap});

  final VoidCallback? onTap;
}

class _CommonSvgImageStyle extends _CommonImageStyle {
  const _CommonSvgImageStyle({
    required this.width,
    required this.height,
    required this.foregroundColor,
    required this.colorBlendMode,
    required this.fit,
    required this.alignment,
    required this.matchTextDirection,
    required this.allowDrawingOutsideViewBox,
    required this.placeholderBuilder,
    required this.clipBehavior,
    required super.onTap,
  });

  final double? width;
  final double? height;
  final Color? foregroundColor;
  final BlendMode? colorBlendMode;
  final BoxFit? fit;
  final Alignment? alignment;
  final bool? matchTextDirection;
  final bool? allowDrawingOutsideViewBox;
  final Widget Function(BuildContext context)? placeholderBuilder;
  final Clip? clipBehavior;
}

class _CommonAssetImageStyle extends _CommonImageStyle {
  const _CommonAssetImageStyle({
    required this.width,
    required this.height,
    required this.foregroundColor,
    required this.frameBuilder,
    required this.errorBuilder,
    required this.colorBlendMode,
    required this.fit,
    required this.alignment,
    required this.repeat,
    required this.centerSlice,
    required this.matchTextDirection,
    required this.gaplessPlayback,
    required this.isAntiAlias,
    required this.filterQuality,
    required super.onTap,
  });

  final double? width;
  final double? height;
  final Color? foregroundColor;
  final ImageFrameBuilder? frameBuilder;
  final Widget Function(BuildContext context, Object error)? errorBuilder;
  final BlendMode? colorBlendMode;
  final BoxFit? fit;
  final Alignment? alignment;
  final ImageRepeat? repeat;
  final Rect? centerSlice;
  final bool? matchTextDirection;
  final bool? gaplessPlayback;
  final bool? isAntiAlias;
  final FilterQuality? filterQuality;
}

class _CommonIconDataImageStyle extends _CommonImageStyle {
  const _CommonIconDataImageStyle({
    required this.size,
    required this.foregroundColor,
    required super.onTap,
  });

  final double? size;
  final Color? foregroundColor;
}

class _CommonFileImageStyle extends _CommonImageStyle {
  const _CommonFileImageStyle({
    required this.width,
    required this.height,
    required this.foregroundColor,
    required this.frameBuilder,
    required this.opacity,
    required this.colorBlendMode,
    required this.centerSlice,
    required this.isAntiAlias,
    required this.cacheHeight,
    required this.cacheWidth,
    required this.scale,
    required this.errorBuilder,
    required this.fit,
    required this.alignment,
    required this.repeat,
    required this.filterQuality,
    required this.matchTextDirection,
    required this.gaplessPlayback,
    required super.onTap,
  });

  final double? width;
  final double? height;
  final Color? foregroundColor;
  final ImageFrameBuilder? frameBuilder;
  final Animation<double>? opacity;
  final BlendMode? colorBlendMode;
  final Rect? centerSlice;
  final bool? isAntiAlias;
  final int? cacheHeight;
  final int? cacheWidth;
  final double? scale;
  final Widget Function(BuildContext context, Object error)? errorBuilder;
  final BoxFit? fit;
  final Alignment? alignment;
  final ImageRepeat? repeat;
  final FilterQuality? filterQuality;
  final bool? matchTextDirection;
  final bool? gaplessPlayback;
}

class _CommonMemoryImageStyle extends _CommonImageStyle {
  const _CommonMemoryImageStyle({
    required this.width,
    required this.height,
    required this.foregroundColor,
    required this.frameBuilder,
    required this.opacity,
    required this.colorBlendMode,
    required this.centerSlice,
    required this.isAntiAlias,
    required this.cacheHeight,
    required this.cacheWidth,
    required this.scale,
    required this.errorBuilder,
    required this.fit,
    required this.alignment,
    required this.repeat,
    required this.filterQuality,
    required this.matchTextDirection,
    required this.gaplessPlayback,
    required super.onTap,
  });

  final double? width;
  final double? height;
  final Color? foregroundColor;
  final ImageFrameBuilder? frameBuilder;
  final Animation<double>? opacity;
  final BlendMode? colorBlendMode;
  final Rect? centerSlice;
  final bool? isAntiAlias;
  final int? cacheHeight;
  final int? cacheWidth;
  final double? scale;
  final Widget Function(BuildContext context, Object error)? errorBuilder;
  final BoxFit? fit;
  final Alignment? alignment;
  final ImageRepeat? repeat;
  final FilterQuality? filterQuality;
  final bool? matchTextDirection;
  final bool? gaplessPlayback;
}

class _CommonNetworkImageStyle extends _CommonImageStyle {
  const _CommonNetworkImageStyle({
    required this.useCachedNetworkImage,
    required this.width,
    required this.height,
    required this.foregroundColor,
    required this.placeholderBuilder,
    required this.errorBuilder,
    required this.loadingBuilder,
    required this.alignment,
    required this.repeat,
    required this.filterQuality,
    required this.matchTextDirection,
    required this.colorBlendMode,
    required this.cacheKey,
    required this.progressIndicatorBuilder,
    required this.placeholderFadeInDuration,
    required this.fadeOutDuration,
    required this.fadeOutCurve,
    required this.fadeInDuration,
    required this.fadeInCurve,
    required this.memCacheWidth,
    required this.memCacheHeight,
    required this.maxWidthDiskCache,
    required this.maxHeightDiskCache,
    required this.imageBuilder,
    required this.httpHeaders,
    required this.useOldImageOnUrlChange,
    required this.imageRenderMethodForWeb,
    required this.cacheManager,
    required this.fit,
    required super.onTap,
  });

  final bool useCachedNetworkImage;
  final double? width;
  final double? height;
  final Color? foregroundColor;
  final Widget Function(BuildContext context)? placeholderBuilder;
  // ignore: avoid_dynamic
  final Widget Function(BuildContext context, dynamic error)? errorBuilder;
  final Widget Function(BuildContext context)? loadingBuilder;
  final BoxFit? fit;
  final Alignment? alignment;
  final ImageRepeat? repeat;
  final FilterQuality? filterQuality;
  final bool? matchTextDirection;
  final BlendMode? colorBlendMode;
  final String? cacheKey;
  final ProgressIndicatorBuilder? progressIndicatorBuilder;
  final Duration? placeholderFadeInDuration;
  final Duration? fadeOutDuration;
  final Curve? fadeOutCurve;
  final Duration? fadeInDuration;
  final Curve? fadeInCurve;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final int? maxWidthDiskCache;
  final int? maxHeightDiskCache;
  final ImageWidgetBuilder? imageBuilder;
  final Map<String, String>? httpHeaders;
  final bool? useOldImageOnUrlChange;
  final ImageRenderMethodForWeb? imageRenderMethodForWeb;
  final BaseCacheManager? cacheManager;
}

Widget _showProgressIndicator(_CommonNetworkImageStyle _style) {
  return SizedBox(
    width: _style.width,
    height: _style.height,
    child: const Center(
      child: SizedBox(
        width: 20,
        height: 20,
        child: CommonProgressIndicator(),
      ),
    ),
  );
}

class _RetryNetworkImage extends HookConsumerWidget {
  const _RetryNetworkImage({
    required this.imageUrl,
    this.width,
    this.height,
    this.fit,
    this.alignment,
    this.color,
    this.errorBuilder,
    this.loadingBuilder,
    this.headers,
    this.repeat,
    this.filterQuality,
    this.matchTextDirection,
    this.colorBlendMode,
    this.cacheWidth,
  });

  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Alignment? alignment;
  final Color? color;
  final Widget Function(BuildContext context, Object error, StackTrace? stackTrace)? errorBuilder;
  final Widget Function(BuildContext context, Widget child, ImageChunkEvent? loadingProgress)?
      loadingBuilder;
  final Map<String, String>? headers;
  final ImageRepeat? repeat;
  final FilterQuality? filterQuality;
  final bool? matchTextDirection;
  final BlendMode? colorBlendMode;
  final int? cacheWidth;

  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 1);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use hooks to manage state
    final retryCount = useState(0);
    final imageKey = useState(UniqueKey());

    // Function to handle retry logic
    void retryLoading() {
      if (retryCount.value < maxRetries) {
        retryCount.value++;
        imageKey.value = UniqueKey(); // Force reload by changing the key
      }
    }

    // ignore: prefer_common_widgets
    return Image.network(
      imageUrl,
      key: imageKey.value,
      width: width,
      height: height,
      color: color,
      headers: headers,
      repeat: repeat ?? ImageRepeat.noRepeat,
      filterQuality: filterQuality ?? FilterQuality.low,
      matchTextDirection: matchTextDirection ?? false,
      colorBlendMode: colorBlendMode,
      cacheWidth: cacheWidth,
      fit: fit,
      alignment: alignment ?? Alignment.center,
      loadingBuilder: loadingBuilder,
      errorBuilder: (context, error, stackTrace) {
        if (retryCount.value < maxRetries) {
          // Schedule a retry after a short delay to avoid immediate reload loops
          Future.delayed(retryDelay, () {
            if (context.mounted) retryLoading();
          });
          return SizedBox(width: width, height: height);
        } else {
          return errorBuilder != null
              ? errorBuilder!(context, error, stackTrace)
              : SizedBox(width: width, height: height);
        }
      },
    );
  }
}
