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
my $opt_debug = 0;

my %encode_list = (
  Japan => [ qw/
    78-EUC-H
    78-EUC-V
    78-H
    78-RKSJ-H
    78-RKSJ-V
    78-V
    78ms-RKSJ-H
    78ms-RKSJ-V
    83pv-RKSJ-H
    90ms-RKSJ-H
    90ms-RKSJ-V
    90msp-RKSJ-H
    90msp-RKSJ-V
    90pv-RKSJ-H
    90pv-RKSJ-V
    Add-H
    Add-RKSJ-H
    Add-RKSJ-V
    Add-V
    Adobe-Japan1-0
    Adobe-Japan1-1
    Adobe-Japan1-2
    Adobe-Japan1-3
    Adobe-Japan1-4
    Adobe-Japan1-5
    Adobe-Japan1-6
    EUC-H
    EUC-V
    Ext-H
    Ext-RKSJ-H
    Ext-RKSJ-V
    Ext-V
    H
    Hankaku
    Hiragana
    Identity-H
    Identity-V
    Katakana
    NWP-H
    NWP-V
    RKSJ-H
    RKSJ-V
    Roman
    UniJIS-UCS2-H
    UniJIS-UCS2-HW-H
    UniJIS-UCS2-HW-V
    UniJIS-UCS2-V
    UniJIS-UTF16-H
    UniJIS-UTF16-V
    UniJIS-UTF32-H
    UniJIS-UTF32-V
    UniJIS-UTF8-H
    UniJIS-UTF8-V
    UniJIS2004-UTF16-H
    UniJIS2004-UTF16-V
    UniJIS2004-UTF32-H
    UniJIS2004-UTF32-V
    UniJIS2004-UTF8-H
    UniJIS2004-UTF8-V
    UniJISPro-UCS2-HW-V
    UniJISPro-UCS2-V
    UniJISPro-UTF8-V
    UniJISX0213-UTF32-H
    UniJISX0213-UTF32-V
    UniJISX02132004-UTF32-H
    UniJISX02132004-UTF32-V
    V
    WP-Symbol/ ],
  GB => [ qw/
    Adobe-GB1-0
    Adobe-GB1-1
    Adobe-GB1-2
    Adobe-GB1-3
    Adobe-GB1-4
    Adobe-GB1-5
    GB-EUC-H
    GB-EUC-V
    GB-H
    GB-RKSJ-H
    GB-V
    GBK-EUC-H
    GBK-EUC-V
    GBK2K-H
    GBK2K-V
    GBKp-EUC-H
    GBKp-EUC-V
    GBT-EUC-H
    GBT-EUC-V
    GBT-H
    GBT-RKSJ-H
    GBT-V
    GBTpc-EUC-H
    GBTpc-EUC-V
    GBpc-EUC-H
    GBpc-EUC-V
    Identity-H
    Identity-V
    UniGB-UCS2-H
    UniGB-UCS2-V
    UniGB-UTF16-H
    UniGB-UTF16-V
    UniGB-UTF32-H
    UniGB-UTF32-V
    UniGB-UTF8-H
    UniGB-UTF8-V/ ],
  CNS => [ qw/
    Adobe-CNS1-0
    Adobe-CNS1-1
    Adobe-CNS1-2
    Adobe-CNS1-3
    Adobe-CNS1-4
    Adobe-CNS1-5
    Adobe-CNS1-6
    B5-H
    B5-V
    B5pc-H
    B5pc-V
    CNS-EUC-H
    CNS-EUC-V
    CNS1-H
    CNS1-V
    CNS2-H
    CNS2-V
    ETHK-B5-H
    ETHK-B5-V
    ETen-B5-H
    ETen-B5-V
    ETenms-B5-H
    ETenms-B5-V
    HKdla-B5-H
    HKdla-B5-V
    HKdlb-B5-H
    HKdlb-B5-V
    HKgccs-B5-H
    HKgccs-B5-V
    HKm314-B5-H
    HKm314-B5-V
    HKm471-B5-H
    HKm471-B5-V
    HKscs-B5-H
    HKscs-B5-V
    Identity-H
    Identity-V
    UniCNS-UCS2-H
    UniCNS-UCS2-V
    UniCNS-UTF16-H
    UniCNS-UTF16-V
    UniCNS-UTF32-H
    UniCNS-UTF32-V
    UniCNS-UTF8-H
    UniCNS-UTF8-V/ ],
  Korea => [ qw/
    Adobe-Korea1-0
    Adobe-Korea1-1
    Adobe-Korea1-2
    Identity-H
    Identity-V
    KSC-EUC-H
    KSC-EUC-V
    KSC-H
    KSC-Johab-H
    KSC-Johab-V
    KSC-RKSJ-H
    KSC-V
    KSCms-UHC-H
    KSCms-UHC-HW-H
    KSCms-UHC-HW-V
    KSCms-UHC-V
    KSCpc-EUC-H
    KSCpc-EUC-V
    UniKS-UCS2-H
    UniKS-UCS2-V
    UniKS-UTF16-H
    UniKS-UTF16-V
    UniKS-UTF32-H
    UniKS-UTF32-V
    UniKS-UTF8-H
    UniKS-UTF8-V/ ] );



if (! GetOptions(
        "n|dry-run" => \$dry_run,
	      "h|help" =>    \$opt_help,
        "q|quiet" =>   \$opt_quiet,
        "d+"      =>   \$opt_debug,
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
  # info_found_files();
  generate_cidfmap();
  generate_cid();
}

sub generate_cid {
  my $fontdest = "Font";
  my $ciddest  = "CIDFont";
  if (-r $fontdest) {
    if (! -d $fontdest) {
      print_error("$fontdest is not a directory, cannot create CID snippets there!\n");
      exit 1;
    }
  } else {
    mkdir($fontdest);
  }
  if (-r $ciddest) {
    if (! -d $ciddest) {
      print_error("$ciddest is not a directory, cannot link CID fonts there!\n");
      exit 1;
    }
  } else {
    mkdir($ciddest);
  }
  for my $k (keys %fontdb) {
    my @foundfiles;
    for my $f (keys %{$fontdb{$k}{'files'}}) {
      push @foundfiles, $f if $fontdb{$k}{'files'}{$f};
    }
    if (@foundfiles) {
      if ($fontdb{$k}{'type'} eq 'CID') {
        for my $f (@foundfiles) {
          generate_cid_font_snippet($fontdest,
            $k, $fontdb{$k}{'class'}, $fontdb{$k}{'files'}{$f});
          link_cid_font($ciddest, $k, $fontdb{$k}{'files'}{$f});
        }
      }
    }
  }
}

sub generate_cid_font_snippet {
  my ($fd, $n, $c, $f) = @_;
  for my $enc (@{$encode_list{$c}}) {
    open(FOO, ">$fd/$n-$enc") || die("cannot open $fd/$n-$enc for writing: $!");
    print FOO "%%!PS-Adobe-3.0 Resource-Font
%%%%DocumentNeededResources: $enc (CMap)
%%%%IncludeResource: $enc (CMap)
%%%%BeginResource: Font ($n-$enc)
($n-$enc)
($enc) /CMap findresource
[($n) /CIDFont findresource]
composefont
pop
%%%%EndResource
%%%%EOF
";
    close(FOO);
  }
}

sub link_cid_font {
  my ($cd, $n, $f) = @_;
  symlink($f, "$cd/$n");
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
          $outp .= generate_cidfmap_entry($k, $fontdb{$k}{'class'}, $fontdb{$k}{'files'}{$f});
        }
      }
    }
  }
  if ($outp) {
    open(FOO, ">cidfmap.local") || die "Cannot open cidfmap.local: $!";
    print FOO $outp;
    close(FOO);
  }
}

sub generate_cidfmap_entry {
  my ($n, $c, $f) = @_;
  # extract subfont
  my $rf = $f;
  my $sf = 0;
  if ($f =~ m/^(.*)\((\d*)\)$/) {
    $rf = $1;
    $sf = $2;
  }
  my $s = "/$n <<
  /FileType /TrueType
  /SubfontID 0
  /CSI [($c";
  if ($c eq "Japan") {
    $s .= "1) 6]";
  } elsif ($c eq "GB") {
    $s .= "1) 5]";
  } elsif ($c eq "CNS") {
    $s .= "1) 5]";
  } elsif ($c eq "Korean") {
    print_warning("don't know how to handle class $c for $n, skipping.\n");
    return '';
  } else {
    print_warning("unknown class $c for $n, skipping.\n");
    return '';
  }
  $s .= "
  /Path ($f) >> ;

";
  return $s;
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
    # push current value of OSFONTDIR
    push @extradirs, $ENV{'OSFONTDIR'} if $ENV{'OSFONTDIR'};
    # compose OSFONTDIR
    my $osfontdir = join ':', @extradirs;
    $ENV{'OSFONTDIR'} = $osfontdir;
  }
  if ($ENV{'OSFONTDIR'}) {
    print_debug("final setting of OSFONTDIR: $ENV{'OSFONTDIR'}\n");
  }
  # shoot up kpsewhich
  #print "checking for kpsewhich @fn\n\n";
  chomp( my @foundfiles = `kpsewhich @fn`);
  print_debug("Found files @foundfiles\n");
  # map basenames to filenames
  my %bntofn;
  for my $f (@foundfiles) {
    my $bn = basename($f);
    $bntofn{$bn} = $f;
  }
  print_ddebug(Data::Dumper::Dumper(\%bntofn));

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
sub print_debug {
  print STDERR "$prg [DEBUG]: ", @_ if ($opt_debug >= 1);
}
sub print_ddebug {
  print STDERR "$prg [DEBUG]: ", @_ if ($opt_debug >= 2);
}




### Local Variables:
### perl-indent-level: 2
### tab-width: 2
### indent-tabs-mode: nil
### End:
# vim: set tabstop=2 expandtab autoindent:
