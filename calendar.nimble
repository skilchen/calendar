# Package

version       = "0.1.0"
author        = "skilchen"
description   = "a clone of calendar.py from python stdlib"
license       = "MIT"

bin           = @["calendar"]

# Dependencies

requires "nim >= 0.17.0"
requires "nimcalcal >= 0.1.0"
requires "docopt >= 0.6.5"

task yearcalendar, "show a simple text calendar of 2018":
    exec "nim c -r calendar 2018"

task yearcalendar_js, "show a simple text calendar of 2018 using the js backend":
    exec "nim js -d:nodejs -r calendar 2018"

task yearcalendar_iso, "show a simple text calendar of 2018 with iso week numbers":
    exec "nim c -r calendar 2018 --iso"

task easter, "show the date of easter 2018 together with a month calendar":
    exec "nim c -r calendar 2018 --easter"

task easter_js, "show the date of easter 2018 using the js backend":
    exec "nim js -d:nodejs -r calendar 2018 --easter"

task yearcalendar_js_iso, "show a simple text calendar of 2018 with iso week numbers using the js backend":
    exec "nim js -d:nodejs -r calendar 2018 --iso"

task thanksgiving, "show the date of thanksgiving for 10 years":
    exec "nim c -r calendarpkg/examples/thanksgiving 2017 2027"

task thanksgiving_js, "show the date of thanksgiving for 10 years using the js backend":
    exec "nim js -d:nodejs -r calendarpkg/examples/thanksgiving 2017 2027"

task columbus_day, "show the date of columbus day for 10 years":
    exec "nim c -r calendarpkg/examples/columbus_day 2017 2027"

task columbus_day_js, "show the date of columbus day for 10 years using the js backend":
    exec "nim js -d:nodejs -r calendarpkg/examples/columbus_day 2017 2027"

task labor_day, "show the date of labor day for 10 years":
    exec "nim c -r calendarpkg/examples/labor_day 2017 2027"

task labor_day_js, "show the date of labor day for 10 years using the js backend":
    exec "nim js -d:nodejs -r calendarpkg/examples/labor_day 2017 2027"    

task new_year_on_monday, "show years starting on monday":
    exec "nim c -r calendarpkg/examples/years_starting_on_monday 2017 2117"

task new_year_on_monday_js, "show years starting on monday using js backend":
    exec "nim js -d:nodejs -r calendarpkg/examples/years_starting_on_monday 2017 2117"

task more_than_4_sundays, "show months with more than 4 sundays":
    exec "nim c -r calendarpkg/examples/months_with_more_than_4_sundays 2017 2027"

task more_than_4_sundays_js, "show months with more than 4 sundays using js backend":
    exec "nim js -d:nodejs -r calendarpkg/examples/months_with_more_than_4_sundays 2017 2027"
