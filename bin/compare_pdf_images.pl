#!/usr/bin/perl
# make_dita_grammar.pl - make DITA RelaxNG grammar plugin modules from high-level descriptions
#
# Prerequisites on linux:
#
#  sudo apt update
#  sudo apt install cpanminus
#  sudo cpanm install XML::Twig Acme::Tools

use warnings;
use strict;
require File::Temp;
use Getopt::Long 'HelpMessage';
use List::Util qw(max);

# process command-line arguments
my $verbose = 0;
GetOptions(
 'verbose'      => \$verbose,
 'help'         => sub { HelpMessage(0) }
) or HelpMessage(1);
HelpMessage(1) if scalar(@ARGV != 2);
do {die "PDF file '$_' does not exist" if !(-f $_);} for @ARGV;

# identify utilities we need
`which gs` or die "Couldn't find 'gs'";
`which magick` or die "Couldn't find 'magick'";

# use Ghostscript to render two input PDFs to TIFFs
my @pagecount = ();
my $tempdir = File::Temp->newdir() or die "Couldn't get temporary directory";
for my $i (1..2) {
 my $pdf = shift or die 'No PDF file $i specified.';
 my $pdfcmd = "gs -dNOPAUSE  -dBATCH -sDEVICE=tiff24nc -sOutputFile='${tempdir}/$i.tiff' -sCompression=lzw -dUseCropBox -r72 '$pdf'";
 print "Rendering PDF file '$pdf' to TIFF via the following command:\n  $pdfcmd\n\n" if $verbose;
 my $pdfoutput = `$pdfcmd`;
 die "Could not render '$pdf' ($pdfcmd)" if !(($pagecount[$i]) = ($pdfoutput =~ m!Processing pages 1 through (\d+)!));
}

# use ImageMagick to compare TIFFs for differences
my $tiffcmd = "magick '${tempdir}/1.tiff' null: '${tempdir}/2.tiff' -background None -compose Difference -layers Composite -format 'IsDifferent=%[fx:maxima==0?0:1]\n' info:";
print "Comparing temporary TIFF files via the following command:\n  ".($tiffcmd =~ s!\n!\\n!r)."\n\n" if $verbose;
my $tiffoutput = `$tiffcmd`;
my @difference_flags = ($tiffoutput =~ m!IsDifferent=([01])!g) or die "Couldn't obtain difference information from ImageMagick ($tiffcmd)";
die "Found fewer difference flags than pages ($tiffcmd)" if (max(@pagecount[1..2]) < scalar(@difference_flags));

# print results
if (!grep {$_ eq '1'} @difference_flags) {
 printf("Of %d pages, PDF images are identical.\n", $pagecount[1]);  # page counts are identical, can use either one
} else {
 # turn an array of difference flags (0 1 0 1 1 1 0)
 # into an array of array hashes of modified pages ( [2] [4 5 6] )
 my @sections = ();
 while (my ($i, $flag) = each(@difference_flags)) {
  if ($flag) {
   push @sections, ([]) if (!defined($sections[-1]) || $sections[-1]->[-1] != (($i+1)-1));  # if most recently pushed page number isn't (thispage-1), then start a new section
   push @{$sections[-1]}, ($i+1);  # push to the last section in the list
  }
 }

 my @section_text = map {scalar(@{$_} == 1) ? "$_->[0]" : "$_->[0]-$_->[-1]"} @sections;  # convert ( [2] [4 5 6] ) to ('2' '4-6')
 printf("Of %s pages, PDF images differ at: %s.\n",
   ($pagecount[1] == $pagecount[2]) ? ($pagecount[1]) : sprintf('(%d and %d)', ($pagecount[1], $pagecount[2])),
   join(', ', @section_text));
}


=head1 NAME

compare_pdf_images.pl - compare two PDF files visually (by bitmap-rendered images)

=head1 SYNOPSIS

  <pdf1> <pdf2>
        Two PDF files to compare
  -verbose
        Show additional information about reading and processing files

=head1 VERSION

0.20

=cut

