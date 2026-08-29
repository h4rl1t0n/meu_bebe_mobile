/// Categorias canônicas de exame para a UI de cadastro (FASE 9C).
///
/// Cada valor carrega o `code` (valor de domínio persistido no HTTP, sempre em
/// minúsculo e estável) e o `label` (texto exibido ao usuário). A categoria é
/// OPCIONAL: `null` (não informada) é permitida e NÃO conta como ultrassom.
///
/// `ultrassom` é o valor reservado ao mapeamento da 1ª ultrassonografia — ver
/// `ExameModel.firstUltrasoundDate`.
enum CategoriaExame {
  ultrassom('ultrassom', 'Ultrassom'),
  sangue('sangue', 'Sangue'),
  urina('urina', 'Urina');

  const CategoriaExame(this.code, this.label);

  final String code;
  final String label;
}
