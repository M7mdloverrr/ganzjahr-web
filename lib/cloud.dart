import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

import 'models.dart';
import 'storage/storage.dart';
import 'store.dart';

/// Canonical JSON (sorted keys) so equal data always compares equal.
String canonical(Object? v) {
  Object? norm(Object? x) {
    if (x is Map) {
      final keys = x.keys.map((k) => '$k').toList()..sort();
      return {for (final k in keys) k: norm(x[k])};
    }
    if (x is List) return x.map(norm).toList();
    return x;
  }

  return jsonEncode(norm(v));
}

class CloudException implements Exception {
  CloudException(this.code);

  /// short, wrong, exists, noaccount, locked, storage, auth, offline
  final String code;

  @override
  String toString() => 'CloudException($code)';
}

/// Keeps company, customers, services and documents on the GanzJahr server (website /api/sync).
/// Changes made offline stay queued on the device and are uploaded once there is internet.
class CloudSync extends ChangeNotifier with WidgetsBindingObserver {
  CloudSync(this.store, {http.Client? client, Uri? server}) : _http = client ?? http.Client(), server = server ?? defaultServer;

  static Uri get defaultServer =>
      kIsWeb && Uri.base.scheme.startsWith('http') ? Uri.parse('${Uri.base.origin}/') : Uri.parse('https://ganzjahr-web.vercel.app/');

  final Store store;
  final Uri server;
  final http.Client _http;

  String? _token;
  int _rev = -1;

  /// Last data known to be on the server: key -> canonical JSON.
  Map<String, String> _base = {};

  bool get signedIn => _token != null;
  bool? storageReady;
  bool? hasAccount;
  bool online = true;
  bool pending = false;
  DateTime? lastSync;

  /// Set by the UI: decides what to do when both this device and the cloud already have data.
  Future<bool> Function()? askUseCloud;

  static const _stateFile = 'cloud_state.json';
  Timer? _timer;
  Timer? _debounce;
  Completer<void>? _running;
  bool _again = false;

  Future<void> init() async {
    try {
      final raw = await readData(_stateFile);
      if (raw != null) {
        final j = jsonDecode(raw) as Map<String, dynamic>;
        _token = j['token'] as String?;
        _rev = j['rev'] as int? ?? -1;
        _base = Map<String, String>.from(j['base'] as Map? ?? {});
        final t = j['lastSync'] as String?;
        lastSync = t == null ? null : DateTime.tryParse(t);
      }
    } catch (e) {
      debugPrint('Cloud state unreadable: $e');
    }
    if (_token != null) _start();
  }

  Future<void> _saveState() async {
    try {
      await writeData(_stateFile, jsonEncode({'token': _token, 'rev': _rev, 'base': _base, 'lastSync': lastSync?.toIso8601String()}));
    } catch (e) {
      debugPrint('Cloud state not saved: $e');
    }
  }

  void _start() {
    store.onLocalChange = _schedule;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 20), (_) => sync());
    WidgetsBinding.instance.removeObserver(this);
    WidgetsBinding.instance.addObserver(this);
    unawaited(sync());
  }

  void _stop() {
    store.onLocalChange = null;
    _timer?.cancel();
    _debounce?.cancel();
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(sync());
  }

  void _schedule() {
    pending = true;
    notifyListeners();
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 700), sync);
  }

  Uri _api(String path, [Map<String, String>? query]) => server.resolve(path).replace(queryParameters: query);

  Map<String, String> get _headers => {'Content-Type': 'application/json', if (_token != null) 'Authorization': 'Bearer $_token'};

  Future<Map<String, dynamic>> _call(String method, String path, {Object? body, Map<String, String>? query}) async {
    final http.Response res;
    try {
      final req = http.Request(method, _api(path, query))..headers.addAll(_headers);
      if (body != null) req.body = jsonEncode(body);
      res = await http.Response.fromStream(await _http.send(req).timeout(const Duration(seconds: 20)));
    } catch (_) {
      throw CloudException('offline');
    }
    Map<String, dynamic> j;
    try {
      j = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      throw CloudException('offline');
    }
    if (res.statusCode >= 400) throw CloudException(j['error'] as String? ?? 'offline');
    return j;
  }

  /// Asks the server whether the database is switched on and whether the company account exists.
  Future<void> refreshStatus() async {
    try {
      final j = await _call('GET', 'api/sync/login');
      storageReady = j['storage'] as bool?;
      hasAccount = j['account'] as bool?;
      online = true;
    } on CloudException {
      online = false;
    }
    notifyListeners();
  }

  Future<void> signIn(String user, String password, {bool create = false}) async {
    final j = await _call('POST', 'api/sync/login', body: {'user': user.trim(), 'password': password, 'create': create});
    _token = j['token'] as String;
    hasAccount = true;
    try {
      await _firstSync();
    } catch (e) {
      _token = null;
      rethrow;
    }
    await _saveState();
    _start();
    notifyListeners();
  }

  Future<void> signOut() async {
    _stop();
    try {
      await _call('DELETE', 'api/sync/login');
    } catch (_) {}
    _token = null;
    _base = {};
    _rev = -1;
    pending = false;
    await _saveState();
    notifyListeners();
  }

  Map<String, Map<String, dynamic>> _local() => {
    'meta/company': store.company.toJson(),
    for (final c in store.customers) 'customers/${c.id}': c.toJson(),
    for (final c in store.catalog) 'catalog/${c.id}': c.toJson(),
    for (final d in store.documents) 'documents/${d.id}': d.toJson(),
  };

  Future<(int, Map<String, Map<String, dynamic>>?)> _fetch({bool full = false}) async {
    final j = await _call('GET', 'api/sync', query: full || _rev < 0 ? null : {'since': '$_rev'});
    final items = j['items'] as Map<String, dynamic>?;
    return (j['rev'] as int, items?.map((k, v) => MapEntry(k, Map<String, dynamic>.from(jsonDecode(v as String) as Map))));
  }

  Future<void> _firstSync() async {
    final (rev, cloud) = await _fetch(full: true);
    final remote = cloud ?? {};
    final deviceHasData = store.customers.isNotEmpty || store.documents.isNotEmpty;
    if (remote.isNotEmpty) {
      final useCloud = !deviceHasData || await (askUseCloud?.call() ?? Future.value(true));
      if (useCloud) {
        _apply(remote);
      } else {
        _merge(remote);
      }
    }
    _base = remote.map((k, v) => MapEntry(k, canonical(v)));
    _rev = rev;
    await _syncOnce();
  }

  /// Local changes since the last known server state.
  (Map<String, String>, List<String>) _diff() {
    final local = _local();
    final set = <String, String>{};
    for (final e in local.entries) {
      final c = canonical(e.value);
      if (_base[e.key] != c) set[e.key] = c;
    }
    final del = _base.keys.where((k) => !local.containsKey(k)).toList();
    return (set, del);
  }

  /// Uploads local changes and downloads changes from other devices.
  Future<void> sync() {
    if (_token == null) return Future.value();
    final running = _running;
    if (running != null) {
      _again = true;
      return running.future;
    }
    final done = _running = Completer<void>();
    () async {
      try {
        do {
          _again = false;
          await _syncOnce();
        } while (_again && _token != null);
        online = true;
      } on CloudException catch (e) {
        online = false;
        if (e.code == 'auth') {
          _stop();
          _token = null;
          _base = {};
          _rev = -1;
          await _saveState();
        }
      } finally {
        _running = null;
        notifyListeners();
        done.complete();
      }
    }();
    return done.future;
  }

  Future<void> _syncOnce() async {
    final (set, del) = _diff();
    pending = set.isNotEmpty || del.isNotEmpty;
    final entries = set.entries.toList();
    for (var i = 0; i < entries.length || (i == 0 && del.isNotEmpty); i += 100) {
      final chunk = Map.fromEntries(entries.skip(i).take(100));
      await _call('POST', 'api/sync', body: {'set': chunk, 'del': i == 0 ? del : <String>[]});
      _base.addAll(chunk);
      if (i == 0) del.forEach(_base.remove);
    }
    final (rev, cloud) = await _fetch(full: pending);
    if (cloud != null) {
      final (s, d) = _diff();
      if (s.isNotEmpty || d.isNotEmpty) {
        _again = true;
        return;
      }
      _apply(cloud);
      _base = cloud.map((k, v) => MapEntry(k, canonical(v)));
    }
    _rev = rev;
    pending = false;
    lastSync = DateTime.now();
    await _saveState();
  }

  void _merge(Map<String, Map<String, dynamic>> cloud) {
    final local = _local();
    final remoteCompany = cloud['meta/company'];
    store.applyRemote(() {
      for (final e in cloud.entries) {
        if (local.containsKey(e.key) || e.key == 'meta/company') continue;
        final (col, _) = _split(e.key);
        switch (col) {
          case 'customers':
            store.customers.add(Customer.fromJson(e.value));
          case 'catalog':
            store.catalog.add(CatalogItem.fromJson(e.value));
          case 'documents':
            store.documents.add(Document.fromJson(e.value));
        }
      }
      if (remoteCompany != null) {
        final rc = Company.fromJson(remoteCompany);
        final c = store.company;
        if (c.name.trim().isEmpty) store.company = rc;
        store.company
          ..nextInvoiceNo = [c.nextInvoiceNo, rc.nextInvoiceNo].reduce((a, b) => a > b ? a : b)
          ..nextQuoteNo = [c.nextQuoteNo, rc.nextQuoteNo].reduce((a, b) => a > b ? a : b)
          ..nextCustomerNo = [c.nextCustomerNo, rc.nextCustomerNo].reduce((a, b) => a > b ? a : b);
      }
    });
  }

  (String, String) _split(String key) {
    final i = key.indexOf('/');
    return (key.substring(0, i), key.substring(i + 1));
  }

  /// Replaces local data with the server state, keeping unchanged objects as they are.
  void _apply(Map<String, Map<String, dynamic>> cloud) {
    List<T> merge<T>(
      String col,
      List<T> current,
      String Function(T) id,
      T Function(Map<String, dynamic>) parse,
      Map<String, dynamic> Function(T) json,
    ) {
      final byId = {for (final x in current) id(x): x};
      final out = <T>[];
      for (final e in cloud.entries) {
        final (c, docId) = _split(e.key);
        if (c != col) continue;
        final old = byId[docId];
        out.add(old != null && canonical(json(old)) == canonical(e.value) ? old : parse(e.value));
      }
      return out;
    }

    final local = _local();
    final same = local.length == cloud.length && cloud.entries.every((e) => local[e.key] != null && canonical(local[e.key]) == canonical(e.value));
    if (same) return;
    store.applyRemote(() {
      final company = cloud['meta/company'];
      if (company != null && canonical(store.company.toJson()) != canonical(company)) {
        store.company = Company.fromJson(company);
      }
      store.customers = merge('customers', store.customers, (c) => c.id, Customer.fromJson, (c) => c.toJson());
      store.catalog = merge('catalog', store.catalog, (c) => c.id, CatalogItem.fromJson, (c) => c.toJson());
      store.documents = merge('documents', store.documents, (d) => d.id, Document.fromJson, (d) => d.toJson());
    });
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }
}
