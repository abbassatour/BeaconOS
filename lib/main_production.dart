import 'package:beacon_os/app/app.dart';
import 'package:beacon_os/bootstrap.dart';

Future<void> main() async {
  await bootstrap(() => const App());
}
