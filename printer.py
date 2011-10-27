from __future__ import division
import numpy as np
import matplotlib.pyplot as plt
import sdxf

class PDFPrinter:
    def __init__(self):
        plt.figure(figsize=[6, 6])
        plt.hold(True)

    def save(self, filename):
        plt.axis('equal')
        plt.tick_params(colors='w')
        plt.savefig(filename+'.pdf', bbox_inches = 'tight')
    
    def draw_arc(self, center, r, angles = [np.pi/6, 5*np.pi/6], **kwargs):
        angles = np.linspace(angles[0], angles[1])
        plt.plot(center[0] + r * np.cos(angles), center[1] + r * np.sin(angles),
                linewidth=.5,
                **kwargs)
        # plt.plot(x, y+z, style, marker='*', markersize=2)
        # plt.plot([x, x-z*np.cos(angles[0])], [y+z, y+z-z*np.sin(angles[0])],
        #         style, linestyle=':', linewidth=.25)
        # plt.plot([x, x-z*np.cos(angles[-1])], [y+z, y+z-z*np.sin(angles[-1])],
        #         style, linestyle=':', linewidth=.25)

    def draw_line(self, center, length, angle, style='k-', **kwargs):
        plt.plot([center[0] - length/2 * np.cos(angle),
                  center[0] + length/2 * np.cos(angle)],
                 [center[1] - length/2 * np.sin(angle),
                  center[1] + length/2 * np.sin(angle)], style, **kwargs)
   
    def draw_circle(self, center, r):
        angles = np.linspace(0, 2*np.pi, 100)
        plt.plot(center[0] + r * np.cos(angles), 
                 center[1] + r * np.sin(angles), 'k-', linewidth=.5)

class DXFPrinter:
    def __init__(self):
        self.dxf = sdxf.Drawing()

    def save(self, filename):
        self.dxf.saveas(filename+'.dxf')

    def draw_arc(self, center, r, angles = [np.pi/6, 5*np.pi/6], **kwargs):
        self.dxf.append(sdxf.Arc(center = center + [0], radius = r,
                                startAngle = angles[0]*180/np.pi,
                                endAngle = angles[1]*180/np.pi,
                                layer = "drawinglayer"))
    
    def draw_line(self, center, length, angle, style='k-', **kwargs):
        self.dxf.append(sdxf.Line(points=
            [[center[0] - length/2 * np.cos(angle),
              center[1] - length/2 * np.sin(angle)],
             [center[0] + length/2 * np.cos(angle),
              center[1] + length/2 * np.sin(angle)]]))

        
