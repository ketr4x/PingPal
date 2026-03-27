import 'package:flutter/foundation.dart';

void printDebug(String text) {
  if (kDebugMode) {
    print(text);
  }
}