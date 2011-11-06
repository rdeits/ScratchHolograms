from __future__ import division
import numpy as np
from vertex import VertexReader
from printer import PDFPrinter, DXFPrinter
import random
import sys
import os.path
import csv
import matplotlib.pyplot as plt

__author__ = "Robin Deits <robin.deits@gmail.com>"

RESOLUTION = 60

class PatternMaker:
    def __init__(self, reader, printer, image_width_in = 4):
        self.setup_common(reader, printer, image_width_in)

    def setup_common(self, reader, printer, image_width_in):
        self.reader = reader
        self.data = self.reader.to_array()
        self.printer = printer
        self.rescale(image_width_in)
        self.filename = self.reader.filename
        z_max = np.max(np.abs(self.data[:,2]))
        self.x_range = (np.max(self.data[:,0]) 
                - np.min(self.data[:,0]) 
                + 2*z_max)
        self.y_range = (np.max(self.data[:,1]) 
                - np.min(self.data[:,1])
                + 2*z_max)
        self.overall_range = max(self.x_range, self.y_range)

    def rescale(self, image_width_in):
        z_max = np.max(np.abs(self.data[:,2]))
        x_range = (np.max(self.data[:,0]) 
                - np.min(self.data[:,0]) 
                + 2*z_max)
        self.data[:,:3] *= image_width_in / x_range

    def print_pattern(self):
        num_points = len(self.data[:,0])
        printed = np.zeros(num_points)
        min_dist = self.overall_range / RESOLUTION
        for i in range(num_points):
            too_close = False
            for j in range(i):
                if printed[j] and distance(self.data[i,:], self.data[j,:]) < min_dist:
                    too_close = True
                    # print "skipped"
                    break
            if too_close:
                continue
            else:
                # print "printing"
                printed[i] = 1
                self.plot_point(self.data[i, 0], self.data[i, 1], self.data[i, 2])
        self.printer.save(os.path.splitext(self.filename)[0])

    def plot_point(self, x, y, z):
        if z < 0:
            color = 'k'
        else:
            color = 'k'
        self.printer.draw_arc(center = [x, y+z], r = -z, color = color)

    def draw_view(self, angle, name=''):
        view_printer = PDFPrinter()
        num_points = len(self.data[:,0])
        for i in range(num_points):
            x = self.data[i,0]
            y = self.data[i,1]
            z = self.data[i,2]
            self.plot_point(x, y, z)
            plt.plot(x - z*np.cos(angle+np.pi/2), y + z - z*np.sin(angle+np.pi/2),
                     'k*')
        self.printer.save(os.path.splitext(self.filename)[0] + name)

    def draw_views(self, angle):
        if isinstance(self.printer, DXFPrinter):
            print "DXFPrinter can't draw perspective views, aborting"
            return
        self.draw_view(angle, '_right')
        self.draw_view(-angle, '_left')

class GridPatternMaker(PatternMaker):
    def __init__(self, reader, printer, num_bins = 80, 
                 image_width_in = 4,
                 draw_verticals = True):
        self.setup_common(reader, printer, image_width_in)

        self.draw_verticals = draw_verticals
        self.bin_width = self.overall_range / num_bins
        x_min = min(self.data[:,0]) - z_max/2
        x_max = max(self.data[:,0]) + z_max/2
        y_min = min(self.data[:,1]) - z_max/2
        y_max = max(self.data[:,1]) + z_max/4
        self.x_bins = np.arange(x_min, x_max + self.bin_width, self.bin_width)
        self.y_bins = np.arange(y_min, y_max + self.bin_width, self.bin_width)
        self.bin_angles = np.zeros((len(self.x_bins), len(self.y_bins))) + np.pi/2
        for i in range(len(self.data[:,0])):
            self.plot_point(self.data[i, 0], self.data[i, 1], self.data[i, 2])

    def print_pattern(self):
        r = self.bin_width / 2
        # for x in self.x_bins:
        #     for y in self.y_bins:
        #         self.printer.draw_circle([x,y], r)
        for i in range(len(self.x_bins)):
            for j in range(len(self.y_bins)):
                if (self.bin_angles[i][j] != np.pi/2 or self.draw_verticals):
                    self.printer.draw_line([self.x_bins[i], 
                                            self.y_bins[j]], 
                                           .8*self.bin_width, 
                                           self.bin_angles[i][j])
        self.printer.save(os.path.splitext(self.filename)[0]+'_grid')

    def plot_point(self, x, y, z):
        print "printing:", x, y, z
        for i in range(len(self.x_bins)):
            if (x - abs(z) - self.bin_width/2) <= self.x_bins[i] <=\
               (x + abs(z) + self.bin_width/2):
                for j in range(len(self.y_bins)):
                    if ((abs(z) - self.bin_width/2) 
                            <= distance([x, y+z], [self.x_bins[i], self.y_bins[j]])
                            <= (abs(z) + self.bin_width/2)):
                        if ((z <= 0 and self.y_bins[j] >= (y+z)) 
                                or (z >= 0 and self.y_bins[j] <= (y+z))):
                            angle = np.arctan((x - self.x_bins[i]) / (self.y_bins[j] 
                                - (y+z)))
                            if abs(angle) < abs(self.bin_angles[i][j]):
                                self.bin_angles[i][j] = angle


    def draw_view(self, angle, name=''):
        self.printer.__init__()
        for i, x in enumerate(self.x_bins):
            for j, y in enumerate(self.y_bins):
                # self.printer.draw_circle([x,y], self.bin_width/2)
                # plt.plot(x, y, 'k.', markersize=2)
                self.printer.draw_line([x, y], .8*self.bin_width, self.bin_angles[i][j],
                               style = 'k:', linewidth=.5)
                if abs(angle - self.bin_angles[i][j]) < 5*np.pi/180:
                    self.printer.draw_line([x, y], self.bin_width, self.bin_angles[i][j])
                    # plt.plot(x, y, 'ko', markerfacecolor='k', markersize=20)
        self.printer.save(os.path.splitext(self.filename)[0] + '_grid'+name)

def distance(p0, p1):
    return np.sqrt(np.sum(np.power(np.array(p1) - np.array(p0), 2)))

class SolidPatternMaker(PatternMaker):
    def __init__(self, filename, printer, image_width_in = 4):
        self.filename = filename
        self.reader = csv.reader(open(filename, 'rb'))
        self.printer = printer
        self.data = np.array([[float(i) for i in row] for row in self.reader])
        print self.data
        print np.abs(self.data)
        # self.rescale(image_width_in)

    def print_pattern(self):
        num_points = len(self.data[:,0])
        for i in range(num_points):
            self.plot_point(self.data[i,:])
        self.printer.save(os.path.splitext(self.filename)[0])

    def plot_point(self, point):
        x = point[0]
        y = point[1]
        z = point[2]
        angles = -np.array([point[3], point[4]]) + np.pi / 2
        self.printer.draw_arc([y, z + x], -x,
                              angles = angles, color='k')
        # self.printer.draw_arc([y, z+x], -x,
        #                       angles = [angle - angle_delta, angle + angle_delta])

    def draw_view(self, angle, name=''):
        num_points = len(self.data[:,0])
        view_printer = PDFPrinter()
        for i in range(num_points):
            x = self.data[i,0]
            y = self.data[i,1]
            z = self.data[i,2]
            if self.data[i, 3] < angle < self.data[i,4]:
                draw_angle = -angle + np.pi/2
                view_printer.draw_point([y - x * np.cos(draw_angle),
                         z + x - x * np.sin(draw_angle)], marker = '*', 
                                        color = 'k')
        view_printer.save(os.path.splitext(self.filename)[0] +name)

