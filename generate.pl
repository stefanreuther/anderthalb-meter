#!/usr/bin/perl -w
#
#  Read through HTML, check all referenced images, and render them using Inkscape.
#  This script implements "make" logic, that is, it only processes SVG images that are new or changed.
#
use strict;

my $INKSCAPE = 'inkscape';
my @html = qw(html/index.html);
my %todo;

# Read list of files to generate
foreach my $file (@html) {
    # Slurp file
    open FILE, '<', $file or die "$file: $!";
    my $text = join('', <FILE>);
    close FILE;

    # Determine directory
    my $dir_prefix = ($file =~ m|^(.*/)| ? $1 : '');

    # I know I'm not supposed to parse HTML with regexps
    while ($text =~ m/<(img\s+src=|a\s+href=)"(.*?)_(\d+)x(\d+)\.png"/g) {
        $todo{"$dir_prefix${2}_${3}x${4}.png"} = {
            in => "$2.svg",
            w => $3,
            h => $4
        };
    }
}

# Process them
my $self_time = file_time($0);
foreach my $out (sort keys %todo) {
    my $spec = $todo{$out};
    if (! -f "$out" || file_time($out) < file_time($spec->{in}) || file_time($out) < $self_time) {
        print "\tGenerating $out...\n";

        my @command = ($INKSCAPE, '-e', $out, '-y', '0', '-w', $spec->{w}, '-h', $spec->{h}, $spec->{in});
        if (system(@command)  != 0) {
            print STDERR "*** Command '", join(' ', @command), "' returned non-zero exit status.\n";
            exit 1;
        }
    }
}



sub file_time {
    my $x = shift;
    return (stat($x))[9];
}
