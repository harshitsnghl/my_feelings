String toExact(double value) {
  var sign = "";
  if (value < 0) {
    value = -value;
    sign = "-";
  }
  var string = value.toString();
  var e = string.lastIndexOf('e');
  if (e < 0) return "$sign$string";
  assert(string.indexOf('.') == 1);
  var offset =
      int.parse(string.substring(e + (string.startsWith('-', e + 1) ? 1 : 2)));
  var digits = string.substring(0, 1) + string.substring(2, e);
  if (offset < 0) {
    return "${sign}0.${"0" * ~offset}$digits";
  }
  if (offset > 0) {
    if (offset >= digits.length) {
      return sign + digits.padRight(offset + 1, "0");
    }
    return "$sign${digits.substring(0, offset + 1)}"
        ".${digits.substring(offset + 1)}";
  }
  return digits;
}
