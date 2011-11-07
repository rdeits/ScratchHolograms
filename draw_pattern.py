from __future__ import division
print "1"
from pattern import PatternMaker
from printer import PDFPrinter, DXFPrinter
import sys
import numpy as np
print "2"

filename = sys.argv[1]
pat = PatternMaker(filename, [PDFPrinter(), DXFPrinter()])
pat.print_pattern()
pat.draw_view(-25*np.pi/180)
pat.draw_view(25*np.pi/180)
pat.draw_view(0)
print "done"
