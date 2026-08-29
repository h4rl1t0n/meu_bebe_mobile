import 'package:flutter_test/flutter_test.dart';
import 'package:meu_bebe/app/model/exame/exame_categoria.dart';
import 'package:meu_bebe/app/model/exame/exame_model.dart';

void main() {
  group('CategoriaExame', () {
    test('Ultrassom → code canônico "ultrassom" (minúsculo)', () {
      expect(CategoriaExame.ultrassom.code, 'ultrassom');
      expect(CategoriaExame.ultrassom.label, 'Ultrassom');
    });

    test('code de ultrassom coincide com ExameModel.ultrassom', () {
      expect(CategoriaExame.ultrassom.code, ExameModel.ultrassom);
    });

    test('outras categorias têm code próprio e não colidem com ultrassom', () {
      expect(CategoriaExame.sangue.code, 'sangue');
      expect(CategoriaExame.urina.code, 'urina');
      expect(CategoriaExame.sangue.code, isNot('ultrassom'));
      expect(CategoriaExame.urina.code, isNot('ultrassom'));
    });
  });
}
