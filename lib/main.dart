import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'mobile_stub.dart' if (dart.library.io) 'mobile_app.dart';

import 'api.dart';

import 'web_bridge_stub.dart' if (dart.library.js_interop) 'web_bridge.dart';

void main() => runApp(kIsWeb ? const LoadSecure() : const SiteMobileApp());
const red = Color(0xffff001a);
const panel = Color(0xff151515);
const muted = Color(0xff999999);

class LoadSecure extends StatelessWidget {
  final Api? api;
  const LoadSecure({super.key, this.api});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'LoadSecure',
    debugShowCheckedModeBanner: false,
    theme: ThemeData.dark(useMaterial3: true).copyWith(
      scaffoldBackgroundColor: Colors.black,
      primaryColor: red,
      colorScheme: const ColorScheme.dark(primary: red, surface: panel),
      textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'Arial'),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xff202020),
        isDense: true,
        hintStyle: const TextStyle(color: Color(0xff777777), fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: const BorderSide(color: Color(0xff444444)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: const BorderSide(color: Color(0xff444444)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: red,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
        ),
      ),
    ),
    home: Workspace(api: api),
  );
}

class Workspace extends StatefulWidget {
  final Api? api;
  const Workspace({super.key, this.api});
  @override
  State<Workspace> createState() => _WorkspaceState();
}

class _WorkspaceState extends State<Workspace> {
  String page = 'Apresentação',
      filter = 'Todos',
      mapTab = 'Mapa',
      scanTab = 'QR Code';
  bool menu = false,
      signup = false,
      terms = false,
      hidePassword = true,
      flashlight = false;
  String search = '', name = 'Manuela', email = 'manuvitorio@gmail.com';
  final loginEmail = TextEditingController(),
      password = TextEditingController();
  final registrationName = TextEditingController();
  final List<Map<String, String>> movements = [
    {
      'code': 'MOV-2026-10000',
      'route': 'Almoxarifado → Linha A',
      'equipment': 'Empilhadeira',
      'operator': 'Carlos Souza',
      'cargo': 'Eletrônicos',
      'status': 'Concluída',
      'date': '27/08/2026, 21:42',
      'impacts': '2',
    },
    {
      'code': 'MOV-2026-10001',
      'route': 'Recebimento → Estoque',
      'equipment': 'Transpaleteira',
      'operator': 'Marcos Silva',
      'cargo': 'Peças automotivas',
      'status': 'Concluída',
      'date': '27/08/2026, 15:44',
      'impacts': '2',
    },
    {
      'code': 'MOV-2026-10002',
      'route': 'Estoque → Expedição',
      'equipment': 'Carrinho manual',
      'operator': 'Ana Paula Ribeiro',
      'cargo': 'Vidros',
      'status': 'Com problema',
      'date': '27/08/2026, 01:11',
      'impacts': '3',
    },
    {
      'code': 'MOV-2026-10003',
      'route': 'Produção → QA',
      'equipment': 'Ponte rolante',
      'operator': 'João Pereira',
      'cargo': 'Produtos químicos',
      'status': 'Em andamento',
      'date': '27/08/2026, 02:11',
      'impacts': '0',
    },
    {
      'code': 'MOV-2026-10004',
      'route': 'Dock → Galpão B',
      'equipment': 'AGV',
      'operator': 'Fernanda Costa',
      'cargo': 'Alimentos',
      'status': 'Concluída',
      'date': '26/08/2026, 20:20',
      'impacts': '1',
    },
  ];
  final List<Map<String, String>> cargos = [
    {
      'name': 'Monitores LED 27',
      'category': 'Eletrônicos',
      'fragility': 'Alta',
      'package': 'Caixa',
      'risk': 'Alto',
      'note': 'Manuseio com cuidado, evitar queda e vibração excessiva',
    },
    {
      'name': 'Vidros temperados',
      'category': 'Vidros',
      'fragility': 'Alta',
      'package': 'Pallet',
      'risk': 'Alto',
      'note': 'Produto frágil, transporte com cuidado',
    },
    {
      'name': 'Bebidas engarrafadas',
      'category': 'Alimentos',
      'fragility': 'Média',
      'package': 'Caixa',
      'risk': 'Médio',
      'note': 'Evitar impactos bruscos e exposição ao sol',
    },
    {
      'name': 'Motor elétrico industrial',
      'category': 'Máquinas',
      'fragility': 'Média',
      'package': 'Pallet',
      'risk': 'Médio',
      'note': 'Proteger contra umidade e impactos laterais',
    },
  ];
  final List<Map<String, String>> impacts = [
    {'g': '9.9', 'level': 'Alto', 'place': 'Corredor Central', 'time': '21:32'},
    {'g': '5.7', 'level': 'Médio', 'place': 'Rampa Expedição', 'time': '21:22'},
    {'g': '5.3', 'level': 'Médio', 'place': 'Setor de QA', 'time': '21:12'},
    {
      'g': '13.4',
      'level': 'Crítico',
      'place': 'Linha de Produção 1',
      'time': '15:54',
    },
    {'g': '4.5', 'level': 'Médio', 'place': 'Estoque 3', 'time': '01:41'},
    {
      'g': '1.9',
      'level': 'Baixo',
      'place': 'Doca de Recebimento',
      'time': '01:31',
    },
    {
      'g': '12.1',
      'level': 'Crítico',
      'place': 'Rampa Expedição',
      'time': '02:11',
    },
    {'g': '9.0', 'level': 'Alto', 'place': 'Setor de QA', 'time': '20:20'},
  ];
  final List<String> inspectionStates = [
    'Pendente',
    'Em andamento',
    'Pendente',
    'Pendente',
    'Pendente',
    'Em andamento',
    'Em andamento',
    'Concluída',
  ];
  final List<String> checklist = [
    'Conferir nível de bateria do equipamento',
    'Inspecionar integridade da embalagem',
    'Confirmar tipo de embalagem adequado à carga',
    'Verificar fixação da carga no pallet',
    'Conferir peso dentro do limite do equipamento',
    'Liberar rota livre de obstáculos',
    'Sinalizar piso molhado/irregular na rota',
    'Ativar sensor de impacto (MPU6050)',
    'Confirmar calibração do acelerômetro',
    'Sinalizar piso molhado/irregular na rota',
  ];
  final Set<int> checked = {};
  late final Api _api;
  bool _dialogOpen = false;
  bool _busy = false,
      _loaded = false,
      _saving = false,
      _reading = false,
      _joining = false;
  String? _authError;
  Map<String, dynamic>? _user;
  Timer? _poll, _debounce;
  final companyController = TextEditingController(),
      phoneController = TextEditingController(),
      joinController = TextEditingController();
  final Map<String, int> _revisions = {};
  final Map<String, String> _baseline = {};
  final List<String> _inspectionIds = [];
  final Map<String, String> settingsData = {};
  final Map<String, TextEditingController> settingControllers = {};
  String _id() => List.generate(
    12,
    (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
  int get criticalCount => impacts.where((i) => i['level'] == 'Crítico').length;
  String get averageG => impacts.isEmpty
      ? '0.0'
      : (impacts.fold<double>(
                  0,
                  (a, i) => a + (double.tryParse(i['g'] ?? '0') ?? 0),
                ) /
                impacts.length)
            .toStringAsFixed(1);
  List<(String, String)> get points {
    final counts = <String, int>{};
    for (final i in impacts) {
      counts.update(i['place'] ?? '', (v) => v + 1, ifAbsent: () => 1);
    }
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.map((e) => (e.key, '${e.value}')).toList();
  }

  String get companyName => _user?['companyName']?.toString() ?? '';
  bool get isAdmin => _user?['role'] == 'admin';
  String _key(String kind, String id) => '$kind:$id';
  Map<String, Map<String, String>> _snapshot() {
    while (inspectionStates.length < impacts.length) {
      inspectionStates.add('Pendente');
    }
    final out = <String, Map<String, String>>{};
    for (final pair in [
      ('movements', movements),
      ('cargos', cargos),
      ('impacts', impacts),
      ('routes', routes),
    ]) {
      for (final row in pair.$2) {
        row.putIfAbsent('_id', _id);
        out[_key(pair.$1, row['_id']!)] = Map.from(row);
      }
    }
    while (_inspectionIds.length < inspectionStates.length) {
      _inspectionIds.add(_id());
    }
    for (int i = 0; i < inspectionStates.length; i++) {
      out[_key('inspections', _inspectionIds[i])] = {
        'status': inspectionStates[i],
        'impactId': i < impacts.length ? impacts[i]['_id'] ?? '' : '',
      };
    }
    out[_key('checklist', 'template')] = {
      'checked': (checked.toList()..sort()).join(','),
    };
    if (isAdmin || _baseline.containsKey(_key('settings', 'limits'))) {
      out[_key('settings', 'limits')] = Map.from(settingsData);
    }
    return out;
  }

  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
    if (_loaded && !_reading) {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 350), _saveChanges);
    }
  }

  Future<void> _restore() async {
    try {
      final result = await _api.call('me');
      _user = Map.from(result['user']);
      await _loadData();
      if (_loaded && mounted) {
        super.setState(() {
          page = 'Dashboard';
        });
        final requested = Uri.base.queryParameters['cargo'];
        if (requested != null) _findCargo(requested);
        _startPolling();
      }
    } catch (e) {
      if (e is! ApiError || (e.status != 401)) {
        if (mounted) super.setState(() => _authError = e.toString());
      }
    }
  }

  void _startPolling() {
    _poll?.cancel();
    _poll = Timer.periodic(const Duration(seconds: 8), (_) {
      if (_loaded &&
          !_saving &&
          !_reading &&
          _snapshot().entries.every(
            (e) => jsonEncode(e.value) == _baseline[e.key],
          )) {
        _loadData();
      }
    });
  }

  Future<void> _authenticate() async {
    if (_busy) return;
    if (!loginEmail.text.contains('@') || password.text.length < 8) {
      setState(
        () => _authError =
            'Informe um e-mail válido e uma senha com pelo menos 8 caracteres.',
      );
      return;
    }
    if (signup && (!terms || registrationName.text.trim().isEmpty)) {
      setState(() => _authError = 'Preencha seu nome e aceite os termos.');
      return;
    }
    setState(() {
      _busy = true;
      _authError = null;
    });
    try {
      final result = await _api.call(
        signup ? 'register' : 'login',
        method: 'POST',
        data: {
          'email': loginEmail.text,
          'password': password.text,
          if (signup) ...{
            'name': registrationName.text,
            'companyName': companyController.text,
            'joinCode': _joining ? joinController.text : '',
            'phone': phoneController.text,
            'terms': terms,
          },
        },
      );
      if (signup) {
        try {
          await _api.call('logout', method: 'POST');
        } catch (_) {}
        if (!mounted) return;
        super.setState(() {
          page = 'Login';
          signup = false;
          _user = null;
          _joining = false;
          password.clear();
          registrationName.clear();
          companyController.clear();
          joinController.clear();
          phoneController.clear();
          terms = false;
          _authError = null;
        });
        notice('Cadastro realizado com sucesso! Faça login para continuar.');
        return;
      }
      _user = Map.from(result['user']);
      await _loadData();
      if (!_loaded) {
        throw ApiError(
          'Não foi possível carregar os dados da empresa. Tente entrar novamente.',
          503,
        );
      }
      if (!mounted) return;
      super.setState(() {
        page = 'Dashboard';
        menu = false;
      });
      password.clear();
      final requested = Uri.base.queryParameters['cargo'];
      if (requested != null) _findCargo(requested);
      _startPolling();
    } catch (e) {
      if (mounted) super.setState(() => _authError = e.toString());
    } finally {
      if (mounted) super.setState(() => _busy = false);
    }
  }

  Future<void> _loadData() async {
    if (_reading || _saving || _dialogOpen) return;
    _reading = true;
    try {
      final result = await _api.call('state');
      if (!mounted || _dialogOpen) return;
      super.setState(() {
        _user = Map.from(result['user']);
        name = _user!['name'];
        email = _user!['email'];
        movements.clear();
        cargos.clear();
        impacts.clear();
        routes.clear();
        inspectionStates.clear();
        _inspectionIds.clear();
        checked.clear();
        settingsData.clear();
        _baseline.clear();
        _revisions.clear();
        final rows = List<Map<String, dynamic>>.from(
          (result['records'] as List).map((r) => Map<String, dynamic>.from(r)),
        );
        final inspections = <Map<String, dynamic>>[];
        for (final r in rows) {
          final kind = r['kind'].toString(), id = r['id'].toString();
          final data = Map<String, String>.from(
            (r['data'] as Map).map(
              (k, v) => MapEntry(k.toString(), v.toString()),
            ),
          );
          _revisions[_key(kind, id)] = r['revision'];
          if (kind == 'inspections') {
            inspections.add({...r, 'data': data});
            continue;
          }
          if (['movements', 'cargos', 'impacts', 'routes'].contains(kind)) {
            data['_id'] = id;
            ({
              'movements': movements,
              'cargos': cargos,
              'impacts': impacts,
              'routes': routes,
            }[kind]!).add(data);
          }
          if (kind == 'checklist') {
            for (final n in (data['checked'] ?? '').split(',')) {
              final i = int.tryParse(n);
              if (i != null) checked.add(i);
            }
          }
          if (kind == 'settings') settingsData.addAll(data);
          _baseline[_key(kind, id)] = jsonEncode(data);
        }
        for (final impact in impacts) {
          final match = inspections.where(
            (r) => r['data']['impactId'] == impact['_id'],
          );
          if (match.isNotEmpty) {
            final row = match.first;
            inspectionStates.add(row['data']['status']);
            _inspectionIds.add(row['id']);
            _baseline[_key('inspections', row['id'])] = jsonEncode(
              Map<String, String>.from(row['data']),
            );
          }
        }
        _baseline.putIfAbsent(
          _key('checklist', 'template'),
          () => jsonEncode({'checked': ''}),
        );
        _loaded = true;
      });
    } catch (e) {
      if (e is ApiError && e.status == 401) {
        _loaded = false;
        _poll?.cancel();
        if (mounted) {
          super.setState(() {
            page = 'Login';
            _authError = e.message;
          });
        }
      } else if (mounted) {
        notice(e.toString());
      }
    } finally {
      _reading = false;
    }
  }

  Future<void> _saveChanges() async {
    if (!_loaded || _saving || _reading) return;
    final current = _snapshot();
    final changes = current.entries
        .where((e) => jsonEncode(e.value) != _baseline[e.key])
        .map((e) {
          final split = e.key.indexOf(':');
          return {
            'kind': e.key.substring(0, split),
            'id': e.key.substring(split + 1),
            'revision': _revisions[e.key] ?? 0,
            'data': e.value,
          };
        })
        .toList();
    if (changes.isEmpty) return;
    _saving = true;
    try {
      final result = await _api.call(
        'state',
        method: 'POST',
        data: {'changes': changes},
      );
      for (final saved in result['saved']) {
        final k = _key(saved['kind'], saved['id']);
        _revisions[k] = saved['revision'];
        _baseline[k] = jsonEncode(current[k]);
      }
    } catch (e) {
      if (mounted) {
        notice(
          e is ApiError && e.status == 409
              ? 'Um colega atualizou o mesmo registro. Atualizando os dados da equipe.'
              : 'Não foi possível salvar: $e',
        );
      }
      if (e is ApiError && e.status == 409) {
        _saving = false;
        await _loadData();
      }
    } finally {
      _saving = false;
    }
    if (_loaded &&
        _snapshot().entries.any(
          (e) => jsonEncode(e.value) != _baseline[e.key],
        )) {
      _debounce?.cancel();
      _debounce = Timer(const Duration(seconds: 5), _saveChanges);
    }
  }

  Future<void> _logout() async {
    await _saveChanges();
    try {
      await _api.call('logout', method: 'POST');
    } catch (e) {
      if (mounted) notice(e.toString());
      return;
    }
    _loaded = false;
    _poll?.cancel();
    _debounce?.cancel();
    _user = null;
    if (mounted) {
      super.setState(() {
        page = 'Login';
        menu = false;
      });
    }
  }

  Future<void> _team() async {
    try {
      final data = await _api.call('team');
      if (!mounted) return;
      showDialog<void>(
        context: context,
        builder: (c) => AlertDialog(
          backgroundColor: panel,
          title: txt('Equipe de $companyName', size: 18),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                txt('Código de equipe', size: 12, color: muted),
                SelectableText(data['joinCode']),
                const SizedBox(height: 12),
                txt(
                  'Os colegas usam este código no cadastro para entrar na empresa.',
                  size: 12,
                ),
                const SizedBox(height: 16),
                for (final m in data['members'])
                  ListTile(
                    title: txt(m['name'], size: 13),
                    subtitle: txt(m['email'], size: 11, color: muted),
                    trailing: tag(
                      m['role'] == 'admin' ? 'Administrador' : 'Colaborador',
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text('Fechar'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) notice(e.toString());
    }
  }

  Future<void> _updateProfile(List<String> v) async {
    try {
      final data = await _api.call(
        'profile',
        method: 'POST',
        data: {'name': v[0], 'phone': v[1]},
      );
      if (mounted) {
        setState(() {
          _user = Map.from(data['user']);
          name = _user!['name'];
        });
      }
    } catch (e) {
      if (mounted) notice(e.toString());
    }
  }

  Future<void> _changePassword(List<String> v) async {
    try {
      await _api.call(
        'password',
        method: 'POST',
        data: {'currentPassword': v[0], 'password': v[1]},
      );
      if (mounted) notice('Senha atualizada.');
    } catch (e) {
      if (mounted) notice(e.toString());
    }
  }

  Map<String, String>? selected;
  void go(String v) => setState(() {
    page = v;
    menu = false;
    search = '';
    filter = 'Todos';
  });
  Widget txt(String s, {double size = 14, Color? color, FontWeight? weight}) =>
      Text(
        s,
        style: TextStyle(
          fontSize: size,
          color: color ?? Colors.white,
          fontWeight: weight,
        ),
      );
  Widget box(Widget child, {Color color = panel, EdgeInsets? padding}) =>
      Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 14),
        padding: padding ?? const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Material(color: Colors.transparent, child: child),
      );
  Widget line(String s, {IconData? icon, Color color = muted}) => Padding(
    padding: const EdgeInsets.only(top: 5),
    child: Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 7),
        ],
        Expanded(child: txt(s, size: 11, color: color)),
      ],
    ),
  );
  Widget button(String s, VoidCallback fn, {bool outline = false}) => outline
      ? OutlinedButton(
          onPressed: fn,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(7),
            ),
          ),
          child: Text(s),
        )
      : ElevatedButton(onPressed: fn, child: Text(s));
  Widget tag(String s) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: tint(s).withValues(alpha: .15),
      borderRadius: BorderRadius.circular(10),
    ),
    child: txt(s, size: 10, color: tint(s)),
  );
  Color tint(String s) => s == 'Concluída' || s == 'Baixo'
      ? const Color(0xff00bb86)
      : s == 'Em andamento'
      ? const Color(0xff4285ec)
      : s == 'Médio' || s == 'Pendente'
      ? const Color(0xffffb500)
      : s == 'Alto'
      ? const Color(0xffff851b)
      : red;
  Widget heading(String title, String subtitle, {IconData? icon}) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 24),
              const SizedBox(width: 7),
            ],
            Expanded(child: txt(title, size: 22, weight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 5),
        txt(subtitle, size: 14, color: const Color(0xffb0b0b0)),
      ],
    ),
  );
  Widget field(
    String label,
    TextEditingController c, {
    String? hint,
    bool secret = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        txt(label, size: 13),
        const SizedBox(height: 7),
        TextField(
          controller: c,
          obscureText: secret && hidePassword,
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: secret
                ? IconButton(
                    onPressed: () =>
                        setState(() => hidePassword = !hidePassword),
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                  )
                : null,
          ),
        ),
      ],
    ),
  );
  void notice(String s) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));
  @override
  void initState() {
    super.initState();
    _api = widget.api ?? Api();
    _restore();
    bindNavigation((route) {
      if (!mounted) return false;
      if (!['Apresentação', 'Login'].contains(page) &&
          [
            'Dashboard',
            'Cargas',
            'Movimentações',
            'Impactos',
            'Inspeções',
            'Checklists',
            'Configurações',
            'Notificações',
            'Escanear',
            'Mapas',
            'Perfil',
          ].contains(route)) {
        go(route);
        return true;
      }
      return false;
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    _debounce?.cancel();
    companyController.dispose();
    phoneController.dispose();
    joinController.dispose();
    for (final c in settingControllers.values) {
      c.dispose();
    }
    loginEmail.dispose();
    password.dispose();
    registrationName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = page == 'Apresentação' || page == 'Login';
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: LayoutBuilder(
            builder: (context, constraints) => Stack(
              children: [
                Positioned.fill(
                  child: auth
                      ? (page == 'Apresentação' ? intro() : login())
                      : Column(
                          children: [
                            header(),
                            Expanded(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.fromLTRB(
                                  22,
                                  14,
                                  22,
                                  110,
                                ),
                                child: content(),
                              ),
                            ),
                          ],
                        ),
                ),
                if (!auth)
                  Positioned(bottom: 0, left: 0, right: 0, child: bottom()),
                if (menu && !auth) ...[
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: () => setState(() => menu = false),
                      child: Container(
                        color: Colors.black.withValues(alpha: .65),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    bottom: 86,
                    left: 0,
                    width: 225,
                    child: Container(
                      color: panel,
                      padding: const EdgeInsets.fromLTRB(12, 70, 12, 0),
                      child: Column(
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
                              onPressed: () => setState(() => menu = false),
                              icon: const Icon(Icons.close),
                            ),
                          ),
                          for (final e in [
                            ('Dashboard', Icons.dashboard_outlined),
                            ('Impactos', Icons.warning_amber),
                            ('Movimentações', Icons.local_shipping_outlined),
                            ('Inspeções', Icons.fact_check_outlined),
                            ('Checklists', Icons.checklist),
                            ('Configurações', Icons.settings_outlined),
                          ])
                            Container(
                              decoration: BoxDecoration(
                                color: page == e.$1
                                    ? red.withValues(alpha: .15)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: ListTile(
                                  dense: true,
                                  leading: Icon(e.$2, color: red, size: 19),
                                  title: txt(e.$1, size: 13),
                                  onTap: () => go(e.$1),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget header() => Padding(
    padding: const EdgeInsets.fromLTRB(12, 45, 12, 16),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () => setState(() => menu = !menu),
          icon: const Icon(Icons.menu, size: 23),
        ),
        brand(),
        IconButton(
          onPressed: () => go('Notificações'),
          icon: Badge(
            smallSize: 7,
            backgroundColor: red,
            child: const Icon(Icons.notifications_none, size: 25),
          ),
        ),
      ],
    ),
  );
  Widget brand() => RichText(
    text: const TextSpan(
      style: TextStyle(
        fontFamily: 'Arial',
        fontSize: 19,
        fontWeight: FontWeight.w800,
      ),
      children: [
        TextSpan(
          text: 'LOAD',
          style: TextStyle(color: Colors.white),
        ),
        TextSpan(
          text: 'SECURE',
          style: TextStyle(color: red),
        ),
      ],
    ),
  );
  Widget bottom() => Container(
    height: 86,
    decoration: const BoxDecoration(
      color: Color(0xff111111),
      border: Border(top: BorderSide(color: Color(0xff333333))),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        nav('Início', 'Dashboard', Icons.home),
        nav('Cargas', 'Cargas', Icons.view_in_ar_outlined),
        Transform.translate(
          offset: const Offset(0, -15),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () => go('Escanear'),
                child: Container(
                  padding: const EdgeInsets.all(13),
                  decoration: const BoxDecoration(
                    color: red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.document_scanner_outlined, size: 29),
                ),
              ),
              const SizedBox(height: 7),
              txt('Escanear', size: 12, color: muted),
            ],
          ),
        ),
        nav('Mapas', 'Mapas', Icons.location_on_outlined),
        nav('Perfil', 'Perfil', Icons.person_outline),
      ],
    ),
  );
  Widget nav(String label, String target, IconData icon) => InkWell(
    onTap: () => go(target),
    child: SizedBox(
      width: 65,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 29, color: page == target ? red : muted),
          const SizedBox(height: 6),
          txt(label, size: 12, color: page == target ? red : muted),
        ],
      ),
    ),
  );
  Widget authVisual({bool compact = false}) => Container(
    height: compact ? 190 : 360,
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 24),
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xff4a1821)),
      boxShadow: [BoxShadow(color: red.withValues(alpha: .08), blurRadius: 35)],
    ),
    child: Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/tracker.png',
          fit: BoxFit.cover,
          alignment: compact ? const Alignment(0, .05) : Alignment.center,
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: .2),
                Colors.transparent,
                Colors.black.withValues(alpha: .9),
              ],
              stops: const [0, .45, 1],
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              txt(
                'MONITORAMENTO INTELIGENTE',
                size: compact ? 10 : 12,
                color: const Color(0xffdddddd),
              ),
              const SizedBox(height: 4),
              txt(
                'Segurança em cada movimento.',
                size: compact ? 16 : 23,
                weight: FontWeight.bold,
              ),
            ],
          ),
        ),
      ],
    ),
  );
  Widget intro() => GestureDetector(
    onHorizontalDragEnd: (_) => go('Login'),
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 45, 28, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Image.asset(
              'assets/logo.png',
              height: 80,
              width: 350,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 15),
          authVisual(),
          feature(
            Icons.shield_outlined,
            'Proteção completa',
            'Detecta impacto, vibração, violação e desvios de rota.',
          ),
          feature(
            Icons.location_on_outlined,
            'Rastreamento em tempo real',
            'Acompanhe cada movimentação da sua carga.',
          ),
          feature(
            Icons.stacked_bar_chart,
            'Análise inteligente',
            'Dados que transformam informação em decisão.',
          ),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: button('ACESSAR MINHA CONTA', () => go('Login')),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.circle, size: 10, color: red),
              IconButton(
                tooltip: 'Ir para login',
                onPressed: () => go('Login'),
                icon: const Icon(Icons.circle, size: 10, color: muted),
              ),
            ],
          ),
        ],
      ),
    ),
  );
  Widget feature(IconData icon, String title, String description) => Padding(
    padding: const EdgeInsets.only(bottom: 28),
    child: Row(
      children: [
        Icon(icon, color: red, size: 33),
        const SizedBox(width: 17),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              txt(title, size: 15, weight: FontWeight.bold),
              const SizedBox(height: 6),
              txt(description, size: 11),
            ],
          ),
        ),
      ],
    ),
  );
  Widget login() => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(28, 32, 28, 30),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Image.asset(
            'assets/logo.png',
            height: 60,
            fit: BoxFit.contain,
          ),
        ),
        authVisual(compact: true),
        txt('Bem-vindo ao', size: 33, weight: FontWeight.bold),
        RichText(
          text: const TextSpan(
            style: TextStyle(
              fontSize: 33,
              fontFamily: 'Arial',
              fontWeight: FontWeight.bold,
            ),
            children: [
              TextSpan(
                text: 'Load',
                style: TextStyle(color: Colors.white),
              ),
              TextSpan(
                text: 'Secure',
                style: TextStyle(color: red),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        txt(
          signup
              ? 'Crie sua conta para proteger suas cargas'
              : 'Faça login para acessar sua conta',
          size: 14,
          color: muted,
        ),
        const SizedBox(height: 45),
        Row(
          children: [
            for (final b in [false, true])
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => signup = b),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: signup == b ? red : const Color(0xff333333),
                          width: 2,
                        ),
                      ),
                    ),
                    child: Center(
                      child: txt(
                        b ? 'CADASTRO' : 'LOGIN',
                        size: 16,
                        color: signup == b ? red : muted,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 32),
        if (signup)
          field('Nome completo', registrationName, hint: 'Seu nome completo'),
        field('E-mail', loginEmail, hint: 'seu@email.com'),
        if (signup) ...[
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                value: false,
                label: Text('Minha empresa', style: TextStyle(fontSize: 11)),
              ),
              ButtonSegment(
                value: true,
                label: Text('Entrar na equipe', style: TextStyle(fontSize: 11)),
              ),
            ],
            selected: {_joining},
            onSelectionChanged: (v) => setState(() => _joining = v.first),
          ),
          const SizedBox(height: 16),
          if (_joining)
            field(
              'Código de equipe',
              joinController,
              hint: 'Código fornecido pelo administrador',
            )
          else
            field('Empresa', companyController, hint: 'Nome da empresa'),
          field('Telefone', phoneController, hint: '(00) 00000-0000'),
        ],
        field(
          'Senha',
          password,
          hint: signup ? 'Crie uma senha' : 'Sua senha',
          secret: true,
        ),
        if (signup)
          Row(
            children: [
              Checkbox(
                value: terms,
                onChanged: (v) => setState(() => terms = v ?? false),
              ),
              Expanded(
                child: txt(
                  'Aceito os termos de uso e política de privacidade',
                  size: 10,
                  color: red,
                ),
              ),
            ],
          )
        else
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => form('Recuperar senha', ['E-mail'], (v) {
                notice(
                  'Solicitação registrada. O envio de e-mail depende da integração de autenticação.',
                );
              }),
              child: txt('Esqueceu sua senha?', color: red, size: 12),
            ),
          ),
        if (_authError != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: txt(_authError!, size: 12, color: red),
          ),
        const SizedBox(height: 27),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: button(
            _busy
                ? 'AGUARDE...'
                : signup
                ? 'CADASTRAR'
                : 'ENTRAR',
            _authenticate,
          ),
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: txt('ou', color: muted),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 15),
        for (final provider in ['Google', 'Microsoft'])
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: button(
                'Entrar com $provider',
                () => notice(
                  'O acesso com $provider precisa ser conectado ao provedor de autenticação.',
                ),
                outline: true,
              ),
            ),
          ),
        const SizedBox(height: 15),
        Center(
          child: TextButton(
            onPressed: () => setState(() => signup = !signup),
            child: txt(
              signup
                  ? 'Já possui uma conta? Faça login'
                  : 'Ainda não tem conta? Cadastre-se',
              size: 11,
              color: red,
            ),
          ),
        ),
        const SizedBox(height: 50),
        Center(
          child: IconButton(
            onPressed: () => go('Apresentação'),
            icon: const Icon(Icons.circle, size: 11, color: muted),
          ),
        ),
      ],
    ),
  );
  Widget content() {
    switch (page) {
      case 'Dashboard':
        return dashboard();
      case 'Cargas':
        return cargoPage();
      case 'Movimentações':
        return movementPage();
      case 'Detalhes':
        return details();
      case 'Impactos':
        return impactPage();
      case 'Inspeções':
        return inspections();
      case 'Checklists':
        return checklistPage();
      case 'Configurações':
        return settings();
      case 'Notificações':
        return notifications();
      case 'Escanear':
        return scanner();
      case 'Mapas':
        return maps();
      case 'Perfil':
        return profile();
      default:
        return const SizedBox();
    }
  }

  Widget metric(String title, String value, String note, {Color? color}) =>
      Expanded(
        child: Container(
          margin: const EdgeInsets.only(right: 4),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: panel,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              txt(title, size: 9, color: muted),
              const SizedBox(height: 8),
              txt(value, size: 18, weight: FontWeight.bold),
              const SizedBox(height: 7),
              txt(note, size: 9, color: color ?? muted),
            ],
          ),
        ),
      );
  Widget dashboard() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      heading('Bem-vindo, $name!', 'Visão geral de $companyName'),
      Container(
        padding: const EdgeInsets.all(13),
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: const Color(0xff200000),
          border: Border.all(color: const Color(0xff742020)),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber, color: red),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  txt(
                    '$criticalCount impacto(s) crítico(s) detectado(s)',
                    size: 12,
                    color: red,
                    weight: FontWeight.bold,
                  ),
                  const SizedBox(height: 5),
                  txt(
                    'Verifique as movimentações afetadas e ordens de inspeção geradas.',
                    size: 9,
                  ),
                ],
              ),
            ),
            button('Ver impactos', () => go('Impactos')),
          ],
        ),
      ),
      Row(
        children: [
          metric('MOVIMENTAÇÕES', '${movements.length}', 'Total registradas'),
          metric(
            'IMPACTOS DETECTADOS',
            '${impacts.length}',
            'Registrados pela equipe',
            color: red,
          ),
          metric('REDUÇÃO DE PERDAS', '—', 'Aguardando histórico'),
        ],
      ),
      const SizedBox(height: 18),
      criticalPoints(),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: box(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  txt('Impactos recentes', size: 12, weight: FontWeight.bold),
                  const SizedBox(height: 12),
                  for (final i in impacts.take(5)) impactCard(i, compact: true),
                ],
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: box(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  txt('Cargas monitoradas', size: 12, weight: FontWeight.bold),
                  const SizedBox(height: 12),
                  for (final c in cargos)
                    InkWell(
                      onTap: () => go('Cargas'),
                      child: box(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            txt(c['name']!, size: 11),
                            tag(c['risk']!),
                            line('0 impactos'),
                          ],
                        ),
                        color: Colors.black,
                        padding: const EdgeInsets.all(9),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    ],
  );
  Widget criticalPoints() => box(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.location_on_outlined, color: red, size: 19),
            const SizedBox(width: 5),
            Expanded(
              child: txt(
                'Pontos críticos da fábrica',
                size: 14,
                weight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (points.isEmpty) line('Nenhum impacto registrado pela equipe.'),
        for (final e in points.take(4))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 9),
            child: Row(
              children: [
                const Icon(Icons.circle, color: Color(0xff6d101b), size: 19),
                const SizedBox(width: 10),
                Expanded(child: txt(e.$1, size: 13)),
                txt(e.$2, size: 13, weight: FontWeight.bold),
              ],
            ),
          ),
        TextButton(
          onPressed: () => go('Mapas'),
          child: txt('Ver mapa completo', color: red, size: 12),
        ),
      ],
    ),
  );
  Widget searchField(String hint) => TextField(
    onChanged: (v) => setState(() => search = v),
    decoration: InputDecoration(
      hintText: hint,
      prefixIcon: const Icon(Icons.search, size: 18),
    ),
  );
  Widget filters(List<String> values) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        for (final v in values)
          Padding(
            padding: const EdgeInsets.only(right: 7),
            child: ChoiceChip(
              label: Text(
                v,
                style: TextStyle(
                  fontSize: 11,
                  color: filter == v ? red : muted,
                ),
              ),
              selected: filter == v,
              onSelected: (_) => setState(() => filter = v),
              showCheckmark: false,
              backgroundColor: Colors.black,
              selectedColor: const Color(0xff290000),
              padding: EdgeInsets.zero,
            ),
          ),
      ],
    ),
  );
  Widget movementPage() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      heading(
        'Movimentações',
        'Histórico e rastreamento das movimentações internas',
        icon: Icons.local_shipping_outlined,
      ),
      Row(
        children: [
          Expanded(
            child: searchField('Buscar por código, operador ou rota...'),
          ),
          const SizedBox(width: 8),
          button('+ Nova', newMovement),
        ],
      ),
      const SizedBox(height: 8),
      filters(['Todos', 'Concluída', 'Com problema', 'Em andamento']),
      const SizedBox(height: 18),
      if (movements.isEmpty)
        box(txt('Nenhuma movimentação registrada.', color: muted)),
      for (final m in movements.where(
        (m) =>
            (filter == 'Todos' || m['status'] == filter) &&
            m.values.join(' ').toLowerCase().contains(search.toLowerCase()),
      ))
        box(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.qr_code, size: 26, color: muted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        txt(m['code']!, size: 13, weight: FontWeight.bold),
                        txt('${m['impacts']} impactos', size: 10, color: red),
                      ],
                    ),
                  ),
                  tag(m['status']!),
                ],
              ),
              const SizedBox(height: 12),
              line(m['route']!, icon: Icons.location_on_outlined),
              line(m['equipment']!, icon: Icons.local_shipping_outlined),
              line(m['operator']!, icon: Icons.person_outline),
              line(m['cargo']!, icon: Icons.inventory_2_outlined),
              line(m['date']!, icon: Icons.calendar_today_outlined),
              Center(
                child: TextButton(
                  onPressed: () {
                    selected = m;
                    go('Detalhes');
                  },
                  child: txt('Ver detalhes', color: red, size: 11),
                ),
              ),
            ],
          ),
        ),
    ],
  );
  void newMovement() => form(
    'Nova movimentação',
    [
      'Código',
      'Início',
      'Origem',
      'Destino',
      'Equipamento',
      'Status',
      'Operador',
      'Carga',
    ],
    (v) => setState(
      () => movements.add({
        'code': v[0],
        'date': v[1],
        'route': '${v[2]} → ${v[3]}',
        'equipment': v[4],
        'status': v[5],
        'operator': v[6],
        'cargo': v[7],
        'impacts': '0',
      }),
    ),
    defaults: [
      'MOV-${DateTime.now().millisecondsSinceEpoch}',
      DateTime.now().toString().substring(0, 16),
      'Almoxarifado',
      'Linha A',
      'Empilhadeira',
      'Em andamento',
      name,
      'Eletrônicos',
    ],
    save: 'Salvar movimentação',
  );
  Widget details() {
    final m = selected ?? movements.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton(
          onPressed: () => go('Movimentações'),
          child: txt('← Voltar para movimentações', size: 13),
        ),
        box(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              txt(m['code']!, size: 19, weight: FontWeight.bold),
              tag(m['status']!),
              const SizedBox(height: 10),
              for (final e in m.entries.where((e) => e.key != '_id'))
                line('${e.key}: ${e.value}'),
            ],
          ),
        ),
        txt('Impactos registrados', weight: FontWeight.bold),
        const SizedBox(height: 12),
        for (final i in impacts.take(2)) impactCard(i),
        box(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.qr_code_2, size: 120),
              txt('Ordens de inspeção'),
              TextButton(
                onPressed: () => go('Inspeções'),
                child: txt('Ver ordens de inspeção', color: red),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _cargoUrl(Map<String, String> cargo) =>
      'https://loadsecure-flutter.lucashenriquesilvacp.chatgpt.site/?cargo=${Uri.encodeComponent(cargo['_id'] ?? cargo['name']!)}';
  Widget cargoQr(Map<String, String> cargo, {double size = 210}) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: SizedBox(
      width: size,
      height: size,
      child: QrImageView(
        data: _cargoUrl(cargo),
        version: QrVersions.auto,
        size: size,
        errorCorrectionLevel: QrErrorCorrectLevel.M,
        backgroundColor: Colors.white,
      ),
    ),
  );
  void _showCargoQr(Map<String, String> cargo) {
    showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: panel,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: txt(cargo['name']!, size: 18, weight: FontWeight.bold),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            cargoQr(cargo, size: 220),
            const SizedBox(height: 18),
            txt('Escaneie para abrir esta carga.', size: 13, color: muted),
            const SizedBox(height: 10),
            SelectableText(
              cargo['_id'] ?? '',
              style: const TextStyle(fontSize: 11, color: muted),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  void _findCargo(String code) {
    final uri = Uri.tryParse(code);
    final key = uri?.queryParameters['cargo'] ?? code.trim();
    final match = cargos.where(
      (c) => c['_id'] == key || c['name']!.toLowerCase() == key.toLowerCase(),
    );
    if (match.isEmpty) {
      notice('Carga não encontrada na sua empresa.');
      return;
    }
    go('Cargas');
    setState(() => search = match.first['name']!);
  }

  Widget cargoPage() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      heading(
        'Cargas',
        'Acompanhe todas as cargas em trânsito e seu status atual.',
      ),
      Align(
        alignment: Alignment.centerRight,
        child: button(
          '+ Nova carga',
          () => form(
            'Nova carga',
            [
              'Nome',
              'Categoria',
              'Fragilidade',
              'Tipo de embalagem',
              'Nível de risco',
              'Observações',
            ],
            (v) => setState(
              () => cargos.add({
                'name': v[0],
                'category': v[1],
                'fragility': v[2],
                'package': v[3],
                'risk': v[4],
                'note': v[5],
              }),
            ),
            defaults: [
              '',
              'Eletrônicos',
              'Alta',
              'Caixa',
              'Alto',
              'Manusear com cuidado.',
            ],
            save: 'Cadastrar carga',
          ),
        ),
      ),
      searchField('Buscar carga, ID ou destino...'),
      const SizedBox(height: 17),
      if (cargos.isEmpty)
        box(txt('Cadastre a primeira carga da empresa.', color: muted)),
      for (final c in cargos.where(
        (c) => c['name']!.toLowerCase().contains(search.toLowerCase()),
      ))
        box(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.view_in_ar_outlined, color: red, size: 23),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        txt(c['name']!, weight: FontWeight.bold),
                        txt(c['category']!, size: 11, color: muted),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'QR Code da carga',
                    onPressed: () => _showCargoQr(c),
                    icon: const Icon(Icons.qr_code_2, color: red, size: 21),
                  ),
                  IconButton(
                    onPressed: () => editCargo(c),
                    icon: const Icon(
                      Icons.edit_outlined,
                      size: 17,
                      color: muted,
                    ),
                  ),
                ],
              ),
              Wrap(
                spacing: 7,
                children: [
                  tag('Risco ${c['risk']}'),
                  tag('Fragilidade ${c['fragility']}'),
                  tag(c['package']!),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  metric('Movimentações', '0', ''),
                  metric('Impactos', '0', ''),
                  metric('Impactos críticos', '0', ''),
                ],
              ),
              line('0.0g', icon: Icons.warning_amber),
              line(c['note']!),
            ],
          ),
        ),
    ],
  );
  void editCargo(Map<String, String> c) => form(
    'Editar carga',
    [
      'Nome da carga',
      'Categoria',
      'Fragilidade',
      'Tipo de embalagem',
      'Peso médio (kg)',
      'Nível de risco',
      'Observações',
    ],
    (v) => setState(() {
      c['name'] = v[0];
      c['category'] = v[1];
      c['fragility'] = v[2];
      c['package'] = v[3];
      c['risk'] = v[5];
      c['note'] = v[6];
    }),
    defaults: [
      c['name']!,
      c['category']!,
      c['fragility']!,
      c['package']!,
      '15',
      c['risk']!,
      c['note']!,
    ],
    save: 'Salvar',
  );
  Widget impactCard(Map<String, String> i, {bool compact = false}) => box(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [tag(i['level']!), if (!compact) tag('Inspeção gerada')],
        ),
        const SizedBox(height: 9),
        if (!compact) txt('${i['g']} g', size: 23, weight: FontWeight.bold),
        Row(
          children: [
            Expanded(child: txt(i['place']!, size: compact ? 10 : 13)),
            if (compact) txt('${i['g']} g', size: 10),
          ],
        ),
        line(
          '${i['date'] ?? ''} ${i['time']}',
          icon: Icons.calendar_today_outlined,
        ),
        if (!compact)
          TextButton(
            onPressed: () => go('Inspeções'),
            child: txt('Ver inspeção', size: 10, color: red),
          ),
      ],
    ),
    color: compact ? Colors.black : panel,
    padding: EdgeInsets.all(compact ? 9 : 14),
  );
  Widget impactPage() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      heading(
        'Impactos Registrados',
        'Análise de vibração e impacto por severidade e localização',
        icon: Icons.bolt,
      ),
      txt('Resumo de hoje', weight: FontWeight.bold),
      const SizedBox(height: 10),
      Row(
        children: [
          metric(
            'Total de impactos',
            '${impacts.length}',
            'Total registrado',
            color: red,
          ),
          metric(
            'Impactos críticos',
            '$criticalCount',
            'Total crítico',
            color: red,
          ),
          metric('Vibração média', '5.6g', '-8% vs ontem', color: Colors.green),
          metric('Tempo monitorado', '—', 'Sensor não conectado'),
        ],
      ),
      const SizedBox(height: 20),
      box(
        Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                txt('Tendência de impactos', size: 13),
                txt('7 dias', size: 11, color: muted),
              ],
            ),
            const SizedBox(height: 15),
            SizedBox(
              height: 110,
              width: double.infinity,
              child: CustomPaint(
                painter: TrendPainter(
                  values: impacts
                      .map((i) => double.tryParse(i['g'] ?? '0') ?? 0)
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
      Row(
        children: [
          Expanded(
            child: txt('${impacts.length} impacto(s) exibido(s)', size: 12),
          ),
          button(
            '+ Registrar impacto',
            () => form(
              'Registrar impacto (sensor MPU6050)',
              [
                'Movimentação',
                'Vibração (g)',
                'Temperatura (°C)',
                'Localização na fábrica',
                'Severidade',
              ],
              (v) => setState(
                () => impacts.add({
                  'g': v[1],
                  'level': v[4],
                  'place': v[3],
                  'time': DateTime.now().toString().substring(11, 16),
                  'date': DateTime.now().toString().substring(0, 10),
                }),
              ),
              defaults: [
                'MOV-2026-10000',
                '5.6',
                '23',
                'Almoxarifado',
                'Médio',
              ],
              save: 'Registrar impacto',
            ),
          ),
        ],
      ),
      const SizedBox(height: 15),
      Wrap(
        spacing: 12,
        children: [
          for (final i in impacts)
            SizedBox(
              width:
                  (MediaQuery.sizeOf(context).width.clamp(320, 500) - 56) / 2,
              child: impactCard(i),
            ),
        ],
      ),
    ],
  );
  Widget inspections() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      heading(
        'Ordens de Inspeção',
        'Inspeções geradas automaticamente após impactos',
        icon: Icons.manage_search,
      ),
      Row(
        children: [
          for (final s in ['Pendente', 'Em andamento', 'Concluída'])
            Expanded(
              child: InkWell(
                onTap: () => setState(() => filter = filter == s ? 'Todos' : s),
                child: Container(
                  margin: const EdgeInsets.only(right: 5),
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: tint(s).withValues(alpha: .12),
                    border: Border.all(
                      color: filter == s ? Colors.white : Colors.transparent,
                    ),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      txt(s.toUpperCase(), size: 9, color: tint(s)),
                      txt(
                        '${inspectionStates.where((e) => e == s).length}',
                        size: 18,
                        color: tint(s),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      const SizedBox(height: 18),
      for (int j = 0; j < inspectionStates.length; j++)
        if (filter == 'Todos' || inspectionStates[j] == filter)
          box(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    tag(inspectionStates[j]),
                    const SizedBox(width: 5),
                    tag('Prioridade alta'),
                    const Spacer(),
                    TextButton(
                      onPressed: () => setState(
                        () => inspectionStates[j] =
                            inspectionStates[j] == 'Pendente'
                            ? 'Em andamento'
                            : 'Concluída',
                      ),
                      child: txt(
                        inspectionStates[j] == 'Pendente'
                            ? 'Iniciar'
                            : inspectionStates[j] == 'Concluída'
                            ? 'Concluída'
                            : 'Concluir',
                        size: 11,
                        color: inspectionStates[j] == 'Em andamento'
                            ? Colors.green
                            : muted,
                      ),
                    ),
                  ],
                ),
                txt(
                  'Inspeção de carga após impacto ${impacts[j]['level']!.toLowerCase()} (${impacts[j]['g']}g) em ${impacts[j]['place']}. Verificar embalagem e integridade do produto.',
                  size: 12,
                ),
                line(
                  'Movimentação: MOV-2026-1000${j % 5} · Aberta em 27/08/2026, ${impacts[j]['time']}',
                ),
              ],
            ),
          ),
    ],
  );
  Widget checklistPage() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      heading(
        'Checklists',
        'Checklist digital antes da movimentação',
        icon: Icons.checklist,
      ),
      txt('Template padrão de checklist', size: 14),
      const SizedBox(height: 15),
      box(
        Column(
          children: [
            for (int i = 0; i < checklist.length; i++)
              CheckboxListTile(
                value: checked.contains(i),
                onChanged: (v) => setState(
                  () => v == true ? checked.add(i) : checked.remove(i),
                ),
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: txt(checklist[i], size: 12),
                subtitle: txt(
                  '${['Equipamento', 'Embalagem', 'Embalagem', 'Carga', 'Carga', 'Rota', 'Rota', 'Sensor', 'Sensor', 'Equipamento'][i]} · ${i == 6 ? 'Opcional' : 'Obrigatório'}',
                  size: 10,
                  color: muted,
                ),
              ),
          ],
        ),
      ),
      txt('Movimentações aguardando checklist', size: 15),
      const SizedBox(height: 15),
      for (final m in movements.where((e) => e['status'] == 'Em andamento'))
        box(
          Column(
            children: [
              txt(m['code']!, weight: FontWeight.bold),
              line(m['route']!),
              const SizedBox(height: 10),
              button('Concluir checklist', () {
                if (checked.length < 9) {
                  notice('Confira todos os itens obrigatórios.');
                  return;
                }
                setState(() => m['checklist'] = 'Concluído');
                notice('Checklist concluído para ${m['code']}');
              }),
            ],
          ),
        ),
    ],
  );
  Widget settings() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      heading(
        'Configurações',
        'Limites de impacto e alertas do projeto',
        icon: Icons.settings_outlined,
      ),
      box(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            txt('Limites de impacto — aceleração (g)', size: 13),
            line(
              'Defina os limites de severidade para classificação dos impactos.',
            ),
            const SizedBox(height: 16),
            for (final e in [
              ('Limite impacto baixo (g)', '2'),
              ('Limite impacto médio (g)', '5'),
              ('Limite impacto alto (g)', '8'),
              ('Limite impacto crítico (g)', '12'),
            ])
              field(
                e.$1,
                settingControllers.putIfAbsent(
                  e.$1,
                  () => TextEditingController(text: settingsData[e.$1] ?? e.$2),
                ),
              ),
            button('Salvar limites', () {
              if (!isAdmin) {
                notice('Somente o administrador pode alterar limites.');
                return;
              }
              setState(() {
                for (final e in settingControllers.entries) {
                  settingsData[e.key] = e.value.text;
                }
              });
            }),
          ],
        ),
      ),
      box(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            txt('Alertas por e-mail', size: 13),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: txt(
                'Enviar e-mail automaticamente quando ocorrer impacto crítico',
                size: 12,
              ),
              value: settingsData['emailAlerts'] == 'true',
              onChanged: isAdmin
                  ? (v) => setState(() => settingsData['emailAlerts'] = '$v')
                  : null,
            ),
            field(
              'E-mail de alerta',
              settingControllers.putIfAbsent(
                'alertEmail',
                () => TextEditingController(
                  text: settingsData['alertEmail'] ?? email,
                ),
              ),
            ),
          ],
        ),
      ),
      box(
        Column(
          children: [
            CheckboxListTile(
              title: txt(
                'Gerar ordem de inspeção automaticamente após impacto crítico',
                size: 12,
              ),
              value: true,
              onChanged: (_) => notice('Inspeção automática ativa.'),
            ),
          ],
        ),
      ),
      box(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            txt('Pontos críticos da fábrica'),
            Wrap(
              spacing: 8,
              children: [
                for (final s in [
                  'Almoxarifado',
                  'Expedição',
                  'Estoque',
                  'Produção',
                  'Rampa',
                  'Recebimento',
                ])
                  tag(s),
              ],
            ),
          ],
        ),
      ),
      txt('Como funciona', weight: FontWeight.bold),
      line(
        'O dispositivo mede impactos e vibrações da carga. Os limites permitem identificar operações de risco.',
      ),
    ],
  );
  Widget notifications() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      heading(
        'Notificações',
        'Alertas compartilhados de $companyName',
        icon: Icons.notifications,
      ),
      if (impacts.isEmpty && inspectionStates.isEmpty)
        box(txt('Nenhum alerta registrado.', color: muted)),
      for (final i in impacts.where(
        (i) => i['level'] == 'Crítico' || i['level'] == 'Alto',
      ))
        InkWell(
          onTap: () => go('Impactos'),
          child: box(
            Row(
              children: [
                const Icon(Icons.warning_amber, color: red),
                const SizedBox(width: 10),
                Expanded(
                  child: txt(
                    'Impacto ${i['level']!.toLowerCase()} · ${i['g']}g em ${i['place']}',
                    size: 12,
                  ),
                ),
                tag(i['level']!),
              ],
            ),
          ),
        ),
      for (int i = 0; i < inspectionStates.length; i++)
        if (inspectionStates[i] == 'Pendente')
          InkWell(
            onTap: () => go('Inspeções'),
            child: box(
              Row(
                children: [
                  const Icon(Icons.fact_check_outlined, color: Colors.amber),
                  const SizedBox(width: 10),
                  Expanded(
                    child: txt(
                      'Inspeção pendente · ${i < impacts.length ? impacts[i]['place'] : ''}',
                      size: 12,
                    ),
                  ),
                  tag('Pendente'),
                ],
              ),
            ),
          ),
    ],
  );
  Widget scanner() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      heading(
        'Escanear',
        'Abra o QR Code da carga ou informe seu código para visualizar informações e status.',
      ),
      Row(
        children: [
          for (final t in ['QR Code', 'Código manual'])
            Expanded(
              child: TextButton(
                onPressed: () => setState(() => scanTab = t),
                child: txt(t, color: scanTab == t ? red : muted),
              ),
            ),
        ],
      ),
      if (scanTab == 'QR Code') ...[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.only(top: 10, bottom: 18),
          decoration: BoxDecoration(
            color: const Color(0xff101014),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xff39202a)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.qr_code_scanner, color: red, size: 20),
                  const SizedBox(width: 8),
                  txt('QR CODE DA CARGA', size: 12, weight: FontWeight.bold),
                ],
              ),
              const SizedBox(height: 20),
              if (cargos.isNotEmpty)
                cargoQr(cargos.first, size: 210)
              else
                Container(
                  height: 230,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xff555555)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: txt(
                    'Cadastre uma carga para gerar seu QR Code.',
                    size: 15,
                    color: muted,
                  ),
                ),
              const SizedBox(height: 18),
              txt(
                cargos.isEmpty
                    ? 'Nenhuma carga cadastrada'
                    : cargos.first['name']!,
                size: 15,
                weight: FontWeight.bold,
              ),
              const SizedBox(height: 8),
              txt(
                'O código abre os dados da carga após o login da empresa.',
                size: 12,
                color: muted,
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: button(
                  'INFORMAR CÓDIGO',
                  () => setState(() => scanTab = 'Código manual'),
                  outline: true,
                ),
              ),
            ],
          ),
        ),
        box(
          Row(
            children: [
              const Icon(Icons.shield_outlined, color: red),
              const SizedBox(width: 12),
              Expanded(
                child: txt(
                  'Somente a equipe da empresa pode acessar os dados vinculados ao QR Code.',
                  size: 12,
                ),
              ),
            ],
          ),
        ),
      ] else
        box(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              field(
                'Código da carga',
                loginEmail,
                hint: 'Ex: MC-4587 ou 123456789',
              ),
              txt(
                'Digite o código exatamente como está na embalagem.',
                size: 10,
                color: muted,
              ),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                child: button('Buscar carga', () {
                  search = loginEmail.text;
                  go('Cargas');
                }),
              ),
              const SizedBox(height: 25),
              txt('Como encontrar o código?'),
              line('Na caixa ou embalagem'),
              line('Na nota fiscal'),
              line('No sistema'),
            ],
          ),
        ),
      const SizedBox(height: 18),
      txt('Histórico recente', weight: FontWeight.bold),
      const SizedBox(height: 12),
      if (movements.isEmpty)
        box(txt('Nenhuma movimentação registrada.', color: muted)),
      for (final m in movements.reversed.take(3))
        box(
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [txt(m['code']!, size: 12), line(m['route']!)],
                ),
              ),
              tag(m['status']!),
            ],
          ),
        ),
    ],
  );

  final routes = <Map<String, String>>[
    {
      'name': 'Almoxarifado → Linha A',
      'from': 'Almoxarifado A',
      'to': 'Linha de Produção 1',
      'distance': '120',
      'impacts': '8',
      'g': '7.94',
      'note': 'Reduzir velocidade na curva do Almoxarifado e sinalizar piso irregular.',
    },
    {
      'name': 'Recebimento → Estoque',
      'from': 'Doca de Recebimento',
      'to': 'Estoque 3',
      'distance': '85',
      'impacts': '6',
      'g': '7.07',
      'note': 'Treinar operadores para frenagem progressiva; instalar sinalização no corredor.',
    },
  ];
  Widget maps() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      heading('Mapas', 'Visualize pontos críticos e rotas internas'),
      Row(
        children: [
          button(
            'Hoje',
            () => notice('Exibindo dados do período selecionado.'),
            outline: true,
          ),
          const Spacer(),
          if (mapTab == 'Rotas')
            button(
              '+ Nova rota',
              () => form(
                'Nova rota interna',
                ['Nome da rota', 'Origem', 'Destino', 'Distância (m)'],
                (v) => setState(
                  () => routes.add({
                    'name': v[0],
                    'from': v[1],
                    'to': v[2],
                    'distance': v[3],
                    'impacts': '0',
                    'g': '0',
                    'note': 'Rota cadastrada.',
                  }),
                ),
                save: 'Cadastrar rota',
              ),
            ),
        ],
      ),
      Row(
        children: [
          for (final t in ['Mapa', 'Rotas'])
            Expanded(
              child: TextButton(
                onPressed: () => setState(() => mapTab = t),
                child: txt(t, color: mapTab == t ? red : muted),
              ),
            ),
        ],
      ),
      if (mapTab == 'Mapa') ...[
        box(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              txt(
                'Planta da fábrica — pontos de impacto',
                size: 13,
                weight: FontWeight.bold,
              ),
              const SizedBox(height: 10),
              Container(
                height: 315,
                color: Colors.white,
                child: const CustomPaint(
                  painter: FactoryPainter(),
                  child: SizedBox.expand(),
                ),
              ),
            ],
          ),
        ),
        criticalPoints(),
        box(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              txt('Destaques'),
              line('Total de pontos críticos: $criticalCount'),
              line('Locais com registros: ${points.length}'),
              line('Cargas cadastradas: ${cargos.length}'),
              const SizedBox(height: 10),
              txt('Último evento crítico', color: red),
              line(
                impacts.isEmpty
                    ? 'Sem eventos registrados'
                    : 'Último local: ${impacts.last['place']}',
              ),
              line('Dados compartilhados da empresa'),
              TextButton(
                onPressed: () => go('Impactos'),
                child: txt('Ver detalhes', color: red),
              ),
            ],
          ),
        ),
      ] else ...[
        box(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              txt('Rotas Internas'),
              const SizedBox(height: 10),
              const SizedBox(
                height: 190,
                width: double.infinity,
                child: CustomPaint(painter: BarPainter()),
              ),
            ],
          ),
        ),
        for (final r in routes)
          box(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                txt('Rota ${r['name']}', size: 13, weight: FontWeight.bold),
                line('${r['from']} → ${r['to']} · ${r['distance']} m'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    metric('Movimentações', '4', ''),
                    metric('Impactos', r['impacts']!, ''),
                    metric('Vibração média', '${r['g']}g', ''),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  color: const Color(0xff32070a),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      txt('Nível de risco: Alto', color: red, size: 12),
                      const SizedBox(height: 6),
                      txt(r['note']!, size: 11),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    ],
  );
  Widget profile() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      heading('Perfil', 'Gerencie sua conta e preferências'),
      box(
        Row(
          children: [
            const CircleAvatar(
              backgroundColor: Color(0xff300005),
              child: Icon(Icons.person_outline, color: red),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  txt(name, weight: FontWeight.bold),
                  line(email),
                  tag(isAdmin ? 'Administrador' : 'Colaborador'),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: red),
          ],
        ),
      ),
      const SizedBox(height: 15),
      txt('Minha conta', size: 14),
      const SizedBox(height: 12),
      box(
        Column(
          children: [
            profileItem(
              'Dados pessoais',
              'Nome, e-mail e telefone',
              Icons.person_outline,
              () => form(
                'Dados pessoais',
                ['Nome', 'Telefone'],
                _updateProfile,
                defaults: [name, _user?['phone'] ?? ''],
              ),
            ),
            profileItem(
              'Segurança',
              'Senha e autenticação',
              Icons.lock_outline,
              () => form('Segurança', [
                'Senha atual',
                'Nova senha',
              ], _changePassword),
            ),
            profileItem(
              'Notificações',
              'Preferências de alertas',
              Icons.notifications_none,
              () => go('Notificações'),
            ),
            profileItem(
              'Aparência',
              'Tema do aplicativo',
              Icons.contrast,
              () => notice('Tema escuro do projeto selecionado.'),
            ),
            profileItem(
              'Idioma',
              'Português (Brasil)',
              Icons.language,
              () => notice('Português (Brasil) selecionado.'),
            ),
          ],
        ),
      ),
      const SizedBox(height: 10),
      txt('Empresa · $companyName'),
      const SizedBox(height: 12),
      box(
        Column(
          children: [
            profileItem(
              'Dados da empresa',
              'Informações cadastrais',
              Icons.business_outlined,
              () => notice('Empresa: $companyName'),
            ),
            profileItem(
              'Usuários e permissões',
              'Gerencie acessos e funções',
              Icons.people_outline,
              isAdmin
                  ? _team
                  : () => notice(
                      'Peça o código de equipe ao administrador da empresa.',
                    ),
            ),
            profileItem(
              'Integrações',
              'ERP, WMS e outros sistemas',
              Icons.hub_outlined,
              () => notice('Nenhuma integração externa conectada.'),
            ),
            profileItem(
              'Planos e assinatura',
              'Seu plano atual e faturas',
              Icons.credit_card,
              () => notice('Não há plano ou fatura vinculados.'),
            ),
          ],
        ),
      ),
      box(
        profileItem(
          'Resumo da sua operação',
          'Acompanhe o desempenho geral',
          Icons.insights,
          () => go('Dashboard'),
        ),
      ),
      SizedBox(
        width: double.infinity,
        child: button('Sair da conta', _logout, outline: true),
      ),
    ],
  );
  Widget profileItem(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback fn,
  ) => ListTile(
    contentPadding: EdgeInsets.zero,
    dense: true,
    leading: Icon(icon, size: 20, color: muted),
    title: txt(title, size: 12),
    subtitle: txt(subtitle, size: 10, color: muted),
    trailing: const Icon(Icons.chevron_right, size: 17, color: muted),
    onTap: fn,
  );
  void form(
    String title,
    List<String> labels,
    void Function(List<String>) saveFn, {
    List<String>? defaults,
    String save = 'Salvar',
  }) {
    final cs = List.generate(
      labels.length,
      (i) => TextEditingController(text: defaults == null ? '' : defaults[i]),
    );
    _dialogOpen = true;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: panel,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Expanded(child: txt(title, size: 17, weight: FontWeight.bold)),
            IconButton(
              onPressed: () => Navigator.pop(dialogContext),
              icon: const Icon(Icons.close, size: 17),
            ),
          ],
        ),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < labels.length; i++) field(labels[i], cs[i]),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: txt('Cancelar', size: 12, color: muted),
          ),
          button(save, () {
            if (cs.any((c) => c.text.trim().isEmpty)) {
              notice('Preencha todos os campos.');
              return;
            }
            saveFn(cs.map((c) => c.text.trim()).toList());
            Navigator.pop(dialogContext);
          }),
        ],
      ),
    ).whenComplete(() {
      _dialogOpen = false;
    });
  }
}

class TrendPainter extends CustomPainter {
  final List<double> values;
  const TrendPainter({this.values = const []});
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xff333333)
      ..strokeWidth = .6;
    for (int i = 0; i < 4; i++) {
      final y = i * (size.height - 25) / 3;
      canvas.drawLine(Offset(22, y), Offset(size.width, y), p);
      label(canvas, '${15 - i * 5}', Offset(0, y), 9, muted);
    }
    final vals = List<double>.generate(
      7,
      (i) => i < values.length ? values[i] : 0,
    );
    final path = Path();
    for (int i = 0; i < 7; i++) {
      final x = 25 + i * (size.width - 30) / 6,
          y = (15 - vals[i]) / 15 * (size.height - 30);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
      label(canvas, '${21 + i}/08', Offset(x - 13, size.height - 15), 8, muted);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = red
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

void label(
  Canvas c,
  String s,
  Offset o,
  double font,
  Color color, {
  double width = 100,
}) {
  final t = TextPainter(
    text: TextSpan(
      text: s,
      style: TextStyle(fontSize: font, color: color, fontFamily: 'Arial'),
    ),
    textDirection: TextDirection.ltr,
  );
  t.layout(maxWidth: width);
  t.paint(c, o);
}

class FactoryPainter extends CustomPainter {
  const FactoryPainter();
  @override
  void paint(Canvas c, Size s) {
    final blocks = [
      ('Almoxarifado A', .03, .22, .28, .18),
      ('Estoque 3', .36, .03, .27, .13),
      ('Linha de\nProdução 1', .73, .03, .24, .37),
      ('Corredor\nCentral', .35, .42, .29, .24),
      ('Setor de QA', .72, .43, .25, .13),
      ('Doca de\nRecebimento', .03, .69, .29, .27),
      ('Galpão\nB', .47, .79, .16, .17),
      ('Rampa\nExpedição', .69, .69, .28, .27),
    ];
    for (final b in blocks) {
      final r = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          b.$2 * s.width,
          b.$3 * s.height,
          b.$4 * s.width,
          b.$5 * s.height,
        ),
        const Radius.circular(5),
      );
      c.drawRRect(r, Paint()..color = Colors.black);
      label(
        c,
        b.$1,
        Offset(r.left + 8, r.top + 15),
        11,
        Colors.white,
        width: r.width - 12,
      );
    }
    for (final pos in [
      (.39, .2),
      (.45, .28),
      (.17, .5),
      (.22, .55),
      (.81, .15),
      (.86, .2),
      (.55, .5),
    ]) {
      c.drawCircle(
        Offset(pos.$1 * s.width, pos.$2 * s.height),
        3,
        Paint()..color = red,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class BarPainter extends CustomPainter {
  const BarPainter();
  @override
  void paint(Canvas c, Size s) {
    for (int i = 0; i < 5; i++) {
      final y = i * (s.height - 25) / 4;
      label(c, '${8 - i * 2}', Offset(0, y), 9, muted);
    }
    for (int i = 0; i < 2; i++) {
      final x = 45 + i * s.width * .48;
      for (int j = 0; j < 2; j++) {
        final h =
            (j == 0
                ? 4
                : i == 0
                ? 8
                : 6) /
            8 *
            (s.height - 30);
        c.drawRect(
          Rect.fromLTWH(x + j * 36, s.height - 25 - h, 31, h),
          Paint()..color = j == 0 ? Colors.white : red,
        );
      }
      label(
        c,
        i == 0 ? 'Almoxarifado → Linha A' : 'Recebimento → Estoque',
        Offset(x - 10, s.height - 16),
        8,
        muted,
        width: s.width * .45,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
