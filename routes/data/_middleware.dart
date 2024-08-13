import 'package:dart_frog/dart_frog.dart';
import 'package:vrrealstatedemo/Firebase.dart';

Handler middleware(Handler handler) {
  return handler.use(fireStoreMiddleware());
}
