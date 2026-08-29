/// Converte o `created_at` ISO (`2026-08-29T00:00:00Z`) do backend em
/// `DD/MM/YYYY` para exibição. Retorna `—` para nulo/vazio e o valor original
/// quando o padrão não é reconhecido (formatação apenas visual).
String formatDssDate(String? iso) {
  if (iso == null || iso.isEmpty) return '—';
  final datePart = iso.split('T').first;
  final parts = datePart.split('-');
  if (parts.length != 3) return iso;
  final year = parts[0];
  final month = parts[1];
  final day = parts[2];
  if (year.length != 4 || month.length != 2 || day.length != 2) return iso;
  return '$day/$month/$year';
}
