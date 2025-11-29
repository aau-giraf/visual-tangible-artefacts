import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:global_configuration/global_configuration.dart';

class PlatformUtils {
  static String getApiUrl() {
    if (kIsWeb) {
      return GlobalConfiguration().appConfig['ApiSettings']['BaseUrl']['Local'];
    } else if (Platform.isAndroid) {
      return GlobalConfiguration().appConfig['ApiSettings']['BaseUrl']['LocalAndroid'];
    } else {
      return GlobalConfiguration().appConfig['ApiSettings']['BaseUrl']['Local'];
    }
  }

  static String getSyncServiceUrl() {
    if (kIsWeb) {
      return GlobalConfiguration().appConfig['ApiSettings']['BaseUrl']['SyncService'];
    } else if (Platform.isAndroid) {
      return GlobalConfiguration().appConfig['ApiSettings']['BaseUrl']['SyncServiceAndroid'];
    } else {
      return GlobalConfiguration().appConfig['ApiSettings']['BaseUrl']['SyncService'];
    }
  }
}