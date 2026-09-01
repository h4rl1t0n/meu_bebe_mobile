import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../../core/ui/theme/styles/colors_app.dart';
import '../../core/ui/theme/styles/design_tokens.dart';
import '../../core/ui/theme/styles/text_styles.dart';
import 'onboarding_gate_controller.dart';

/// Tela de verificação/retry (FASE 9G-FIX1). Re-resolve o estado do onboarding
/// e encaminha o usuário (retry ou próximo passo). Nunca libera a Main sem
/// onboarding completo e nunca expõe erro de HTTP/DioException/stack trace.
class OnboardingGatePage extends StatefulWidget {
  const OnboardingGatePage({super.key});

  @override
  State<OnboardingGatePage> createState() => _OnboardingGatePageState();
}

class _OnboardingGatePageState extends State<OnboardingGatePage> {
  final _controller = Modular.get<OnboardingGateController>();

  @override
  void initState() {
    super.initState();
    _controller.resolve();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;

    return Observer(
      builder: (_) {
        return Scaffold(
          backgroundColor: colors.scaffoldBackground,
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(Spacing.xxl),
                child: _controller.checking
                    ? const CircularProgressIndicator.adaptive()
                    : _buildRetry(colors, textStyles),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRetry(ColorsApp colors, TextStyles textStyles) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.cloud_off, size: 64, color: colors.primary300),
        SizedBox(height: Spacing.lg),
        Text(
          'Não foi possível verificar seus dados no momento. Tente novamente.',
          textAlign: TextAlign.center,
          style: textStyles.textStyle.copyWith(color: colors.onSurface),
        ),
        SizedBox(height: Spacing.xl),
        ElevatedButton.icon(
          onPressed: _controller.resolve,
          icon: const Icon(Icons.refresh),
          label: const Text('Tentar novamente'),
        ),
      ],
    );
  }
}
