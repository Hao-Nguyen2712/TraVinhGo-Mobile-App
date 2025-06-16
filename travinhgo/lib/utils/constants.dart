import 'package:flutter/material.dart';
import 'env_config.dart';

const kcontentColor = Color(0xffF5F5F5);
const kprimaryColor = Color(0xff158247);

// Using environment variables with fallback
String get Base_api => "${EnvConfig.apiBaseUrl}/";
