import 'package:intl/intl.dart';

class DateFormatter {
  static String formatFriendly(DateTime fechaOriginal) {
    final fecha = fechaOriginal.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final fechaDate = DateTime(fecha.year, fecha.month, fecha.day);

    if (fechaDate == today) {
      return 'Hoy ${DateFormat.Hm().format(fecha)}';
    } else if (fechaDate == yesterday) {
      return 'Ayer ${DateFormat.Hm().format(fecha)}';
    } else if (now.difference(fecha).inDays < 7) {
      return '${_getDayName(fecha.weekday)} ${DateFormat.Hm().format(fecha)}';
    } else {
      return DateFormat('dd MMM, HH:mm', 'es').format(fecha);
    }
  }

  static String _getDayName(int weekday) {
    const days = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    return days[weekday - 1];
  }

  static String formatShort(DateTime fecha) {
    return DateFormat('dd/MM HH:mm').format(fecha.toLocal());
  }

  static String formatFull(DateTime fecha) {
    return DateFormat('dd/MM/yyyy HH:mm:ss').format(fecha.toLocal());
  }
}
