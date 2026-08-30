import 'package:flutter_test/flutter_test.dart';
import 'package:meu_bebe/app/modules/formulario/catalog/trabalho_options.dart';
import 'package:meu_bebe/app/modules/formulario/submodules/trabalho/trabalho_controller.dart';

void main() {
  group('TrabalhoController', () {
    test('setMotivoDesemprego codifica como código canônico no buildTrabalhoData', () {
      final controller = TrabalhoController();
      controller.setEmpregado(false);

      controller.setMotivoDesemprego(MotivoDesemprego.gestacao);

      expect(controller.buildTrabalhoData().motivoDesemprego, 'gestacao');
    });

    test('setImpactoGestacaoTrabalho codifica como código canônico no buildTrabalhoData', () {
      final controller = TrabalhoController();

      controller.setImpactoGestacaoTrabalho(ImpactoGestacaoTrabalho.afastamentoTemporario);

      expect(controller.buildTrabalhoData().impactoGestacaoTrabalho, 'afastamento_temporario');
    });

    test('empregado = true zera apenas motivo_desemprego e preserva recebe_beneficio_social', () {
      final controller = TrabalhoController();
      controller.setEmpregado(false);
      controller.setMotivoDesemprego(MotivoDesemprego.problemasSaude);
      controller.setRecebeBeneficioSocial(true);

      controller.setEmpregado(true);

      final data = controller.buildTrabalhoData();
      expect(data.motivoDesemprego, isNull);
      expect(data.recebeBeneficioSocial, isTrue);
    });

    test('recebe_beneficio_social é independente da situação de emprego', () {
      final controller = TrabalhoController();

      controller.setEmpregado(true);
      controller.setRecebeBeneficioSocial(true);
      expect(controller.buildTrabalhoData().recebeBeneficioSocial, isTrue);

      controller.setEmpregado(false);
      expect(controller.buildTrabalhoData().recebeBeneficioSocial, isTrue);
    });

    test('empregado = false zera os campos de trabalho condicionais e preserva faixa_renda', () {
      final controller = TrabalhoController();
      controller.setEmpregado(true);
      controller.setTipoEmprego(TipoEmprego.clt);
      controller.setFaixaRenda(FaixaRenda.ate1Sm);
      controller.setPermitePreNatal(true);

      controller.setEmpregado(false);

      final data = controller.buildTrabalhoData();
      expect(data.tipoEmprego, isNull);
      expect(data.permitePreNatal, isNull);
      expect(data.faixaRenda, 'ate_1_sm');
      expect(data.empregado, isFalse);
    });

    test('faixa_renda é independente da situação de emprego', () {
      final controller = TrabalhoController();
      controller.setFaixaRenda(FaixaRenda.entre1e2Sm);

      controller.setEmpregado(true);
      expect(controller.buildTrabalhoData().faixaRenda, 'entre_1_2_sm');

      controller.setEmpregado(false);
      expect(controller.buildTrabalhoData().faixaRenda, 'entre_1_2_sm');
    });

    test('empregado começa null e isValid exige os obrigatórios da situação', () {
      final controller = TrabalhoController();
      expect(controller.empregado, isNull);
      expect(controller.isValid, isFalse); // empregado null

      controller.setEmpregado(false);
      expect(controller.isValid, isFalse); // faixa_renda null

      controller.setFaixaRenda(FaixaRenda.ate1Sm);
      expect(controller.isValid, isFalse); // recebe_beneficio_social null

      controller.setRecebeBeneficioSocial(false);
      expect(controller.isValid, isFalse); // motivo_desemprego null (desempregada)

      controller.setMotivoDesemprego(MotivoDesemprego.gestacao);
      expect(controller.isValid, isTrue); // desempregada completa → válido

      controller.setEmpregado(true);
      expect(controller.isValid, isFalse); // tipo_emprego null

      controller.setTipoEmprego(TipoEmprego.clt);
      expect(controller.isValid, isFalse); // beneficios vazio

      controller.toggleBeneficio(BeneficioTrabalho.valeTransporte);
      expect(controller.isValid, isTrue);
    });

    test('recebe_beneficio_social: null invalida, "Não" (false) e "Sim" (true) validam', () {
      final controller = TrabalhoController();
      controller.setEmpregado(false);
      controller.setFaixaRenda(FaixaRenda.ate1Sm);
      controller.setMotivoDesemprego(MotivoDesemprego.gestacao);

      expect(controller.recebeBeneficioSocial, isNull);
      expect(controller.isValid, isFalse); // não respondida

      controller.setRecebeBeneficioSocial(false); // "Não" é válido
      expect(controller.isValid, isTrue);
      expect(controller.buildTrabalhoData().recebeBeneficioSocial, isFalse);

      controller.setRecebeBeneficioSocial(true); // "Sim" também
      expect(controller.isValid, isTrue);
      expect(controller.buildTrabalhoData().recebeBeneficioSocial, isTrue);
    });

    test('motivo_desemprego é obrigatório apenas quando desempregada', () {
      final controller = TrabalhoController();
      controller.setEmpregado(true);
      controller.setTipoEmprego(TipoEmprego.clt);
      controller.setFaixaRenda(FaixaRenda.ate1Sm);
      controller.setRecebeBeneficioSocial(false);
      controller.toggleBeneficio(BeneficioTrabalho.valeTransporte);

      expect(controller.isValid, isTrue); // empregada: motivo não exigido

      controller.setEmpregado(false);
      expect(controller.isValid, isFalse); // desempregada: motivo exigido

      controller.setMotivoDesemprego(MotivoDesemprego.gestacao);
      expect(controller.isValid, isTrue);
    });

    test('sem_beneficios é mutuamente exclusiva e nunca é serializado como label', () {
      final controller = TrabalhoController();
      controller.setEmpregado(true);
      controller.toggleBeneficio(BeneficioTrabalho.valeTransporte);
      controller.toggleBeneficio(BeneficioTrabalho.auxilioMaternidade);

      controller.toggleBeneficio(BeneficioTrabalho.semBeneficios);

      expect(controller.buildTrabalhoData().beneficiosTrabalho, ['sem_beneficios']);

      controller.toggleBeneficio(BeneficioTrabalho.valeAlimentacao);
      final codes = controller.buildTrabalhoData().beneficiosTrabalho;
      expect(codes, contains('vale_alimentacao'));
      expect(codes, isNot(contains('sem_beneficios')));
      expect(codes, isNot(contains('Vale-transporte')));
    });

    test('beneficios_trabalho é null quando desempregada ou não respondida', () {
      final controller = TrabalhoController();

      expect(controller.buildTrabalhoData().beneficiosTrabalho, isNull); // empregado null

      controller.setEmpregado(false);
      expect(controller.buildTrabalhoData().beneficiosTrabalho, isNull); // desempregada

      controller.setEmpregado(true);
      expect(controller.buildTrabalhoData().beneficiosTrabalho, isEmpty); // empregada, ainda não respondeu
    });

    test('impacto_gestacao_trabalho aplica-se tanto empregada quanto desempregada', () {
      final controller = TrabalhoController();
      controller.setImpactoGestacaoTrabalho(ImpactoGestacaoTrabalho.reduziuJornada);

      expect(controller.buildTrabalhoData().impactoGestacaoTrabalho, 'reduziu_jornada');

      controller.setEmpregado(true);
      expect(controller.buildTrabalhoData().impactoGestacaoTrabalho, 'reduziu_jornada');

      controller.setEmpregado(false);
      expect(controller.buildTrabalhoData().impactoGestacaoTrabalho, 'reduziu_jornada');
    });
  });
}
