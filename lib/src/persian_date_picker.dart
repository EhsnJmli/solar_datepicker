import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:shamsi_date/shamsi_date.dart';

import 'persian_date.dart';

// Examples can assume:
// BuildContext context;

/// Initial display mode of the date picker dialog.
///
/// Date picker UI mode for either showing a list of available years or a
/// monthly calendar initially in the dialog shown by calling [showSolarDatePicker].
///
/// See also:
///
///  * [showSolarDatePicker], which shows a dialog that contains a material design
///    date picker.
enum SolarDatePickerMode {
  /// Show a date picker UI for choosing a month and day.
  day,

  /// Show a date picker UI for choosing a year.
  year,
}

const Duration _kMonthScrollDuration = Duration(milliseconds: 200);
const double _kDayPickerRowHeight = 42;
const int _kMaxDayPickerRowCount = 6; // A 31 day month that starts on Saturday.
// Two extra rows: one for the day-of-week header and one for the month header.
const double _kMaxDayPickerHeight =
    _kDayPickerRowHeight * (_kMaxDayPickerRowCount + 2);

// Shows the selected date in large font and toggles between year and day mode
class _SolarDatePickerHeader extends StatelessWidget {
  const _SolarDatePickerHeader({
    Key? key,
    required this.selectedDate,
    required this.mode,
    required this.onModeChanged,
    required this.orientation,
    this.isPersian = true,
    this.headerContentColor,
  }) : super(key: key);

  final DateTime selectedDate;
  final SolarDatePickerMode mode;
  final ValueChanged<SolarDatePickerMode> onModeChanged;
  final Orientation orientation;
  final bool isPersian;
  final Color? headerContentColor;

  void _handleChangeMode(SolarDatePickerMode value) {
    if (value != mode) {
      onModeChanged(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    final themeData = Theme.of(context);
    final headerTextTheme = themeData.primaryTextTheme;
    final persianDate = SolarDate.sDate(gregorian: selectedDate.toString());

    Color dayColor;
    Color yearColor;
    switch (themeData.colorScheme.brightness) {
      case Brightness.light:
        dayColor = headerContentColor ??
            (mode == SolarDatePickerMode.day ? Colors.black87 : Colors.black54);
        yearColor = headerContentColor ??
            (mode == SolarDatePickerMode.year
                ? Colors.black87
                : Colors.black54);
        break;
      case Brightness.dark:
        dayColor = headerContentColor ??
            (mode == SolarDatePickerMode.day ? Colors.white : Colors.white70);
        yearColor = headerContentColor ??
            (mode == SolarDatePickerMode.year ? Colors.white : Colors.white70);
        break;
    }
    final dayStyle = headerTextTheme.headlineMedium?.copyWith(color: dayColor);
    final yearStyle = headerTextTheme.titleMedium?.copyWith(color: yearColor);

    Color backgroundColor;
    switch (themeData.brightness) {
      case Brightness.light:
        backgroundColor = themeData.primaryColor;
        break;
      case Brightness.dark:
        backgroundColor = themeData.colorScheme.background;
        break;
    }

    EdgeInsets padding;
    late MainAxisAlignment mainAxisAlignment;
    switch (orientation) {
      case Orientation.portrait:
        padding = const EdgeInsets.all(16);
        mainAxisAlignment = MainAxisAlignment.center;
        break;
      case Orientation.landscape:
        padding = const EdgeInsets.all(8);
        mainAxisAlignment = MainAxisAlignment.start;
        break;
    }

    final Widget yearButton = IgnorePointer(
      ignoring: mode != SolarDatePickerMode.day,
      ignoringSemantics: false,
      child: _DateHeaderButton(
        color: backgroundColor,
        onTap: Feedback.wrapForTap(
            () => _handleChangeMode(SolarDatePickerMode.year), context),
        child: Semantics(
          selected: mode == SolarDatePickerMode.year,
          child: Text(
              isPersian
                  ? '${persianDate.year}'
                  : localizations.formatYear(selectedDate),
              style: yearStyle),
        ),
      ),
    );

    final Widget dayButton = IgnorePointer(
      ignoring: mode == SolarDatePickerMode.day,
      ignoringSemantics: false,
      child: _DateHeaderButton(
        color: backgroundColor,
        onTap: Feedback.wrapForTap(
            () => _handleChangeMode(SolarDatePickerMode.day), context),
        child: Semantics(
          selected: mode == SolarDatePickerMode.day,
          child: Text(
              isPersian
                  ? '${persianDate.weekdayName},  ${persianDate.day} ${persianDate.monthName}'
                  : localizations.formatMediumDate(selectedDate),
              style: dayStyle),
        ),
      ),
    );

    return Container(
      padding: padding,
      color: backgroundColor,
      child: Column(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[yearButton, dayButton],
      ),
    );
  }
}

class _DateHeaderButton extends StatelessWidget {
  const _DateHeaderButton({
    Key? key,
    this.onTap,
    this.color,
    this.child,
  }) : super(key: key);

  final VoidCallback? onTap;
  final Color? color;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      type: MaterialType.button,
      color: color,
      child: InkWell(
        borderRadius: kMaterialEdges[MaterialType.button],
        highlightColor: theme.highlightColor,
        splashColor: theme.splashColor,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: child,
        ),
      ),
    );
  }
}

class _DayPickerGridDelegate extends SliverGridDelegate {
  const _DayPickerGridDelegate();

  @override
  SliverGridLayout getLayout(SliverConstraints constraints) {
    const columnCount = DateTime.daysPerWeek;
    final tileWidth = constraints.crossAxisExtent / columnCount;
    final viewTileHeight =
        constraints.viewportMainAxisExtent / (_kMaxDayPickerRowCount + 1);
    final tileHeight = math.max(_kDayPickerRowHeight, viewTileHeight);
    return SliverGridRegularTileLayout(
      crossAxisCount: columnCount,
      mainAxisStride: tileHeight,
      crossAxisStride: tileWidth,
      childMainAxisExtent: tileHeight,
      childCrossAxisExtent: tileWidth,
      reverseCrossAxis: axisDirectionIsReversed(constraints.crossAxisDirection),
    );
  }

  @override
  bool shouldRelayout(_DayPickerGridDelegate oldDelegate) => false;
}

const _DayPickerGridDelegate _kDayPickerGridDelegate = _DayPickerGridDelegate();

/// Displays the days of a given month and allows choosing a day.
///
/// The days are arranged in a rectangular grid with one column for each day of
/// the week.
///
/// The day picker widget is rarely used directly. Instead, consider using
/// [showSolarDatePicker], which creates a date picker dialog.
///
/// See also:
///
///  * [showSolarDatePicker], which shows a dialog that contains a material design
///    date picker.
///  * [showTimePicker], which shows a dialog that contains a material design
///    time picker.
class SolarDayPicker extends StatelessWidget {
  /// Creates a day picker.
  ///
  /// Rarely used directly. Instead, typically used as part of a [SolarMonthPicker].
  SolarDayPicker({
    Key? key,
    required this.selectedDate,
    required this.currentDate,
    required this.onChanged,
    required this.firstDate,
    required this.lastDate,
    required this.displayedMonth,
    this.selectableDayPredicate,
    this.isPersian = true,
    this.dragStartBehavior = DragStartBehavior.start,
  })  : assert(!firstDate.isAfter(lastDate)),
        assert(selectedDate.isAfter(firstDate) ||
            selectedDate.isAtSameMomentAs(firstDate)),
        super(key: key);

  final bool isPersian;

  /// The currently selected date.
  ///
  /// This date is highlighted in the picker.
  final DateTime selectedDate;

  /// The current date at the time the picker is displayed.
  final DateTime currentDate;

  /// Called when the user picks a day.
  final ValueChanged<DateTime> onChanged;

  /// The earliest date the user is permitted to pick.
  final DateTime firstDate;

  /// The latest date the user is permitted to pick.
  final DateTime lastDate;

  /// The month whose days are displayed by this picker.
  final DateTime displayedMonth;

  /// Optional user supplied predicate function to customize selectable days.
  final SelectableDayPredicate? selectableDayPredicate;

  /// Determines the way that drag start behavior is handled.
  ///
  /// If set to [DragStartBehavior.start], the drag gesture used to scroll a
  /// date picker wheel will begin upon the detection of a drag gesture. If set
  /// to [DragStartBehavior.down] it will begin when a down event is first
  /// detected.
  ///
  /// In general, setting this to [DragStartBehavior.start] will make drag
  /// animation smoother and setting it to [DragStartBehavior.down] will make
  /// drag behavior feel slightly more reactive.
  ///
  /// By default, the drag start behavior is [DragStartBehavior.start].
  ///
  /// See also:
  ///
  ///  * [DragGestureRecognizer.dragStartBehavior], which gives an example for the different behaviors.
  final DragStartBehavior dragStartBehavior;

  /// Builds widgets showing abbreviated days of week. The first widget in the
  /// returned list corresponds to the first day of week for the current locale.
  ///
  /// Examples:
  ///
  /// ```
  /// ┌ Sunday is the first day of week in the US (en_US)
  /// |
  /// S M T W T F S  <-- the returned list contains these widgets
  /// _ _ _ _ _ 1 2
  /// 3 4 5 6 7 8 9
  ///
  /// ┌ But it's Monday in the UK (en_GB)
  /// |
  /// M T W T F S S  <-- the returned list contains these widgets
  /// _ _ _ _ 1 2 3
  /// 4 5 6 7 8 9 10
  /// ```
  List<Widget> _getDayHeaders(
      TextStyle? headerStyle, MaterialLocalizations localizations) {
    final result = <Widget>[];
    for (var i = localizations.firstDayOfWeekIndex; true; i = (i + 1) % 7) {
      final weekday = localizations.narrowWeekdays[i];
      result.add(ExcludeSemantics(
        child: Center(child: Text(weekday, style: headerStyle)),
      ));
      if (i == ((isPersian ? 5 : localizations.firstDayOfWeekIndex - 1)) % 7) {
        break;
      }
    }
    return result;
  }

  static List<String> dayShort = const [
    'شنبه',
    'یکشنبه',
    'دوشنبه',
    'سه شنبه',
    'چهارشنبه',
    'پنج شنبه',
    'جمعه',
  ];

  // Do not use this directly - call getDaysInMonth instead.
  static const List<int> _daysInMonth = <int>[
    31,
    -1,
    31,
    30,
    31,
    30,
    31,
    31,
    30,
    31,
    30,
    31
  ];

  /// Returns the number of days in a month, according to the proleptic
  /// Gregorian calendar.
  ///
  /// This applies the leap year logic introduced by the Gregorian reforms of
  /// 1582. It will not give valid results for dates prior to that time.
  // ignore: avoid_positional_boolean_parameters
  static int getDaysInMonth(int year, int month, [bool isPersian = false]) {
    if (isPersian) {
      return Jalali.fromDateTime(DateTime(year, month)).monthLength;
    } else {
      if (month == DateTime.february) {
        final isLeapYear =
            (year % 4 == 0) && (year % 100 != 0) || (year % 400 == 0);
        if (isLeapYear) {
          return 29;
        }
        return 28;
      }
      return _daysInMonth[month - 1];
    }
  }

  /// Computes the offset from the first day of week that the first day of the
  /// [month] falls on.
  ///
  /// For example, September 1, 2017 falls on a Friday, which in the calendar
  /// localized for United States English appears as:
  ///
  /// ```
  /// S M T W T F S
  /// _ _ _ _ _ 1 2
  /// ```
  ///
  /// The offset for the first day of the months is the number of leading blanks
  /// in the calendar, i.e. 5.
  ///
  /// The same date localized for the Russian calendar has a different offset,
  /// because the first day of week is Monday rather than Sunday:
  ///
  /// ```
  /// M T W T F S S
  /// _ _ _ _ 1 2 3
  /// ```
  ///
  /// So the offset is 4, rather than 5.
  ///
  /// This code consolidates the following:
  ///
  /// - [DateTime.weekday] provides a 1-based index into days of week, with 1
  ///   falling on Monday.
  /// - [MaterialLocalizations.firstDayOfWeekIndex] provides a 0-based index
  ///   into the [MaterialLocalizations.narrowWeekdays] list.
  /// - [MaterialLocalizations.narrowWeekdays] list provides localized names of
  ///   days of week, always starting with Sunday and ending with Saturday.
  int _computeFirstDayOffset(
      int year, int month, int mDay, MaterialLocalizations localizations) {
    // 0-based day of week, with 0 representing Monday.
    final weekdayFromMonday = DateTime(year, month).weekday - 1;
    // 0-based day of week, with 0 representing Sunday and Saturday.
    final firstDayOfWeekFromSunday = localizations.firstDayOfWeekIndex;
    // firstDayOfWeekFromSunday recomputed to be Monday-based
    final firstDayOfWeekFromMonday = (firstDayOfWeekFromSunday - 1) % 7;
    // Number of days between the first day of week appearing on the calendar,
    // and the day corresponding to the 1-st of the month.
    return (weekdayFromMonday - firstDayOfWeekFromMonday) % 7;
  }

  String _digits(int? value, int length) {
    var ret = '$value';
    if (ret.length < length) {
      ret = '0' * (length - ret.length) + ret;
    }
    return ret;
  }

  final SolarDate date = SolarDate.sDate();

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final localizations = MaterialLocalizations.of(context);
    final year = displayedMonth.year;
    final month = displayedMonth.month;
    final mDay = displayedMonth.day;

    final getPearData = SolarDate.sDate(gregorian: displayedMonth.toString());
    final selectedPersianDate =
        SolarDate.sDate(gregorian: selectedDate.toString());

    final currentPDate = SolarDate.sDate(gregorian: currentDate.toString());

    final daysInMonth = getDaysInMonth(year, month, isPersian);
    final pDay = _digits(mDay, 2);
    final gMonth = _digits(month, 2);

    final parseP = date.parse('$year-$gMonth-$pDay');
    final stgData = date.solarToGregorian(parseP[0], parseP[1], 01);

    final pMonth = _digits(stgData[1], 2);

    final pDate =
        SolarDate.sDate(gregorian: '${stgData[0]}-$pMonth-${stgData[2]}');

    final firstDayOffset = isPersian
        ? dayShort.indexOf(pDate.weekdayName)
        : _computeFirstDayOffset(year, month, mDay, localizations);
    final labels = <Widget>[
      ..._getDayHeaders(themeData.textTheme.bodySmall, localizations),
    ];
    // ignore: literal_only_boolean_expressions
    for (var i = 0; true; i += 1) {
      // 1-based day of month, e.g. 1-31 for January, and 1-29 for February on
      // a leap year.
      final day = i - firstDayOffset + 1;
      if (day > daysInMonth) {
        break;
      }
      if (day < 1) {
        labels.add(Container());
      } else {
        final pDay = _digits(day, 2);
        final jtgData = Gregorian.fromJalali(
            Jalali(getPearData.year!, getPearData.month!, int.parse(pDay)));

        final dayToBuild = isPersian
            ? DateTime(jtgData.year, jtgData.month, jtgData.day)
            : DateTime(year, month, day);
        final disabled = dayToBuild.isAfter(lastDate) ||
            dayToBuild.isBefore(firstDate) ||
            (selectableDayPredicate != null &&
                !selectableDayPredicate!(dayToBuild));

        BoxDecoration? decoration;
        var itemStyle = themeData.textTheme.bodyMedium;

        final isSelectedDay = !isPersian
            ? (selectedDate.year == year &&
                selectedDate.month == month &&
                selectedDate.day == day)
            : (selectedPersianDate.year == getPearData.year &&
                selectedPersianDate.month == getPearData.month &&
                selectedPersianDate.day == day);
        if (isSelectedDay) {
          // The selected day gets a circle background highlight, and a contrasting text color.
          itemStyle = themeData.textTheme.bodyLarge?.copyWith(
            color: themeData.colorScheme.onSecondary,
          );
          decoration = BoxDecoration(
            color: themeData.colorScheme.secondary,
            shape: BoxShape.circle,
          );
        } else if (disabled) {
          itemStyle = themeData.textTheme.bodyMedium!
              .copyWith(color: themeData.disabledColor);
        } else {
          if ((isPersian &&
                  currentDate.year == year &&
                  currentDate.month == month &&
                  currentDate.day == day) ||
              (isPersian &&
                  currentPDate.year == getPearData.year &&
                  currentPDate.month == getPearData.month &&
                  currentPDate.day == day)) {
            // The current day gets a different text color.
            itemStyle = themeData.textTheme.bodyLarge
                ?.copyWith(color: themeData.colorScheme.secondary);
          }
        }

        Widget dayWidget = Container(
          decoration: decoration,
          child: Center(
            child: Semantics(
              // We want the day of month to be spoken first irrespective of the
              // locale-specific preferences or TextDirection. This is because
              // an accessibility user is more likely to be interested in the
              // day of month before the rest of the date, as they are looking
              // for the day of month. To do that we prepend day of month to the
              // formatted full date.
              label:
                  '${localizations.formatDecimal(day)}, ${localizations.formatFullDate(dayToBuild)}',
              selected: isSelectedDay,
              sortKey: OrdinalSortKey(day.toDouble()),
              child: ExcludeSemantics(
                child: Text(localizations.formatDecimal(day), style: itemStyle),
              ),
            ),
          ),
        );

        if (!disabled) {
          dayWidget = GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              onChanged(dayToBuild);
            },
            dragStartBehavior: dragStartBehavior,
            child: dayWidget,
          );
        }

        labels.add(dayWidget);
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: <Widget>[
          Container(
            height: _kDayPickerRowHeight,
            child: Center(
              child: ExcludeSemantics(
                child: Text(
                  isPersian
                      ? '${pDate.monthName}  ${pDate.year}'
                      : localizations.formatMonthYear(displayedMonth),
                  style: themeData.textTheme.titleMedium,
                ),
              ),
            ),
          ),
          Flexible(
            child: GridView.custom(
              gridDelegate: _kDayPickerGridDelegate,
              childrenDelegate:
                  SliverChildListDelegate(labels, addRepaintBoundaries: false),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  String formatPersianDate(Date d) {
    final f = d.formatter;

    return '${f.mN} ${f.yyyy}';
  }

  String formatPersianDate2(Date d) {
    final f = d.formatter;

    return '${f.d}';
  }
}

/// A scrollable list of months to allow picking a month.
///
/// Shows the days of each month in a rectangular grid with one column for each
/// day of the week.
///
/// The month picker widget is rarely used directly. Instead, consider using
/// [showSolarDatePicker], which creates a date picker dialog.
///
/// See also:
///
///  * [showSolarDatePicker], which shows a dialog that contains a material design
///    date picker.
///  * [showTimePicker], which shows a dialog that contains a material design
///    time picker.
class SolarMonthPicker extends StatefulWidget {
  /// Creates a month picker.
  ///
  /// Rarely used directly. Instead, typically used as part of the dialog shown
  /// by [showSolarDatePicker].
  SolarMonthPicker({
    Key? key,
    required this.selectedDate,
    required this.onChanged,
    required this.firstDate,
    required this.lastDate,
    this.isPersian = true,
    this.selectableDayPredicate,
    this.dragStartBehavior = DragStartBehavior.start,
  })  : assert(!firstDate.isAfter(lastDate)),
        assert(selectedDate.isAfter(firstDate) ||
            selectedDate.isAtSameMomentAs(firstDate)),
        super(key: key);

  /// The currently selected date.
  ///
  /// This date is highlighted in the picker.
  final DateTime selectedDate;

  /// Called when the user picks a month.
  final ValueChanged<DateTime> onChanged;

  /// The earliest date the user is permitted to pick.
  final DateTime firstDate;

  /// The latest date the user is permitted to pick.
  final DateTime lastDate;

  /// Optional user supplied predicate function to customize selectable days.
  final SelectableDayPredicate? selectableDayPredicate;

  /// {@macro flutter.widgets.scrollable.dragStartBehavior}
  final DragStartBehavior dragStartBehavior;

  final bool isPersian;

  @override
  _SolarMonthPickerState createState() => _SolarMonthPickerState();
}

class _SolarMonthPickerState extends State<SolarMonthPicker>
    with SingleTickerProviderStateMixin {
  static final Animatable<double> _chevronOpacityTween =
      Tween<double>(begin: 1, end: 0)
          .chain(CurveTween(curve: Curves.easeInOut));

  @override
  void initState() {
    super.initState();
    // Initially display the pre-selected date.
    final monthPage = _monthDelta(widget.firstDate, widget.selectedDate);
    _dayPickerController = PageController(initialPage: monthPage);
    _handleMonthPageChanged(monthPage);
    _updateCurrentDate();

    // Setup the fade animation for chevrons
    _chevronOpacityController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _chevronOpacityAnimation =
        _chevronOpacityController!.drive(_chevronOpacityTween);
  }

  @override
  void didUpdateWidget(SolarMonthPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedDate != oldWidget.selectedDate) {
      final monthPage = _monthDelta(widget.firstDate, widget.selectedDate);
      _dayPickerController = PageController(initialPage: monthPage);
      _handleMonthPageChanged(monthPage);
    }
  }

  late MaterialLocalizations localizations;
  late TextDirection textDirection;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    localizations = MaterialLocalizations.of(context);
    textDirection = Directionality.of(context);
  }

  late DateTime _todayDate;
  late DateTime _currentDisplayedMonthDate;
  Timer? _timer;
  late PageController _dayPickerController;
  AnimationController? _chevronOpacityController;
  late Animation<double> _chevronOpacityAnimation;

  void _updateCurrentDate() {
    _todayDate = DateTime.now();
    final tomorrow =
        DateTime(_todayDate.year, _todayDate.month, _todayDate.day + 1);
    var timeUntilTomorrow = tomorrow.difference(_todayDate);
    timeUntilTomorrow +=
        const Duration(seconds: 1); // so we don't miss it by rounding
    _timer?.cancel();
    _timer = Timer(timeUntilTomorrow, () {
      setState(_updateCurrentDate);
    });
  }

  static int _monthDelta(DateTime startDate, DateTime endDate) {
    return (endDate.year - startDate.year) * 12 +
        endDate.month -
        startDate.month;
  }

  /// Add months to a month truncated date.
  DateTime _addMonthsToMonthDate(DateTime monthDate, int monthsToAdd) =>
      DateTime(monthDate.year + monthsToAdd ~/ 12,
          monthDate.month + monthsToAdd % 12);

  Widget _buildItems(BuildContext context, int index) {
    var month = _addMonthsToMonthDate(widget.firstDate, index);
    if (widget.isPersian) {
      final selectedPersianDate = SolarDate.sDate(
          gregorian: widget.selectedDate.toString()); // To Edit Month Display

      final isLeapYear = ((selectedPersianDate.year ?? 0) + 1) % 4 == 0;
      if (selectedPersianDate.day! >= 1 && selectedPersianDate.day! < 12) {
        month = _addMonthsToMonthDate(widget.firstDate, index + 1);
      }
      if ((selectedPersianDate.day == 11 && widget.selectedDate.day == 1) ||
          (selectedPersianDate.day == 10 && widget.selectedDate.day == 1) ||
          (selectedPersianDate.day == 11 && widget.selectedDate.day == 2) ||
          (selectedPersianDate.day == 11 && widget.selectedDate.day == 3)) {
        month = _addMonthsToMonthDate(widget.firstDate, index);
      }
      if (isLeapYear &&
          (selectedPersianDate.day == 12 && widget.selectedDate.day == 31)) {
        month = _addMonthsToMonthDate(widget.firstDate, index + 1);
      }
    }

    return SolarDayPicker(
      key: ValueKey<DateTime>(month),
      selectedDate: widget.selectedDate,
      isPersian: widget.isPersian,
      currentDate: _todayDate,
      onChanged: widget.onChanged,
      firstDate: widget.firstDate,
      lastDate: widget.lastDate,
      displayedMonth: month,
      selectableDayPredicate: widget.selectableDayPredicate,
      dragStartBehavior: widget.dragStartBehavior,
    );
  }

  void _handleNextMonth() {
    if (!_isDisplayingLastMonth) {
      SemanticsService.announce(
          localizations.formatMonthYear(_nextMonthDate), textDirection);
      _dayPickerController.nextPage(
          duration: _kMonthScrollDuration, curve: Curves.ease);
    }
  }

  void _handlePreviousMonth() {
    if (!_isDisplayingFirstMonth) {
      SemanticsService.announce(
          localizations.formatMonthYear(_previousMonthDate), textDirection);
      _dayPickerController.previousPage(
          duration: _kMonthScrollDuration, curve: Curves.ease);
    }
  }

  /// True if the earliest allowable month is displayed.
  bool get _isDisplayingFirstMonth => !_currentDisplayedMonthDate
      .isAfter(DateTime(widget.firstDate.year, widget.firstDate.month));

  /// True if the latest allowable month is displayed.
  bool get _isDisplayingLastMonth {
    var month = widget.lastDate.month;

    if (widget.isPersian) {
      final selectedPersianDate = SolarDate.sDate(
          gregorian: widget.lastDate.toString()); // To Edit Month Display

      final isLeapYear = ((selectedPersianDate.year ?? 0) + 1) % 4 == 0;
      if (selectedPersianDate.day! >= 1 && selectedPersianDate.day! < 12) {
        month = widget.lastDate.month + 1;
      }
      if ((selectedPersianDate.day == 11 && widget.selectedDate.day == 1) ||
          (selectedPersianDate.day == 10 && widget.selectedDate.day == 1) ||
          (selectedPersianDate.day == 11 && widget.selectedDate.day == 2) ||
          (selectedPersianDate.day == 11 && widget.selectedDate.day == 3)) {
        month = widget.lastDate.month;
      }
      if (isLeapYear &&
          (selectedPersianDate.day == 12 && widget.selectedDate.day == 31)) {
        month = widget.lastDate.month + 1;
      }
    }

    return !_currentDisplayedMonthDate
        .isBefore(DateTime(widget.lastDate.year, month));
  }

  late DateTime _previousMonthDate;
  late DateTime _nextMonthDate;

  void _handleMonthPageChanged(int monthPage) {
    setState(() {
      _previousMonthDate =
          _addMonthsToMonthDate(widget.firstDate, monthPage - 1);
      _currentDisplayedMonthDate =
          _addMonthsToMonthDate(widget.firstDate, monthPage);
      _nextMonthDate = _addMonthsToMonthDate(widget.firstDate, monthPage + 1);
    });
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        // The month picker just adds month navigation to the day picker, so make
        // it the same height as the DayPicker
        height: _kMaxDayPickerHeight,
        child: Stack(
          children: <Widget>[
            Semantics(
              sortKey: _MonthPickerSortKey.calendar,
              child: NotificationListener<ScrollStartNotification>(
                onNotification: (_) {
                  _chevronOpacityController!.forward();
                  return false;
                },
                child: NotificationListener<ScrollEndNotification>(
                  onNotification: (_) {
                    _chevronOpacityController!.reverse();
                    return false;
                  },
                  child: PageView.builder(
                    dragStartBehavior: widget.dragStartBehavior,
                    key: ValueKey<DateTime>(widget.selectedDate),
                    controller: _dayPickerController,
                    scrollDirection: Axis.horizontal,
                    itemCount:
                        _monthDelta(widget.firstDate, widget.lastDate) + 2,
                    itemBuilder: _buildItems,
                    onPageChanged: _handleMonthPageChanged,
                  ),
                ),
              ),
            ),
            PositionedDirectional(
              top: 0,
              start: 8,
              child: Semantics(
                sortKey: _MonthPickerSortKey.previousMonth,
                child: FadeTransition(
                  opacity: _chevronOpacityAnimation,
                  child: IconButton(
                    icon: const Icon(Icons.chevron_left),
                    tooltip: _isDisplayingFirstMonth
                        ? null
                        : '${localizations.previousMonthTooltip} ${localizations.formatMonthYear(_previousMonthDate)}',
                    onPressed:
                        _isDisplayingFirstMonth ? null : _handlePreviousMonth,
                  ),
                ),
              ),
            ),
            PositionedDirectional(
              top: 0,
              end: 8,
              child: Semantics(
                sortKey: _MonthPickerSortKey.nextMonth,
                child: FadeTransition(
                  opacity: _chevronOpacityAnimation,
                  child: IconButton(
                    icon: const Icon(Icons.chevron_right),
                    tooltip: _isDisplayingLastMonth
                        ? null
                        : '${localizations.nextMonthTooltip} ${localizations.formatMonthYear(_nextMonthDate)}',
                    onPressed: _isDisplayingLastMonth ? null : _handleNextMonth,
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  @override
  void dispose() {
    _timer?.cancel();
    _chevronOpacityController?.dispose();
    _dayPickerController.dispose();
    super.dispose();
  }
}

// Defines semantic traversal order of the top-level widgets inside the month
// picker.
class _MonthPickerSortKey extends OrdinalSortKey {
  const _MonthPickerSortKey(double order) : super(order);

  static const _MonthPickerSortKey previousMonth = _MonthPickerSortKey(1);
  static const _MonthPickerSortKey nextMonth = _MonthPickerSortKey(2);
  static const _MonthPickerSortKey calendar = _MonthPickerSortKey(3);
}

/// A scrollable list of years to allow picking a year.
///
/// The year picker widget is rarely used directly. Instead, consider using
/// [showSolarDatePicker], which creates a date picker dialog.
///
/// Requires one of its ancestors to be a [Material] widget.
///
/// See also:
///
///  * [showSolarDatePicker], which shows a dialog that contains a material design
///    date picker.
///  * [showTimePicker], which shows a dialog that contains a material design
///    time picker.
class SolarYearPicker extends StatefulWidget {
  /// Creates a year picker.
  ///
  /// The [selectedDate] and [onChanged] arguments must not be null. The
  /// [lastDate] must be after the [firstDate].
  ///
  /// Rarely used directly. Instead, typically used as part of the dialog shown
  /// by [showSolarDatePicker].
  SolarYearPicker({
    Key? key,
    required this.selectedDate,
    required this.onChanged,
    required this.firstDate,
    required this.lastDate,
    this.isPersian = true,
    this.dragStartBehavior = DragStartBehavior.start,
  })  : assert(!firstDate.isAfter(lastDate)),
        super(key: key);

  /// The currently selected date.
  ///
  /// This date is highlighted in the picker.
  final DateTime selectedDate;

  /// Called when the user picks a year.
  final ValueChanged<DateTime> onChanged;

  /// The earliest date the user is permitted to pick.
  final DateTime firstDate;

  /// The latest date the user is permitted to pick.
  final DateTime lastDate;

  /// {@macro flutter.widgets.scrollable.dragStartBehavior}
  final DragStartBehavior dragStartBehavior;

  final bool isPersian;

  @override
  _SolarYearPickerState createState() => _SolarYearPickerState();
}

class _SolarYearPickerState extends State<SolarYearPicker> {
  static const double _itemExtent = 50;
  ScrollController? scrollController;

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController(
      // Move the initial scroll position to the currently selected date's year.
      initialScrollOffset:
          (widget.selectedDate.year - widget.firstDate.year) * _itemExtent,
    );
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    final themeData = Theme.of(context);
    final style = themeData.textTheme.bodyMedium;
    return ListView.builder(
      dragStartBehavior: widget.dragStartBehavior,
      controller: scrollController,
      itemExtent: _itemExtent,
      itemCount: widget.lastDate.year - widget.firstDate.year + 1,
      itemBuilder: (context, index) {
        final year = widget.firstDate.year + index;
        final isSelected = year == widget.selectedDate.year;
        final dateee =
            DateTime(year, widget.selectedDate.month, widget.selectedDate.day);
        final pYear = SolarDate.sDate(gregorian: dateee.toString());
        final itemStyle = isSelected
            ? themeData.textTheme.headlineSmall!
                .copyWith(color: themeData.colorScheme.secondary)
            : style;
        return InkWell(
          key: ValueKey<int>(year),
          onTap: () {
            widget.onChanged(DateTime(
                year, widget.selectedDate.month, widget.selectedDate.day));
          },
          child: Center(
            child: Semantics(
              selected: isSelected,
              child: Text(
                  widget.isPersian ? pYear.year.toString() : year.toString(),
                  style: itemStyle),
            ),
          ),
        );
      },
    );
  }
}

class _DatePickerDialog extends StatefulWidget {
  const _DatePickerDialog({
    Key? key,
    required this.initialDatePickerMode,
    this.isPersian = true,
    this.initialDate,
    this.firstDate,
    this.lastDate,
    this.selectableDayPredicate,
    this.headerContentColor,
  }) : super(key: key);

  final DateTime? initialDate;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool isPersian;
  final SelectableDayPredicate? selectableDayPredicate;
  final SolarDatePickerMode initialDatePickerMode;
  final Color? headerContentColor;

  @override
  _DatePickerDialogState createState() => _DatePickerDialogState();
}

class _DatePickerDialogState extends State<_DatePickerDialog> {
  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _mode = widget.initialDatePickerMode;
  }

  bool _announcedInitialDate = false;

  late MaterialLocalizations localizations;
  late TextDirection textDirection;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    localizations = MaterialLocalizations.of(context);
    textDirection = Directionality.of(context);
    if (!_announcedInitialDate) {
      _announcedInitialDate = true;
      SemanticsService.announce(
        localizations.formatFullDate(_selectedDate!),
        textDirection,
      );
    }
  }

  DateTime? _selectedDate;
  late SolarDatePickerMode _mode;
  final GlobalKey _pickerKey = GlobalKey();

  void _vibrate() {
    switch (Theme.of(context).platform) {
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        HapticFeedback.vibrate();
        break;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        break;
    }
  }

  void _handleModeChanged(SolarDatePickerMode mode) {
    _vibrate();
    setState(() {
      _mode = mode;
      if (_mode == SolarDatePickerMode.day) {
        SemanticsService.announce(
            localizations.formatMonthYear(_selectedDate!), textDirection);
      } else {
        SemanticsService.announce(
            localizations.formatYear(_selectedDate!), textDirection);
      }
    });
  }

  void _handleYearChanged(DateTime value) {
    if (value.isBefore(widget.firstDate!)) {
      // ignore: parameter_assignments
      value = widget.firstDate!;
    } else if (value.isAfter(widget.lastDate!)) {
      // ignore: parameter_assignments
      value = widget.lastDate!;
    }
    if (value == _selectedDate) {
      return;
    }

    _vibrate();
    setState(() {
      _mode = SolarDatePickerMode.day;
      _selectedDate = value;
    });
  }

  void _handleDayChanged(DateTime value) {
    _vibrate();
    setState(() {
      _selectedDate = value;
    });
  }

  void _handleCancel() {
    Navigator.pop(context);
  }

  void _handleOk() {
    Navigator.pop(context, _selectedDate);
  }

  Widget? _buildPicker() {
    switch (_mode) {
      case SolarDatePickerMode.day:
        return SolarMonthPicker(
          key: _pickerKey,
          isPersian: widget.isPersian,
          selectedDate: _selectedDate!,
          onChanged: _handleDayChanged,
          firstDate: widget.firstDate!,
          lastDate: widget.lastDate!,
          selectableDayPredicate: widget.selectableDayPredicate,
        );
      case SolarDatePickerMode.year:
        return SolarYearPicker(
          key: _pickerKey,
          isPersian: widget.isPersian,
          selectedDate: _selectedDate!,
          onChanged: _handleYearChanged,
          firstDate: widget.firstDate!,
          lastDate: widget.lastDate!,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final picker = _buildPicker();
    final Widget actions = ButtonBar(
      children: <Widget>[
        TextButton(
          onPressed: _handleCancel,
          child: Text(localizations.cancelButtonLabel),
        ),
        TextButton(
          onPressed: _handleOk,
          child: Text(localizations.okButtonLabel),
        ),
      ],
    );

    final dialog = Dialog(
      child: OrientationBuilder(builder: (context, orientation) {
        final Widget header = _SolarDatePickerHeader(
          selectedDate: _selectedDate!,
          isPersian: widget.isPersian,
          mode: _mode,
          onModeChanged: _handleModeChanged,
          orientation: orientation,
          headerContentColor: widget.headerContentColor,
        );
        switch (orientation) {
          case Orientation.portrait:
            return Container(
              color: theme.dialogBackgroundColor,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  header,
                  Flexible(child: picker!),
                  actions,
                ],
              ),
            );
          case Orientation.landscape:
            return Container(
              color: theme.dialogBackgroundColor,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Flexible(child: header),
                  Flexible(
                    flex: 2, // have the picker take up 2/3 of the dialog width
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Flexible(child: picker!),
                        actions,
                      ],
                    ),
                  ),
                ],
              ),
            );
        }
      }),
    );

    return Theme(
      data: theme.copyWith(
        dialogBackgroundColor: Colors.transparent,
      ),
      child: dialog,
    );
  }
}

/// Signature for predicating dates for enabled date selections.
///
/// See [showSolarDatePicker].
typedef SelectableDayPredicate = bool Function(DateTime day);

/// Shows a dialog containing a material design date picker.
///
/// The returned [Future] resolves to the date selected by the user when the
/// user closes the dialog. If the user cancels the dialog, null is returned.
///
/// An optional [selectableDayPredicate] function can be passed in to customize
/// the days to enable for selection. If provided, only the days that
/// [selectableDayPredicate] returned true for will be selectable.
///
/// An optional [initialDatePickerMode] argument can be used to display the
/// date picker initially in the year or month+day picker mode. It defaults
/// to month+day, and must not be null.
///
/// An optional [locale] argument can be used to set the locale for the date
/// picker. It defaults to the ambient locale provided by [Localizations].
///
/// An optional [textDirection] argument can be used to set the text direction
/// (RTL or LTR) for the date picker. It defaults to the ambient text direction
/// provided by [Directionality]. If both [locale] and [textDirection] are not
/// null, [textDirection] overrides the direction chosen for the [locale].
///
/// An optional [headerContentColor] argument can be used to set the color of
/// date picker header content.
///
/// The [context], [useRootNavigator] and [routeSettings] arguments are passed to
/// [showDialog], the documentation for which discusses how it is used.
///
/// The [builder] parameter can be used to wrap the dialog widget
/// to add inherited widgets like [Theme].
///
/// {@animation 350 622 https://flutter.github.io/assets-for-api-docs/assets/material/show_date_picker.mp4}
///
/// {@tool snippet}
/// Show a date picker with the dark theme.
///
/// ```dart
/// Future<DateTime> selectedDate = showDatePicker(
///   context: context,
///   initialDate: DateTime.now(),
///   firstDate: DateTime(2018),
///   lastDate: DateTime(2030),
///   builder: (BuildContext context, Widget child) {
///     return Theme(
///       data: ThemeData.dark(),
///       child: child,
///     );
///   },
/// );
/// ```
/// {@end-tool}
///
/// The [context], [initialDate], [firstDate], and [lastDate] parameters must
/// not be null.
///
/// See also:
///
///  * [showTimePicker], which shows a dialog that contains a material design
///    time picker.
///  * [SolarDayPicker], which displays the days of a given month and allows
///    choosing a day.
///  * [SolarMonthPicker], which displays a scrollable list of months to allow
///    picking a month.
///  * [SolarYearPicker], which displays a scrollable list of years to allow picking
///    a year.
Future<DateTime?> showSolarDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  bool isPersian = true,
  SelectableDayPredicate? selectableDayPredicate,
  SolarDatePickerMode initialDatePickerMode = SolarDatePickerMode.day,
  Locale? locale,
  TextDirection? textDirection,
  TransitionBuilder? builder,
  bool useRootNavigator = true,
  RouteSettings? routeSettings,
  Color? headerContentColor,
}) async {
  assert(!initialDate.isBefore(firstDate),
      'initialDate must be on or after firstDate');
  assert(!initialDate.isAfter(lastDate),
      'initialDate must be on or before lastDate');
  assert(
      !firstDate.isAfter(lastDate), 'lastDate must be on or after firstDate');
  assert(selectableDayPredicate == null || selectableDayPredicate(initialDate),
      'Provided initialDate must satisfy provided selectableDayPredicate');
  assert(debugCheckHasMaterialLocalizations(context));

  Widget child = _DatePickerDialog(
    initialDate: initialDate,
    firstDate: firstDate,
    lastDate: lastDate,
    isPersian: isPersian,
    selectableDayPredicate: selectableDayPredicate,
    initialDatePickerMode: initialDatePickerMode,
    headerContentColor: headerContentColor,
  );

  if (textDirection != null) {
    child = Directionality(
      textDirection: textDirection,
      child: child,
    );
  }

  if (locale != null) {
    child = Localizations.override(
      context: context,
      locale: locale,
      child: child,
    );
  }

  return showDialog<DateTime>(
    context: context,
    useRootNavigator: useRootNavigator,
    builder: (context) => builder == null ? child : builder(context, child),
    routeSettings: routeSettings,
  );
}
