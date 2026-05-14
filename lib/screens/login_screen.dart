import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_health_card/models/agent.dart';
import 'package:smart_health_card/state/app_state.dart';
import 'package:smart_health_card/utils/constants.dart';
import 'package:smart_health_card/widgets/custom_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _agentController = TextEditingController(text: 'agent001');
  final _passwordController = TextEditingController(text: '1234');
  bool _isLoading = false;
  bool _hidePassword = true;

  @override
  void dispose() {
    _agentController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final storage = ref.read(storageProvider);
    final encryption = ref.read(encryptionProvider);
    final id = _agentController.text.trim();
    final password = _passwordController.text;

    try {
      Agent? agent = await storage.getAgent(id);

      if (agent == null && id == 'agent001' && password == '1234') {
        final hashedPassword = await encryption.hashPassword(password);
        agent = Agent(
          id: id,
          name: 'Agent Smart Health',
          hospital: 'Centre de santé',
          hashedPassword: hashedPassword,
        );
        await storage.saveAgent(agent);
      }

      final isValid =
          agent != null &&
          await encryption.verifyPassword(password, agent.hashedPassword);

      if (!mounted) return;
      if (!isValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Identifiants invalides.')),
        );
        return;
      }

      ref.read(agentSessionProvider.notifier).login(agent);
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Connexion impossible : $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.health_and_safety,
                      color: AppColors.burkinaGreen,
                      size: 82,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      AppStrings.appName,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      AppStrings.agentAccess,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    TextFormField(
                      controller: _agentController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: AppStrings.agentId,
                        helperText: 'Compte test hors ligne : agent001',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      validator:
                          (value) =>
                              value == null || value.trim().isEmpty
                                  ? AppStrings.requiredFields
                                  : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _hidePassword,
                      decoration: InputDecoration(
                        labelText: AppStrings.password,
                        helperText: 'Mot de passe test : 1234',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          tooltip:
                              _hidePassword
                                  ? 'Afficher le mot de passe'
                                  : 'Masquer le mot de passe',
                          icon: Icon(
                            _hidePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            setState(() => _hidePassword = !_hidePassword);
                          },
                        ),
                      ),
                      validator:
                          (value) =>
                              value == null || value.isEmpty
                                  ? AppStrings.requiredFields
                                  : null,
                      onFieldSubmitted: (_) => _login(),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    CustomButton(
                      label: AppStrings.login,
                      icon: Icons.login,
                      isLoading: _isLoading,
                      onPressed: _login,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text(AppStrings.publicQrOnly),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
