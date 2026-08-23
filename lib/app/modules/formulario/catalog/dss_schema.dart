/// Versão e utilitários do contrato de dados do formulário DSS.
///
/// O contrato de dados separa três coisas que não podem ser confundidas:
///   1. identificador da variável (a chave no JSON, ex.: `escolaridade`);
///   2. valor canônico (o código snake_case, ex.: `medio_completo`);
///   3. texto exibido ao usuário (o rótulo, ex.: `Ensino Médio Completo`).
///
/// O texto exibido ao usuário NUNCA é usado como valor de feature: ele pode
/// mudar sem que o dataset seja afetado. O código canônico, sim, é estável.
abstract final class DssSchema {
  DssSchema._();

  /// Versão do schema/contrato de dados.
  ///
  /// Deve ser incrementada sempre que houver mudança estrutural no instrumento
  /// (adição/remoção/renomeação de perguntas ou alteração nos códigos
  /// canônicos), para que cada registro coletado possa ser rastreado até a
  /// versão do formulário que o gerou.
  static const String schemaVersion = '1.6';

  /// Compara duas listas por conteúdo (usado nos operadores `==` dos models,
  /// que possuem campos de múltipla escolha).
  static bool listsEqual(List<dynamic>? a, List<dynamic>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return a == b;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
