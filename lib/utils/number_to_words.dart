class NumberToWords {
  static const List<String> _unidades = [
    '', 'UNO', 'DOS', 'TRES', 'CUATRO', 'CINCO', 'SEIS', 'SIETE', 'OCHO', 'NUEVE'
  ];
  static const List<String> _diez = [
    'DIEZ', 'ONCE', 'DOCE', 'TRECE', 'CATORCE', 'QUINCE', 'DIECISEIS', 'DIECISIETE', 'DIECIOCHO', 'DIECINUEVE'
  ];
  static const List<String> _decenas = [
    '', 'DIEZ', 'VEINTE', 'TREINTA', 'CUARENTA', 'CINCUENTA', 'SESENTA', 'SETENTA', 'OCHENTA', 'NOVENTA'
  ];
  static const List<String> _centenas = [
    '', 'CIENTO', 'DOSCIENTOS', 'TRESCIENTOS', 'CUATROCIENTOS', 'QUINIENTOS', 'SEISCIENTOS', 'SETECIENTOS', 'OCHOCIENTOS', 'NOVECIENTOS'
  ];

  static String convert(double amount) {
    int wholePart = amount.floor();
    int decimalPart = ((amount - wholePart) * 100).round();
    
    String wholeWords = _convertNumber(wholePart);
    if (wholeWords.isEmpty) wholeWords = 'CERO';
    
    return '$wholeWords Y ${decimalPart.toString().padLeft(2, '0')}/100 SOLES';
  }

  static String _convertNumber(int number) {
    if (number == 0) return '';
    if (number == 100) return 'CIEN';
    
    if (number < 10) return _unidades[number];
    if (number < 20) return _diez[number - 10];
    if (number < 30) return number == 20 ? 'VEINTE' : 'VEINTI${_unidades[number - 20]}';
    
    if (number < 100) {
      int ten = number ~/ 10;
      int unit = number % 10;
      return '${_decenas[ten]}${unit > 0 ? ' Y ${_unidades[unit]}' : ''}';
    }
    
    if (number < 1000) {
      int hundred = number ~/ 100;
      int rest = number % 100;
      return '${_centenas[hundred]} ${rest > 0 ? _convertNumber(rest) : ''}'.trim();
    }
    
    if (number < 1000000) {
      int thousand = number ~/ 1000;
      int rest = number % 1000;
      String thousandStr = thousand == 1 ? 'MIL' : '${_convertNumber(thousand)} MIL';
      return '$thousandStr ${rest > 0 ? _convertNumber(rest) : ''}'.trim();
    }

    return number.toString(); // Fallback for larger numbers (unlikely for a restaurant bill)
  }
}
