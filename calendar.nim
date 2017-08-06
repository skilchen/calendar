{.deadCodeElim:on.}

## Calendar printing functions
##
## Note when comparing these calendars to the ones printed by cal(1): By
## default, these calendars have Monday as the first day of the week, and
## Sunday as the last (the European convention). Use setfirstweekday() to
## set the first day of the week (0=Monday, 6=Sunday).
##

import strutils
import nimcalcal
when not defined(js):
  import posix
  import encodings

const VERSION = "0.1.0"  

type 
  Calendar = object
    firstWeekday*: int
  TextCalendar = object
    cal*: Calendar
  HTMLCalendar = object
    cal*: Calendar
    
type
  dayData = seq[int]
  weekDayData = seq[(int, int)]
  isoWeekDayData = (int, weekDayData)
  dateData = seq[calDate]
  monthDateData = seq[dateData]
  monthDayData = seq[dayData]
  monthWeekDayData = seq[weekDayData]
  monthISOWeekDayData = seq[isoWeekDayData]
  yearDateData = seq[seq[monthDateData]]
  yearDayData = seq[seq[monthDayData]]
  yearWeekDayData = seq[seq[monthWeekDayData]]
  yearISOWeekDayData = seq[seq[monthISOWeekDayData]]

const mDays = [0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

const cssclasses = ["sun", "mon", "tue", "wed", "thu", "fri", "sat"]

proc rstrip(str: string): string =
  return strip(str, leading=false, trailing=true)


proc centar(str: string, width: int, fillChar = " "): string =
  result = ""
  let strlen = len(str)
  if strlen > width:
    return str

  let right_padding = (width - strlen) div 2
  let left_padding = width - strlen - right_padding
  result.add(fillChar.repeat(left_padding))
  result.add(str)
  result.add(fillChar.repeat(right_padding))


when not defined(js):
  proc dateToTM(year, month, day: int): Tm =
    let gDate = gregorian_date(year, month, day)
    result.tm_sec = 0
    result.tm_min = 0
    result.tm_hour = 0
    result.tm_mday = cint(day)
    result.tm_mon = cint(month)
    result.tm_year = cint(year - 1900)
    result.tm_wday = cint(day_of_week_from_fixed(fixed_from_gregorian(gDate)))
    result.tm_yday = cint(day_number(gDate))
    result.tm_isdst = 0


  proc localized_days(fmt: string): seq[string] = 
    result = @[]
    # January 1, 2017, was a Sunday.
    for i in 0..6:
      var tm = dateToTM(2017, 1, i + 1)
      var wd_name = " ".repeat(21)
      let r = strftime(cstring(wd_name), cint(20), cstring(fmt), tm)
      if r != 0:
        wd_name.setLen(r)
        result.add(wd_name)
      else:
        raise new ValueError
    return result


  proc localized_months(fmt: string): array[1..12, string] = 
    # January 1, 2001, was a Monday.
    var tm: Tm 
    for i in countUp(1, 12):
      tm = dateToTM(2001, i - 1, 1)
      var month_name = " ".repeat(41)
      let r = strftime(cstring(month_name), cint(40), cstring(fmt), tm)
      if r != 0:
        month_name.setLen(r)
        result[i] = month_name
      else:
        raise new ValueError
    return result

  # Full and abbreviated names of weekdays
  var day_names = localized_days("%A")
  var day_abbrs = localized_days("%a")

  # Full and abbreviated names of months (1-based arrays!!!)
  var month_names = localized_months("%B")
  var month_abbrs = localized_months("%b")

else:

  var day_names = @["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
  var day_abbrs = @["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]
  var month_names: array[1..12, string] = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
  var month_abbrs: array[1..12, string] = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]


proc initCalendar*(firstWeekDay = 1): Calendar =
  return Calendar(firstWeekDay: firstWeekDay)


proc initTextCalendar*(firstWeekDay = 1): TextCalendar =
  return TextCalendar(cal: Calendar(firstWeekDay: firstWeekDay))


proc initHTMLCalendar*(firstWeekDay = 1): HTMLCalendar =
  # CSS classes for the day <td>s

  return HTMLCalendar(cal: Calendar(firstWeekDay: firstWeekDay))


when not defined(js):
  proc initLocaleCalendar*(firstWeekDay = 1, locale: cstring = nil): Calendar =
    if locale == nil:
      let lcl = setlocale(0, "")  
    # Full and abbreviated names of weekdays
    day_names = localized_days("%A")
    day_abbrs = localized_days("%a")

    # Full and abbreviated names of months (1-based arrays!!!)
    month_names = localized_months("%B")
    month_abbrs = localized_months("%b")
    result.firstWeekday = firstWeekDay


proc monthrange*(year, month: int): (int, int) = 
    ##
    ## Return weekday (0-6 ~ Mon-Sun) and number of days (28-31) for
    ## year, month.
    ## 
    if month  < 1 or month > 12:
        raise new ValueError

    let day1 = day_of_week_from_fixed(fixed_from_gregorian(gregorian_date(year, month, 1)))
    var ndays = mdays[month]
    if month == 2 and is_gregorian_leap_year(year): 
      ndays += 1
    return (day1, ndays)


iterator iterweekdays*(cal: Calendar): int =
  ##
  ##  Return an iterator for one week of weekday numbers starting with the
  ##  configured first one.
  ##
  for i in countUp(cal.firstweekday, cal.firstweekday + 6):
    yield modulo(i, 7)


iterator iterISOWeekDates*(cal: Calendar, year, isoweek: int): calDate =
  ##
  ## Return an iterator for one iso week
  ## 
  var fDate = fixed_from_iso(iso_date(year, isoweek, 1))
  while true:
    var gDate = gregorian_from_fixed(fDate)
    yield gDate
    fDate += 1
    let isoDate = iso_from_fixed(fDate)
    if iso_week(isoDate) != isoweek:
      break


iterator iterISOWeekDays*(cal: Calendar, year, isoweek: int): int =
  ##
  ## like iterISOWeekDates, but will yield day numbers. For days outside
  ## the specified year, the day number is 0
  ## 
  for gDate in iterISOWeekDates(cal, year, isoweek):
    if standard_year(gDate) != year:
      yield 0
    else:
      yield standard_day(gDate)


iterator iterISOWeekDays2*(cal: Calendar, year, isoweek: int): (int, int) =
    ##
    ## Like iterISOWeekDays, but will yield (day number, weekday number)
    ## tuples. For days outside the specified year the day number is 0.
    ## ISO Weekday number are defined as 1 (MO) to 7 (SU)
    var wd_nr = 1
    for d in iterISOWeekDays(cal, year, isoweek):
      yield (d, wd_nr)
      inc(wd_nr)


iterator iterISOWeekDays3*(cal: Calendar, year, isoweek: int): (int, int, int) =
    ##
    ## Like iterISOWeekDays, but will yield (month number, day number, weekday number)
    ## tuples. For days outside the specified year the month and day numbers are 0.
    ## ISO Weekday number are defined as 1 (MO) to 7 (SU)
    var wd_nr = 1
    for gDate in iterISOWeekDates(cal, year, isoweek):
      if standard_year(gDate) != year:
        yield (0, 0, wd_nr)
      else:
        yield (standard_month(gDate), standard_day(gDate), wd_nr)
      inc(wd_nr)


proc isoWeekDays3calendar(cal: Calendar, year, isoweek: int): seq[(int, int, int)] =
  result = @[]
  for m, d, wd in iterISOWeekDays3(cal, year, isoweek):
    result.add((m, d, wd))
  return result


iterator iterMonthDates*(cal: Calendar, year: int, month: int): calDate =
  ##
  ## Return an iterator for one month. The iterator will yield gregorian date
  ## values and will always iterate through complete weeks, so it will yield
  ## dates outside the specified month.
  ## 
  var fDate = fixed_from_gregorian(gregorian_date(year, month, 1))
  let days = modulo((day_of_week_from_fixed(fDate) - cal.firstweekday), 7)
  fDate -= days

  while true:
    var gDate = gregorian_from_fixed(fDate)
    yield gDate
    fDate += 1
    gDate = gregorian_from_fixed(fDate)
    if standard_month(gDate) != month and day_of_week_from_fixed(fDate) == cal.firstweekday:
      break


iterator itermonthdays*(cal: Calendar, year, month: int): int =
    ##
    ## Like itermonthdates(), but will yield day numbers. For days outside
    ## the specified month the day number is 0.
    ##
    let (day1, ndays) = monthrange(year, month)
    let days_before = modulo((day1 - cal.firstweekday), 7)
    for _ in countUp(0, days_before - 1):
        yield 0
    for d in countUp(1, ndays):
        yield d
    let days_after = modulo(cal.firstweekday - day1 - ndays, 7)
    for _ in countUp(0, days_after - 1):
        yield 0


iterator itermonthdays2*(cal: Calendar, year, month: int): (int, int) =
    ##
    ## Like itermonthdates(), but will yield (day number, weekday number)
    ## tuples. For days outside the specified month the day number is 0.
    ##
    var i = cal.firstWeekDay
    for d in cal.itermonthdays(year, month):
        yield (d, modulo(i, 7))
        inc(i)


# proc monthdatescalendar(cal: Calendar, year, month: int): seq[seq[calDate]] =
proc monthdatescalendar*(cal: Calendar, year, month: int): monthDateData =
    ##
    ## Return a matrix (list of lists) representing a month's calendar.
    ## Each row represents a week; week entries are gregorian_date values.
    ## 
    result = @[]
    var dates: seq[calDate] = @[]
    for d in cal.itermonthdates(year, month):
      dates.add(d)
    for i in countUp(0, len(dates) - 1, 7):
      result.add(dates[i..i+6])
    return result


# proc monthdays2calendar(cal: Calendar, year, month: int): seq[seq[(int, int)]] =
proc monthdays2calendar*(cal: Calendar, year, month: int): monthWeekDayData =
    ##
    ## Return a matrix representing a month's calendar.
    ## Each row represents a week; week entries are
    ## (day number, weekday number) tuples. Day numbers outside this month
    ## are zero.
    ##
    result = @[]
    var days: seq[(int, int)] = @[]
    for d in cal.itermonthdays2(year, month):
      days.add(d)
    for i in countUp(0, len(days) - 1, 7):
      result.add(days[i..i+6])
    return result


# proc monthdays2calendar_iso(cal: Calendar, year, month: int): seq[(int, seq[(int, int)])] =
proc monthdays2calendar_iso*(cal: Calendar, year, month: int): monthISOWeekDayData =
    ##
    ## Return a matrix representing a month's calendar.
    ## Each row represents a week; week entries are iso week number followed by
    ## (day number, weekday number) tuples. Day numbers outside this month
    ## are zero.
    ##
    result = @[]
    var days: seq[(int, int)] = @[]
    for d in cal.itermonthdays2(year, month):
      days.add(d)
    for i in countUp(0, len(days) - 1, 7):
      var nonzero_day: int
      var iso_week: int
      for j in i..i+6:
        if days[j][0] != 0:
          iso_week = iso_week(iso_from_fixed(fixed_from_gregorian(gregorian_date(year, month, days[j][0]))))
          break
      result.add((iso_week, days[i..i+6]))
    return result


# proc monthdayscalendar(cal: Calendar, year, month: int): seq[seq[int]] =
proc monthdayscalendar*(cal: Calendar, year, month: int): monthDayData =
    ##
    ## Return a matrix representing a month's calendar.
    ## Each row represents a week; days outside this month are zero.
    ##
    result = @[]
    var days: seq[int] = @[]
    for d in cal.itermonthdays(year, month):
      days.add(d)
    for i in countUp(0, len(days) - 1, 7):
      result.add(days[i..i+6])
    return result


#proc yeardatescalendar(cal: Calendar, year: int, width: int = 3): seq[seq[seq[calDate]]] =
proc yeardatescalendar*(cal: Calendar, year: int, width: int = 3): yearDateData =
    ##
    ## Return the data for the specified year ready for formatting. The return
    ## value is a list of month rows. Each month row contains up to width months.
    ## Each month contains between 4 and 6 weeks and each week contains 1-7
    ## days. Days are gregorian_date objects.
    ##
    # var months: seq[seq[calDate]] = @[]
    var months: seq[monthDateData] = @[]
    for i in countUp(1, 12):
      months.add(cal.monthdatescalendar(year, i))
    result = @[]
    for i in countUp(0, len(months) - 1, width):
      result.add(months[i..i+width-1])
    return result


# proc yeardays2calendar(cal: Calendar, year: int, width: int =3): seq[seq[seq[seq[(int, int)]]]] =
proc yeardays2calendar*(cal: Calendar, year: int, width: int =3): yearWeekDayData =
    ##
    ## Return the data for the specified year ready for formatting (similar to
    ## yeardatescalendar()). Entries in the week lists are
    ## (day number, weekday number) tuples. Day numbers outside this year are
    ## zero.
    ##
    # var months: seq[seq[seq[(int, int)]]] = @[]
    var months: seq[monthWeekDayData] = @[]
    for i in countUp(1, 12):
        months.add(cal.monthdays2calendar(year, i))
    result = @[]
    for i in countUp(0, len(months) - 1, width):
      result.add(months[i..min(i+width-1, high(months))])
    return result


# proc yeardays2calendar_iso(cal: Calendar, year: int, width: int =3): seq[seq[seq[(int, seq[(int, int)])]]] =
proc yeardays2calendar_iso*(cal: Calendar, year: int, width: int =3): yearISOWeekDayData =
    ##
    ## Return the data for the specified year ready for formatting (similar to
    ## yeardatescalendar()). Entries in the week lists are iso_week followed by
    ## (day number, weekday number)) tuples. Day numbers outside this year are
    ## zero.
    ##
    # var months: seq[seq[(int, seq[(int, int)])]] = @[]
    var months: seq[monthISOWeekDayData] = @[]
    for i in countUp(1, 12):
        months.add(cal.monthdays2calendar_iso(year, i))
    result = @[]
    for i in countUp(0, len(months) - 1, width):
      result.add(months[i..i+width-1])
    return result


# proc yeardayscalendar(cal: Calendar, year: int, width: int =3): seq[seq[seq[int]]] =
proc yeardayscalendar*(cal: Calendar, year: int, width: int =3): yearDayData =
    ##
    ## Return the data for the specified year ready for formatting (similar to
    ## yeardatescalendar()). Entries in the week lists are day numbers.
    ## Day numbers outside this year are zero.
    ##
    # var months: seq[seq[int]] = @[]
    var months: seq[monthDayData] = @[]
    for i in countUp(1, 12):
      months.add(cal.monthdayscalendar(year, i))
    result = @[]
    for i in countUp(0, len(months) - 1, width):
      result.add(months[i..i+width-1])
    return result


proc isoYearCalendar*(cal: Calendar, year: int): seq[(int, seq[(int, int, int)])] =
  ##
  ## Return the data for the specified year ready for formatting.
  ## Entries in the week list are iso week number, followed by a
  ## sequence of month_number, day_number, weekday_number triples 
  ## in the iso week. days outside this year are zero.
  ## 
  let first_iso_week = iso_week(iso_from_fixed(gregorian_new_year(year)))
  let last_iso_week = iso_week(iso_from_fixed(gregorian_year_end(year)))
  result = @[]
  if first_iso_week != 1:
    var wd = 1
    var days: seq[(int, int, int)] = @[]
    for gd in iterISOWeekDates(cal, year - 1, first_iso_week):
      if standard_year(gd) == year:
        days.add((standard_month(gd), standard_day(gd), wd))
      else:
        days.add((0, 0, wd))
      inc(wd)
    result.add((first_iso_week, days))

  for week in 1..52:
    result.add((week, isoWeekDays3calendar(cal, year, week)))

  if last_iso_week == 53:
    result.add((last_iso_week, isoWeekDays3calendar(cal, year, last_iso_week)))
  elif last_iso_week == 1:
    var wd = 1
    var days: seq[(int, int, int)] = @[]
    for gd in iterISOWeekDates(cal, year + 1, last_iso_week):
      if standard_year(gd) == year:
        days.add((standard_month(gd), standard_day(gd), wd))
      else:
        days.add((0, 0, wd))
      inc(wd)
    result.add((last_iso_week, days))
  return result


proc formatday*(tcal: TextCalendar, day, weekday, width: int): string =
  ##
  ## Returns a formatted day.
  ##
  result = ""
  if day != 0:
    if day < 10:
      result.add(" ")
    result.add($day)
  return result.center(width)


proc formatday*(hcal: HTMLCalendar, day, weekday: int): string =
  ##
  ## Return a day as a table cell.
  ##
  if day == 0:
    return """<td class="$1">&nbsp;</td>""" % ["noday"] # day outside month
  else:
    return """<td class="$1" align="center">$2</td>""" % [cssclasses[weekday], $day]


proc formatweek*(tcal: TextCalendar, theweek: seq[(int, int)], width: int): string =
    ##
    ## Returns a single week in a string (no newline).
    ##
    result = ""
    for d in theweek:
      result.add(tcal.formatday(d[0], d[1], width))
      result.add(" ")
    return result[0..^2]


proc formatweek*(hcal: HTMLCalendar, theweek: seq[(int, int)]): string =
  ##
  ## Return a complete week as a table row.
  ##
  var daylist: seq[string] = @[]

  for d, wd in items(theweek):
    daylist.add(formatday(hcal, d, wd))
  return """<tr>$1</tr>""" % [join(daylist, "")]


proc formatweek_iso*(tcal: TextCalendar, theweek: (int, seq[(int, int)]), width: int): string =
    ##
    ## Returns a single week in a string (no newline).
    ##
    result = ""
    let iso_week = theweek[0]
    result.add(tcal.formatday(iso_week, 0, width) & " ")
    for d in theweek[1]:
      result.add(tcal.formatday(d[0], d[1], width))
      result.add(" ")
    return result[0..^2]


proc formatweek_iso*(hcal: HTMLCalendar, theweek: (int, seq[(int, int)])): string =
  var daylist: seq[string] = @[]
  
  let iso_week = theweek[0]
  daylist.add("""<td class="isoweek" align="center">$1</td>""" % [$iso_week])
  for d, wd in items(theweek[1]):
    daylist.add(formatday(hcal, d, wd))
  return """<tr>$1</tr>""" % [join(daylist, "")]


proc formatweekday*(tcal: TextCalendar, day, width: int): string =
    ##
    ## Returns a formatted week day name.
    ##
    var names: seq[string]
    if width >= 9:
        names = day_names
    else:
        names = day_abbrs
    var name = names[day]
    if len(name) >= width:
      name = name[0..width-1]
    return name.center(width)


proc formatweekday(hcal: HTMLCalendar, day: int): string =
  ##
  ## Return a weekday name as a table header.
  ##
  return """<th class="$1" align="center">$2</th>""" % [cssclasses[day], day_abbrs[day]]


proc formatisoweektxt*(tcal: TextCalendar, width: int): string =
  if width < 5:
    return "wn".center(width)
  elif width < 8:
    return "week".center(width)
  else:
    return "iso week".center(width)


proc formatweekheader*(tcal: TextCalendar, width: int): string =
    ##
    ## Return a header for a week.
    ##
    result = ""
    for i in tcal.cal.iterweekdays():
      result.add(tcal.formatweekday(i, width))
      result.add(" ")
    return result[0..^2]


proc formatweekheader*(hcal: HTMLCalendar): string =
  ##
  ## Return a header for a week as a table row.
  ## 
  var headerlist: seq[string] = @[]
  for i in hcal.cal.iterweekdays():
    headerlist.add(formatweekday(hcal, i))
  return """<tr class="week">$1</tr>""" % [join(headerlist, "")]


proc formatweekheader_iso*(tcal: TextCalendar, width: int): string =
    ##
    ## Return a header for a iso week including week number
    ##
    result = tcal.formatisoweektxt(width) & " "
    for i in tcal.cal.iterweekdays():
      result.add(tcal.formatweekday(i, width))
      result.add(" ")
    return result[0..^2]

proc formatweekheader_iso*(hcal: HTMLCalendar): string =
  ##
  ## Return a header for a week as a table row.
  ## 
  var headerlist: seq[string] = @[]
  headerlist.add("""<th class="isoweek">week</th>""")
  for i in hcal.cal.iterweekdays():
    headerlist.add(formatweekday(hcal, i))
  return """<tr class="week">$1</tr>""" % [join(headerlist, "")]


proc formatmonthname*(tcal: TextCalendar, theyear, themonth, width: int, withyear: bool=true): string =
    ##
    ## Return a formatted month name.
    ## 
    var s = $month_names[themonth]
    if withyear:
      s = s & " " & $theyear
    return s.center(width)


proc formatmonthname*(hcal: HTMLCalendar, theyear, themonth: int, withyear: bool = true, withweek = false): string =
  ##
  ## Return a month name as a table row.
  ##
  var s: string
  if withyear:
    s = """$1 $2""" % [month_names[themonth], $theyear]
  else:
    s = """$1""" % [month_names[themonth]]
  if withweek:
    return """<tr><th colspan="8" class="month">$1</th></tr>""" % [s]
  else:
    return """<tr><th colspan="7" class="month">$1</th></tr>""" % [s]


proc formatmonth*(tcal: TextCalendar, theyear, themonth: int, w=0, lines=0): string =
    ##
    ## Return a month's calendar string (multi-line).
    ##
    let w = max(2, w)
    let lines = max(1, lines)
    var s = tcal.formatmonthname(theyear, themonth, 7 * (w + 1) - 1)
    s = s.rstrip()
    s = s & "\n".repeat(lines)
    s = s & tcal.formatweekheader(w).rstrip()
    s = s & "\n".repeat(lines)
    for week in tcal.cal.monthdays2calendar(theyear, themonth):
        s = s & tcal.formatweek(week, w).rstrip()
        s = s & "\n".repeat(lines)
    return s


proc formatmonth(hcal: HTMLCalendar, theyear, themonth: int, withyear = true): string =
  ##
  ## Return a formatted month as a table.
  ##
  var v: seq[string] = @[]
  v.add("""<table border="0" cellpadding="3" cellspacing="0" class="month" width="100%">""")
  v.add(hcal.formatmonthname(theyear, themonth, withyear = withyear))
  v.add(hcal.formatweekheader())
  for week in hcal.cal.monthdays2calendar(theyear, themonth):
    v.add(hcal.formatweek(week))
  v.add("</table>")
  return join(v, "\n")


proc formatmonth_iso*(tcal: TextCalendar, theyear, themonth: int, w=0, lines=0): string =
    ##
    ## Return a month's calendar string including iso week numbers (multi-line).
    ##
    let w = max(2, w)
    let lines = max(1, lines)
    var s = tcal.formatmonthname(theyear, themonth, 8 * (w + 1) - 2)
    s = s.rstrip()
    s = s & "\n".repeat(lines)
    s = s & tcal.formatweekheader_iso(w).rstrip()
    s = s & "\n".repeat(lines)
    for week in tcal.cal.monthdays2calendar_iso(theyear, themonth):
      let iso_week = week[0]
      s = s & tcal.formatday(iso_week, 0, w)
      s = s & " "
      s = s & tcal.formatweek(week[1], w).rstrip()
      s = s & "\n".repeat(lines)
    return s


proc formatmonth_iso*(hcal: HTMLCalendar, theyear, themonth: int, withyear = true): string =
  ##
  ## Return a formatted month as a table, including iso week numbers
  ##
  var v: seq[string] = @[]
  v.add("""<table border="0" cellpadding="3" cellspacing="0" class="month" width="100%">""")
  v.add(hcal.formatmonthname(theyear, themonth, withyear = withyear, withweek = true))
  v.add(hcal.formatweekheader_iso())
  for week in hcal.cal.monthdays2calendar_iso(theyear, themonth):
    v.add(hcal.formatweek_iso(week))
  v.add("</table>")
  return join(v, "\n")


proc prmonth*(tcal: TextCalendar, theyear, themonth: int, w=0, lines=0) = 
    ##
    ## Print a month's calendar.
    ## 
    echo tcal.formatmonth(theyear, themonth, w, lines)


proc prmonth_iso*(tcal: TextCalendar, theyear, themonth: int, w=0, lines=0) = 
    ##
    ## Print a month's calendar including iso week numbers
    ## 
    echo tcal.formatmonth_iso(theyear, themonth, w, lines)


const default_colwidth = 7*3 - 1         # Amount printed by prweek()
const default_spacing = 6 # number of spaces between columns


proc formatstring*(cols: seq[string], colwidth=default_colwidth, spacing=default_spacing): string =
    ## Returns a string formatted from n strings, centered within n columns.
    let spaces = " ".repeat(spacing)
    result = ""
    for c in cols:
      result.add(c.center(colwidth))
      result.add(spaces)
    return result.rstrip()


proc formatyear*(tcal: TextCalendar, theyear: int, w=2, lines=1, c=6, m=3): string =
    ##
    ## Returns a year's calendar as a multi-line string.
    ##
    let w = max(2, w)
    let lines = max(1, lines)
    let c = max(2, c)
    let colwidth = (w + 1) * 7 - 1
    var v: seq[string] = @[]

    v.add(($theyear).center(colwidth*m+c*(m-1)).rstrip())
    v.add("\n".repeat(lines))
    let header = tcal.formatweekheader(w)
    var i = 0
    for row in tcal.cal.yeardays2calendar(theyear, m):
      # months in this row
      v.add("\n".repeat(lines))
      var names: seq[string] = @[]
      for k in countup(m * i + 1, min(m * (i + 1), 12)):
        names.add(tcal.formatmonthname(theyear, k, colwidth, false))

      v.add(formatstring(names, colwidth, c).rstrip())
      v.add("\n".repeat(lines))
      var headers: seq[string] = @[]
      for k in countup(m * i + 1, min(m * (i + 1), 12)):
        headers.add(header)
      v.add(formatstring(headers, colwidth, c).rstrip())
      v.add("\n".repeat(lines))
      # max number of weeks for this row
      var height: int
      for cal in row:
        if len(cal) > height:
          height = len(cal)
      for j in countup(0, height - 1):
        var weeks: seq[string] = @[]
        for cal in row:
          if j >= len(cal):
            weeks.add("")
          else:
            weeks.add(tcal.formatweek(cal[j], w))
        v.add(formatstring(weeks, colwidth, c).rstrip())
        v.add("\n".repeat(lines))
      inc(i)

    return join(v, "")


proc formatyear(hcal: HTMLCalendar, theyear: int, months_per_row: int = 3): string =
  ##
  ## Return a formatted year as a table of tables.
  ##
  var v: seq[string] = @[]

  let months_per_row = max(months_per_row, 1)
  v.add("""<table border="0", cellpadding="10" cellspacing="0" class="year" width="100%">""")
  v.add("""<tr class="year"><th colspan="$1" class="year" width="100%">$2</th></tr>""" % [$months_per_row, $theyear])
  for i in countUp(1, 12, months_per_row):
    # months in this row
    v.add("""<tr class="year">""")
    for month in countUp(i, min(i + months_per_row - 1, 12)):
      v.add("""<td class="year" valign="top">""")
      v.add(hcal.formatmonth(theyear, month, withyear = false))
      v.add("</td>")
    v.add("</tr>")
  v.add("</table>")
  return join(v, "\n")


proc formatyear_iso*(hcal: HTMLCalendar, theyear: int, months_per_row: int = 3): string =
  ##
  ## Return a formatted year as a table of tables.
  ##
  var v: seq[string] = @[]

  let months_per_row = max(months_per_row, 1)
  v.add("""<table border="0", cellpadding="10" cellspacing="0" class="year" width="100%">""")
  v.add("""<tr class="year"><th colspan="$1" class="year" width="100%">$2</th></tr>""" % [$months_per_row, $theyear])
  for i in countUp(1, 12, months_per_row):
    # months in this row
    v.add("""<tr class="year">""")
    for month in countUp(i, min(i + months_per_row - 1, 12)):
      v.add("""<td class="year" valign="top">""")
      v.add(hcal.formatmonth_iso(theyear, month, withyear = false))
      v.add("</td>")
    v.add("</tr>")
  v.add("</table>")
  return join(v, "\n")


proc formatmonthpage(hcal: HTMLCalendar, theyear, themonth: int, css = "calendar.css", 
                     encoding: string = "UTF-8", withiso: bool = false): string =
  ##
  ## Return a formatted year as a complete HTML page.
  ##
  var v: seq[string] = @[]

  v.add("""<?xml version="1.0" encoding="$1"?>""" % [encoding])
  v.add("""<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">""")
  v.add("<html>")
  v.add("<head>")
  v.add("""<meta http-equiv="Content-Type" content="text/html; charset=$1"/>""" % [encoding])
  if css != "":
    v.add("""<link rel="stylesheet" type="text/css" href="$1"/>""" % [css])
  v.add("""<title>Calendar for $1 $2</title>""" % [$theyear, $themonth])
  v.add("</head>")
  v.add("<body>")
  if withiso:
    v.add(hcal.formatmonth_iso(theyear, themonth, withyear = true))
  else:
    v.add(hcal.formatmonth(theyear, themonth, withyear = true))
  v.add("</body>")
  v.add("</html>")
  return join(v, "\n") # .encode(encoding, "xmlcharrefreplace")


proc formatyearpage(hcal: HTMLCalendar, theyear: int, width = 3, css = "calendar.css", 
                    encoding: string = "UTF-8", withiso: bool = false): string =
  ##
  ## Return a formatted year as a complete HTML page.
  ##
  var v: seq[string] = @[]

  v.add("""<?xml version="1.0" encoding="$1"?>""" % [encoding])
  v.add("""<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">""")
  v.add("<html>")
  v.add("<head>")
  v.add("""<meta http-equiv="Content-Type" content="text/html; charset=$1"/>""" % [encoding])
  if css != "":
    v.add("""<link rel="stylesheet" type="text/css" href="$1"/>""" % [css])
  v.add("""<title>Calendar for $1</title>""" % [$theyear])
  v.add("</head>")
  v.add("<body>")
  if withiso:
    v.add(hcal.formatyear_iso(theyear, width))
  else:
    v.add(hcal.formatyear(theyear, width))
  v.add("</body>")
  v.add("</html>")
  return join(v, "\n") # .encode(encoding, "xmlcharrefreplace")


proc formatyear_iso*(tcal: TextCalendar, theyear: int, w=2, lines=1, c=6, m=3): string =
    ##
    ## Returns a year's calendar including iso week numbers as a multi-line string.
    ##
    let w = max(2, w)
    let lines = max(1, lines)
    let c = max(2, c)
    let colwidth = (w + 1) * 8 - 1
    var v: seq[string] = @[]

    v.add(($theyear).center(colwidth*m+c*(m-1)).rstrip())
    v.add("\n".repeat(lines))
    let header = tcal.formatweekheader_iso(w)
    var i = 0
    for row in tcal.cal.yeardays2calendar_iso(theyear, m):
      # months in this row
      v.add("\n".repeat(lines))
      var names: seq[string] = @[]
      for k in countup(m * i + 1, min(m * (i + 1), 12)):
        names.add(tcal.formatmonthname(theyear, k, colwidth, false))

      v.add(formatstring(names, colwidth, c).rstrip())
      v.add("\n".repeat(lines))
      var headers: seq[string] = @[]
      for k in countup(m * i + 1, min(m * (i + 1), 12)):
        headers.add(header)
      v.add(formatstring(headers, colwidth, c).rstrip())
      v.add("\n".repeat(lines))
      # max number of weeks for this row
      var height: int
      for cal in row:
        if len(cal) > height:
          height = len(cal)
      for j in countup(0, height - 1):
        var weeks: seq[string] = @[]
        for cal in row:
          if j >= len(cal):
            weeks.add("")
          else:
            weeks.add(tcal.formatweek_iso(cal[j], w))
        v.add(formatstring(weeks, colwidth, c).rstrip())
        v.add("\n".repeat(lines))
      inc(i)

    return join(v, "")


proc formatISOYearCalendar*(tcal: TextCalendar, theyear: int, width, lines: int): string =
  var width = max(5, width)
  let linewidth = (width + 1) * 8 - 1
  var lines = max(1, lines)
  var v: seq[string] = @[]

  v.add(($theyear).center(linewidth).rstrip())
  v.add("\n".repeat(lines))
  let header = tcal.formatweekheader_iso(width)
  v.add(header.rstrip())
  v.add("\n".repeat(lines))
  for wn, weekdata in items(isoYearCalendar(tcal.cal, theyear)):
    var line = ""
    line.add(formatday(tcal, wn, 0, width))
    line.add(" ")
    for m, d, wd in items(weekdata):
      var day = ""
      if d == 0:
        day.add(" ".repeat(width))
      else: 
        if m < 10:
          day.add("0")
        day.add($m)
        day.add("-")
        if d < 10:
          day.add("0")
        day.add($d)
      line.add(center(day, width))
      line.add(" ")
    v.add(line.rstrip())
    v.add("\n".repeat(lines))
  return v.join("")


proc pryear*(tcal: TextCalendar, theyear: int, w=0, lines=0, c=6, m=3) =
    ## Print a year's calendar.
    echo tcal.formatyear(theyear, w, lines, c, m)


proc pryear_iso*(tcal: TextCalendar, theyear: int, w=0, lines=0, c=6, m=3) =
    ## Print a year's calendar, including iso week numbers
    echo tcal.formatyear_iso(theyear, w, lines, c, m)


proc prISOyear*(tcal: TextCalendar, theyear: int, width=5, lines=1) =
  ##
  ## Print a somewhat strange ISO year calendar
  ## 
  echo tcal.formatISOYearCalendar(theyear, width, lines)


when isMainModule:
  let helpText = """
    Usage: 
      $1 [options] [--] [<year>] [<month>]
      $1 -h  to show possible options

    Options:
       -h, --help              Show this screen and exit.
       -v, --version           Show version and exit.
       -y, --year=<y>          show year calendar for year <y> (only necessary for negative years)      
       -w, --width=<w>         width of date column [default: 2]
       -l, --lines=<n>         number of lines for each week [default: 1]
       -s, --spacing=<n>       spacing between months [default: 6]
       -m, --months=<n>        months per row [default: 3]
       -L, --localized         day and month names in your current locale setting [default: false]
       -W, --firstWeekDay=<n>  first day of week, where Mo = 1, Tu = 2, We = 3, Th = 4, Fr = 5, Sa = 6, Su = 0 [default: 1]
       -t, --type=<str>        output type (text or html) [default: text]
       -c, --css=<filename>    CSS to use for calendar page (html only) [default: calendar.css]
       --locale=<locale_id>    "use locale_id for the day and month names"
       --iso                   include iso week number in output
       --isoYear               list of iso weeks in year
       --easter                get the gregorian date of easter in a specified year or the current year
  """ % ["calendar1"] 

  when not defined(js):
    import docopt

    let args = docopt(helpText, version="0.1.0")
    # echo $args

    var cal: Calendar

    if args["--locale"]:
      let lcl = setlocale(0, $args["--locale"])
      cal = initLocaleCalendar(firstWeekday = parseInt($args["--firstWeekDay"]), lcl)
    if args["--localized"]:
      cal = initLocaleCalendar(firstWeekday = parseInt($args["--firstWeekDay"]))
    else:
      cal = initCalendar(firstWeekday = parseInt($args["--firstWeekDay"]))

    if $args["--type"] == "text":
      var tcal = TextCalendar(cal: cal)    

      if args["--isoYear"]:
        var year: int
        if args["<year>"]:
          year = parseInt($args["<year>"])
        elif args["--year"]:
          year = parseInt($args["--year"])
        else:
          year = standard_year(gregorian_from_fixed(fixed_from_now()))
        let width = max(5, parseInt($args["--width"]))
        let lines = parseInt($args["--lines"])
        prISOyear(tcal, year, width, lines)
        quit(0)

      var pryear_proc = pryear
      var prmonth_proc = prmonth
      if args["--iso"]:
        tcal.cal.firstweekday = 1
        pryear_proc = pryear_iso
        prmonth_proc = prmonth_iso

      if args["--easter"]:
        var year = standard_year(gregorian_from_fixed(fixed_from_now()))
        if args["<year>"]:
          year = parseInt($args["<year>"])
        elif args["--year"]:
          year = parseInt($args["--year"])
        let easter = gregorian_from_fixed(easter(year))
        year = standard_year(easter)
        let month = standard_month(easter)
        tcal.prmonth_proc(year, month,
                          w = parseInt($args["--width"]),
                          lines = parseInt($args["--lines"]))  
        echo "easter date: ",  easter
        quit(0)

      if args["--year"]:
        let year = parseInt($args["--year"])
        if args["<year>"]:
          # if --year is on the command line, we interpret the first positional
          # argument as the month
          let month = parseInt($args["<year>"])
          tcal.prmonth_proc(year, month,
                            w = parseInt($args["--width"]),
                            lines = parseInt($args["--lines"]))  
        else:
          tcal.pryear_proc(year,
                           w = parseInt($args["--width"]),
                           lines = parseInt($args["--lines"]),
                           c = parseInt($args["--spacing"]),
                           m = parseInt($args["--months"]))    
      elif args["<year>"] and args["<month>"]:
        tcal.prmonth_proc(parseInt($args["<year>"]), parseInt($args["<month>"]),
                         w = parseInt($args["--width"]),
                         lines = parseInt($args["--lines"]))
      elif args["<year>"] and not args["<month>"]:
        tcal.pryear_proc(parseInt($args["<year>"]),
                         w = parseInt($args["--width"]),
                         lines = parseInt($args["--lines"]),
                         c = parseInt($args["--spacing"]),
                         m = parseInt($args["--months"]))
      elif not args["<year>"] and not args["<month>"]:
        let year = standard_year(gregorian_from_fixed(fixed_from_now()))
        tcal.pryear_proc(year,
                         w = parseInt($args["--width"]),
                         lines = parseInt($args["--lines"]),
                         c = parseInt($args["--spacing"]),
                         m = parseInt($args["--months"]))

    elif $args["--type"] == "html":
      var hcal = HTMLCalendar(cal: cal)
      var year: int
      var month: int
      if args["--year"] or args["<year>"]:
        if args["--year"]:
          year = parseInt($args["--year"])
          if args["<year>"]:
            # if --year is on the command line, we interpret the first positional
            # argument as the month
            month = parseInt($args["<year>"])
        else:
          year = parseInt($args["<year>"])
          if args["<month>"]:
            month = parseInt($args["<month>"])
      else:
        year = standard_year(gregorian_from_fixed(fixed_from_now()))

      if month != 0:
        if args["--iso"]:
          echo convert(hcal.formatmonthpage(year, month, css = $args["--css"], withiso = true))
        else:
          echo convert(hcal.formatmonthpage(year, month, css = $args["--css"], withiso = false))
      else:
        if args["--iso"]:
          echo convert(hcal.formatyearpage(year,
                                           width = parseInt($args["--months"]),
                                           css = $args["--css"], withiso = true))
        else:
          echo convert(hcal.formatyearpage(year,
                                           width = parseInt($args["--months"]),
                                           css = $args["--css"], withiso = false))
    else:
      echo unindent(helpText)
  else:
    import strtabs
    let helpTextJS = """
      Usage: 
        $1 [options] [<year>] [<month>]
        $1 -h  to show possible options

        negative years must be specified with the --year option

      Options:
         -h, --help              Show this screen and exit.
         -v, --version           Show version and exit.
         -y, --year=<y>          show year calendar for year <y> (only necessary for negative years)      
         -w, --width=<w>         width of date column [default: 2]
         -l, --lines=<n>         number of lines for each week [default: 1]
         -s, --spacing=<n>       spacing between months [default: 6]
         -m, --months=<n>        months per row [default: 3]
         -W, --firstWeekDay=<n>  first day of week, where Mo = 1, Tu = 2, We = 3, Th = 4, Fr = 5, Sa = 6, Su = 0 [default: 1]
         -t, --type=<str>        output type (text or html) [default: text]
         -c, --css=<filename>    CSS to use for calendar page (html only) [default: calendar.css]
         --iso                   include iso week number in output
         --isoYear               list of iso weeks in year
         --easter                get the gregorian date of easter in a specified year or the current year
    """ % ["calendar1"] 

    var optdict = newStringTable({"year": "",
                                  "month": "",
                                  "width": "2",
                                  "lines": "1",
                                  "spacing": "6",
                                  "months": "3",
                                  "firstWeekDay": "1",
                                  "type": "text",
                                  "css": "calendar.css",
                                  "iso": "false",
                                  "isoYear": "false",
                                  "easter": "false"}, modeCaseSensitive)

    # ugly trick to access nodejs's command line arguments
    var args {.importc.}: seq[cstring]
    {.emit: "`args` = process.argv;" .}
    # echo args[2..^1]

    var yearset = false
    var helpRequested = false
    var versionRequested = false
    var arg: string = ""
    var i = 2
    while i < len(args):
      arg = $args[i]
      if not arg.startsWith("-"):
        if not yearset:
          optdict["year"] = arg
          yearset = true
        else:
          optdict["month"] = $arg
      else:
        if arg == "-h" or arg == "--help":
          helpRequested = true
          break
        if arg == "-v" or arg == "--version":
          versionRequested = true
        if arg == "-l" or arg == "--lines=":
          optdict["lines"] = $(args[i + 1])
          inc(i)
        if arg == "-y" or arg == "--year":
          if optdict["year"] != "":
            optdict["month"] = optdict["year"]
          optdict["year"] = $(args[i + 1])
          inc(i)
        if arg == "-w" or arg == "--width":
          optdict["width"] = $(args[i + 1])
          inc(i)
        if arg == "-s" or arg == "--spacing":
          optdict["spacing"] = $(args[i + 1])
          inc(i)
        if arg == "-m" or arg == "--months":
          optdict["months"] = $(args[i + 1])
          inc(i)
        if arg == "-W" or arg == "--firstWeekDay":
          optdict["firstWeekDay"] = $(args[i + 1])
          inc(i)
        if arg == "-t" or arg == "--type":
          optdict["type"] = $(args[i + 1])
          inc(i)
        if arg == "-c" or arg == "--css":
          optdict["css"] = $(args[i + 1])
          inc(i)
        if arg == "--iso":
          optdict["iso"] = "true"
        if arg == "--isoYear":
          optdict["isoYear"] = "true"
        if arg == "--easter":
          optdict["easter"] = "true"
      inc(i)

    if helpRequested or versionRequested:
      if helpRequested:
        echo unindent(helpTextJS)
      else:
        echo VERSION
    else:    
      if optdict["type"] == "text":
        var tcal = initTextCalendar(firstweekday=parseInt(optdict["firstWeekDay"]))

        if optdict["isoYear"] == "true":
          var year: int
          if optdict["year"] != "":
            year = parseInt(optdict["year"])
          else:
            year = standard_year(gregorian_from_fixed(fixed_from_now()))
          let width = max(5, parseInt(optdict["width"]))
          let lines = parseInt(optdict["lines"])
          prISOyear(tcal, year, width, lines)
        elif optdict["easter"] == "true":
          var year = standard_year(gregorian_from_fixed(fixed_from_now()))
          if optdict["year"] != "":
            year = parseInt(optdict["year"])
          let easter = gregorian_from_fixed(easter(year))
          echo "easter date: ", easter
        else:
          var pryear_proc = pryear
          var prmonth_proc = prmonth
          if optdict["iso"] == "true":
            tcal.cal.firstweekday = 1
            pryear_proc = pryear_iso
            prmonth_proc = prmonth_iso

          var year: int
          var month: int

          if optdict["year"] != "":
            year = parseInt(optdict["year"])
          else:
            year = standard_year(gregorian_from_fixed(fixed_from_now()))

          if optdict["month"] != "":
            month = parseInt(optdict["month"])

          if month != 0:
            prmonth_proc(tcal, year, month, parseInt(optdict["width"]), parseInt(optdict["lines"]))
          else:
            pryear_proc(tcal, year, 
                        w = parseInt(optdict["width"]),
                        lines = parseInt(optdict["lines"]),
                        c = parseInt(optdict["spacing"]),
                        m = parseInt(optdict["months"]))
      else:
        var hcal = initHTMLCalendar(firstweekday=parseInt(optdict["firstWeekDay"]))
        var year: int
        var month: int
        if optdict["year"] != "":
          year = parseInt(optdict["year"])
        else:
          year = standard_year(gregorian_from_fixed(fixed_from_now()))

        if optdict["month"] != "":
          month = parseInt(optdict["month"])

        if month != 0:
          if optdict["iso"] == "true":
            echo hcal.formatmonthpage(year, month, css = optdict["css"], withiso = true)
          else:
            echo hcal.formatmonthpage(year, month, css = optdict["css"], withiso = false)
        else:
          if optdict["iso"] == "true":
            echo hcal.formatyearpage(year,
                                     width = parseInt(optdict["months"]),
                                     css = optdict["css"], withiso = true)
          else:
            echo hcal.formatyearpage(year,
                                     width = parseInt(optdict["months"]),
                                     css = optdict["css"], withiso = false)
    
