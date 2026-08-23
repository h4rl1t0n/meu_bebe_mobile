import '../../catalog/habitacao_options.dart';

class HabitacaoValidator {
  static String? tipoMoradia(TipoMoradia? value) {
    if (value == null) return 'Campo obrigatório';
    return null;
  }

  static String? numeroPessoas(String? value) {
    if (value == null || value.trim().isEmpty) return 'Campo obrigatório';
    final n = int.tryParse(value);
    if (n == null || n <= 0) return 'Informe um número válido';
    return null;
  }

  static String? segurancaEstrutural(SegurancaResidencia? value) {
    if (value == null) return 'Campo obrigatório';
    return null;
  }

  static bool isTabValid({
    required TipoMoradia? tipoMoradia,
    required int numeroPessoas,
    required SegurancaResidencia? segurancaEstrutural,
  }) {
    return tipoMoradia != null && numeroPessoas > 0 && segurancaEstrutural != null;
  }
}
