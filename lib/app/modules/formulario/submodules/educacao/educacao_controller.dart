import 'package:mobx/mobx.dart';

import '../../catalog/educacao_options.dart';
import '../../models/educacao/educacao_model.dart';
import 'educacao_validator.dart';

part 'educacao_controller.g.dart';

class EducacaoController = EducacaoControllerBase with _$EducacaoController;

abstract class EducacaoControllerBase with Store {
  @observable
  bool estuda = false;

  @observable
  Escolaridade? escolaridade;

  @observable
  bool interrompeuEstudos = false;

  @observable
  ObservableList<DificuldadeEducacao> dificuldadesEscolares = ObservableList<DificuldadeEducacao>();

  @observable
  bool entendeOrientacoes = false;

  @observable
  bool fezCursoExtracurricular = false;

  @observable
  bool isValid = false;

  @action
  void setEstuda(bool value) {
    estuda = value;
    validate();
  }

  @action
  void setEscolaridade(Escolaridade? value) {
    escolaridade = value;
    validate();
  }

  @action
  void setInterrompeuEstudos(bool value) {
    interrompeuEstudos = value;
    validate();
  }

  @action
  void toggleDificuldade(DificuldadeEducacao dificuldade) {
    if (dificuldadesEscolares.contains(dificuldade)) {
      dificuldadesEscolares.remove(dificuldade);
    } else {
      dificuldadesEscolares.add(dificuldade);
    }
    validate();
  }

  @action
  void setEntendeOrientacoes(bool value) {
    entendeOrientacoes = value;
    validate();
  }

  @action
  void setFezCursoExtracurricular(bool value) {
    fezCursoExtracurricular = value;
    validate();
  }

  @action
  void validate() {
    isValid = EducacaoValidator.isTabValid(escolaridade: escolaridade);
  }

  EducacaoModel buildEducacaoData() {
    return EducacaoModel(
      estuda: estuda,
      escolaridade: escolaridade?.code,
      interrompeuEstudos: interrompeuEstudos,
      dificuldadesEducacao: dificuldadesEscolares.map((d) => d.code).toList(),
      entendeOrientacoes: entendeOrientacoes,
      fezCursoExtracurricular: fezCursoExtracurricular,
    );
  }
}
