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
