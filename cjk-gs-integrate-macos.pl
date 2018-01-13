#!/usr/bin/env perl
#
# cjk-gs-integrate-macos - wrapper for cjk-gs-integrate on macOS
#
# Copyright 2017-2018 by Japanese TeX Development Community
#
# This file is licensed under GPL version 3 or any later version.
# For copyright statements see end of file.
#
# For development see
#  https://github.com/texjporg/cjk-gs-support
#

$^W = 1;
use Getopt::Long qw(:config no_autoabbrev ignore_case_always pass_through);
use File::Basename;
use strict;
(my $prg = basename($0)) =~ s/\.pl$//;

my $opt_help = 0;
GetOptions("h|help" => \$opt_help);

sub macosx { return ($^O=~/^darwin$/i); }

if ($opt_help) {
  print "Usage: [perl] $prg\[.pl\] [OPTIONS]\n";
  print "This is a wrapper for cjk-gs-integrate on macOS.\n";
  exit 0;
}

my $addname;
if (macosx()) {
  my $macos_ver = `sw_vers -productVersion`;
  my $macos_ver_major = $macos_ver;
  $macos_ver_major =~ s/^(\d+)\.(\d+).*/$1/;
  my $macos_ver_minor = $macos_ver;
  $macos_ver_minor =~ s/^(\d+)\.(\d+).*/$2/;
  if ($macos_ver_major==10) {
    if ($macos_ver_minor==8) {
      $addname = "mountainlion";
    } elsif ($macos_ver_minor==9) {
      $addname = "mavericks";
    } elsif ($macos_ver_minor==10) {
      $addname = "mavericks"; # yosemite
    } elsif ($macos_ver_minor==11) {
      $addname = "elcapitan";
    } elsif ($macos_ver_minor==12) {
      $addname = "sierra";
    } elsif ($macos_ver_minor==13) {
      $addname = "highsierra";
    }
  }
}

my @newarg;
push @newarg, "--fontdef-add=cjkgs-macos-$addname.dat" if ($addname);
push @newarg, @ARGV if ($addname);
if (-f "cjk-gs-integrate.pl") {
  system("perl cjk-gs-integrate.pl @newarg");
} else {
  system("cjk-gs-integrate @newarg");  
}


### Local Variables:
### perl-indent-level: 2
### tab-width: 2
### indent-tabs-mode: nil
### End:
# vim: set tabstop=2 expandtab autoindent:
