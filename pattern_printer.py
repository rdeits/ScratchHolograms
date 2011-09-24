from __future__ import division
import numpy as np
import matplotlib.pyplot as plt
from vertex_reader import VertexReader
import random
import sys
import os.path

RESOLUTION = 100

class PatternPrinter:
    def __init__(self, reader):
        self.filename = reader.filename
        self.data = reader.to_array()
        print self.data
        plt.figure()
        plt.hold(True)
        num_points = len(self.data[:,0])
        printed = np.zeros(num_points)
#         angles = np.linspace(np.pi/4, 3*np.pi/4, num_points)
        x_range = np.max(self.data[:,0]) - np.min(self.data[:,0])
        y_range = np.max(self.data[:,1]) - np.min(self.data[:,1])
        overall_range = max(x_range, y_range)
        min_dist = overall_range / RESOLUTION
        for i in range(num_points):
            too_close = False
            for j in range(i):
                if plotted[j] and distance(self.data[i,:], self.data[j,:]) < min_dist:
                    too_close = True
                    break
            if too_close:
                continue
            else:
                plot_point(self.data[i, 0], self.data[i, 1], self.data[i, 2])
        plt.axis('equal')
        plt.minorticks_on()
        plt.gca().grid(b=True, which='major')
#         plt.show()
        plt.savefig('./pdf/'+os.path.splitext(os.path.split(self.filename)[1])[0]+'.pdf',
                        bbox_inches = 'tight')
        
def plot_point(x, y, z):
    if z < 0:
        style = 'b-'
    else:
        style = 'r-'    
    angles = np.linspace(np.pi/4, 3*np.pi/4)
    plt.plot(x + -z * np.cos(angles), y + z - z * np.sin(angles), style,linewidth=.25)
    plt.plot(x, y + z, style, markersize=3)
    angle = np.pi/4
    plt.plot([x, x - z * np.cos(angle)], [y + z, y + z - z * np.sin(angle)],
            style, linewidth=.25)

def distance(p0, p1):
    return np.sqrt(np.sum(np.power(p1 - p0, 2)))
    

if __name__ == "__main__":
    filename = sys.argv[1]
    print filename
    pat = PatternPrinter(VertexReader(filename))
    
