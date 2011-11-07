from __future__ import division
from pattern import PatternMaker
from printer import PDFPrinter, DXFPrinter
import sys
import numpy as np

print "Beginning Python script..."
filename = sys.argv[1]
pat = PatternMaker(filename, [PDFPrinter(), DXFPrinter()])
pat.print_pattern()
pat.draw_view(-25*np.pi/180)
pat.draw_view(25*np.pi/180)
pat.draw_view(0)
print "Pattern printing completed."
