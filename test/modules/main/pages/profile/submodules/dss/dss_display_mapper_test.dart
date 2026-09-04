import 'package:flutter_test/flutter_test.dart';
import 'package:meu_bebe/app/modules/main/pages/profile/submodules/dss/dss_display_mapper.dart';

void main() {
  group('DssDisplayMapper', () {
    test('labelForField resolve a pergunta humana', () {
      expect(DssDisplayMapper.labelForField('acesso_ubs'), 'Como você costuma chegar à UBS?');
      expect(DssDisplayMapper.labelForField('tipo_moradia'), 'Tipo de moradia');
      expect(DssDisplayMapper.labelForField('numero_pessoas'), 'Nº de pessoas na casa');
      expect(
        DssDisplayMapper.labelForField('destino_lixo_sem_coleta'),
        'Quando o lixo não é recolhido pelo serviço de coleta, qual é a principal forma de destinação?',
      );
    });

    test('labelForField com campo desconhecido retorna a própria chave', () {
      expect(DssDisplayMapper.labelForField('campo_desconhecido'), 'campo_desconhecido');
    });

    test('labelForValue resolve código canônico em rótulo', () {
      expect(DssDisplayMapper.labelForValue('acesso_ubs', 'transporte_publico'), 'Transporte público');
      expect(DssDisplayMapper.labelForValue('escolaridade', 'sem_instrucao'), 'Sem instrução');
      expect(DssDisplayMapper.labelForValue('faixa_renda', 'entre_1_2_sm'), '1-2 salários mínimos');
    });

    test('labelForValue com campo/código desconhecido retorna o código', () {
      expect(DssDisplayMapper.labelForValue('campo_desconhecido', 'x'), 'x');
      expect(DssDisplayMapper.labelForValue('escolaridade', 'codigo_x'), 'codigo_x');
    });

    test('formatBoolean usa Sim/Não', () {
      expect(DssDisplayMapper.formatBoolean(true), 'Sim');
      expect(DssDisplayMapper.formatBoolean(false), 'Não');
    });

    test('formatValue formata booleano', () {
      expect(DssDisplayMapper.formatValue('faltou_consulta', true), 'Sim');
      expect(DssDisplayMapper.formatValue('faltou_consulta', false), 'Não');
    });

    test('formatValue formata categórica', () {
      expect(DssDisplayMapper.formatValue('escolaridade', 'medio_completo'), 'Ensino Médio Completo');
      expect(DssDisplayMapper.formatValue('tipo_moradia', 'apartamento'), 'Apartamento');
    });

    test('formatValue formata número', () {
      expect(DssDisplayMapper.formatValue('numero_pessoas', 4), '4');
      expect(DssDisplayMapper.formatValue('numero_comodos', 0), '0');
    });

    test('formatList converte múltipla escolha em lista de rótulos', () {
      expect(
        DssDisplayMapper.formatList('dificuldades_saude', <String>['falta_profissional', 'falta_exames']),
        <String>['Falta de profissionais', 'Falta de exames'],
      );
      expect(
        DssDisplayMapper.formatList('alimentos_consumidos', <String>['frutas_verduras', 'carnes']),
        <String>['Frutas e verduras', 'Carnes (vermelha, frango ou peixe)'],
      );
    });

    test('formatValue une múltipla escolha com quebra de linha', () {
      expect(
        DssDisplayMapper.formatValue('dificuldades_saude', <String>['falta_profissional', 'falta_exames']),
        'Falta de profissionais\nFalta de exames',
      );
    });

    test('formatList vazia retorna vazia', () {
      expect(DssDisplayMapper.formatList('dificuldades_saude', <String>[]), isEmpty);
    });

    test('formatValue com null em campo comum retorna "Não informado"', () {
      expect(DssDisplayMapper.formatValue('faltou_consulta', null), 'Não informado');
      expect(DssDisplayMapper.formatValue('escolaridade', null), 'Não informado');
    });

    test('formatValue com null em campo condicional retorna "Não se aplica"', () {
      expect(DssDisplayMapper.formatValue('tipo_emprego', null), 'Não se aplica');
      expect(DssDisplayMapper.formatValue('motivo_desemprego', null), 'Não se aplica');
      expect(DssDisplayMapper.formatValue('destino_lixo_sem_coleta', null), 'Não se aplica');
      expect(DssDisplayMapper.formatValue('beneficios_trabalho', null), 'Não se aplica');
    });

    test('orderedFields segue a ordem do questionário', () {
      final fields = <String, dynamic>{
        'empregado': true,
        'faixa_renda': 'ate_1_sm',
        'tipo_emprego': 'clt',
        'motivo_desemprego': null,
      };
      expect(
        DssDisplayMapper.orderedFields('trabalho', fields),
        <String>['empregado', 'tipo_emprego', 'motivo_desemprego', 'faixa_renda'],
      );
    });

    test('orderedFields preserva chaves desconhecidas ao final', () {
      final fields = <String, dynamic>{
        'campo_novo': 1,
        'distancia_ubs': 'distante',
      };
      expect(
        DssDisplayMapper.orderedFields('saude', fields),
        <String>['distancia_ubs', 'campo_novo'],
      );
    });

    test('labelForDimension resolve o nome da dimensão', () {
      expect(DssDisplayMapper.labelForDimension('saude'), 'Saúde');
      expect(DssDisplayMapper.labelForDimension('trabalho'), 'Trabalho e Renda');
      expect(DssDisplayMapper.labelForDimension('desconhecida'), 'desconhecida');
    });
  });
}
