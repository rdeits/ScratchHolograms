from __future__ import division
import numpy as np
import matplotlib.pyplot as plt
from vertex import VertexReader
import random
import sys
import os.path

__author__ = "Robin Deits <robin.deits@gmail.com>"

RESOLUTION = 50

class PatternPrinter:
    def __init__(self, reader):
        self.reader = reader
        self.filename = self.reader.filename
        self.data = self.reader.to_array()
        z_max = np.max(np.abs(self.data[:,2]))
        self.x_range = (np.max(self.data[:,0]) 
                - np.min(self.data[:,0]) 
                + 2*z_max)
        self.y_range = (np.max(self.data[:,1]) 
                - np.min(self.data[:,1])
                + 2*z_max)
        self.overall_range = max(self.x_range, self.y_range)

    def print_pattern(self):
        # print self.data
        plt.figure(figsize=[6, 6])
        plt.hold(True)
        num_points = len(self.data[:,0])
        printed = np.zeros(num_points)
#         angles = np.linspace(np.pi/4, 3*np.pi/4, num_points)
        min_dist = self.overall_range / RESOLUTION
        for i in range(num_points):
            too_close = False
            for j in range(i):
                if printed[j] and distance(self.data[i,:], self.data[j,:]) < min_dist:
                    too_close = True
                    print "skipped"
                    break
            if too_close:
                continue
            else:
                printed[i] = 1
                self.plot_point(self.data[i, 0], self.data[i, 1], self.data[i, 2])
        plt.axis('equal')
        plt.tick_params(colors='w')
        # plt.minorticks_on()
        # plt.gca().grid(b=True, which='major')
#         plt.show()
        plt.savefig('./pdf/'+os.path.splitext(os.path.split(self.filename)[1])[0]+'.pdf',
                        bbox_inches = 'tight')
    def plot_point(self, x, y, z):
        if z < 0:
            style = 'b-'
        else:
            style = 'r-'    
        angles = np.linspace(np.pi/6, 5*np.pi/6)
        plt.plot(x + -z * np.cos(angles), y + z - z * np.sin(angles), style,
                linewidth=.25)
        plt.plot(x, y+z, style, marker='*', markersize=2)
        plt.plot([x, x-z*np.cos(angles[0])], [y+z, y+z-z*np.sin(angles[0])],
                style, linestyle=':', linewidth=.25)
        plt.plot([x, x-z*np.cos(angles[-1])], [y+z, y+z-z*np.sin(angles[-1])],
                style, linestyle=':', linewidth=.25)

class GridPatternPrinter(PatternPrinter):
    def __init__(self, reader, num_bins = 100):
        self.reader = reader
        self.filename = self.reader.filename
        self.data = self.reader.to_array()
        z_max = np.max(np.abs(self.data[:,2]))
        self.x_range = (np.max(self.data[:,0]) 
                - np.min(self.data[:,0]) 
                + 2*z_max)
        self.y_range = (np.max(self.data[:,1]) 
                - np.min(self.data[:,1])
                + 2*z_max)
        self.overall_range = max(self.x_range, self.y_range)
        self.bin_width = self.overall_range / num_bins
        x_min = min(self.data[:,0]) - z_max
        x_max = max(self.data[:,0]) + z_max
        y_min = min(self.data[:,1]) - z_max
        y_max = max(self.data[:,1]) + z_max
        self.x_bins = np.linspace(x_min, x_max, (x_max - x_min)/self.bin_width)
        self.y_bins = np.linspace(y_min, y_max, (y_max - y_min)/self.bin_width)
        print self.x_bins
        print self.y_bins
        print "bin width", self.bin_width

    def plot_point(self, x, y, z):
        print "printing:", x, y, z
        for i in range(len(self.x_bins)):
            for j in range(len(self.y_bins)):
                if ((abs(z) - self.bin_width/2) 
                        < distance([x, y], [self.x_bins[i], self.y_bins[j]])
                        < (abs(z) + self.bin_width/2)):
                    if ((z < 0 and self.y_bins[j] > y) 
                            or (z > 0 and self.y_bins[j] < y)):
                        angle = np.arctan((x - self.x_bins[i]) / (self.y_bins[j] 
                            - y))
                        plt.plot([self.x_bins[i] - self.bin_width/2 * np.cos(angle),
                                    self.x_bins[i]
                                    + self.bin_width/2 * np.cos(angle)],
                                [self.y_bins[j] - self.bin_width/2 * np.sin(angle),
                                    self.y_bins[j] 
                                    + self.bin_width/2 * np.sin(angle)], 
                                'b-')
                # else:
                    # print "too far from", self.x_bins[i], self.y_bins[j],\
                            # "dist", distance([x, y], [self.x_bins[i], self.y_bins[j]])



def distance(p0, p1):
    return np.sqrt(np.sum(np.power(np.array(p1) - np.array(p0), 2)))
    

if __name__ == "__main__":
    filename = sys.argv[1]
    print filename
    pat = GridPatternPrinter(VertexReader(filename))
    pat.print_pattern()
    
