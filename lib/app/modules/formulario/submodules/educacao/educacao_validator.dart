import '../../catalog/educacao_options.dart';

class EducacaoValidator {
  static String? escolaridade(Escolaridade? value) {
    if (value == null) return 'Campo obrigatório';
    return null;
  }

  static bool isTabValid({required Escolaridade? escolaridade}) {
    return escolaridade != null;
  }
}
