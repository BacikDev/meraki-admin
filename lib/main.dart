import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://igronjvbphfftsqqhsiy.supabase.co',
    anonKey: 'sb_publishable_bJ8jk_-xQV3WrXqA14hxmQ_V1eB-jGr',
  );

  runApp(const MerakiAdminApp());
}