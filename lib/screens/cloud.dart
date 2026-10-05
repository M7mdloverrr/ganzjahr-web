import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../cloud.dart';
import '../format.dart';
import '../i18n.dart';
import '../theme.dart';
import '../widgets.dart';

class CloudScreen extends StatefulWidget {
  const CloudScreen({super.key});

  @override
  State<CloudScreen> createState() => _CloudScreenState();
}

class _CloudScreenState extends State<CloudScreen> {
  final _user = TextEditingController();
  final _password = TextEditingController();
  final _form = GlobalKey<FormState>();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<CloudSync>().refreshStatus());
  }

  @override
  void dispose() {
    _user.dispose();
    _password.dispose();
    super.dispose();
  }

  String _error(Object e) => switch (e is CloudException ? e.code : '') {
    'wrong' => 'Wrong username or password'.tr,
    'user' => 'Please enter your username'.tr,
    'short' => 'At least 6 characters'.tr,
    'exists' => 'The account already exists. Please sign in.'.tr,
    'noaccount' => 'No account yet. Please create one first.'.tr,
    'locked' => 'Too many attempts. Try again in 15 minutes.'.tr,
    'storage' => 'The cloud database is not switched on yet.'.tr,
    'offline' => 'No internet connection'.tr,
    _ => '$e',
  };

  Future<void> _signIn({required bool create}) async {
    if (!_form.currentState!.validate()) return;
    final cloud = context.read<CloudSync>();
    cloud.askUseCloud = () async {
      final r = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: Text('Cloud already has data'.tr),
          content: Text('This phone also has data. Use only the cloud data, or merge both?'.tr),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Merge both'.tr)),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Use cloud data'.tr)),
          ],
        ),
      );
      return r ?? true;
    };
    setState(() => _busy = true);
    try {
      await cloud.signIn(_user.text, _password.text, create: create);
      _password.clear();
      if (mounted) toast(context, 'All data is saved in the cloud.'.tr);
    } catch (e) {
      if (mounted) toast(context, _error(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cloud = context.watch<CloudSync>();
    final signedIn = cloud.signedIn;
    final create = cloud.hasAccount == false;
    return Scaffold(
      appBar: AppBar(title: Text('Cloud sync'.tr)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: (!signedIn ? Colors.black12 : brandGreen.withValues(alpha: 0.2)),
                    child: Icon(
                      !signedIn ? Icons.cloud_off_rounded : (cloud.pending || !cloud.online ? Icons.cloud_upload_rounded : Icons.cloud_done_rounded),
                      color: !signedIn ? Colors.black45 : brandGreenDark,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          !signedIn ? 'Not signed in'.tr : 'Connected to the GanzJahr cloud'.tr,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        if (signedIn)
                          Text(
                            !cloud.online
                                ? 'Waiting for internet…'.tr
                                : cloud.lastSync == null
                                ? ''
                                : 'Last synced {t}'.trf({'t': dmyHm(cloud.lastSync!)}),
                            style: const TextStyle(color: Colors.black54, fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'All customers, invoices and settings are saved on your GanzJahr server. Sign in with the same password in the phone app and on the website – everything stays in sync automatically, even after working offline.'
                .tr,
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 16),
          if (signedIn) ...[
            FilledButton.tonalIcon(icon: const Icon(Icons.sync_rounded), label: Text('Sync now'.tr), onPressed: cloud.sync),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.logout_rounded),
              label: Text('Sign out'.tr),
              onPressed: () async {
                if (await confirm(context, 'Sign out'.tr, 'Sign out of the cloud? Data stays on this phone.'.tr, ok: 'Sign out'.tr)) {
                  await cloud.signOut();
                }
              },
            ),
          ] else if (cloud.storageReady == false)
            Card(
              color: const Color(0xFFFFF7E6),
              child: Padding(padding: const EdgeInsets.all(14), child: Text('The cloud database is not switched on yet.'.tr)),
            )
          else
            Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (create) ...[
                    Text('First time: choose a password for your company account.'.tr, style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                  ],
                  TextFormField(
                    controller: _user,
                    autocorrect: false,
                    autofillHints: const [AutofillHints.username],
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(labelText: 'Username'.tr, prefixIcon: const Icon(Icons.person_outline_rounded)),
                    validator: (v) => (v ?? '').trim().isNotEmpty ? null : 'Please enter your username'.tr,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _password,
                    obscureText: true,
                    autofillHints: const [AutofillHints.password],
                    decoration: InputDecoration(labelText: 'Password'.tr, prefixIcon: const Icon(Icons.lock_outline_rounded)),
                    validator: (v) => (v ?? '').length >= 6 ? null : 'At least 6 characters'.tr,
                    onFieldSubmitted: (_) => _signIn(create: create),
                  ),
                  const SizedBox(height: 16),
                  if (_busy)
                    const Center(child: CircularProgressIndicator())
                  else if (create)
                    FilledButton.icon(
                      icon: const Icon(Icons.person_add_alt_1_rounded),
                      label: Text('Create account'.tr),
                      onPressed: () => _signIn(create: true),
                    )
                  else
                    FilledButton.icon(icon: const Icon(Icons.login_rounded), label: Text('Sign in'.tr), onPressed: () => _signIn(create: false)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
