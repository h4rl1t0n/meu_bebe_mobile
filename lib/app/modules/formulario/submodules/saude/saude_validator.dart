import '../../catalog/saude_options.dart';

class SaudeValidator {
  static String? distanciaUBS(DistanciaUBS? value) {
    if (value == null) return 'Campo obrigatório';
    return null;
  }

  static String? acessibilidadeUBS(AcessoUBS? value) {
    if (value == null) return 'Campo obrigatório';
    return null;
  }

  static String? avaliacaoPreNatal(AvaliacaoPreNatal? value) {
    if (value == null) return 'Campo obrigatório';
    return null;
  }

  static bool isTabValid({
    required DistanciaUBS? distanciaUBS,
    required AcessoUBS? acessibilidadeUBS,
    required AvaliacaoPreNatal? avaliacaoPreNatal,
  }) {
    return distanciaUBS != null && acessibilidadeUBS != null && avaliacaoPreNatal != null;
  }
}
