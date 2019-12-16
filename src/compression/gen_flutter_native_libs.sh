#!/bin/sh

set -euo pipefail

pushd native_compression

#cargo clean
cargo test

cargo lipo --release --targets=aarch64-apple-ios,x86_64-apple-ios,armv7-apple-ios,armv7s-apple-ios
cargo build --target aarch64-linux-android --release
cargo build --target armv7-linux-androideabi --release
cargo build --target i686-linux-android --release

popd

mkdir flutter_native_compression/android/src/main/jniLibs/ || true
mkdir flutter_native_compression/android/src/main/jniLibs/arm64-v8a/ || true
mkdir flutter_native_compression/android/src/main/jniLibs/armeabi-v7a/ || true
mkdir flutter_native_compression/android/src/main/jniLibs/x86/ || true

cp native_compression/target/universal/release/libdart_native_compression.a flutter_native_compression/ios/
cp native_compression/target/aarch64-linux-android/release/libdart_native_compression.so flutter_native_compression/android/src/main/jniLibs/arm64-v8a/
cp native_compression/target/armv7-linux-androideabi/release/libdart_native_compression.so flutter_native_compression/android/src/main/jniLibs/armeabi-v7a/
cp native_compression/target/i686-linux-android/release/libdart_native_compression.so flutter_native_compression/android/src/main/jniLibs/x86/
