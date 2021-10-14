/*
 * Copyright (C) 2019-present Alibaba Inc. All rights reserved.
 * Author: Kraken Team.
 */
import 'dart:core';
import 'dart:ui';

import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:kraken/rendering.dart';
import 'package:kraken/css.dart';

// CSS Box Model: https://drafts.csswg.org/css-box-4/
// CSS Backgrounds and Borders: https://drafts.csswg.org/css-backgrounds/

/// - background
/// - border
mixin CSSBoxMixin on RenderStyleBase {
  static CSSBackgroundPosition DEFAULT_BACKGROUND_POSITION = CSSBackgroundPosition(percentage: -1);
  static CSSBackgroundSize DEFAULT_BACKGROUND_SIZE = CSSBackgroundSize(fit: BoxFit.none);

  /// Background-clip
  BackgroundBoundary? get backgroundClip => _backgroundClip;
  BackgroundBoundary? _backgroundClip;
  set backgroundClip(BackgroundBoundary? value) {
    if (value == _backgroundClip) return;
    _backgroundClip = value;
    renderBoxModel!.markNeedsPaint();
  }

  /// Background-origin
  BackgroundBoundary? get backgroundOrigin => _backgroundOrigin;
  BackgroundBoundary? _backgroundOrigin;
  set backgroundOrigin(BackgroundBoundary? value) {
    if (value == _backgroundOrigin) return;
    _backgroundOrigin = value;
    renderBoxModel!.markNeedsPaint();
  }

  Color? get backgroundColor => _backgroundColor;
  Color? _backgroundColor;
  set backgroundColor(Color? value) {
    if (value == _backgroundColor) return;
    _backgroundColor = value;
    renderBoxModel!.markNeedsPaint();
  }

  /// Background-image
  CSSBackgroundImage? get backgroundImage => _backgroundImage;
  CSSBackgroundImage? _backgroundImage;
  set backgroundImage(CSSBackgroundImage? value) {
    if (value == _backgroundImage) return;
    _backgroundImage = value;
    renderBoxModel!.markNeedsPaint();
  }

  /// Background-position-x
  CSSBackgroundPosition get backgroundPositionX => _backgroundPositionX ?? DEFAULT_BACKGROUND_POSITION;
  CSSBackgroundPosition? _backgroundPositionX;
  set backgroundPositionX(CSSBackgroundPosition? value) {
    if (value == _backgroundPositionX) return;
    _backgroundPositionX = value;
    renderBoxModel!.markNeedsPaint();
  }

  /// Background-position-y
  CSSBackgroundPosition get backgroundPositionY => _backgroundPositionY ?? DEFAULT_BACKGROUND_POSITION;
  CSSBackgroundPosition? _backgroundPositionY;
  set backgroundPositionY(CSSBackgroundPosition? value) {
    if (value == _backgroundPositionY) return;
    _backgroundPositionY = value;
    renderBoxModel!.markNeedsPaint();
  }

  /// Background-size
  CSSBackgroundSize get backgroundSize => _backgroundSize ?? DEFAULT_BACKGROUND_SIZE;
  CSSBackgroundSize? _backgroundSize;
  set backgroundSize(CSSBackgroundSize? value) {
    if (value == _backgroundSize) return;
    _backgroundSize = value;
    renderBoxModel!.markNeedsPaint();
  }

  /// Background-attachment
  CSSBackgroundAttachmentType? get backgroundAttachment => _backgroundAttachment;
  CSSBackgroundAttachmentType? _backgroundAttachment;
  set backgroundAttachment(CSSBackgroundAttachmentType? value) {
    if (value == _backgroundAttachment) return;
    _backgroundAttachment = value;
    renderBoxModel!.markNeedsPaint();
  }

  /// Background-repeat
  ImageRepeat get backgroundRepeat => _backgroundRepeat ?? ImageRepeat.repeat;
  ImageRepeat? _backgroundRepeat;
  set backgroundRepeat(ImageRepeat? value) {
    if (value == _backgroundRepeat) return;
    _backgroundRepeat = value;
    renderBoxModel!.markNeedsPaint();
  }

  CSSBorderRadius? _borderTopLeftRadius;
  set borderTopLeftRadius(CSSBorderRadius? value) {
    if (value == _borderTopLeftRadius) return;
    _borderTopLeftRadius = value;
    renderBoxModel!.markNeedsPaint();
  }
  CSSBorderRadius get borderTopLeftRadius => _borderTopLeftRadius ?? CSSBorderRadius.zero;

  CSSBorderRadius? _borderTopRightRadius;
  set borderTopRightRadius(CSSBorderRadius? value) {
    if (value == _borderTopRightRadius) return;
    _borderTopRightRadius = value;
    renderBoxModel!.markNeedsPaint();
  }
  CSSBorderRadius get borderTopRightRadius => _borderTopRightRadius ?? CSSBorderRadius.zero;

  CSSBorderRadius? _borderBottomRightRadius;
  set borderBottomRightRadius(CSSBorderRadius? value) {
    if (value == _borderBottomRightRadius) return;
    _borderBottomRightRadius = value;
    renderBoxModel!.markNeedsPaint();
  }
  CSSBorderRadius get borderBottomRightRadius => _borderBottomRightRadius ?? CSSBorderRadius.zero;

  CSSBorderRadius? _borderBottomLeftRadius;
  set borderBottomLeftRadius(CSSBorderRadius? value) {
    if (value == _borderBottomLeftRadius) return;
    _borderBottomLeftRadius = value;
    renderBoxModel!.markNeedsPaint();
  }
  CSSBorderRadius get borderBottomLeftRadius => _borderBottomLeftRadius ?? CSSBorderRadius.zero;

  List<CSSBoxShadow>? _boxShadow;
  set boxShadow(List<CSSBoxShadow>? value) {
    if (value == _boxShadow) return;
    _boxShadow = value;
    renderBoxModel!.markNeedsPaint();
  }
  List<CSSBoxShadow>? get boxShadow => _boxShadow;

  /// What decoration to paint, should get value after layout.
  CSSBoxDecoration? get decoration {
    List<Radius>? radius = _getBorderRadius();
    List<BorderSide>? borderSides = _getBorderSides();
    List<KrakenBoxShadow>? boxShadow = _getBoxShadow();
 
    if (backgroundColor == null &&
        backgroundImage == null &&
        borderSides == null &&
        radius == null &&
        boxShadow == null) {
      return null;
    }

    Border? border;
    if (borderSides != null) {
      // Side read inorder left top right bottom.
      border = Border(left: borderSides[0], top: borderSides[1], right: borderSides[2], bottom: borderSides[3]);
    }

    BorderRadius? borderRadius;
    // Flutter border radius only works when border is uniform.
    if (radius != null && (border == null || border.isUniform)) {
      borderRadius = BorderRadius.only(
        topLeft: radius[0],
        topRight: radius[1],
        bottomRight: radius[2],
        bottomLeft: radius[3],
      );
    }

    Gradient? gradient = backgroundImage?.gradient;
    if (gradient is BorderGradientMixin && border != null) {
      gradient.borderEdge = border.dimensions as EdgeInsets;
    }

    return CSSBoxDecoration(
      boxShadow: boxShadow,
      color: gradient != null ? null : backgroundColor, // FIXME: chrome will work with gradient and color.
      image: decorationImage,
      border: border,
      borderRadius: borderRadius,
      gradient: gradient,
    );
  }

  DecorationImage? get decorationImage {
    ImageProvider? image = backgroundImage?.image;
    if (image!= null) {
      return DecorationImage(
        image: image,
        repeat: backgroundRepeat,
      );
    }
  }

  DecorationPosition decorationPosition = DecorationPosition.background;
  ImageConfiguration imageConfiguration = ImageConfiguration.empty;

  List<BorderSide>? _getBorderSides() {
    RenderStyle renderStyle = this as RenderStyle;
    BorderSide? leftSide = CSSBorderSide.getBorderSide(renderStyle, CSSBorderSide.LEFT);
    BorderSide? topSide = CSSBorderSide.getBorderSide(renderStyle, CSSBorderSide.TOP);
    BorderSide? rightSide = CSSBorderSide.getBorderSide(renderStyle, CSSBorderSide.RIGHT);
    BorderSide? bottomSide = CSSBorderSide.getBorderSide(renderStyle, CSSBorderSide.BOTTOM);

    bool hasBorder = leftSide != null ||
        topSide != null ||
        rightSide != null ||
        bottomSide != null;

    return hasBorder ? [
      leftSide ?? CSSBorderSide.none,
      topSide ?? CSSBorderSide.none,
      rightSide ?? CSSBorderSide.none,
      bottomSide ?? CSSBorderSide.none] : null;
  }

  List<Radius>? _getBorderRadius() {
    RenderStyle renderStyle = this as RenderStyle;
    // border radius add border topLeft topRight bottomLeft bottomRight
    CSSBorderRadius? topLeftRadius = renderStyle.borderTopLeftRadius;
    CSSBorderRadius? topRightRadius = renderStyle.borderTopRightRadius;
    CSSBorderRadius? bottomRightRadius = renderStyle.borderBottomRightRadius;
    CSSBorderRadius? bottomLeftRadius = renderStyle.borderBottomLeftRadius;

    bool hasBorderRadius = topLeftRadius != CSSBorderRadius.zero ||
        topRightRadius != CSSBorderRadius.zero ||
        bottomRightRadius != CSSBorderRadius.zero ||
        bottomLeftRadius != CSSBorderRadius.zero;

    return hasBorderRadius ? [
      topLeftRadius.computedRadius,
      topRightRadius.computedRadius,
      bottomRightRadius.computedRadius,
      bottomLeftRadius.computedRadius
    ] : null;
  }

  List<KrakenBoxShadow>? _getBoxShadow() {
    if (boxShadow == null) {
      return null;
    }
    List<KrakenBoxShadow> result = [];
    for (CSSBoxShadow shadow in boxShadow!) {
      result.add(shadow.computedBoxShdow);
    }
    return result;
  }
}

class CSSBoxDecoration extends BoxDecoration {
  CSSBoxDecoration({
    this.color,
    this.image,
    this.border,
    this.borderRadius,
    this.boxShadow,
    this.gradient,
    this.backgroundBlendMode,
    this.shape = BoxShape.rectangle,
  }): super(color: color, image: image, border: border, borderRadius: borderRadius,
    gradient: gradient, backgroundBlendMode: backgroundBlendMode, shape: shape);

  @override
  final Color? color;

  @override
  final DecorationImage? image;

  @override
  final BoxBorder? border;

  @override
  final BorderRadiusGeometry? borderRadius;

  @override
  final List<KrakenBoxShadow>? boxShadow;

  @override
  final Gradient? gradient;

  @override
  final BlendMode? backgroundBlendMode;

  @override
  final BoxShape shape;

  CSSBoxDecoration clone({
    Color? color,
    DecorationImage? image,
    BoxBorder? border,
    BorderRadiusGeometry? borderRadius,
    List<KrakenBoxShadow>? boxShadow,
    Gradient? gradient,
    BlendMode? backgroundBlendMode,
    BoxShape? shape,
  }) {
    return CSSBoxDecoration(
      color: color ?? this.color,
      image: image ?? this.image,
      border: border ?? this.border,
      borderRadius: borderRadius ?? this.borderRadius,
      boxShadow: boxShadow ?? this.boxShadow,
      gradient: gradient ?? this.gradient,
      backgroundBlendMode: backgroundBlendMode ?? this.backgroundBlendMode,
      shape: shape ?? this.shape,
    );
  }
}

