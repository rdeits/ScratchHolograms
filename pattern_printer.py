from __future__ import division
import numpy as np
import matplotlib.pyplot as plt
from vertex_reader import VertexReader
import random
import sys
import os.path

class PatternPrinter:
    def __init__(self, reader):
        self.filename = reader.filename
        self.data = reader.to_array()
        print self.data
        plt.figure()
        plt.hold(True)
        num_points = len(self.data[:,0])
        angles = np.linspace(np.pi/4, 3*np.pi/4, num_points)
        for i in range(num_points):
            plot_point(self.data[i, 0], self.data[i, 1], self.data[i, 2], angles[i])
        plt.axis('equal')
        plt.savefig('./pdf/'+os.path.splitext(os.path.split(self.filename)[1])[0]+'.pdf')
        
def plot_point(x, y, z, angle):
    plt.plot([x, x + -z * np.cos(angle)], [y + z, y + z - z * np.sin(angle)], 'b*-')
    plt.plot(x, y + z, 'bo')
    

if __name__ == "__main__":
    filename = sys.argv[1]
    print filename
    pat = PatternPrinter(VertexReader(filename))
    
