class SaudeValidator {
  static String? distanciaUBS(String? value) {
    if (value == null || value.trim().isEmpty) return 'Campo obrigatório';
    return null;
  }

  static String? acessibilidadeUBS(String? value) {
    if (value == null || value.trim().isEmpty) return 'Campo obrigatório';
    return null;
  }

  static String? avaliacaoPreNatal(String? value) {
    if (value == null || value.trim().isEmpty) return 'Campo obrigatório';
    return null;
  }

  static bool isTabValid({
    required String distanciaUBS,
    required String acessibilidadeUBS,
    required String avaliacaoPreNatal,
  }) {
    return distanciaUBS.trim().isNotEmpty && acessibilidadeUBS.trim().isNotEmpty && avaliacaoPreNatal.trim().isNotEmpty;
  }
}
