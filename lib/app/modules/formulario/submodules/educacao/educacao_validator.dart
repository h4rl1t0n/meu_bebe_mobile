import '../../catalog/educacao_options.dart';

class EducacaoValidator {
  static String? escolaridade(Escolaridade? value) {
    if (value == null) return 'Campo obrigatório';
    return null;
  }

  /// A aba só é válida quando a escolaridade, a situação dos estudos na
  /// gestação e todos os booleanos foram respondidos. Booleanos `null`
  /// significam "não respondido" e, portanto, invalidam a aba — distinguindo
  /// "Não" (`false`) de "não informado" (`null`).
  static bool isTabValid({
    required Escolaridade? escolaridade,
    required bool? estuda,
    required SituacaoEstudosGestacao? situacaoEstudosGestacao,
    required bool? entendeOrientacoes,
    required bool? fezCursoQualificacaoProfissional,
  }) {
    return escolaridade != null &&
        estuda != null &&
        situacaoEstudosGestacao != null &&
        entendeOrientacoes != null &&
        fezCursoQualificacaoProfissional != null;
  }
}
