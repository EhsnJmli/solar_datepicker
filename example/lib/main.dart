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
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String pickedDate = 'click to choose';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Container(
        alignment: Alignment.center,
        child: ElevatedButton(
          child: Text(pickedDate),
          onPressed: () async {
            final picked = await showSolarDatePicker(
              context: context,
              initialDate: DateTime.now(),
              locale: Locale('fa','IR'),
              firstDate: DateTime.now().subtract(Duration(days: 100 * 365)),
              lastDate: DateTime.now().add(Duration(days: 100 * 365)),
              isPersian: true,
              initialDatePickerMode: SolarDatePickerMode.year,
            );
            if (picked != null) {
              setState(() {
                final f = Jalali.fromDateTime(picked).formatter;
                pickedDate = '${f.yyyy}/${f.mm}/${f.dd}';
              });
            }
          },
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
