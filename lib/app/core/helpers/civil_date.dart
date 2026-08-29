/// Utilitário de datas civis (sem horário) para a fronteira consulta/exame.
///
/// A API trafega datas como ISO `AAAA-MM-DD` (`date` do Pydantic); a UI exibe e
/// coleta em `DD/MM/AAAA`. Estas funções convertem validando data REAL
/// (rejeitam `99/99/2025`), mas SEM rejeitar datas futuras — consultas e exames
/// podem ser agendados à frente (a "próxima consulta" é uma data futura).
library;

/// Converte `DD/MM/AAAA` (exibição/entrada) para ISO `AAAA-MM-DD`.
///
/// Retorna `null` se vazio ou inválido (formato errado, dia/mês/ano
/// inexistentes). Não rejeita datas futuras.
String? civilDateDisplayToIso(String? display) {
  final v = (display ?? '').trim();
  if (v.isEmpty) return null;

  final parts = v.split('/');
  if (parts.length != 3) return null;

  final day = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final year = int.tryParse(parts[2]);
  if (day == null || month == null || year == null) return null;

  final date = DateTime(year, month, day);
  if (date.year != year || date.month != month || date.day != day) return null;

  return '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';
}

/// Data de hoje como ISO `AAAA-MM-DD` (fallback quando o usuário deixa a data
/// em branco ao adicionar consulta/exame).
String civilDateTodayIso() {
  final n = DateTime.now();
  return '${n.year.toString().padLeft(4, '0')}-'
      '${n.month.toString().padLeft(2, '0')}-'
      '${n.day.toString().padLeft(2, '0')}';
}

/// Converte ISO `AAAA-MM-DD` para `DD/MM/AAAA` (exibição).
///
/// Retorna string vazia se o ISO for vazio ou não seguir o formato esperado.
String civilDateIsoToDisplay(String? iso) {
  final v = (iso ?? '').trim();
  if (v.isEmpty) return '';
  final parts = v.split('-');
  if (parts.length != 3) return '';
  if (int.tryParse(parts[0]) == null ||
      int.tryParse(parts[1]) == null ||
      int.tryParse(parts[2]) == null) {
    return '';
  }
  return '${parts[2]}/${parts[1]}/${parts[0]}';
}
