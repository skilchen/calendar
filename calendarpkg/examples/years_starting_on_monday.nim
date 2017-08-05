import calendar
import strutils
import times

proc display_years_starting_on_january_1(startYear, stopYear: int) = 
  let cal = initCalendar()

  for i in countUp(startYear, stopYear):
    for d, wd in cal.itermonthdays2(i, 1):
      if  d == 1 and wd == 1:
        echo i
        break

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

  display_years_starting_on_january_1(start_year, stop_year)
