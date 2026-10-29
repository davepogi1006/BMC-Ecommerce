import 'package:intl/intl.dart';

final _peso = NumberFormat.currency(symbol: '₱', decimalDigits: 2);

/// 1500 -> ₱1,500.00
String peso(double amount) => _peso.format(amount);
