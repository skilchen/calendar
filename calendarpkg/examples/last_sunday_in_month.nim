import calendar
import strutils
import strfmt
import times

proc display_last_sunday_in_month(startYear, stopYear: int) = 
  let cal = initCalendar()

  for i in countUp(startYear, stopYear):
    for j in 1..12:
      let mc = cal.monthdays2calendar(i, j)
      if mc[mc.high][6][0] == 0:
        echo "{:5d}-{:02d}-{:02d}".fmt(i, j, mc[mc.high - 1][6][0])
      else:
        echo "{:5d}-{:02d}-{:02d}".fmt(i, j, mc[mc.high][6][0])

when isMainModule:
  var start_year: int
  var stop_year: int

  when not defined(js):
    import os
    if paramCount() > 0:
      start_year = parseInt(paramStr(1))
    else:
      start_year = getGMTime(getTime()).year
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
      start_year = getGMTime(getTime()).year
    if len(args) > 3:
      stop_year = parseInt($(args[3]))
    else:
      stop_year = start_year

  display_last_sunday_in_month(start_year, stop_year)


