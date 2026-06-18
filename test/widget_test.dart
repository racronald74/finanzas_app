import 'package:finanzas_app/data/services/password_hasher.dart';
import 'package:finanzas_app/data/models/income_model.dart';
import 'package:finanzas_app/main.dart';
import 'package:finanzas_app/providers/auth_provider.dart';
import 'package:finanzas_app/providers/income_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  test('PasswordHasher stores a hash and verifies the original password', () {
    const password = 'contrasena-segura';

    final hash = PasswordHasher.hash(password);

    expect(hash, isNot(password));
    expect(hash.startsWith(r'pbkdf2$'), isTrue);
    expect(PasswordHasher.verify(password, hash), isTrue);
    expect(PasswordHasher.verify('otra-contrasena', hash), isFalse);
  });

  test('IncomeModel does not send null default columns to SQLite', () {
    final income = IncomeModel(
      descripcion: '',
      monto: 500000,
      fecha: DateTime(2026, 6, 18).toIso8601String(),
      tipo: 'ADICIONAL',
      idCategoria: 2,
      idUsuario: 1,
    );

    final map = income.toMap();

    expect(map.containsKey('fecha_registro'), isFalse);
    expect(map.containsKey('id_ingreso'), isFalse);
    expect(map['monto'], 500000);
  });

  testWidgets('App starts on the login screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => IncomeProvider()),
        ],
        child: const MyApp(),
      ),
    );

    expect(find.text('Iniciar sesion'), findsWidgets);
    expect(find.text('Correo'), findsOneWidget);
    expect(find.text('Contrasena'), findsOneWidget);
    expect(find.text('No tienes cuenta? Registrate'), findsOneWidget);
  });
}
