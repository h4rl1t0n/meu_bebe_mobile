import '../../catalog/saude_options.dart';

class SaudeValidator {
  static String? distanciaUBS(DistanciaUBS? value) {
    if (value == null) return 'Campo obrigatório';
    return null;
  }

  static String? acessoUBS(AcessoUBS? value) {
    if (value == null) return 'Campo obrigatório';
    return null;
  }

  static String? avaliacaoPreNatal(AvaliacaoPreNatal? value) {
    if (value == null) return 'Campo obrigatório';
    return null;
  }

  static bool isTabValid({
    required DistanciaUBS? distanciaUBS,
    required AcessoUBS? acessoUBS,
    required bool? cadastradaUBS,
    required AvaliacaoPreNatal? avaliacaoPreNatal,
    required List<ServicoPreNatal> servicosPreNatal,
    required List<DificuldadeSaude> dificuldadesSaude,
  }) {
    return distanciaUBS != null &&
        acessoUBS != null &&
        cadastradaUBS != null &&
        avaliacaoPreNatal != null &&
        servicosPreNatal.isNotEmpty &&
        dificuldadesSaude.isNotEmpty;
  }
}
