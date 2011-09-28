from __future__ import division
import numpy as np
# RESOLUTION = 100


class VertexReader:
    def __init__(self, filename):
        self.filename = filename
        self.f = open(filename, 'r')
    def to_array(self):
        xyz_str = [line[1:].split(';')[:-1] for line in self.f if line[0] == 'v']
        self.f.close()
        data = np.array([[float(i.strip()) for i in line] for line in xyz_str])
        return data
#         result = interpolate(data[0], data[1], RESOLUTION)
#         for i in range(1,len(data[:, 1])-1):
#             result = np.concatenate((result, interpolate(data[i], data[i+1], 
#                     RESOLUTION)))
#         return result

def interpolate(p0, p1, resolution):
    num_points = max(2, int(np.sqrt(np.sum(np.power(p0 - p1, 2))) / resolution))
    interp_points = [np.linspace(p0[i], p1[i], num_points) for i in range(3)]
    result = np.array([[interp_points[j][i] for j in range(3)]\
            for i in range(num_points)])
    print result
    return result
