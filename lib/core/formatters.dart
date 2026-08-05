import 'package:intl/intl.dart';

class AppFormatters {
  AppFormatters._();

  static final NumberFormat _currency = NumberFormat.decimalPattern('en_US');
  static final DateFormat _date = DateFormat('dd MMM yyyy');
  static final DateFormat _dateShort = DateFormat('dd/MM/yy');

  static String money(num value) => 'TSh ${_currency.format(value.round())}';

  static String number(num value) => _currency.format(value);

  static String date(DateTime date) => _date.format(date);

  static String dateShort(DateTime date) => _dateShort.format(date);
}
