from __future__ import division
import numpy as np
RESOLUTION = 10

__author__ = "Robin Deits <robin.deits@gmail.com>"

class VertexReader:
    def __init__(self, filename):
        self.filename = filename
        self.f = open(filename, 'r')
    def to_array(self):
        xyz_str = [line[1:].split(';')[:-1] for line in self.f if line[0] == 'v']
        vertices = np.array([[float(i.strip()) for i in line] for line in xyz_str])
        self.f.seek(0)
        edge_str = [line[1:].split(';') for line in self.f if line[0] == 'e']
        edges = np.array([[float(i.strip()) for i in line] for line in edge_str])
        print edges
        x_range = np.max(vertices[:,0]) - np.min(vertices[:,0])
        y_range = np.max(vertices[:,1]) - np.min(vertices[:,1])
        overall_range = max(x_range, y_range)
        for i in range(len(edges[:,0])):
            vertices = np.vstack((vertices, 
                    interpolate(vertices[edges[i,0],:], vertices[edges[i,1],:],
                        overall_range/RESOLUTION)))
        return vertices
            

def interpolate(p0, p1, resolution):
    print resolution
    num_points = max(2, int(np.sqrt(np.sum(np.power(p0 - p1, 2))) / resolution))
    interp_points = [np.linspace(p0[i], p1[i], num_points) for i in range(3)]
    result = np.array([[interp_points[j][i] for j in range(3)]\
            for i in range(num_points)])
    print result
    return result
