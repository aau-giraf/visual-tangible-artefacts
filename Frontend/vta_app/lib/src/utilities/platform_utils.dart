import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:global_configuration/global_configuration.dart';

class PlatformUtils {
  static String getApiUrl() {
    String url;
    if (kIsWeb) {
      url = GlobalConfiguration().appConfig['ApiSettings']['BaseUrl']['Local'];
      print('[PlatformUtils] Using Web API URL: $url');
    } else if (Platform.isAndroid) {
      url = GlobalConfiguration().appConfig['ApiSettings']['BaseUrl']['LocalAndroid'];
      print('[PlatformUtils] Using Android API URL: $url');
    } else {
      url = GlobalConfiguration().appConfig['ApiSettings']['BaseUrl']['Local'];
      print('[PlatformUtils] Using Desktop API URL: $url');
    }
    return url;
  }

  static String getSyncServiceUrl() {
    String url;
    if (kIsWeb) {
      url = GlobalConfiguration().appConfig['ApiSettings']['BaseUrl']['SyncService'];
      print('[PlatformUtils] Using Web SyncService URL: $url');
    } else if (Platform.isAndroid) {
      url = GlobalConfiguration().appConfig['ApiSettings']['BaseUrl']['SyncServiceAndroid'];
      print('[PlatformUtils] Using Android SyncService URL: $url');
    } else {
      url = GlobalConfiguration().appConfig['ApiSettings']['BaseUrl']['SyncService'];
      print('[PlatformUtils] Using Desktop SyncService URL: $url');
    }
    return url;
  }
}