import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'injection.config.dart';

final GetIt sl = GetIt.instance;

/// Initialize all app dependencies using Injectable code generation
@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: true,
  asExtension: true,
)
Future<void> configureDependencies() async => sl.init();
