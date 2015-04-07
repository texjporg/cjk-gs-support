#!/usr/bin/env perl
#
# cjk-gs-integrate - setup ghostscript for CID/TTF CJK fonts
#
# Copyright 2015 by Norbert Preining
#
# This file is licensed under GPL version 3 or any later version.
# For copyright statements see end of file.
#
# For development see
#  https://github.com/norbusan/cjk-gs-support
#

$^W = 1;
use Getopt::Long qw(:config no_autoabbrev ignore_case_always);
use File::Basename;
use strict;

# for debugging
use Data::Dumper;
$Data::Dumper::Indent = 1;

(my $prg = basename($0)) =~ s/\.pl$//;
my $version = '$VER$';

my $dry_run = 0;
my $opt_help = 0;
my $opt_quiet = 0;

if (! GetOptions(
        "n|dry-run" => \$dry_run,
	      "h|help" =>    \$opt_help,
        "q|quiet" =>   \$opt_quiet,
        "version" =>   sub { print &version(); exit(0); }, ) ) {
  die "Try \"$0 --help\" for more information.\n";
}

sub win32 { return ($^O=~/^MSWin(32|64)$/i); }
my $nul = (win32() ? 'nul' : '/dev/null') ;
my $sep = (win32() ? ';' : ':');
my %fontdb;

if ($opt_help) {
  Usage();
  exit 0;
}


main(@ARGV);

#
# only sub definitions from here on
#
sub main {
   my $gsres = find_gs_resource();
   if (!$gsres) {
     print_error("Cannot find GhostScript, (not really) terminating!\n");
     # for now keep working
     # exit(1);
  }
  read_font_database();
  check_for_files();
  info_found_files();
}

sub generate_cidfmap {
  my $outp = '';
  for my $k (keys %fontdb) {
    my @foundfiles;
    for my $f (keys %{$fontdb{$k}{'files'}}) {
      push @foundfiles, $f if $fontdb{$k}{'files'}{$f};
    }
    if (@foundfiles) {
      if ($fontdb{$k}{'type'} eq 'TTF') {
        for my $f (@foundfiles) {
          $outp .= generate_cidfmap_entry($k, $fontdb{$k}{'class'}, $f);
        }
      }
    }
  }
  #open(FOO, ">cidfmap.local") || die "Cannot open cidfmap.local: $!";
}

#
# dump found files
sub info_found_files {
  for my $k (keys %fontdb) {
    my @foundfiles;
    for my $f (keys %{$fontdb{$k}{'files'}}) {
      push @foundfiles, $f if $fontdb{$k}{'files'}{$f};
    }
    if (@foundfiles) {
      print "Font:  $k\n";
      print "Type:  $fontdb{$k}{'type'}\n";
      print "Class: $fontdb{$k}{'class'}\n";
      for my $f (@foundfiles) {
        print "Path:  $fontdb{$k}{'files'}{$f}\n";
      }
      print "\n";
    } 
  }
}

#
# checks all file names listed in %fontdb
# and sets
sub check_for_files {
  # first collect all files:
  my @fn;
  for my $k (keys %fontdb) {
    for my $f (keys %{$fontdb{$k}{'files'}}) {
      # check for subfont extension 
      if ($f =~ m/^(.*)\(\d*\)$/) {
        push @fn, $1;
      } else {
        push @fn, $f;
      }
    }
  }
  #
  # collect extra directories for search
  my @extradirs;
  if (win32()) {
    push @extradirs, "c:/windows/fonts//";
  } else {
    # other dirs to check, for normal unix?
    for my $d (qw!/Library/Fonts /System/Library/Fonts!) {
      push @extradirs, $d if (-d $d);
    }
  }
  # TODO
  # we need to take command line arguments into account
  #
  if (@extradirs) {
    # final dummy directory
    push @extradirs, "/this/does/not/really/exists/unless/you/are/stupid";
    # compose OSFONTDIR
    my $osfontdir = join ':', @extradirs;
    $ENV{'OSFONTDIR'} = $osfontdir;
  }
  # shoot up kpsewhich
  #print "checking for kpsewhich @fn\n\n";
  chomp( my @foundfiles = `kpsewhich @fn`);
  # print "Found files @foundfiles\n";
  # map basenames to filenames
  my %bntofn;
  for my $f (@foundfiles) {
    my $bn = basename($f);
    $bntofn{$bn} = $f;
  }
  # print Data::Dumper::Dumper(\%bntofn);

  # update the %fontdb with the found files
  for my $k (keys %fontdb) {
    for my $f (keys %{$fontdb{$k}{'files'}}) {
      # check for subfont extension 
      my $realfile = $f;
      $realfile =~ s/^(.*)\(\d*\)$/$1/;
      $fontdb{$k}{'files'}{$f} = $bntofn{$realfile} if ($bntofn{$realfile});
    }
  }
}

sub read_font_database {
  open (FDB, "<cjk-font-definitions.txt") ||
    die "Cannot find cjk-font-definitions.txt: $?";
  chomp(my @dbl = <FDB>);
  # add a "final empty line" to easy parsing
  push @dbl, "";
  close FDB;
  my $fontname = "";
  my $fonttype = "";
  my $fontclass = "";
  my @fontfiles;
  my $lineno = 0;
  for my $l (@dbl) {
    $lineno++;

    next if ($l =~ m/^\s*#/);
    if ($l =~ m/^\s*$/) {
      if ($fontname || $fonttype || $fontclass || $#fontfiles >= 0) {
        if ($fontname && $fonttype && $fontclass && $#fontfiles >= 0) {
          $fontdb{$fontname}{'type'} = $fonttype;
          $fontdb{$fontname}{'class'} = $fontclass;
          for my $f (@fontfiles) {
            # this will be set to the path name if found
            $fontdb{$fontname}{'files'}{$f} = 0;
          }
          # reset to start
          $fontname = $fonttype = $fontclass = "";
          @fontfiles = ();
        } else {
          print_warning("incomplete entry above line $lineno for $fontname/$fonttype/$fontclass, skipping!\n");
          # reset to start
          $fontname = $fonttype = $fontclass = "";
          @fontfiles = ();
        }
      } else {
        # no term is set, so nothing to warn about
      }
      next;
    }
    if ($l =~ m/^Name:\s*(.*)$/) { $fontname = $1; next; }
    if ($l =~ m/^Type:\s*(.*)$/) { $fonttype = $1 ; next ; }
    if ($l =~ m/^Class:\s*(.*)$/) { $fontclass = $1 ; next ; }
    if ($l =~ m/^Filename:\s*(.*)$/) { push @fontfiles, $1 ; next ; }
    # we are still here??
    print_error("Cannot parse this file at line $lineno, exiting. Strange line: >>>$l<<<\n");
    exit (1);
  }
}

sub find_gs_resource {
  # we assume that gs is in the path
  # on Windows we probably have to try something else
  my @ret = `gs --help 2>$nul`;
  my $foundres = '';
  if ($?) {
    print_error("Cannot find gs ...\n");
  } else {
    # try to find resource line
    for (@ret) {
      if (m!Resource/Font!) {
        $foundres = $_;
        $foundres =~ s/^\s*//;
        $foundres =~ s/\s*:\s*$//;
        $foundres =~ s!/Font!!;
        last;
      }
    }
    if (!$foundres) {
      print_error("Found gs but no resource???\n");
    }
  }
  return $foundres;
}

sub version {
  my $ret = sprintf "%s version %s\n", $prg, $version;
  return $ret;
}

sub Usage {
  my $usage = <<"EOF";
  $prg  Configuring GhostScript for CJK CID/TTF fonts.

  more to be written

EOF
;
  print $usage;
  exit 0;
}

# info/warning can be suppressed
# verbose/error cannot be suppressed
sub print_info {
  print STDOUT "$prg: ", @_ if (!$opt_quiet);
}
sub print_verbose {
  print STDOUT "$prg: ", @_;
}
sub print_warning {
  print STDERR "$prg [WARNING]: ", @_ if (!$opt_quiet) 
}
sub print_error {
  print STDERR "$prg [ERROR]: ", @_;
}




### Local Variables:
### perl-indent-level: 2
### tab-width: 2
### indent-tabs-mode: nil
### End:
# vim: set tabstop=2 expandtab autoindent:
