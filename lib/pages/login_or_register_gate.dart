export 'auth/login_page.dart' show LoginPage;
export 'auth/login_page.dart';

// File kecil ini cuma supaya menu_tab.dart tidak perlu import langsung
// dari main.dart (hindari circular import). LoginOrRegisterGate = LoginPage.
import 'auth/login_page.dart';

typedef LoginOrRegisterGate = LoginPage;