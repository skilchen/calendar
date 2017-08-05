import calendar
import strutils
import nimcalcal
import strfmt

# thanksgiving is on the 4th thursday in november

proc display_thanksgiving(startYear, stopYear: int) = 
  let month = 11
  let wday = 3

  let cal = initCalendar()

  for i in countUp(startYear, stop_year):
    let mc = cal.monthdays2calendar(i, month)
    if mc[0][wday][0] != 0:
      echo "{:5d}-{:02d}-{:02d}".fmt(i, 11, mc[3][wday][0])
    else:
      echo "{:5d}-{:02d}-{:02d}".fmt(i, 11, mc[4][wday][0])


when isMainModule:
  var start_year: int
  var stop_year: int

  when not defined(js):
    import os
    if paramCount() > 0:
      start_year = parseInt(paramStr(1))
    else:
      start_year = standard_year(gregorian_from_fixed(fixed_from_now()))
    if paramCount() > 1:
      stop_year = parseInt(paramStr(2))
    else:
      stop_year = start_year
  else:
    # ugly trick to access nodejs's command line arguments
    var args {.importc.}: seq[cstring]
    {.emit: "`args` = process.argv;" .}
    # echo args[2..^1]
    if len(args) > 2:
      start_year = parseInt($(args[2]))
    else:
      start_year = standard_year(gregorian_from_fixed(fixed_from_now()))
    if len(args) > 3:
      stop_year = parseInt($(args[3]))
    else:
      stop_year = start_year

  display_thanksgiving(start_year, stop_year)

