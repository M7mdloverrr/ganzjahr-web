import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

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
    if (x is Timestamp) return x.toDate().toIso8601String();
    return x;
  }

  return jsonEncode(norm(v));
}

Map<String, dynamic> _plain(Map<String, dynamic> m) => jsonDecode(canonical(m)) as Map<String, dynamic>;

const _collections = ['customers', 'catalog', 'documents'];

/// Keeps company, customers, services and documents in Firestore under users/{uid}.
/// Firestore's offline cache queues changes made without internet and uploads them later.
class CloudSync extends ChangeNotifier {
  CloudSync(this.store);

  final Store store;
  bool available = false;
  User? user;
  bool ready = false;
  bool pending = false;
  DateTime? lastSync;

  final Map<String, String> _remote = {};
  final List<StreamSubscription<Object?>> _subs = [];

  /// Set by the UI: decides what to do when both the phone and the cloud already have data.
  Future<bool> Function()? askUseCloud;

  FirebaseFirestore get _db => FirebaseFirestore.instance;
  DocumentReference<Map<String, dynamic>> get _root => _db.collection('users').doc(user!.uid);

  static const androidPackage = 'de.ganzjahr.ganzjahr_rechnung';

  static const _configFile = 'cloud_config.json';

  /// Firebase setup text the user pasted; can be copied to the next device.
  String? config;

  /// Reads Firebase settings from a google-services.json file (Android)
  /// or from the firebaseConfig snippet of a Firebase web app.
  static FirebaseOptions optionsFromConfig(String raw) {
    if (raw.contains('project_info')) return optionsFromGoogleServices(raw);
    final v = {for (final m in RegExp(r'''["']?(\w+)["']?\s*:\s*["']([^"']*)["']''').allMatches(raw)) m.group(1)!: m.group(2)!};
    for (final k in ['apiKey', 'appId', 'projectId', 'messagingSenderId']) {
      if ((v[k] ?? '').isEmpty) throw FormatException('Missing $k');
    }
    return FirebaseOptions(
      apiKey: v['apiKey']!,
      appId: v['appId']!,
      messagingSenderId: v['messagingSenderId']!,
      projectId: v['projectId']!,
      authDomain: v['authDomain'],
      storageBucket: v['storageBucket'],
    );
  }

  /// Reads the Firebase settings from a google-services.json file.
  static FirebaseOptions optionsFromGoogleServices(String raw) {
    final j = jsonDecode(raw) as Map<String, dynamic>;
    final project = j['project_info'] as Map<String, dynamic>;
    final clients = (j['client'] as List).cast<Map<String, dynamic>>();
    final client = clients.firstWhere(
      (c) => c['client_info']?['android_client_info']?['package_name'] == androidPackage,
      orElse: () => clients.first,
    );
    return FirebaseOptions(
      apiKey: (client['api_key'] as List).first['current_key'] as String,
      appId: client['client_info']['mobilesdk_app_id'] as String,
      messagingSenderId: '${project['project_number']}',
      projectId: project['project_id'] as String,
      storageBucket: project['storage_bucket'] as String?,
    );
  }

  Future<void> init() async {
    try {
      final saved = await readData(_configFile);
      config = saved;
      if (saved != null) {
        await Firebase.initializeApp(options: optionsFromConfig(saved)).timeout(const Duration(seconds: 8));
      } else if (kIsWeb) {
        return;
      } else {
        await Firebase.initializeApp().timeout(const Duration(seconds: 8));
      }
      available = true;
    } catch (e) {
      debugPrint('Cloud sync not set up: $e');
      return;
    }
    _start();
  }

  /// Connects the app to a Firebase project chosen later by the user.
  Future<void> connect(String config) async {
    final options = optionsFromConfig(config);
    await Firebase.initializeApp(options: options);
    await writeData(_configFile, config);
    this.config = config;
    available = true;
    _start();
  }

  void _start() {
    store.onLocalChange = push;
    user = FirebaseAuth.instance.currentUser;
    if (user != null) _listen();
    notifyListeners();
  }

  Future<void> signIn(String email, String password, {bool create = false}) async {
    final auth = FirebaseAuth.instance;
    final cred = create
        ? await auth.createUserWithEmailAndPassword(email: email, password: password)
        : await auth.signInWithEmailAndPassword(email: email, password: password);
    user = cred.user;
    notifyListeners();
    await _firstSync();
  }

  Future<void> resetPassword(String email) => FirebaseAuth.instance.sendPasswordResetEmail(email: email);

  Future<void> signOut() async {
    await _stop();
    await FirebaseAuth.instance.signOut();
    user = null;
    ready = false;
    _remote.clear();
    notifyListeners();
  }

  Map<String, Map<String, dynamic>> _local() => {
    'meta/company': store.company.toJson(),
    for (final c in store.customers) 'customers/${c.id}': c.toJson(),
    for (final c in store.catalog) 'catalog/${c.id}': c.toJson(),
    for (final d in store.documents) 'documents/${d.id}': d.toJson(),
  };

  Future<Map<String, Map<String, dynamic>>> _fetchAll() async {
    final out = <String, Map<String, dynamic>>{};
    final company = await _root.collection('meta').doc('company').get();
    if (company.exists) out['meta/company'] = _plain(company.data()!);
    for (final col in _collections) {
      for (final doc in (await _root.collection(col).get()).docs) {
        out['$col/${doc.id}'] = _plain(doc.data());
      }
    }
    return out;
  }

  Future<void> _firstSync() async {
    final cloud = await _fetchAll();
    final phoneHasData = store.customers.isNotEmpty || store.documents.isNotEmpty;
    if (cloud.isNotEmpty) {
      final useCloud = !phoneHasData || await (askUseCloud?.call() ?? Future.value(true));
      _remote
        ..clear()
        ..addAll(cloud.map((k, v) => MapEntry(k, canonical(v))));
      if (useCloud) {
        _apply(cloud);
      } else {
        _merge(cloud);
      }
    }
    ready = true;
    push();
    _listen();
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

  /// Replaces local data with the cloud state, keeping unchanged objects as they are.
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

  /// Uploads everything that changed locally since the last known cloud state.
  void push() {
    if (user == null || !ready) return;
    final local = _local().map((k, v) => MapEntry(k, (v, canonical(v))));
    final ops = <void Function(WriteBatch)>[];
    for (final e in local.entries) {
      if (_remote[e.key] == e.value.$2) continue;
      final ref = _root.collection(_split(e.key).$1).doc(_split(e.key).$2);
      final data = e.value.$1;
      ops.add((b) => b.set(ref, data));
      _remote[e.key] = e.value.$2;
    }
    for (final key in _remote.keys.where((k) => !local.containsKey(k)).toList()) {
      final ref = _root.collection(_split(key).$1).doc(_split(key).$2);
      ops.add((b) => b.delete(ref));
      _remote.remove(key);
    }
    for (var i = 0; i < ops.length; i += 400) {
      final batch = _db.batch();
      for (final op in ops.skip(i).take(400)) {
        op(batch);
      }
      unawaited(batch.commit().catchError((Object e) => debugPrint('Cloud upload failed: $e')));
    }
  }

  final Map<String, QuerySnapshot<Map<String, dynamic>>> _snaps = {};
  DocumentSnapshot<Map<String, dynamic>>? _companySnap;

  void _listen() {
    _stop();
    _subs.add(
      _root.collection('meta').doc('company').snapshots(includeMetadataChanges: true).listen((s) {
        _companySnap = s;
        _onSnapshot();
      }),
    );
    for (final col in _collections) {
      _subs.add(
        _root.collection(col).snapshots(includeMetadataChanges: true).listen((s) {
          _snaps[col] = s;
          _onSnapshot();
        }),
      );
    }
  }

  void _onSnapshot() {
    if (_companySnap == null || _snaps.length < _collections.length) return;
    final cloud = <String, Map<String, dynamic>>{};
    if (_companySnap!.exists) cloud['meta/company'] = _plain(_companySnap!.data()!);
    for (final e in _snaps.entries) {
      for (final d in e.value.docs) {
        cloud['${e.key}/${d.id}'] = _plain(d.data());
      }
    }
    final metas = [_companySnap!.metadata, ..._snaps.values.map((s) => s.metadata)];
    pending = metas.any((m) => m.hasPendingWrites);
    if (!pending && metas.every((m) => !m.isFromCache)) lastSync = DateTime.now();
    if (!pending) {
      _remote
        ..clear()
        ..addAll(cloud.map((k, v) => MapEntry(k, canonical(v))));
      if (cloud.isNotEmpty) _apply(cloud);
      ready = true;
    }
    notifyListeners();
  }

  Future<void> _stop() async {
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
    _snaps.clear();
    _companySnap = null;
  }
}
