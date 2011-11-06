from __future__ import division
print "1"
from pattern import PatternMaker, SolidPatternMaker, GridPatternMaker
from printer import PDFPrinter, DXFPrinter
import sys
import numpy as np
print "2"

filename = sys.argv[1]
spat = SolidPatternMaker(filename, PDFPrinter())
spat.print_pattern()
spat.draw_view(-25*np.pi/180, '_left')
spat.draw_view(25*np.pi/180, '_right')
print "done"
