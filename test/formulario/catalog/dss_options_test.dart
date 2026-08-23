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
      _expectUnique(SituacaoEstudosGestacao.values.map((e) => e.code).toList());

      _expectUnique(TipoEmprego.values.map((e) => e.code).toList());
      _expectUnique(FaixaRenda.values.map((e) => e.code).toList());
      _expectUnique(BeneficioTrabalho.values.map((e) => e.code).toList());
      _expectUnique(MotivoDesemprego.values.map((e) => e.code).toList());
      _expectUnique(ImpactoGestacaoTrabalho.values.map((e) => e.code).toList());

      _expectUnique(FonteAgua.values.map((e) => e.code).toList());
      _expectUnique(EsgotamentoSanitario.values.map((e) => e.code).toList());
      _expectUnique(FrequenciaColetaLixo.values.map((e) => e.code).toList());
      _expectUnique(DestinoLixoSemColeta.values.map((e) => e.code).toList());
      _expectUnique(CuidadoVetor.values.map((e) => e.code).toList());

      _expectUnique(DistanciaUBS.values.map((e) => e.code).toList());
      _expectUnique(AcessoUBS.values.map((e) => e.code).toList());
      _expectUnique(ServicoPreNatal.values.map((e) => e.code).toList());
      _expectUnique(AvaliacaoPreNatal.values.map((e) => e.code).toList());
      _expectUnique(DificuldadeSaude.values.map((e) => e.code).toList());

      _expectUnique(TipoMoradia.values.map((e) => e.code).toList());
      _expectUnique(MaterialMoradia.values.map((e) => e.code).toList());
      _expectUnique(ItemResidencia.values.map((e) => e.code).toList());
      _expectUnique(SegurancaResidencia.values.map((e) => e.code).toList());
      _expectUnique(MelhoriaMoradia.values.map((e) => e.code).toList());

      _expectUnique(RefeicoesPorDia.values.map((e) => e.code).toList());
      _expectUnique(AlimentoConsumido.values.map((e) => e.code).toList());
      _expectUnique(FonteAlimentos.values.map((e) => e.code).toList());
      _expectUnique(AvaliacaoAlimentacao.values.map((e) => e.code).toList());

      expect(Escolaridade.labelOf('medio_completo'), 'Ensino Médio Completo');
      expect(Escolaridade.labelOf('superior_incompleto'), 'Ensino Superior Incompleto');
      expect(Escolaridade.labelOf('superior_completo'), 'Ensino Superior Completo');
      expect(Escolaridade.labelOf(null), '');
      expect(Escolaridade.labelOf('codigo_inexistente'), 'codigo_inexistente');
      expect(DificuldadeEducacao.labelOf('sem_dificuldades'), 'Não tenho dificuldades');
      expect(DificuldadeEducacao.labelOf('falta_dinheiro'), 'Falta de dinheiro');

      expect(SituacaoEstudosGestacao.labelOf('nao_estudava'), 'Não estava estudando');
      expect(
        SituacaoEstudosGestacao.labelOf('nao_interrompeu'),
        'Continuei estudando sem precisar interromper',
      );
      expect(
        SituacaoEstudosGestacao.labelOf('interrompeu'),
        'Precisei interromper os estudos por causa da gestação',
      );

      expect(MotivoDesemprego.labelOf('dificuldade_encontrar_vaga'), 'Dificuldade de encontrar vaga');
      expect(MotivoDesemprego.labelOf('cuidado_casa_filhos'), 'Cuidando da casa/filhos');
      expect(MotivoDesemprego.labelOf('gestacao'), 'Por causa da gestação');
      expect(ImpactoGestacaoTrabalho.labelOf('nao_afetou'), 'Não afetou');
      expect(ImpactoGestacaoTrabalho.labelOf('afastamento_temporario'), 'Afastamento temporário');
      expect(BeneficioTrabalho.labelOf('sem_beneficios'), 'Não possui os benefícios listados');
      expect(ServicoPreNatal.labelOf('nenhum_dos_listados'), 'Nenhum dos serviços listados');
      expect(ItemResidencia.labelOf('nenhum_dos_listados'), 'Nenhum dos itens listados');

      expect(DificuldadeSaude.labelOf('falta_transporte'), 'Falta de transporte');
      expect(DificuldadeSaude.labelOf('sem_dificuldades'), 'Não tenho dificuldades');

      expect(CuidadoVetor.labelOf('elimina_agua_parada'), 'Elimina água parada');
      expect(CuidadoVetor.labelOf('sem_cuidados'), 'Não realiza cuidados específicos');

      expect(FrequenciaColetaLixo.labelOf('nao_possui'), 'Não possui coleta');
      expect(DestinoLixoSemColeta.labelOf('terreno_baldio'), 'Joga em terreno baldio');
      expect(DestinoLixoSemColeta.labelOf('enterra'), 'Enterra o lixo');
      expect(DestinoLixoSemColeta.labelOf('aguarda_proxima_coleta'), 'Armazena o lixo até a próxima coleta');

      expect(TipoMoradia.labelOf('casa'), 'Casa');
      expect(TipoMoradia.labelOf('comodo_unico'), 'Cômodo único');
      expect(MaterialMoradia.labelOf('alvenaria'), 'Alvenaria/tijolo');
      expect(MaterialMoradia.labelOf('mista'), 'Mista');
      expect(SegurancaResidencia.labelOf('muito_segura'), 'Muito segura');
      expect(MelhoriaMoradia.labelOf('sem_melhorias'), 'Não desejo melhorias');
      expect(MelhoriaMoradia.labelOf('melhorar_banheiro'), 'Melhorar o banheiro');
      expect(MelhoriaMoradia.labelOf('outro'), 'Outra melhoria');

      expect(RefeicoesPorDia.labelOf('uma_duas'), '1-2 refeições');
      expect(RefeicoesPorDia.labelOf('quatro_mais'), '4 ou mais refeições');
      expect(AlimentoConsumido.labelOf('feijao_leguminosas'), 'Feijão e outras leguminosas');
      expect(AlimentoConsumido.labelOf('nenhum_dos_listados'), 'Nenhum dos listados');
      expect(FonteAlimentos.labelOf('supermercado_feira'), 'Supermercado/feira');
      expect(FonteAlimentos.labelOf('cesta_basica'), 'Cesta básica');
      expect(AvaliacaoAlimentacao.labelOf('muito_boa'), 'Muito boa - atende todas minhas necessidades');
      expect(AvaliacaoAlimentacao.labelOf('ruim'), 'Ruim - não atende minhas necessidades');
    });
  });
}
