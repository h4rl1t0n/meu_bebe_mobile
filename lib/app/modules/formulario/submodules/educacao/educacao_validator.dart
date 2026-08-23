import '../../catalog/educacao_options.dart';

class EducacaoValidator {
  static String? escolaridade(Escolaridade? value) {
    if (value == null) return 'Campo obrigatório';
    return null;
  }

  /// A aba só é válida quando a escolaridade, a situação dos estudos na
  /// gestação, todos os booleanos e ao menos uma dificuldade foram
  /// respondidos. Booleanos `null` significam "não respondido" e, portanto,
  /// invalidam a aba — distinguindo "Não" (`false`) de "não informado"
  /// (`null`). A lista `dificuldadesEducacao` vazia (`[]`) também invalida.
  static bool isTabValid({
    required Escolaridade? escolaridade,
    required bool? estuda,
    required SituacaoEstudosGestacao? situacaoEstudosGestacao,
    required bool? entendeOrientacoes,
    required bool? fezCursoQualificacaoProfissional,
    required List<DificuldadeEducacao> dificuldadesEducacao,
  }) {
    return escolaridade != null &&
        estuda != null &&
        situacaoEstudosGestacao != null &&
        entendeOrientacoes != null &&
        fezCursoQualificacaoProfissional != null &&
        dificuldadesEducacao.isNotEmpty;
  }
}
