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
    required bool? empregado,
    required TipoEmprego? tipoEmprego,
    required FaixaRenda? faixaRenda,
    required List<BeneficioTrabalho> beneficios,
  }) {
    // empregado e faixa_renda são obrigatórios independentemente da situação.
    if (empregado == null) return false;
    if (faixaRenda == null) return false;
    // Desempregada: apenas faixa_renda (e empregado) são obrigatórios.
    if (empregado == false) return true;
    // Empregada: tipo_emprego e ao menos um benefício são obrigatórios.
    return tipoEmprego != null && beneficios.isNotEmpty;
  }
}
