import 'package:flutter_test/flutter_test.dart';
import 'package:meu_bebe/app/modules/formulario/catalog/alimentacao_options.dart';
import 'package:meu_bebe/app/modules/formulario/catalog/educacao_options.dart';
import 'package:meu_bebe/app/modules/formulario/catalog/habitacao_options.dart';
import 'package:meu_bebe/app/modules/formulario/catalog/saneamento_options.dart';
import 'package:meu_bebe/app/modules/formulario/catalog/saude_options.dart';
import 'package:meu_bebe/app/modules/formulario/catalog/trabalho_options.dart';

void _expectUnique(List<String> codes) {
  expect(codes.toSet().length, codes.length, reason: 'códigos duplicados em $codes');
}

void main() {
  group('Catálogo de opções DSS', () {
    test('códigos canônicos são únicos e labelOf resolve o rótulo', () {
      _expectUnique(Escolaridade.values.map((e) => e.code).toList());
      _expectUnique(DificuldadeEducacao.values.map((e) => e.code).toList());

      _expectUnique(TipoEmprego.values.map((e) => e.code).toList());
      _expectUnique(FaixaRenda.values.map((e) => e.code).toList());
      _expectUnique(BeneficioTrabalho.values.map((e) => e.code).toList());
      _expectUnique(MotivoDesemprego.values.map((e) => e.code).toList());
      _expectUnique(ImpactoGestacaoTrabalho.values.map((e) => e.code).toList());

      _expectUnique(FonteAgua.values.map((e) => e.code).toList());
      _expectUnique(EsgotamentoSanitario.values.map((e) => e.code).toList());
      _expectUnique(ColetaLixo.values.map((e) => e.code).toList());

      _expectUnique(DistanciaUBS.values.map((e) => e.code).toList());
      _expectUnique(AcessoUBS.values.map((e) => e.code).toList());
      _expectUnique(ServicoPreNatal.values.map((e) => e.code).toList());
      _expectUnique(AvaliacaoPreNatal.values.map((e) => e.code).toList());

      _expectUnique(TipoMoradia.values.map((e) => e.code).toList());
      _expectUnique(ItemResidencia.values.map((e) => e.code).toList());
      _expectUnique(SegurancaResidencia.values.map((e) => e.code).toList());

      _expectUnique(RefeicoesPorDia.values.map((e) => e.code).toList());
      _expectUnique(AlimentoConsumido.values.map((e) => e.code).toList());
      _expectUnique(FonteAlimentos.values.map((e) => e.code).toList());
      _expectUnique(AvaliacaoAlimentacao.values.map((e) => e.code).toList());

      expect(Escolaridade.labelOf('medio_completo'), 'Ensino Médio Completo');
      expect(Escolaridade.labelOf(null), '');
      expect(Escolaridade.labelOf('codigo_inexistente'), 'codigo_inexistente');

      expect(MotivoDesemprego.labelOf('dificuldade_encontrar_vaga'), 'Dificuldade de encontrar vaga');
      expect(MotivoDesemprego.labelOf('cuidado_casa_filhos'), 'Cuidando da casa/filhos');
      expect(MotivoDesemprego.labelOf('gestacao'), 'Por causa da gestação');
      expect(ImpactoGestacaoTrabalho.labelOf('nao_afetou'), 'Não afetou');
      expect(ImpactoGestacaoTrabalho.labelOf('afastamento_temporario'), 'Afastamento temporário');
    });
  });
}
