import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
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
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _form = GlobalKey<FormState>();
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  String _authError(Object e) {
    if (e is FirebaseAuthException) {
      return switch (e.code) {
        'invalid-credential' || 'wrong-password' || 'user-not-found' || 'invalid-email' => 'Wrong email or password'.tr,
        'email-already-in-use' => 'This email already has an account'.tr,
        'weak-password' => 'At least 6 characters'.tr,
        'network-request-failed' => 'No internet connection'.tr,
        _ => e.message ?? e.code,
      };
    }
    return '$e';
  }

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
      await cloud.signIn(_email.text.trim(), _password.text, create: create);
      if (mounted) toast(context, 'All data is saved in the cloud.'.tr);
    } catch (e) {
      if (mounted) toast(context, _authError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _pasteConfig() {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Connect cloud'.tr),
        content: TextField(
          controller: ctrl,
          maxLines: 8,
          decoration: InputDecoration(hintText: 'Paste the firebaseConfig from Firebase here'.tr, border: const OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel'.tr)),
          FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: Text('Connect cloud'.tr)),
        ],
      ),
    );
  }

  Future<void> _connect() async {
    String raw;
    if (kIsWeb) {
      final pasted = await _pasteConfig();
      if (pasted == null || pasted.trim().isEmpty || !mounted) return;
      raw = pasted;
    } else {
      final files = await FilePicker.pickFiles(dialogTitle: 'Choose google-services.json'.tr, type: FileType.any);
      if (files.isEmpty || !mounted) return;
      raw = utf8.decode(await files.first.readAsBytes());
    }
    setState(() => _busy = true);
    try {
      if (!mounted) return;
      await context.read<CloudSync>().connect(raw);
      if (mounted) toast(context, 'Cloud connected. Now sign in or create an account.'.tr);
    } catch (e) {
      if (mounted) toast(context, (kIsWeb ? 'This is not a valid Firebase config.' : 'This is not a valid google-services.json file.').tr);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reset() async {
    if (_email.text.trim().isEmpty) {
      toast(context, 'Enter your email first.'.tr);
      return;
    }
    try {
      await context.read<CloudSync>().resetPassword(_email.text.trim());
      if (mounted) toast(context, 'Password reset email sent.'.tr);
    } catch (e) {
      if (mounted) toast(context, _authError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cloud = context.watch<CloudSync>();
    final user = cloud.user;
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
                    backgroundColor: (user == null ? Colors.black12 : brandGreen.withValues(alpha: 0.2)),
                    child: Icon(
                      user == null ? Icons.cloud_off_rounded : (cloud.pending ? Icons.cloud_upload_rounded : Icons.cloud_done_rounded),
                      color: user == null ? Colors.black45 : brandGreenDark,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user == null ? 'Not signed in'.tr : 'Synced as {e}'.trf({'e': user.email ?? ''}),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        if (user != null)
                          Text(
                            cloud.pending
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
            'Sign in with the same account on every phone or tablet – all customers, invoices and settings are saved in the cloud and stay in sync automatically, even after working offline.'
                .tr,
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 16),
          if (!cloud.available) ...[
            Card(
              color: const Color(0xFFFFF7E6),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  (kIsWeb
                          ? 'Cloud is not connected yet. Create a free Firebase project with any Google account (console.firebase.google.com), turn on Email/Password login and Firestore, add a Web app (</> icon), copy the firebaseConfig and paste it here.'
                          : 'Cloud is not connected yet. Create a free Firebase project with any Google account (console.firebase.google.com), add an Android app with the package name de.ganzjahr.ganzjahr_rechnung, turn on Email/Password login and Firestore, download google-services.json and load it here.')
                      .tr,
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_busy)
              const Center(child: CircularProgressIndicator())
            else
              FilledButton.icon(icon: const Icon(Icons.cloud_upload_rounded), label: Text('Connect cloud'.tr), onPressed: _connect),
          ] else if (user != null)
            OutlinedButton.icon(
              icon: const Icon(Icons.logout_rounded),
              label: Text('Sign out'.tr),
              onPressed: () async {
                if (await confirm(context, 'Sign out'.tr, 'Sign out of the cloud? Data stays on this phone.'.tr, ok: 'Sign out'.tr)) {
                  await cloud.signOut();
                }
              },
            )
          else
            Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: InputDecoration(labelText: 'Email'.tr, prefixIcon: const Icon(Icons.mail_outline_rounded)),
                    validator: (v) => (v ?? '').contains('@') ? null : 'Required'.tr,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _password,
                    obscureText: true,
                    autofillHints: const [AutofillHints.password],
                    decoration: InputDecoration(labelText: 'Password'.tr, prefixIcon: const Icon(Icons.lock_outline_rounded)),
                    validator: (v) => (v ?? '').length >= 6 ? null : 'At least 6 characters'.tr,
                  ),
                  const SizedBox(height: 16),
                  if (_busy)
                    const Center(child: CircularProgressIndicator())
                  else ...[
                    FilledButton.icon(icon: const Icon(Icons.login_rounded), label: Text('Sign in'.tr), onPressed: () => _signIn(create: false)),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.person_add_alt_1_rounded),
                      label: Text('Create account'.tr),
                      onPressed: () => _signIn(create: true),
                    ),
                    TextButton(onPressed: _reset, child: Text('Forgot password?'.tr)),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
