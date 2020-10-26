/*
 * Copyright (C) 2019 Alibaba Inc. All rights reserved.
 * Author: Kraken Team.
 */

#include "screen.h"
#include "bindings/jsc/macros.h"
#include "dart_methods.h"

namespace kraken::binding::jsc {

JSValueRef JSScreen::getProperty(JSStringRef nameRef, JSValueRef *exception) {
  std::string name = JSStringToStdString(nameRef);

  if (getDartMethod()->getScreen == nullptr) {
    JSC_THROW_ERROR(context->context(), "Failed to read screen: dart method (getScreen) is not registered.", exception);
    return nullptr;
  }

  Screen *screen = getDartMethod()->getScreen(context->getContextId());

  if (name == "width" || name == "availWidth") {
    return JSValueMakeNumber(context->context(), screen->width);
  } else if (name == "height" || name == "availHeight") {
    return JSValueMakeNumber(context->context(), screen->height);
  }

  return nullptr;
}

void JSScreen::getPropertyNames(JSPropertyNameAccumulatorRef accumulator) {
  for (auto &propertyName : propertyNames) {
    JSPropertyNameAccumulatorAddName(accumulator, propertyName);
  }
}

JSScreen::~JSScreen() {
  for (auto &propertyName : propertyNames) {
    JSStringRelease(propertyName);
  }
}

void bindScreen(std::unique_ptr<JSContext> &context) {
  auto screen = new JSScreen(context.get());
  //  JSC_GLOBAL_BINDING_HOST_OBJECT(context, "screen", screen);
  JSObjectRef object = screen->object;
  JSStringRef name = JSStringCreateWithUTF8CString("screen");
  JSObjectSetProperty(context->context(), context->global(), name, object, kJSPropertyAttributeReadOnly, nullptr);
}

} // namespace kraken::binding::jsc
