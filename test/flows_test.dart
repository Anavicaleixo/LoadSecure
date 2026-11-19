import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loadsecure/main.dart';
import 'package:loadsecure/api.dart';

class FakeApi extends Api {
  bool loggedIn = false;
  Map<String, dynamic> user = {
    'id': 'user1',
    'name': 'Lucas',
    'email': 'lucas@empresa.com',
    'phone': '11999999999',
    'role': 'admin',
    'companyId': 'empresa1',
    'companyName': 'MoviCarga',
    'joinCode': 'CODIGO123',
  };
  final Map<String, Map<String, dynamic>> records = {};
  FakeApi() {
    records['cargos:cargo1'] = {
      'kind': 'cargos',
      'id': 'cargo1',
      'revision': 1,
      'data': {
        'name': 'Monitores LED 27',
        'category': 'Eletrônicos',
        'fragility': 'Alta',
        'package': 'Caixa',
        'risk': 'Alto',
        'note': 'Manusear com cuidado.',
        '_id': 'cargo1',
      },
    };
  }
  @override
  Future<Map<String, dynamic>> call(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? data,
  }) async {
    if (path == 'me' && !loggedIn) throw ApiError('Entre na conta', 401);
    if (path == 'login' || path == 'register') {
      loggedIn = true;
      return {'user': user};
    }
    if (path == 'logout') {
      loggedIn = false;
      return {'ok': true};
    }
    if (path == 'state' && method == 'GET') {
      return {
        'user': user,
        'records': records.values
            .map((v) => jsonDecode(jsonEncode(v)))
            .toList(),
      };
    }
    if (path == 'state') {
      final saved = <Map<String, dynamic>>[];
      for (final c in data!['changes']) {
        final r = {
          'kind': c['kind'],
          'id': c['id'],
          'revision': c['revision'] + 1,
          'data': c['data'],
        };
        records['${c['kind']}:${c['id']}'] = r;
        saved.add(r);
      }
      return {'saved': saved, 'conflicts': []};
    }
    return {'user': user};
  }
}

void main() {
  testWidgets('Company login, saved movement, profile and mobile navigation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(402, 888);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final font = File(
      '/usr/share/fonts/opentype/urw-base35/NimbusSans-Regular.otf',
    );
    if (font.existsSync()) {
      final loader = FontLoader('Arial')
        ..addFont(Future.value(ByteData.sublistView(font.readAsBytesSync())));
      await loader.load();
    }
    final api = FakeApi();
    final capture = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: capture,
        child: LoadSecure(api: api),
      ),
    );
    await tester.runAsync(() async {
      final context = tester.element(find.byType(LoadSecure));
      await precacheImage(const AssetImage('assets/logo.png'), context);
      await precacheImage(const AssetImage('assets/tracker.png'), context);
      final iconFont = File(
        '/workspace/var/flutter-sdk/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
      );
      if (iconFont.existsSync()) {
        final loader = FontLoader('MaterialIcons')
          ..addFont(
            Future.value(ByteData.sublistView(iconFont.readAsBytesSync())),
          );
        await loader.load();
      }
    });
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip('Ir para login'));
    await tester.tap(find.byTooltip('Ir para login'));
    await tester.pumpAndSettle();
    await captureScreen(tester, capture, 'login');
    await tester.enterText(find.byType(TextField).at(0), 'lucas@empresa.com');
    await tester.enterText(find.byType(TextField).at(1), 'senha12345');
    await tester.ensureVisible(find.text('ENTRAR'));
    await tester.tap(find.text('ENTRAR'));
    await tester.pumpAndSettle();
    expect(find.text('Bem-vindo, Lucas!'), findsOneWidget);
    expect(find.text('Visão geral de MoviCarga'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Movimentações').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('+ Nova'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salvar movimentação'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(api.records.values.where((r) => r['kind'] == 'movements').length, 1);
    await tester.tap(find.text('Cargas').last);
    await tester.pumpAndSettle();
    expect(find.text('Monitores LED 27'), findsOneWidget);
    await tester.tap(find.byTooltip('QR Code da carga'));
    await tester.pumpAndSettle();
    expect(find.byType(QrImageView), findsOneWidget);
    await captureScreen(tester, capture, 'qr');
    await tester.tap(find.text('Fechar'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.edit_outlined).first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(1), 'Carga da equipe');
    await tester.ensureVisible(find.text('Salvar').last);
    await tester.tap(find.text('Salvar').last);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(api.records['cargos:cargo1']!['data']['name'], 'Carga da equipe');
    await tester.tap(find.text('Mapas').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rotas'));
    await tester.pumpAndSettle();
    expect(find.text('+ Nova rota'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Perfil').last);
    await tester.pumpAndSettle();
    expect(find.text('Empresa · MoviCarga'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}

Future<void> captureScreen(
  WidgetTester tester,
  GlobalKey key,
  String name,
) async {
  await tester.runAsync(() async {
    final image =
        await (key.currentContext!.findRenderObject()! as RenderRepaintBoundary)
            .toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    Directory('.dart_tool/test-previews').createSync(recursive: true);
    File('.dart_tool/test-previews/$name.png')
        .writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}
