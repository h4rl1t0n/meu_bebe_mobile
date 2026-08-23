import '../../catalog/trabalho_options.dart';

class TrabalhoValidator {
  static String? tipoEmprego(TipoEmprego? value) {
    if (value == null) return 'Campo obrigatório';
    return null;
  }

  static String? faixaRenda(FaixaRenda? value) {
    if (value == null) return 'Campo obrigatório';
    return null;
  }

  static bool isTabValid({
    required bool empregado,
    required TipoEmprego? tipoEmprego,
    required FaixaRenda? faixaRenda,
  }) {
    // faixa_renda é obrigatória independentemente da situação profissional.
    if (faixaRenda == null) return false;
    // tipo_emprego é obrigatório apenas quando empregada.
    if (!empregado) return true;
    return tipoEmprego != null;
  }
}
