from __future__ import division

import chiplotle as ch


plotter = ch.instantiate_plotters()[0]
# c = ch.shapes.circle(300, 100)
# ch.transforms.offset(c, (1500, 1000))
# plotter.write(c)

plotter.write(ch.hpgl.VS(vel=1))
plotter.write(ch.hpgl.FS(force=8))
plotter.pen_up([(6000, 1000)])
plotter.write(ch.hpgl.PD())
plotter.write(ch.hpgl.AR((700, 0), -180))
# plotter.write(ch.hpgl.LB("Hello, World"))
# plotter.write(ch.hpgl.CI(600))
plotter.pen_up([(0,0)])
