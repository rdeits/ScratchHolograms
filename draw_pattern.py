from __future__ import division
print "1"
from pattern import PatternMaker, GridPatternMaker
from printer import PDFPrinter, DXFPrinter
import sys
import numpy as np
print "2"

filename = sys.argv[1]
pat = PatternMaker(filename, [PDFPrinter(), DXFPrinter()])
pat.print_pattern()
pat.draw_view(-5*np.pi/180)
pat.draw_view(5*np.pi/180)
print "done"
