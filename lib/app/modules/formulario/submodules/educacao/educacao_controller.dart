import 'package:mobx/mobx.dart';

import '../../catalog/educacao_options.dart';
import '../../models/educacao/educacao_model.dart';
import 'educacao_validator.dart';

part 'educacao_controller.g.dart';

class EducacaoController = EducacaoControllerBase with _$EducacaoController;

abstract class EducacaoControllerBase with Store {
  @observable
  bool? estuda;

  @observable
  Escolaridade? escolaridade;

  @observable
  SituacaoEstudosGestacao? situacaoEstudosGestacao;

  @observable
  ObservableList<DificuldadeEducacao> dificuldadesEscolares = ObservableList<DificuldadeEducacao>();

  @observable
  bool? entendeOrientacoes;

  @observable
  bool? fezCursoQualificacaoProfissional;

  @observable
  bool isValid = false;

  @action
  void setEstuda(bool? value) {
    estuda = value;
    validate();
  }

  @action
  void setEscolaridade(Escolaridade? value) {
    escolaridade = value;
    validate();
  }

  @action
  void setSituacaoEstudosGestacao(SituacaoEstudosGestacao? value) {
    situacaoEstudosGestacao = value;
    validate();
  }

  @action
  void toggleDificuldade(DificuldadeEducacao dificuldade) {
    if (dificuldade == DificuldadeEducacao.semDificuldades) {
      if (dificuldadesEscolares.contains(dificuldade)) {
        dificuldadesEscolares.remove(dificuldade);
      } else {
        dificuldadesEscolares
          ..clear()
          ..add(dificuldade);
      }
    } else {
      dificuldadesEscolares.remove(DificuldadeEducacao.semDificuldades);
      if (dificuldadesEscolares.contains(dificuldade)) {
        dificuldadesEscolares.remove(dificuldade);
      } else {
        dificuldadesEscolares.add(dificuldade);
      }
    }
    validate();
  }

  @action
  void setEntendeOrientacoes(bool? value) {
    entendeOrientacoes = value;
    validate();
  }

  @action
  void setFezCursoQualificacaoProfissional(bool? value) {
    fezCursoQualificacaoProfissional = value;
    validate();
  }

  @action
  void validate() {
    isValid = EducacaoValidator.isTabValid(
      escolaridade: escolaridade,
      estuda: estuda,
      situacaoEstudosGestacao: situacaoEstudosGestacao,
      entendeOrientacoes: entendeOrientacoes,
      fezCursoQualificacaoProfissional: fezCursoQualificacaoProfissional,
      dificuldadesEducacao: dificuldadesEscolares,
    );
  }

  EducacaoModel buildEducacaoData() {
    return EducacaoModel(
      estuda: estuda,
      escolaridade: escolaridade?.code,
      situacaoEstudosGestacao: situacaoEstudosGestacao?.code,
      dificuldadesEducacao: dificuldadesEscolares.map((d) => d.code).toList(),
      entendeOrientacoes: entendeOrientacoes,
      fezCursoQualificacaoProfissional: fezCursoQualificacaoProfissional,
    );
  }
}
