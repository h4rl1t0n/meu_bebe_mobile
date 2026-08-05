import 'package:mobx/mobx.dart';

import '../../models/educacao/educacao_model.dart';
import 'educacao_validator.dart';

part 'educacao_controller.g.dart';

class EducacaoController = EducacaoControllerBase with _$EducacaoController;

abstract class EducacaoControllerBase with Store {
  @observable
  String escolaridade = '';

  @observable
  bool estuda = false;

  @observable
  bool interrompeuEstudos = false;

  @observable
  String dificuldadesEscolares = '';

  @observable
  bool entendeOrientacoes = false;

  @observable
  String cursosExtracurriculares = '';

  @observable
  String expectativasEducacionais = '';

  @observable
  bool isValid = false;

  @action
  void setEscolaridade(String value) {
    escolaridade = value;
    validate();
  }

  @action
  void setEstuda(bool value) {
    estuda = value;
    validate();
  }

  @action
  void setInterrompeuEstudos(bool value) {
    interrompeuEstudos = value;
    validate();
  }

  @action
  void setDificuldadesEscolares(String value) {
    dificuldadesEscolares = value;
    validate();
  }

  @action
  void setEntendeOrientacoes(bool value) {
    entendeOrientacoes = value;
    validate();
  }

  @action
  void setCursosExtracurriculares(String value) {
    cursosExtracurriculares = value;
    validate();
  }

  @action
  void setExpectativasEducacionais(String value) {
    expectativasEducacionais = value;
    validate();
  }

  @action
  void validate() {
    isValid = EducacaoValidator.isTabValid(escolaridade: escolaridade);
  }

  EducacaoModel buildEducacaoData() {
    return EducacaoModel(
      escolaridade: escolaridade,
      estuda: estuda,
      interrompeuEstudos: interrompeuEstudos,
      dificuldadesEscolares: dificuldadesEscolares,
      entendeOrientacoes: entendeOrientacoes,
      cursosExtracurriculares: cursosExtracurriculares,
      expectativasEducacionais: expectativasEducacionais,
    );
  }
}
