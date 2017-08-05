import calendar
import strfmt
from strutils import parseInt
from times import getTime, getGMTime

# columbus day is on the second monday in october

proc display_columbus_day(start_year, stop_year: int) =
  let cal = initCalendar()

  for i in countUp(startYear, stop_year):
    let mc = cal.monthdays2calendar(i, 10)
    if mc[0][0][0] != 0:
      echo "{:4d}-{:02d}-{:02d}".fmt(i, 10, mc[1][0][0])
    else:
      echo "{:4d}-{:02d}-{:02d}".fmt(i, 10, mc[2][0][0])

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

  display_columbus_day(start_year, stop_year)
