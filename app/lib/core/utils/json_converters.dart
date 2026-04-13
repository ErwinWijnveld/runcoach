double toDouble(dynamic value) => switch (value) {
  num v => v.toDouble(),
  String v => double.parse(v),
  _ => 0.0,
};

double? toDoubleOrNull(dynamic value) => switch (value) {
  num v => v.toDouble(),
  String v => double.tryParse(v),
  _ => null,
};

int toInt(dynamic value) => switch (value) {
  num v => v.toInt(),
  String v => int.parse(v),
  _ => 0,
};

int? toIntOrNull(dynamic value) => switch (value) {
  num v => v.toInt(),
  String v => int.tryParse(v),
  _ => null,
};
