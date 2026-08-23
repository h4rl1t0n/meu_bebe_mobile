import '../../catalog/habitacao_options.dart';

class HabitacaoValidator {
  static String? tipoMoradia(TipoMoradia? value) {
    if (value == null) return 'Campo obrigatório';
    return null;
  }

  static String? materialMoradia(MaterialMoradia? value) {
    if (value == null) return 'Campo obrigatório';
    return null;
  }

  static String? numeroPessoas(String? value) {
    if (value == null || value.trim().isEmpty) return 'Campo obrigatório';
    final n = int.tryParse(value);
    if (n == null || n <= 0) return 'Informe um número válido';
    return null;
  }

  static String? numeroComodos(String? value) {
    if (value == null || value.trim().isEmpty) return 'Campo obrigatório';
    final n = int.tryParse(value);
    if (n == null || n <= 0) return 'Informe um número válido';
    return null;
  }

  static String? numeroDormitorios(String? value, {int? numeroComodos}) {
    if (value == null || value.trim().isEmpty) return 'Campo obrigatório';
    final n = int.tryParse(value);
    if (n == null || n <= 0) return 'Informe um número válido';
    if (numeroComodos != null && n > numeroComodos) {
      return 'Não pode ser maior que o nº de cômodos';
    }
    return null;
  }

  static String? segurancaResidencia(SegurancaResidencia? value) {
    if (value == null) return 'Campo obrigatório';
    return null;
  }

  static bool isTabValid({
    required TipoMoradia? tipoMoradia,
    required MaterialMoradia? materialMoradia,
    required int numeroPessoas,
    required int numeroComodos,
    required int numeroDormitorios,
    required SegurancaResidencia? segurancaResidencia,
    required bool? facilAcessoSaude,
    required List<ItemResidencia> itensResidencia,
    required List<MelhoriaMoradia> melhoriasDesejadas,
  }) {
    return tipoMoradia != null &&
        materialMoradia != null &&
        numeroPessoas > 0 &&
        numeroComodos > 0 &&
        numeroDormitorios > 0 &&
        numeroDormitorios <= numeroComodos &&
        segurancaResidencia != null &&
        facilAcessoSaude != null &&
        itensResidencia.isNotEmpty &&
        melhoriasDesejadas.isNotEmpty;
  }
}
