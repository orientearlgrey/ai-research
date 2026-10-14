import 'package:flutter/material.dart';

import 'app/experiment_app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(ExperimentApp(uri: Uri.base));
}
