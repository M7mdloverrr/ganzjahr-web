import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ganzjahr_rechnung/cloud.dart';
import 'package:ganzjahr_rechnung/models.dart';
import 'package:ganzjahr_rechnung/store.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// In-memory copy of the website's /api/sync endpoints.
class FakeServer {
  String? password;
  final tokens = <String>{};
  final data = <String, String>{};
  int rev = 0;

  http.Response _json(Object body, [int status = 200]) => http.Response(jsonEncode(body), status);

  late final client = MockClient((req) async {
    final body = req.body.isEmpty ? <String, dynamic>{} : jsonDecode(req.body) as Map<String, dynamic>;
    final authed = tokens.contains(req.headers['Authorization']?.replaceFirst('Bearer ', ''));
    switch ((req.method, req.url.path)) {
      case ('GET', '/api/sync/login'):
        return _json({'storage': true, 'account': password != null});
      case ('POST', '/api/sync/login'):
        if (body['create'] == true) {
          if (password != null) return _json({'error': 'exists'}, 409);
          password = body['password'] as String;
        } else if (password != body['password']) {
          return _json({'error': 'wrong'}, 401);
        }
        final t = 'tok${tokens.length}';
        tokens.add(t);
        return _json({'token': t});
      case ('GET', '/api/sync'):
        if (!authed) return _json({'error': 'auth'}, 401);
        final since = req.url.queryParameters['since'];
        if (since != null && int.parse(since) == rev) return _json({'rev': rev});
        return _json({'rev': rev, 'items': data});
      case ('POST', '/api/sync'):
        if (!authed) return _json({'error': 'auth'}, 401);
        data.addAll(Map<String, String>.from(body['set'] as Map));
        for (final k in body['del'] as List) {
          data.remove(k);
        }
        return _json({'rev': ++rev});
    }
    return _json({'error': 'not found'}, 404);
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('phone and website share the same data through the server', () async {
    final server = FakeServer();
    final phone = Store();
    final web = Store();
    final phoneCloud = CloudSync(phone, client: server.client, server: Uri.parse('https://x.test/'));
    final webCloud = CloudSync(web, client: server.client, server: Uri.parse('https://x.test/'));

    await phoneCloud.refreshStatus();
    expect(phoneCloud.hasAccount, false);
    phone.upsertCustomer(Customer(id: 'c1', number: 'K1', name: 'Anna Schmidt'));
    await phoneCloud.signIn('geheim123', create: true);
    expect(server.data.keys, contains('customers/c1'));

    await expectLater(webCloud.signIn('falsch!!'), throwsA(isA<CloudException>().having((e) => e.code, 'code', 'wrong')));
    await webCloud.signIn('geheim123');
    expect(web.customers.single.name, 'Anna Schmidt');

    web.upsertCustomer(Customer(id: 'c2', number: 'K2', name: 'Bernd Müller'));
    web.upsertCustomer(Customer(id: 'c1', number: 'K1', name: 'Anna Schmidt-Weber'));
    await webCloud.sync();
    await phoneCloud.sync();
    expect(phone.customers.map((c) => c.name), unorderedEquals(['Anna Schmidt-Weber', 'Bernd Müller']));

    phone.deleteCustomer('c2');
    await phoneCloud.sync();
    await webCloud.sync();
    expect(web.customers.map((c) => c.id), ['c1']);
    expect(phoneCloud.pending, false);

    final revBefore = server.rev;
    await phoneCloud.sync();
    await webCloud.sync();
    expect(server.rev, revBefore, reason: 'no uploads without changes');

    phoneCloud.dispose();
    webCloud.dispose();
  });
}
