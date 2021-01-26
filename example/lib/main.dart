import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:solar_datepicker/solar_datepicker.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Solar DatePicker Demo',
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
        child: RaisedButton(
          child: Text(pickedDate),
          onPressed: () async {
            final picked = await showSolarDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime.now().subtract(Duration(days: 100 * 365)),
              lastDate: DateTime.now().add(Duration(days: 100 * 365)),
              isPersian: true,
              builder: (context, child) => Column(
                children: [
                  Container(
                    constraints: BoxConstraints(maxWidth: 400, maxHeight: 600),
                    child: child,
                  ),
                ],
              ),
              initialDatePickerMode: SolarDatePickerMode.day,
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
