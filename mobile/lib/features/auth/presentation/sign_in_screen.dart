import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luqa/app/theme_mode_controller.dart';
import 'package:luqa/design_system/luqa_tokens.dart';
import 'package:luqa/features/auth/application/auth_controller.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_formKey.currentState!.validate()) return;
    await HapticFeedback.selectionClick();
    await ref
        .read(authControllerProvider.notifier)
        .signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final theme = Theme.of(context);
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final error = auth.error;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 48,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: AutofillGroup(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Align(
                            alignment: Alignment.centerRight,
                            child: IconButton(
                              tooltip: 'Toggle appearance',
                              onPressed: () => ref
                                  .read(themeModeProvider.notifier)
                                  .select(
                                    theme.brightness == Brightness.dark
                                        ? ThemeMode.light
                                        : ThemeMode.dark,
                                  ),
                              icon: Icon(
                                theme.brightness == Brightness.dark
                                    ? Icons.light_mode_outlined
                                    : Icons.dark_mode_outlined,
                              ),
                            ),
                          ),
                          const SizedBox(height: LuqaSpacing.xl),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(
                                  LuqaRadii.control,
                                ),
                              ),
                              child: SizedBox.square(
                                dimension: 52,
                                child: Center(
                                  child: Text(
                                    'L',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      color: theme.colorScheme.onPrimary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: LuqaSpacing.xxl),
                          Text(
                            'Your life,\nin one place.',
                            style: theme.textTheme.displaySmall,
                          ),
                          const SizedBox(height: LuqaSpacing.lg),
                          Text(
                            'Sign in to sync your timeline with Luqa.',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: LuqaSpacing.xxl),
                          TextFormField(
                            key: const ValueKey('email-field'),
                            controller: _emailController,
                            enabled: !auth.isLoading,
                            autofillHints: const [AutofillHints.email],
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autocorrect: false,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.alternate_email_rounded),
                            ),
                            validator: (value) {
                              final email = value?.trim() ?? '';
                              return email.contains('@')
                                  ? null
                                  : 'Enter your email address.';
                            },
                          ),
                          const SizedBox(height: LuqaSpacing.md),
                          TextFormField(
                            key: const ValueKey('password-field'),
                            controller: _passwordController,
                            enabled: !auth.isLoading,
                            obscureText: _obscurePassword,
                            autofillHints: const [AutofillHints.password],
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(
                                Icons.lock_outline_rounded,
                              ),
                              suffixIcon: IconButton(
                                tooltip: _obscurePassword
                                    ? 'Show password'
                                    : 'Hide password',
                                onPressed: auth.isLoading
                                    ? null
                                    : () => setState(
                                        () => _obscurePassword =
                                            !_obscurePassword,
                                      ),
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                            validator: (value) => (value?.length ?? 0) >= 8
                                ? null
                                : 'Password must contain at least 8 characters.',
                          ),
                          AnimatedSwitcher(
                            duration: disableAnimations
                                ? Duration.zero
                                : LuqaMotion.state,
                            child: error == null
                                ? const SizedBox(
                                    key: ValueKey('no-auth-error'),
                                    height: LuqaSpacing.lg,
                                  )
                                : Padding(
                                    key: const ValueKey('auth-error'),
                                    padding: const EdgeInsets.only(
                                      top: LuqaSpacing.md,
                                    ),
                                    child: Text(
                                      error.toString(),
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: theme.colorScheme.error,
                                          ),
                                    ),
                                  ),
                          ),
                          const SizedBox(height: LuqaSpacing.md),
                          SizedBox(
                            height: 52,
                            child: FilledButton(
                              key: const ValueKey('sign-in-button'),
                              onPressed: auth.isLoading ? null : _submit,
                              child: AnimatedSwitcher(
                                duration: disableAnimations
                                    ? Duration.zero
                                    : LuqaMotion.state,
                                child: auth.isLoading
                                    ? const SizedBox.square(
                                        key: ValueKey('sign-in-progress'),
                                        dimension: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
                                        'Sign in',
                                        key: ValueKey('sign-in-label'),
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: LuqaSpacing.lg),
                          Text(
                            'Private by design. Device credentials stay in your secure system storage.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
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
        ),
      ),
    );
  }
}
