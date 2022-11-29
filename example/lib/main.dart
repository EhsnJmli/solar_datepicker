import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:solar_datepicker/solar_datepicker.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Solar DatePicker Demo',
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Solar DatePicker Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({
    Key? key,
    required this.title,
  }) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  DateTime? pickedDate;

  String? getDateStr() {
    if (pickedDate == null) {
      return null;
    }
    final f = Jalali.fromDateTime(pickedDate!).formatter;
    return '${f.yyyy}/${f.mm}/${f.dd}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Container(
        alignment: Alignment.center,
        child: ElevatedButton(
          child: Text(getDateStr() ?? 'click to choose'),
          onPressed: () async {
            final picked = await showSolarDatePicker(
              context: context,
              textDirection: TextDirection.rtl,
              initialDate: pickedDate ?? DateTime.now(),
              locale: Locale('fa', 'IR'),
              firstDate: DateTime.now().subtract(Duration(days: 100 * 365)),
              lastDate: DateTime.now(),
              isPersian: true,
              headerContentColor: Colors.white,
              initialDatePickerMode: SolarDatePickerMode.year,
            );
            if (picked != null) {
              setState(() {
                pickedDate = picked;
              });
            }
          },
        ),
      ),
    );
  }
}
