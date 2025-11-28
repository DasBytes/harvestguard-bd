import 'package:intl/intl.dart';

String toBangla(dynamic number) {
  if (number == null) return '';
  final formatter = NumberFormat('#,###', 'bn_BD');
  return formatter.format(number);
}

String formatBanglaDate(DateTime date) {
  return DateFormat('d MMMM yyyy', 'bn_BD').format(date);
}
