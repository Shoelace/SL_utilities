#!/usr/bin/perl

# Get command line flags

#print ($#ARGV, "\n");
if($#ARGV == -1) {
    print STDERR "usage: ncsplit.pl --mff -- filename.txt [...] \n\nNote that no space is allowed between the '--' and the related parameter.\n\nThe mff is found on a line followed by a filename.  All of the contents of filename.txt are written to that file until another mff is found.\n";
    exit;
}

# this package sets the ARGV count variable to -1;

use Getopt::Long;
my $mff = "";
$file_switch = GetOptions('mff' => \$mff);

# set a default $mff variable
if ($mff == "") {$mff = "-#-"};
print ("using file switch=", $mff, "\n\n");

while($_ = shift @ARGV) {
    if(-f "$_") {
    push @filelist, $_;
    } 
}

# Could be more than one file name on the command line, 
# but this version throws away the subsequent ones.

for $readfile (@filelist){
#$readfile = $filelist[0];

print "opening $readfile\n";
open SOURCEFILE, "<$readfile" or die "File not found...\n\n";

while (<SOURCEFILE>) {
#   print $outname;
#   print "right is: $1 \n";

	if (/^$mff /) {
	  /^$mff (.*$)/o;
		$outname = $1;

	close OUTFILE;
		open OUTFILE, ">$outname" ;
		print "opened $outname\n";
    }
    else {
		print OUTFILE "$_"
	};
  }

close SOURCEFILE;

}
