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
    required MotivoDesemprego? motivoDesemprego,
    required bool? recebeBeneficioSocial,
  }) {
    // empregado, faixa_renda e recebe_beneficio_social são obrigatórios
    // independentemente da situação.
    if (empregado == null) return false;
    if (faixaRenda == null) return false;
    if (recebeBeneficioSocial == null) return false;
    // Desempregada: motivo_desemprego é obrigatório.
    if (empregado == false) return motivoDesemprego != null;
    // Empregada: tipo_emprego e ao menos um benefício são obrigatórios.
    return tipoEmprego != null && beneficios.isNotEmpty;
  }
}
