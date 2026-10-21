import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_brand_mark.dart';
import '../../../core/widgets/app_icon_tile.dart';

class NewPasswordScreen extends StatefulWidget {
  const NewPasswordScreen({
    super.key,
    required this.onUpdate,
    required this.onComplete,
  });

  final Future<void> Function(String password) onUpdate;
  final VoidCallback onComplete;

  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onUpdate(_passwordController.text);
      if (mounted) widget.onComplete();
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not update your password. Try again.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final pageGutter = AppTheme.pageGutterFor(MediaQuery.sizeOf(context).width);
    return Scaffold(
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(pageGutter, 48, pageGutter, 32),
              child: Form(
                key: _formKey,
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.lightSlate),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppBrandMark(),
                      const SizedBox(height: 30),
                      const AppIconTile(
                        icon: Icons.lock_reset_outlined,
                        color: AppColors.indigo,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Choose a new password',
                        style: textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Use at least 8 characters and keep it somewhere safe.',
                        style: textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        key: const Key('newPasswordField'),
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'New password',
                        ),
                        validator: (value) => (value?.length ?? 0) >= 8
                            ? null
                            : 'Use at least 8 characters',
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        key: const Key('confirmNewPasswordField'),
                        controller: _confirmationController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Confirm new password',
                        ),
                        validator: (value) =>
                            value == _passwordController.text &&
                                (value?.isNotEmpty ?? false)
                            ? null
                            : 'Passwords do not match',
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _saving ? null : _save,
                          child: Text(
                            _saving ? 'Saving…' : 'Save new password',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
