int convertToInt(String e) {
  String num = (double.parse(e) * 100).toStringAsFixed(0);
  return int.parse(num);
}
