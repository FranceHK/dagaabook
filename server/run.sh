#!/bin/bash
cd "$(dirname "$0")"
dart pub get
dart run bin/server.dart
