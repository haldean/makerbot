#!/usr/bin/env python

import serial
import gtk

class colorselector(object):
    def __init__(self):
        self.leds = ledstrip()

        window = gtk.Window()
        window.connect("destroy", gtk.main_quit)

        self.colorsel = gtk.ColorSelection()
        self.colorsel.connect("color_changed", self.setcolor)

        panel = gtk.VBox()
        panel.pack_start(self.colorsel)

        autofade_panel = gtk.HBox()

        autofade_panel.pack_start(gtk.Label("Delay: "))
        self.delayfield = gtk.Entry()
        autofade_panel.pack_start(self.delayfield, padding=10)

        autofade_panel.pack_start(gtk.Label("Delta: "))
        self.deltafield = gtk.Entry()
        autofade_panel.pack_start(self.deltafield, padding=10)

        quit_button = gtk.Button("Quit")
        quit_button.connect("clicked", gtk.main_quit)
        autofade_panel.pack_end(quit_button, expand=False)

        autofade_button = gtk.Button("Autofade")
        autofade_button.connect("clicked", self.autofade)
        autofade_panel.pack_end(autofade_button, expand=False)

        panel.pack_end(autofade_panel)

        window.add(panel)
        window.show_all()

    def setcolor(self, widget):
        color = self.colorsel.get_current_color()
        self.leds.color(color.red / 65535.0, color.green / 65535.0, color.blue / 65535.0)

    def autofade(self, widget):
        self.leds.autofade(self.delayfield.get_text(), self.deltafield.get_text())

class ledstrip(object):
    def __init__(self, port='/dev/ttyUSB0', baud=9600):
        self.serial = serial.Serial(port, baud)

    def color(self, r, g, b):
        (r, g, b) = (int(r * 255), int(g * 255), int(b * 255))
        self.serial.write('1 %d %d %d\r' % (r, g, b))

    def autofade(self, delay, delta):
        self.serial.write('0 %d %d\r' % (int(delay), int(delta)))

if __name__ == "__main__":
    colorselector()
    gtk.main()
