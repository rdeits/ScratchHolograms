from __future__ import division
import numpy as np

class VertexReader:
    def __init__(self, filename):
        self.filename = filename
        self.f = open(filename, 'r')
    def to_array(self):
        xyz_str = [line[1:].split(';')[:-1] for line in self.f if line[0] == 'v']
        data = [[float(i.strip()) for i in line] for line in xyz_str]
        return np.array(data)