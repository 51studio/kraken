![kraken Post](https://user-images.githubusercontent.com/677114/101163298-6264ae80-366e-11eb-9151-f560d18c2ceb.png)

# Kraken [![pub package](https://img.shields.io/pub/v/kraken.svg)](https://pub.dev/packages/kraken)

## 💁 Have a try

1. Install Kraken CLI

    ```shell
    $ npm i @kraken-project/cli -g
    ```

2. Open with kraken

    ```shell
    # kraken [localfile|URL]
    $ kraken https://raw.githubusercontent.com/openkraken/kraken/master/kraken/example/assets/bundle.js
    ```

## 💌 Why kraken

* Quick development 🎉

  Compatibility with web standards means you don't have to change your stack.
  ```js
  const text = document.createTextNode('Hello World!');
  document.body.appendChild(text);
  ```

* Cross platform ⚛️

  [Seamless integration with Flutter](https://pub.dev/packages/kraken), supports web, mobile (iOS, Android) and desktop (MacOS, Linux, Windows).

* Fast performance 🚀

  Provide native-like performance such as navigation, animation and infinite list scrolling.

## 👏 Contributing

By contributing to Kraken, you agree that your contributions will be licensed under its Apache-2.0 License.

0. Prerequisites
    * [Node.js](https://nodejs.org/) v12.0 or later
    * [Flutter](https://flutter.dev/docs/get-started/install) v1.17.0 or later 
    * [CMake](https://cmake.org/)

1. Install
    ```shell
    $ npm install
    ```

2. Build
    ```shell
    $ npm run build:macos
    $ npm run build:android
    $ npm run build:linux
    ```

3. Test (Unit Test and Integration Test)
    ```shell
    $ npm test
    ```

4. Pack vendors and upload to OSS
    ```shell
    $ npm run upload # Set OSS_AK and OSS_SK for env first
    ```
