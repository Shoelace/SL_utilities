#!/usr/bin/perl
# ^^ ensure this is pointing to the correct location.
#
# Title:   SLimPath 
# Author:  David "Shoe Lace" Pyke <shoelace@pipeline.com.au>
#	    :  Tim Nelson <wayland@ne.com.au>
# Purpose: To create a slim version of my envirnoment path so as to eliminate
#		duplicate entries and ensure that the "." path was last.
# Date Created: April 1st 1999
# Revision History:
#   01/04/99: initial tests.. didn't wok verywell at all
#           : retreived path throught '$ENV' call
#   07/04/99: After an email from Tim Nelson <wayland@ne.com.au> got it to work.
#           : used 'push' to add to array
#           : used 'join' to create a delimited string from a list/array.
#   16/02/00: fixed cmd-line options to look/work better
#   25/02/00: made verbosity level-oriented
#

# 
# Copyright (C) 2015  David Pyke
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
# 

use Getopt::Std;
#use Stdlib;

sub	printlevel;

$initial_str = "";
$debug_mode = "";
$delim_chr = ":";
$opt_v = 1;

getopts("v:hd:l:e:s:");

OPTS: {
	$opt_h && do {
print "\n$0 [-v level] [-d level] [-l delim] ( -e varname | -s strname | -h )";
print "\nWhere:";
print "\n	-h	This help";
print "\n	-d	Debug level";
print "\n	-l	Delimiter (between path vars)";
print "\n	-e	Specify environment variable (NB: don't include \$ sign)";
print "\n	-s	String (ie. $0 -s \$PATH:/looser/bin/)";
print "\n	-v	Verbosity (0 = quiet, 1 = normal, 2 = verbose)";
print "\n";
		exit;
	};
	$opt_d && do {
		printlevel 1, "You selected debug level $opt_d\n";
		$debug_mode = $opt_d;
	};
	$opt_l && do {
		printlevel 1, "You are going to delimit the string with \"$opt_l\"\n";
		$delim_chr = $opt_l;
	};
	$opt_e && do {
		if($opt_s) { die "Cannot specify BOTH env var and string\n"; }
		printlevel 1, "Using Environment variable \"$opt_e\"\n";
		$initial_str = $ENV{$opt_e};
	};
	$opt_s && do {
		printlevel 1, "Using String \"$opt_s\"\n";
		$initial_str = $opt_s;
	};
}

if( ($#ARGV != 1) and !$opt_e and !$opt_s){
	die "Nothing to work with -- try $0 -h\n";
}

$what = shift @ARGV;
# Split path using the delimiter
@dirs = split(/$delim_chr/, $initial_str);

$dest;
@newpath = ();
LOOP: foreach (@dirs){
	# Ensure the directory exists and is a directory
	if(! -e ) { printlevel 1, "$_ does not exist\n"; next; }
	# If the directory is ., set $dot and go around again
	if($_ eq '.') { $dot = 1; next; }

#	if ($_ ne `realpath $_`){
#	       	printlevel 2, "$_ becomes ".`realpath $_`."\n";
#	}
	undef $dest;
	#$_=Stdlib::realpath($_,$dest);
	# Check for duplicates and dot path
	foreach $adir (@newpath) { if($_ eq $adir) { 
		printlevel 2, "Duplicate: $_\n";
		next LOOP; 
	}}

	push @newpath, $_;
}

# Join creates a string from a list/array delimited by the first expression
print join($delim_chr, @newpath) . ($dot ? $delim_chr.".\n" : "\n");

printlevel 1, "Thank you for using $0\n";
exit;

sub	printlevel {
	my($level, $string) = @_;

	if($opt_v >= $level) {
		print STDERR $string;
	}
}

