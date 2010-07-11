#!/usr/bin/env perl

use strict;

# Configure these
my $path_to_lunchlines = "/home/haldean/Code/ThirdParty/frostruder-tool-sweet-0001/lunchlines.py";
my $draw_height = 0; # mm
my $move_height = 2; # mm
my $done_height = 15; # mm

my $dxf_file = shift;
my @lunchlines_output = split "\n", 
    `python $path_to_lunchlines --z-height $draw_height --start-delay 0 --stop-delay 0 --stop-distance 0 $dxf_file`;
my $number = "([0-9.]+)";
my $buffered_stop = 0;

for my $line (@lunchlines_output) {
    if ($line =~ m/^\(/ or $line =~ m/^$/) {
	ignore();
    } elsif ($line =~ m/go up to printing level/) {
	stop_draw();
    } elsif ($line =~ m/^M106/) {
	start_draw();
    } elsif ($line =~ m/^M107/) {
	stop_draw();
    } elsif ($line =~ m/^G4 P0/) {
	ignore();
    } elsif ($line =~ m/^M12[67]/) {
	ignore();
    } elsif ($line =~ m/go up to finished level/) {
	cooldown();
    } elsif ($line =~ m/zero all axes/) {
	draw($line);
	initialize();
    } else {
	draw($line);
    }
}

sub start_draw() {
    print "G0 Z$draw_height\n" unless $buffered_stop;
    $buffered_stop = 0;
}

sub stop_draw() {
    $buffered_stop = 1;
}

# For readability and nothing else.
sub ignore() { ; }

sub cooldown() {
    print "G0 Z$done_height\n";
    print "M18\n"; # Turn off motors
    exit 0;
}

sub initialize() {
    print "G0 Z$done_height\n";
    print "M01 (Please remove the calibration paper from the plotter)\n";
}

sub draw($) {
    print "G0 Z$move_height\n" if $buffered_stop;
    $buffered_stop = 0;
    my $line = shift;
    print "$line\n";
}
