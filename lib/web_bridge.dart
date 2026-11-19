import 'dart:js_interop';
import 'dart:js_interop_unsafe';

void bindNavigation(bool Function(String) navigate) {
  globalContext.setProperty(
    'loadSecureNavigate'.toJS,
    ((JSString route) {
      return navigate(route.toDart).toJS;
    }).toJS,
  );
}
