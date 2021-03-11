/*
 * Copyright (C) 2019-present Alibaba Inc. All rights reserved.
 * Author: Kraken Team.
 */

import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:kraken/dom.dart';
import 'package:kraken/css.dart';
import 'package:kraken/rendering.dart';
import 'package:kraken/bridge.dart';
import 'dart:ffi';
import 'dart:collection';

const String IMAGE = 'IMG';

const Map<String, dynamic> _defaultStyle = {DISPLAY: INLINE_BLOCK};

bool _isNumber(String str) {
  RegExp regExp = RegExp(r"^\d+");
  return regExp.hasMatch(str);
}

final Pointer<NativeFunction<GetImageWidth>> nativeGetImageWidth =  Pointer.fromFunction(ImageElement.getImageWidth, 0.0);
final Pointer<NativeFunction<GetImageHeight>> nativeGetImageHeight =  Pointer.fromFunction(ImageElement.getImageHeight, 0.0);
final Pointer<NativeFunction<GetImageWidth>> nativeGetImageNaturalWidth =  Pointer.fromFunction(ImageElement.getImageNaturalWidth, 0.0);
final Pointer<NativeFunction<GetImageHeight>> nativeGetImageNaturalHeight =  Pointer.fromFunction(ImageElement.getImageNaturalHeight, 0.0);

class ImageElement extends Element {
  String _source;
  ImageProvider _image;
  RenderImage _imageBox;
  ImageStream _imageStream;
  ImageInfo _imageInfo;
  double _propertyWidth;
  double _propertyHeight;
  ImageStreamListener _initImageListener;
  ImageStreamListener _renderStreamListener;

  /// Number of image frame, used to identify gif after image loaded
  int _frameNumber = 0;

  bool _hasLazyLoading = false;

  static SplayTreeMap<int, ImageElement> _nativeMap = SplayTreeMap();

  static Element getImageElementOfNativePtr(Pointer<NativeImgElement> nativeImageElement) {
    ImageElement element = _nativeMap[nativeImageElement.address];
    assert(element != null, 'Can not get element from nativeElement: $nativeImageElement');
    return element;
  }

  // imgEl.width -> imgEl.getAttribute('width');
  static double getImageWidth(Pointer<NativeImgElement> nativeImageElement) {
    ImageElement imageElement = getImageElementOfNativePtr(nativeImageElement);
    return imageElement.getProperty(WIDTH);
  }

  static double getImageHeight(Pointer<NativeImgElement> nativeImageElement) {
    ImageElement imageElement = getImageElementOfNativePtr(nativeImageElement);
    return imageElement.getProperty(HEIGHT);
  }

  // https://developer.mozilla.org/en-US/docs/Web/API/HTMLImageElement/naturalWidth
  static double getImageNaturalWidth(Pointer<NativeImgElement> nativeImageElement) {
    ImageElement imageElement = getImageElementOfNativePtr(nativeImageElement);
    return imageElement.naturalWidth;
  }

  static double getImageNaturalHeight(Pointer<NativeImgElement> nativeImageElement) {
    ImageElement imageElement = getImageElementOfNativePtr(nativeImageElement);
    return imageElement.naturalHeight;
  }

  final Pointer<NativeImgElement> nativeImgElement;

  ImageElement(int targetId, this.nativeImgElement, ElementManager elementManager)
      : super(
        targetId,
        nativeImgElement.ref.nativeElement,
        elementManager,
        defaultStyle: _defaultStyle,
        isIntrinsicBox: true,
        tagName: IMAGE) {
    _renderStreamListener = ImageStreamListener(_renderMultiFrameImage);
    _nativeMap[nativeImgElement.address] = this;

    nativeImgElement.ref.getImageWidth = nativeGetImageWidth;
    nativeImgElement.ref.getImageHeight = nativeGetImageHeight;
    nativeImgElement.ref.getImageNaturalWidth = nativeGetImageNaturalWidth;
    nativeImgElement.ref.getImageNaturalHeight = nativeGetImageNaturalHeight;
  }

  @override
  void willAttachRenderer() {
    super.willAttachRenderer();
    style.addStyleChangeListener(_stylePropertyChanged);
    _renderImage();
  }

  @override
  void didAttachRenderer() {
    super.didAttachRenderer();
    _resize();
  }

  @override
  void didDetachRenderer() {
    super.didDetachRenderer();
    style.removeStyleChangeListener(_stylePropertyChanged);
  }

  @override
  void dispose() {
    super.dispose();
    _removeStreamListener();
    _image = null;
    _imageBox = null;
    _imageStream = null;
    _nativeMap.remove(nativeImgElement.address);
  }

  double get naturalWidth {
    if (_imageInfo != null && _imageInfo.image != null) {
      return _imageInfo.image.width.toDouble();
    }
    return 0.0;
  }

  double get naturalHeight {
    if (_imageInfo != null && _imageInfo.image != null) {
      return _imageInfo.image.height.toDouble();
    }
    return 0.0;
  }

  void _renderImage() {
    if (_hasLazyLoading) return;
    String loading = properties['loading'];
    // Image dimensions(width/height) should specified for performance when lazy-load.
    if (loading == 'lazy') {
      _hasLazyLoading = true;
      renderBoxModel.addIntersectionChangeListener(_handleIntersectionChange);
    } else {
      _constructImageChild();
    }
  }

  void _handleIntersectionChange(IntersectionObserverEntry entry) {
    // When appear
    if (entry.isIntersecting) {
      // Once appear remove the listener
      _resetLazyLoading();
    }
    _constructImageChild();
  }

  void _resetLazyLoading() {
    _hasLazyLoading = false;
    renderBoxModel.removeIntersectionChangeListener(_handleIntersectionChange);
  }

  void _removeImage() {
    _removeStreamListener();
    _image = null;
    _imageBox.image = null;
  }

  void _constructImageChild() {
    _imageBox = createRenderImageBox();

    if (childNodes.isEmpty) {
      addChild(_imageBox);
    }
  }

  void _handleEventAfterImageLoaded() {
    // `load` event is a simple event.
    dispatchEvent(Event(EVENT_LOAD));
  }

  void _initImageInfo(ImageInfo imageInfo, bool synchronousCall) {
    _imageInfo = imageInfo;

    // Image load event should trigger asynchronously to make sure load event had bind.
    // Alos make sure the image-box has been layout.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _handleEventAfterImageLoaded();
    });

    if (_initImageListener != null) {
      _imageStream?.removeListener(_initImageListener);
    }
  }

  void _renderMultiFrameImage(ImageInfo imageInfo, bool synchronousCall) {
    _frameNumber++;
    _imageInfo = imageInfo;
    _imageBox?.image = _imageInfo?.image;
    // @HACK Flutter image cache will cause image steam listener to trigger twice when page reload
    // so use two frames to tell multiframe image from static image, note this optimization will fail
    // at multiframe image with only two frames which is not common
    if (_frameNumber > 2) {
      _convertToRepaint();
    } else {
      _convertToNonRepaint();
    }
    _resize();
  }

  /// Convert RenderIntrinsic to non repaint boundary
  void _convertToNonRepaint() {
    if (renderBoxModel != null && renderBoxModel.isRepaintBoundary) {
      _toggleRepaintSelf(repaintSelf: false);
    }
  }

  /// Convert RenderIntrinsic to repaint boundary
  void _convertToRepaint() {
    if (renderBoxModel != null && !renderBoxModel.isRepaintBoundary) {
      _toggleRepaintSelf(repaintSelf: true);
    }
  }

  /// Toggle renderBoxModel between repaint boundary and non repaint boundary
  void _toggleRepaintSelf({bool repaintSelf}) {
    RenderObject parent = renderBoxModel.parent;
    RenderBoxModel targetRenderBox = createRenderBoxModel(this, prevRenderBoxModel: renderBoxModel, repaintSelf: repaintSelf);
    if (parent is ContainerRenderObjectMixin) {
      RenderObject previousSibling = (renderBoxModel.parentData as ContainerParentDataMixin).previousSibling;
      parent.remove(renderBoxModel);
      renderBoxModel = targetRenderBox;
      this.parent.addChildRenderObject(this, after: previousSibling);
    } else if (parent is RenderObjectWithChildMixin) {
      parent.child = targetRenderBox;
    }
    renderBoxModel = targetRenderBox;
    // Update renderBoxModel reference in renderStyle
    renderBoxModel.renderStyle.renderBoxModel = targetRenderBox;
  }

  void _resize() {
    if (isRendererAttached) {
      double width = 0.0;
      double height = 0.0;
      bool containWidth = style.contains(WIDTH) || _propertyWidth != null;
      bool containHeight = style.contains(HEIGHT) || _propertyHeight != null;
      RenderStyle renderStyle = renderBoxModel.renderStyle;
      if (!containWidth && !containHeight) {
        width = naturalWidth;
        height = naturalHeight;
      } else {
        if (containWidth && containHeight) {
          width = renderStyle.width ?? _propertyWidth;
          height = renderStyle.height ?? _propertyHeight;
        } else if (containWidth) {
          width = renderStyle.width ?? _propertyWidth;
          if (naturalWidth != 0) {
            height = width * naturalHeight / naturalWidth;
          }
        } else if (containHeight) {
          height = renderStyle.height ?? _propertyHeight;
          if (naturalHeight != 0) {
            width = height * naturalWidth / naturalHeight;
          }
        }
      }

      if (height == null || !height.isFinite) {
        height = 0.0;
      }
      if (width == null || !width.isFinite) {
        width = 0.0;
      }

      _imageBox?.width = width;
      _imageBox?.height = height;
      renderBoxModel.intrinsicWidth = naturalWidth;
      renderBoxModel.intrinsicHeight = naturalHeight;

      if (naturalWidth == 0.0 || naturalHeight == 0.0) {
        renderBoxModel.intrinsicRatio = null;
      } else {
        renderBoxModel.intrinsicRatio = naturalHeight / naturalWidth;
      }
    }
  }

  void _removeStreamListener() {
    _imageStream?.removeListener(_renderStreamListener);

    if (_initImageListener != null) {
      _imageStream?.removeListener(_initImageListener);
    }
    _imageStream = null;
  }

  BoxFit _getBoxFit(String fit) {
    switch (fit) {
      case 'contain':
        return BoxFit.contain;

      case 'cover':
        return BoxFit.cover;

      case 'none':
        return BoxFit.none;

      case 'scaleDown':
      case 'scale-down':
        return BoxFit.scaleDown;

      case 'fitWidth':
      case 'fit-width':
        return BoxFit.fitWidth;

      case 'fitHeight':
      case 'fit-height':
        return BoxFit.fitHeight;

      case 'fill':
      default:
        return BoxFit.fill;
    }
  }

  Alignment _getAlignment(String position) {
    // Syntax: object-position: <position>
    // position: From one to four values that define the 2D position of the element. Relative or absolute offsets can be used.
    // <position> = [ [ left | center | right ] || [ top | center | bottom ] | [ left | center | right | <length-percentage> ] [ top | center | bottom | <length-percentage> ]? | [ [ left | right ] <length-percentage> ] && [ [ top | bottom ] <length-percentage> ] ]

    if (position != null) {
      List<String> values = CSSStyleProperty.getPositionValues(position);
      return Alignment(_getAlignmentValueFromString(values[0]), _getAlignmentValueFromString(values[1]));
    }

    // The default value for object-position is 50% 50%
    return Alignment.center;
  }

  static double _getAlignmentValueFromString(String value) {
    assert(value != null);

    // Support percentage
    if (value.endsWith('%')) {
      // 0% equal to -1.0
      // 50% equal to 0.0
      // 100% equal to 1.0
      return double.tryParse(value.substring(0, value.length - 1)) / 50 - 1;
    }

    switch (value) {
      case 'top':
      case 'left':
        return -1;

      case 'bottom':
      case 'right':
        return 1;

      case 'center':
      default:
        return 0;
    }
  }

  RenderImage createRenderImageBox() {
    BoxFit fit = _getBoxFit(style[OBJECT_FIT]);
    Alignment alignment = _getAlignment(style[OBJECT_POSITION]);
    return RenderImage(
      image: _imageInfo?.image,
      fit: fit,
      alignment: alignment,
    );
  }

  @override
  void removeProperty(String key) {
    super.removeProperty(key);
    if (key == 'src') {
      _removeImage();
    } else if (key == 'loading' && _hasLazyLoading && _image == null) {
      _resetLazyLoading();
    }
  }

  @override
  void setProperty(String key, dynamic value) {
    super.setProperty(key, value);
    double viewportWidth = elementManager.viewportWidth;
    double viewportHeight = elementManager.viewportHeight;
    Size viewportSize = Size(viewportWidth, viewportHeight);

    // Reset frame number to zero when image needs to reload
    _frameNumber = 0;
    if (key == 'src') {
      _setImage(value);
    } else if (key == 'loading' && _hasLazyLoading) {
      // Should reset lazy when value change.
      _resetLazyLoading();
    } else if (key == WIDTH) {
      if (value is String && _isNumber(value)) {
        value += 'px';
      }

      _propertyWidth = CSSLength.toDisplayPortValue(value, viewportSize);
      _resize();
    } else if (key == HEIGHT) {
      if (value is String && _isNumber(value)) {
        value += 'px';
      }

      _propertyHeight = CSSLength.toDisplayPortValue(value, viewportSize);
      _resize();
    }
  }

  void _setImage(String source) {
    if (_source == null || _source != source) {
      _source = source;
      if (source != null && source.isNotEmpty) {
        _removeStreamListener();
        _image = CSSUrl.parseUrl(source, cache: properties['caching']);
        _imageStream = _image.resolve(ImageConfiguration.empty);
        _imageStream.addListener(_renderStreamListener);

        _initImageListener = ImageStreamListener(_initImageInfo);
        _imageStream.addListener(_initImageListener);
      }
    }
  }

  @override
  dynamic getProperty(String key) {
    switch (key) {
      case WIDTH:
        if (_imageBox != null) {
          return _imageBox.width;
        }
        return 0;
      case HEIGHT:
        if (_imageBox != null) {
          return _imageBox.height;
        }
        return 0;
    }

    return super.getProperty(key);
  }

  void _stylePropertyChanged(String property, String original, String present, bool inAnimation) {
    if (property == WIDTH || property == HEIGHT) {
      _resize();
    } else if (property == OBJECT_FIT) {
      _imageBox.fit = _getBoxFit(present);
    } else if (property == OBJECT_POSITION) {
      _imageBox.alignment = _getAlignment(present);
    }
  }
}
