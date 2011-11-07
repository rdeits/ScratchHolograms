from __future__ import division
import numpy as np
from printer import PDFPrinter, DXFPrinter
import random
import sys
import os.path
import csv
import matplotlib.pyplot as plt

__author__ = "Robin Deits <robin.deits@gmail.com>"

RESOLUTION = 60

class PatternMaker:
    def __init__(self, filename, printers, image_width_in = 4):
        self.setup_common(filename, printers, image_width_in)

    def setup_common(self, filename, printers, image_width_in):
        self.filename = filename
        self.reader = csv.reader(open(filename, 'rb'))
        self.printers = printers
        self.data = np.array([[float(i) for i in row] for row in self.reader])
        # print self.data
        self.rescale(image_width_in)

    def rescale(self, image_width_in):
        z_max = np.max(np.abs(self.data[:,2]))
        x_range = (np.max(self.data[:,0]) 
                - np.min(self.data[:,0]) 
                + 2*z_max)
        self.data[:,:3] *= image_width_in / x_range

    def print_pattern(self):
        num_points = len(self.data[:,0])
        for i in range(num_points):
            self.plot_point(self.data[i,:])
        for printer in self.printers:
            printer.save(os.path.splitext(self.filename)[0])

    def plot_point(self, point):
        x = point[0]
        y = point[1]
        z = point[2]
        angles = -np.array([point[3], point[4]]) + np.pi / 2
        for printer in self.printers:
            printer.draw_arc([x, y + z], -z,
                              angles = angles, color='k')

    def draw_view(self, angle):
        num_points = len(self.data[:,0])
        view_printer = PDFPrinter()
        for i in range(num_points):
            x = self.data[i,0]
            y = self.data[i,1]
            z = self.data[i,2]
            if self.data[i, 3] < angle < self.data[i,4]:
                draw_angle = -angle + np.pi/2
                view_printer.draw_point([x - z * np.cos(draw_angle),
                         y + z - z * np.sin(draw_angle)], marker = '*', 
                                        color = 'k')
        view_printer.save(os.path.splitext(self.filename)[0] 
                          + "_view_" + ("%+3d" %(angle * 180/np.pi)).strip())

    def draw_views(self, angle):
        for printer in self.printers:
            if isinstance(printer, DXFPrinter):
                print "DXFPrinter can't draw perspective views, aborting"
                continue
            self.draw_view(angle)
            self.draw_view(-angle)

def distance(p0, p1):
    return np.sqrt(np.sum(np.power(np.array(p1) - np.array(p0), 2)))
