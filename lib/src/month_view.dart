part of clean_nepali_calendar;

const Duration _kMonthScrollDuration = Duration(milliseconds: 200);

class _MonthView extends StatefulWidget {
  _MonthView({
    Key? key,
    required this.selectedDate,
    required this.onChanged,
    required this.firstDate,
    required this.lastDate,
    required this.language,
    required this.calendarStyle,
    required this.headerStyle,
    this.onChangedMonth,
    this.selectableDayPredicate,
    this.onHeaderLongPressed,
    this.onHeaderTapped,
    this.dragStartBehavior = DragStartBehavior.start,
    this.headerDayType = HeaderDayType.initial,
    this.headerDayBuilder,
    this.dateCellBuilder,
    this.headerBuilder,
    this.emptyCellBuilder,
  })  : assert(!firstDate.isAfter(lastDate)),
        assert(selectedDate.isAfter(firstDate)),
        super(key: key);

  final NepaliDateTime selectedDate;

  final ValueChanged<NepaliDateTime> onChanged;
  final ValueChanged<NepaliDateTime>? onChangedMonth;

  final NepaliDateTime firstDate;

  final NepaliDateTime lastDate;

  final SelectableDayPredicate? selectableDayPredicate;

  final DragStartBehavior dragStartBehavior;

  final Language language;

  final CalendarStyle calendarStyle;

  final HeaderStyle headerStyle;
  final HeaderGestureCallback? onHeaderTapped;
  final HeaderGestureCallback? onHeaderLongPressed;

  final HeaderDayType headerDayType;

  // build custom header
  final HeaderDayBuilder? headerDayBuilder;
  final DateCellBuilder? dateCellBuilder;
  final HeaderBuilder? headerBuilder;
  final EmptyCellBuilder? emptyCellBuilder;

  @override
  _MonthViewState createState() => _MonthViewState();
}

class _MonthViewState extends State<_MonthView>
    with SingleTickerProviderStateMixin {
  static final Animatable<double> _chevronOpacityTween =
      Tween<double>(begin: 1.0, end: 0.0)
          .chain(CurveTween(curve: Curves.easeInOut));

  @override
  void initState() {
    super.initState();
    // Initially display the pre-selected date.
    final monthPage = _monthDelta(widget.firstDate, widget.selectedDate);
    _dayPickerController = PageController(initialPage: monthPage);
    _handleMonthPageChanged(monthPage, widget.onChangedMonth);
    _updateCurrentDate();

    // Setup the fade animation for chevrons
    _chevronOpacityController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    _chevronOpacityAnimation = widget.headerStyle.enableFadeTransition
        ? _chevronOpacityController.drive(_chevronOpacityTween)
        : _chevronOpacityController.drive(Tween<double>(begin: 1.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)));
  }

  @override
  void didUpdateWidget(_MonthView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedDate != oldWidget.selectedDate) {
      final monthPage = _monthDelta(widget.firstDate, widget.selectedDate);
      _dayPickerController = PageController(initialPage: monthPage);
      _handleMonthPageChanged(monthPage, widget.onChangedMonth);
    }
  }

  late TextDirection textDirection;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    textDirection = Directionality.of(context);
  }

  late NepaliDateTime _todayDate;
  NepaliDateTime? _currentDisplayedMonthDate;
  Timer? _timer;
  PageController? _dayPickerController;
  late AnimationController _chevronOpacityController;
  Animation<double>? _chevronOpacityAnimation;

  void _updateCurrentDate() {
    _todayDate = NepaliDateTime.now();
    final tomorrow = NepaliDateTime(
      _todayDate.year,
      _todayDate.month,
      _todayDate.day + 1,
    );
    var timeUntilTomorrow = tomorrow.difference(_todayDate);
    timeUntilTomorrow +=
        const Duration(seconds: 1); // so we don't miss it by rounding
    _timer?.cancel();
    _timer = Timer(timeUntilTomorrow, () {
      setState(_updateCurrentDate);
    });
  }

  static int _monthDelta(NepaliDateTime startDate, NepaliDateTime endDate) {
    return (endDate.year - startDate.year) * 12 +
        endDate.month -
        startDate.month;
  }

  NepaliDateTime _addMonthsToMonthDate(
    NepaliDateTime monthDate,
    int monthsToAdd,
  ) {
    int year = monthsToAdd ~/ 12;
    int months = monthDate.month + monthsToAdd % 12;
    if (months > 12) {
      year += months ~/ 12;
      months = months % 12;
    }
    return NepaliDateTime(
      monthDate.year + year,
      months,
    );
  }

  Widget _buildItems(BuildContext context, int index) {
    final month = _addMonthsToMonthDate(widget.firstDate, index);
    return _DaysView(
      key: ValueKey<NepaliDateTime>(month),
      headerStyle: widget.headerStyle,
      calendarStyle: widget.calendarStyle,
      selectedDate: widget.selectedDate,
      currentDate: _todayDate,
      onChanged: widget.onChanged,
      firstDate: widget.firstDate,
      lastDate: widget.lastDate,
      displayedMonth: month,
      language: widget.language,
      selectableDayPredicate: widget.selectableDayPredicate,
      dragStartBehavior: widget.dragStartBehavior,
      headerDayType: widget.headerDayType,
      headerDayBuilder: widget.headerDayBuilder,
      dateCellBuilder: widget.dateCellBuilder,
      emptyCellBuilder: widget.emptyCellBuilder,
    );
  }

  void _handleNextMonth() {
    if (!_isDisplayingLastMonth) {
      SemanticsService.announce(
          "${formattedMonth(_nextMonthDate!.month, Language.english)} ${_nextMonthDate!.year}",
          textDirection);
      _dayPickerController!
          .nextPage(duration: _kMonthScrollDuration, curve: Curves.ease);
    }
  }

  void _handlePreviousMonth() {
    if (!_isDisplayingFirstMonth) {
      SemanticsService.announce(
          "${formattedMonth(_previousMonthDate!.month, Language.english)} ${_previousMonthDate!.year}",
          textDirection);
      _dayPickerController!
          .previousPage(duration: _kMonthScrollDuration, curve: Curves.ease);
    }
  }

  bool get _isDisplayingFirstMonth {
    return !_currentDisplayedMonthDate!
        .isAfter(NepaliDateTime(widget.firstDate.year, widget.firstDate.month));
  }

  bool get _isDisplayingLastMonth {
    return !_currentDisplayedMonthDate!
        .isBefore(NepaliDateTime(widget.lastDate.year, widget.lastDate.month));
  }

  NepaliDateTime? _previousMonthDate;
  NepaliDateTime? _nextMonthDate;

  void _handleMonthPageChanged(
      int monthPage, ValueChanged<NepaliDateTime>? onSelectedMonthChange) {
    setState(() {
      _previousMonthDate =
          _addMonthsToMonthDate(widget.firstDate, monthPage - 1);
      _currentDisplayedMonthDate =
          _addMonthsToMonthDate(widget.firstDate, monthPage);
      _nextMonthDate = _addMonthsToMonthDate(widget.firstDate, monthPage + 1);
      if (onSelectedMonthChange != null)
        onSelectedMonthChange(_currentDisplayedMonthDate!);
    });
  }

  var _viewMode = CalenderView.MonthView;

  void _toggleMonthAndYearView() {
    if (_viewMode == CalenderView.MonthView)
      _viewMode = CalenderView.YearView;
    else
      _viewMode = CalenderView.MonthView;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    double _kMaxDayPickerHeight =
        widget.calendarStyle.cellHeight * (_kMaxDayPickerRowCount);
    return SizedBox(
      height: _kMaxDayPickerHeight,
      child: Column(
        children: <Widget>[
          _CalendarHeader(
              onHeaderLongPressed: widget.onHeaderLongPressed,
              onHeaderTapped: widget.onHeaderTapped,
              language: widget.language,
              handleNextMonth: _handleNextMonth,
              handlePreviousMonth: _handlePreviousMonth,
              headerStyle: widget.headerStyle,
              chevronOpacityAnimation: _chevronOpacityAnimation,
              isDisplayingFirstMonth: _isDisplayingFirstMonth,
              previousMonthDate: _previousMonthDate,
              date: _currentDisplayedMonthDate,
              isDisplayingLastMonth: _isDisplayingLastMonth,
              nextMonthDate: _nextMonthDate,
              changeToToday: () {
                widget.onChanged(NepaliDateTime.now());
              },
              headerBuilder: widget.headerBuilder,
              toggleMonthViewAndYearView: _toggleMonthAndYearView),
          Expanded(
            child: Stack(
              children: <Widget>[
                AnimatedContainer(
                  duration: Duration(milliseconds: 1000),
                  curve: Curves.elasticOut,
                  child: (_viewMode == CalenderView.YearView)
                      ? _DatePicker(
                          maxHeight: _kMaxDayPickerHeight -
                              widget.headerStyle.headerHeight,
                          firstDate: widget.firstDate,
                          lastDate: widget.lastDate,
                          onChanged: widget.onChanged,
                          toggleView: _toggleMonthAndYearView,
                          selectedDate: widget.selectedDate,
                        )
                      : Semantics(
                          sortKey: _MonthPickerSortKey.calendar,
                          child: NotificationListener<ScrollStartNotification>(
                            onNotification: (_) {
                              _chevronOpacityController.forward();
                              return false;
                            },
                            child: NotificationListener<ScrollEndNotification>(
                              onNotification: (_) {
                                _chevronOpacityController.reverse();
                                return false;
                              },
                              child: PageView.builder(
                                dragStartBehavior: widget.dragStartBehavior,
                                key: ValueKey<NepaliDateTime>(
                                    widget.selectedDate),
                                controller: _dayPickerController,
                                scrollDirection: Axis.horizontal,
                                itemCount: _monthDelta(
                                        widget.firstDate, widget.lastDate) +
                                    1,
                                itemBuilder: _buildItems,
                                onPageChanged: (int pageNumber) {
                                  _handleMonthPageChanged(
                                      pageNumber, widget.onChangedMonth);
                                },
                              ),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _dayPickerController?.dispose();
    super.dispose();
  }
}

class _DatePicker extends StatelessWidget {
  final NepaliDateTime firstDate;
  final NepaliDateTime lastDate;
  final NepaliDateTime selectedDate;

  final double maxHeight;
  final ValueChanged<NepaliDateTime> _onChanged;
  final toggleView;

  _DatePicker(
      {Key? key,
      required this.firstDate,
      required this.lastDate,
      required this.maxHeight,
      required onChanged,
      required this.toggleView,
      required this.selectedDate})
      : _onChanged = onChanged,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: maxHeight,
      padding: EdgeInsets.all(8),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: GridView.builder(
        // spacing: 10,
        // runSpacing: 10,
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 70,
            childAspectRatio: 16 / 9,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10),
        itemCount:
            List.generate(lastDate.year - firstDate.year, (index) => index)
                .length,
        itemBuilder: (BuildContext context, int index) {
          return TextButton(
              style: ButtonStyle(
                  padding: MaterialStateProperty.resolveWith(
                      (states) => EdgeInsets.zero),
                  backgroundColor: MaterialStateProperty.resolveWith(
                      (states) => Theme.of(context).primaryColor),
                  shape: MaterialStateProperty.resolveWith((states) =>
                      RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)))),
              onPressed: () {
                toggleView();

                final dayToBuild = NepaliDateTime(firstDate.year + index,
                    selectedDate.month, selectedDate.day);
                if (firstDate.isBefore(dayToBuild) &&
                    lastDate.isAfter(dayToBuild)) _onChanged(dayToBuild);
              },
              child: Text(
                "${firstDate.year + (index)}",
                style: TextStyle(color: Colors.white),
              ));
        },
      ),
    );
  }
}

// Defines semantic traversal order of the top-level widgets inside the month
// picker.
class _MonthPickerSortKey extends OrdinalSortKey {
  const _MonthPickerSortKey(double order) : super(order);

  static const _MonthPickerSortKey previousMonth = _MonthPickerSortKey(1.0);
  static const _MonthPickerSortKey nextMonth = _MonthPickerSortKey(2.0);
  static const _MonthPickerSortKey calendar = _MonthPickerSortKey(3.0);
}

enum CalenderView { MonthView, YearView }