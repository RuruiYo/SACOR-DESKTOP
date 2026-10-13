class Dinero implements Comparable<Dinero> {
  const Dinero(this.centavos);

  const Dinero.cero() : centavos = 0;

  factory Dinero.desdeNumero(num valor) => Dinero((valor * 100).round());

  static const maximo = Dinero(999999999999);

  final int centavos;

  static Dinero desdeJson(Object? valor) =>
      valor is num ? Dinero.desdeNumero(valor) : const Dinero.cero();

  static Dinero? desdeJsonOpcional(Object? valor) =>
      valor is num ? Dinero.desdeNumero(valor) : null;

  static Dinero? interpretar(String texto) {
    final limpio = texto.trim().replaceAll(r'$', '').replaceAll(',', '').replaceAll(' ', '');
    final coincidencia = RegExp(r'^(\d{1,10})(?:\.(\d{1,2}))?$').firstMatch(limpio);
    if (coincidencia == null) return null;

    final entero = int.parse(coincidencia.group(1)!);
    final decimales = (coincidencia.group(2) ?? '').padRight(2, '0');
    final monto = Dinero(entero * 100 + int.parse(decimales));
    return monto > maximo ? null : monto;
  }

  static Dinero sumar(Iterable<Dinero> montos) =>
      montos.fold(const Dinero.cero(), (total, monto) => total + monto);

  double get comoDouble => centavos / 100;

  bool get esCero => centavos == 0;
  bool get esNegativo => centavos < 0;
  bool get esPositivo => centavos > 0;

  Dinero get absoluto => Dinero(centavos.abs());

  num toJson() => centavos % 100 == 0 ? centavos ~/ 100 : centavos / 100;

  String get comoTextoEditable {
    final signo = centavos < 0 ? '-' : '';
    final absolutos = centavos.abs();
    final resto = absolutos % 100;
    return resto == 0
        ? '$signo${absolutos ~/ 100}'
        : '$signo${absolutos ~/ 100}.${resto.toString().padLeft(2, '0')}';
  }

  Dinero operator +(Dinero otro) => Dinero(centavos + otro.centavos);
  Dinero operator -(Dinero otro) => Dinero(centavos - otro.centavos);
  Dinero operator -() => Dinero(-centavos);
  Dinero multiplicar(int factor) => Dinero(centavos * factor);

  bool operator >(Dinero otro) => centavos > otro.centavos;
  bool operator <(Dinero otro) => centavos < otro.centavos;
  bool operator >=(Dinero otro) => centavos >= otro.centavos;
  bool operator <=(Dinero otro) => centavos <= otro.centavos;

  static Dinero mayor(Dinero a, Dinero b) => a >= b ? a : b;

  @override
  int compareTo(Dinero otro) => centavos.compareTo(otro.centavos);

  @override
  bool operator ==(Object other) => other is Dinero && other.centavos == centavos;

  @override
  int get hashCode => centavos.hashCode;

  @override
  String toString() => 'Dinero($comoTextoEditable)';
}
