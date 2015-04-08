#!/usr/bin/env perl
#
# cjk-gs-integrate - setup ghostscript for CID/TTF CJK fonts
#
# Copyright 2015 by Norbert Preining
#
# Based on research and work by Yusuke Kuroki, Bruno Voisin, Munehiro Yamamoto
# and the TeX Q&A wiki page
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

(my $prg = basename($0)) =~ s/\.pl$//;
my $version = '$VER$';

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

my $dry_run = 0;
my $opt_help = 0;
my $opt_quiet = 0;
my $opt_debug = 0;
my $opt_fontdef;
my $opt_output;

if (! GetOptions(
        "n|dry-run"   => \$dry_run,
        "o|output=s"  => \$opt_output,
	      "h|help"      => \$opt_help,
        "q|quiet"     => \$opt_quiet,
        "d|debug+"    => \$opt_debug,
        "f|fontdef=s" => \$opt_fontdef,
        "v|version"   => sub { print &version(); exit(0); }, ) ) {
  die "Try \"$0 --help\" for more information.\n";
}

sub win32 { return ($^O=~/^MSWin(32|64)$/i); }
my $nul = (win32() ? 'nul' : '/dev/null') ;
my $sep = (win32() ? ';' : ':');
my %fontdb;
my %aliases;

if ($opt_help) {
  Usage();
  exit 0;
}

if ($opt_debug) {
  require Data::Dumper;
  $Data::Dumper::Indent = 1;
}

main(@ARGV);

#
# only sub definitions from here on
#
sub main {
  if (! $opt_output) {
    print_info("searching for GhostScript resource\n");
    my $gsres = find_gs_resource();
    if (!$gsres) {
      print_error("Cannot find GhostScript, (not really) terminating!\n");
      exit(1);
    } else {
      $opt_output = $gsres;
    }
  }
  if (! -d $opt_output) {
    $dry_run || mkdir($opt_output) || 
      die ("Cannot create directory $opt_output: $!");
  }
  print_info("output is going to $opt_output\n");
  print_info("reading font database ...\n");
  read_font_database();
  print_info("checking for files ...\n");
  check_for_files();
  if ($opt_debug > 1) {
    info_found_files();
  }
  print_info("generating font snippets and link CID fonts ...\n");
  generate_cid();
  print_info("generating cidfmap.local ...\n");
  generate_cidfmap();
  print_info("adding cidfmap.local to cidfmap file ...\n");
  update_master_cidfmap();
  print_info("finished\n");
}

sub update_master_cidfmap {
  my $cidfmap_master = "$opt_output/Init/cidfmap";
  my $cidfmap_local = "$opt_output/Init/cidfmap.local";
  if (-r $cidfmap_master) {
    open(FOO, "<", $cidfmap_master) ||
      die ("Cannot open $cidfmap_master for reading: $!");
    my $found = 0;
    while(<FOO>) {
      $found = 1 if
        m/^\s*\(cidfmap\.local\)\s\s*\.runlibfile\s*$/;
    }
    if ($found) {
      print_info("cidfmap.local already loaded in $cidfmap_master, no changes\n");
    } else {
      return if $dry_run;
      open(FOO, ">>", $cidfmap_master) ||
        die ("Cannot open $cidfmap_master for appending: $!");
      print FOO "(cidfmap.local) .runlibfile\n";
      close(FOO);
    }
  } else {
    return if $dry_run;
    open(FOO, ">", $cidfmap_master) ||
      die ("Cannot open $cidfmap_master for writing: $!");
    print FOO "(cidfmap.local) .runlibfile\n";
    close(FOO);
  }
}

sub generate_cid {
  my $fontdest = "$opt_output/Font";
  my $ciddest  = "$opt_output/CIDFont";
  if (-r $fontdest) {
    if (! -d $fontdest) {
      print_error("$fontdest is not a directory, cannot create CID snippets there!\n");
      exit 1;
    }
  } else {
    $dry_run || mkdir($fontdest);
  }
  if (-r $ciddest) {
    if (! -d $ciddest) {
      print_error("$ciddest is not a directory, cannot link CID fonts there!\n");
      exit 1;
    }
  } else {
    $dry_run || mkdir($ciddest);
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
  return if $dry_run;
  for my $enc (@{$encode_list{$c}}) {
    open(FOO, ">$fd/$n-$enc") || 
      die("cannot open $fd/$n-$enc for writing: $!");
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
  return if $dry_run;
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
  #
  # alias handling
  # we use two levels of aliases, one is for the default names that
  # are not actual fonts:
  # Ryumin-Light, GothicBBB-Medium, FutoMinA101-Bold, FutoGoB101-Bold, 
  # Jun101-Light which are the original Morisawa names.
  #
  # the second level of aliases is for Morisawa OTF font names:
  # A-OTF-RyuminPro-Light, A-OTF-GothicBBBPro-Medium,
  # A-OTF-FutoMinA101Pro-Bold, A-OTF-FutoGoB101Pro-Bold
  # A-OTF-Jun101Pro-Light
  #
  # the order of fonts selected is
  # Morisawa Pr6, Morisawa, Hiragino ProN, Hiragino, 
  # Yu OSX, Yu Win, Kozuka ProN, Kozuka, IPAex, IPA
  # but is defined in the Provides: Name(Priority) in the font definiton
  #
  $outp .= "\n\n% Aliases\n\n";
  my @al = keys %aliases;
  for my $al (keys %aliases) {
    # search lowest number
    my @ks = keys(%{$aliases{$al}});
    my $first = (sort { $a <=> $b} @ks)[0];
    $outp .= "/$al /$aliases{$al}{$first} ;\n";
  }
  #
  return if $dry_run;
  if ($outp) {
    if (! -d "$opt_output/Init") {
      mkdir("$opt_output/Init") ||
        die("Cannot create directory $opt_output/Init: $!");
    }
    open(FOO, ">$opt_output/Init/cidfmap.local") || 
      die "Cannot open $opt_output/cidfmap.local: $!";
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
    $s .= "1) 2]";
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
  # prepare for kpsewhich call, we need to do quoting
  my $cmdl = 'kpsewhich ';
  for my $f (@fn) {
    $cmdl .= " \"$f\" ";
  }
  # shoot up kpsewhich
  print_debug("checking for $cmdl\n");
  chomp( my @foundfiles = `$cmdl`);
  print_debug("Found files @foundfiles\n");
  # map basenames to filenames
  my %bntofn;
  for my $f (@foundfiles) {
    my $bn = basename($f);
    $bntofn{$bn} = $f;
  }
  if ($opt_debug > 1) {
    print_ddebug("dumping basename to filename list:\n");
    print_ddebug(Data::Dumper::Dumper(\%bntofn));
  }

  # update the %fontdb with the found files
  for my $k (keys %fontdb) {
    $fontdb{$k}{'available'} = 0;
    for my $f (keys %{$fontdb{$k}{'files'}}) {
      # check for subfont extension 
      my $realfile = $f;
      $realfile =~ s/^(.*)\(\d*\)$/$1/;
      if ($bntofn{$realfile}) {
        # we found a representative, make it available
        $fontdb{$k}{'files'}{$f} = $bntofn{$realfile};
        $fontdb{$k}{'available'} = 1;
      }
    }
  }
  # make a second round through the fontdb to check for provides
  for my $k (keys %fontdb) {
    if ($fontdb{$k}{'available'}) {
      for my $p (keys %{$fontdb{$k}{'provides'}}) {
        # do not check alias if the real font is available
        next if $fontdb{$p}{'available'};
        # use the priority as key
        # if priorities are double, this will pick one at chance
        $aliases{$p}{$fontdb{$k}{'provides'}{$p}} = $k;
      }
    }
  }
  if ($opt_debug > 1) {
    print_ddebug("dumping font database:\n");
    print_ddebug(Data::Dumper::Dumper(\%fontdb));
    print_ddebug("dumping aliases:\n");
    print_ddebug(Data::Dumper::Dumper(\%aliases));
  }
}

sub read_font_database {
  my @dbl;
  if ($opt_fontdef) {
    open (FDB, "<$opt_fontdef") ||
      die "Cannot find $opt_fontdef: $!";
    @dbl = <FDB>;
    close(FDB);
  } else {
    @dbl = <DATA>;
  }
  chomp(@dbl);
  # add a "final empty line" to easy parsing
  push @dbl, "";
  my $fontname = "";
  my $fonttype = "";
  my $fontclass = "";
  my %fontprovides = ();
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
          $fontdb{$fontname}{'provides'} = { %fontprovides };
          # reset to start
          $fontname = $fonttype = $fontclass = "";
          @fontfiles = ();
          %fontprovides = ();
        } else {
          print_warning("incomplete entry above line $lineno for $fontname/$fonttype/$fontclass, skipping!\n");
          # reset to start
          $fontname = $fonttype = $fontclass = "";
          @fontfiles = ();
          %fontprovides = ();
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
    if ($l =~ m/^Provides:\s*(.*)\((\d+)\)$/) { $fontprovides{$1} = $2; next; }
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

Usage: $prg [OPTION] ...

Configuring GhostScript for CJK CID/TTF fonts.

Options:
  -n, --dry-run         do not actually output anything
  -f, --fontdef FILE    specify alternate set of font definitions, if not
                        given, the built-in set is used
  -o, --output DIR      specifies the base output dir, if not provided,
                        the Resource directory of an install GhostScript
                        is searched and used.
  -q, --quiet           be less verbose
  -d, --debug           output debug information, can be given multiple times
  -v, --version         outputs only the version information
  -h, --help            this help

Operation:

  This script searches a list of directories (see below) for CJK fonts,
  and makes them available to an installed GhostScript. In the simplest
  case with sufficient privileges, a run without arguments should effect
  in a complete setup of GhostScript.

  For each found TrueType (TTF) font it creates a cidfmap entry in
    <Resource>/Init/cidfmap.local
  For each CID font it creates a snippet in
    <Resource>/Font/
  and links the font to 
    <Resource>/CIDFont
  The <Resource> dir is either given by -o/--output, or otherwise searched
  from an installed GhostScript (binary name is assumed to be 'gs').

  Finally, it tries to add runlib call to
    <Resource>/Init/cidfmap
  to load the cidfmap.local.

How and which directories are searched:

  Search is done using the kpathsea library, in particular using kpsewhich
  program. By default the following directories are searched:
  - all TEXMF trees
  - /Library/Fonts and /System/Library/Fonts (if available)
  - c:/windows/fonts (on Windows)
  - the directories in OSFONTDIR environment variable

  In case you want to add some directories to the search path, adapt the
  OSFONTDIR environment variable accordingly: Example:
    OSFONTDIR="/usr/local/share/fonts/truetype//:/usr/local/share/fonts/opentype//" $prg
  will result in fonts found in the above two given directories to be
  searched in addition.

Output files:

  If no output option is given, the program searches for a GhostScript
  interpreter 'gs' and determines its Resource directory. This might
  fail, in which case one need to pass the output directory manually.

  Since the program adds files and link to this directory, sufficient
  permissions are necessary.

Aliases:

  The program tries to set up aliases if necessary for the set of
  original Morisawa names
    Ryumin-Light GothicBBB-Medium FutoMinA101-Bold
    FutoGoB101-Bold Jun101-Light
  and the otf Morisawa names
    A-OTF-RyuminPro-Light A-OTF-GothicBBBPro-Medium A-OTF-FutoMinA101Pro-Bold
    A-OTF-FutoGoB101Pro-Bold A-OTF-Jun101Pro-Light
  The order is determined by the Provides setting in the font database,
  and currently is 
    Morisawa Pr6, Morisawa, Hiragino ProN, Hiragino, 
    Yu OSX, Yu Win, Kozuka ProN, Kozuka, IPAex, IPA
  That is, the first font found in this order will be used to provide the
  alias if necessary.

Authors, Contributors, and Copyright:

  The script and its documentation was written by Norbert Preining, based
  on research and work by Yusuke Kuroki, Bruno Voisin, Munehiro Yamamoto
  and the TeX Q&A wiki page.

  The script is licensed under GNU General Public License Version 3 or later.
  The contained font data is not copyrightable.

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


__DATA__
#
# CJK FONT DEFINITIONS
#

# JAPAN

# Morisawa

Name: A-OTF-FutoGoB101Pr6N-Bold
Type: CID
Class: Japan
Provides: FutoGoB101-Bold(10)
Provides: A-OTF-FutoGoB101Pro-Bold(10)
Filename: A-OTF-FutoGoB101Pr6N-Bold.otf

Name: A-OTF-FutoGoB101Pro-Bold
Type: CID
Class: Japan
Provides: FutoGoB101-Bold(20)
Filename: A-OTF-FutoGoB101Pro-Bold.otf

Name: A-OTF-FutoMinA101Pr6N-Bold
Type: CID
Class: Japan
Provides: FutoMinA101-Bold(10)
Provides: A-OTF-FutoMinA101Pro-Bold(10)
Filename: A-OTF-FutoMinA101Pr6N-Bold.otf

Name: A-OTF-FutoMinA101Pro-Bold
Type: CID
Class: Japan
Provides: FutoMinA101-Bold(20)
Filename: A-OTF-FutoMinA101Pro-Bold.otf

Name: A-OTF-GothicBBBPr6N-Medium
Type: CID
Class: Japan
Provides: GothicBBB-Medium(10)
Provides: A-OTF-GothicBBBPro-Medium(10)
Filename: A-OTF-GothicBBBPr6N-Medium.otf

Name: A-OTF-GothicBBBPro-Medium
Type: CID
Class: Japan
Provides: GothicBBB-Medium(20)
Filename: A-OTF-GothicBBBPro-Medium.otf

Name: A-OTF-Jun101Pro-Light
Type: CID
Class: Japan
Provides: Jun101-Light(20)
Filename: A-OTF-Jun101Pro-Light.otf

Name: A-OTF-MidashiGoPr6N-MB31
Type: CID
Class: Japan
Filename: A-OTF-MidashiGoPr6N-MB31.otf

Name: A-OTF-MidashiGoPro-MB31
Type: CID
Class: Japan
Filename: A-OTF-MidashiGoPro-MB31.otf

Name: A-OTF-RyuminPr6N-Light
Type: CID
Class: Japan
Provides: Ryumin-Light(10)
Provides: A-OTF-RyuminPro-Light(10)
Filename: A-OTF-RyuminPr6N-Light.otf

Name: A-OTF-RyuminPro-Light
Type: CID
Class: Japan
Provides: Ryumin-Light(20)
Filename: A-OTF-RyuminPro-Light.otf

Name: A-OTF-ShinMGoPr6N-Light
Type: CID
Class: Japan
Provides: Jun101-Light(10)
Provides: A-OTF-Jun101Pro-Light(10)
Filename: A-OTF-ShinMGoPr6N-Light.otf


# Hiragino

Name: HiraKakuPro-W3
Type: CID
Class: Japan
Provides: GothicBBB-Medium(40)
Provides: A-OTF-GothicBBBPro-Medium(40)
Filename: ヒラギノ角ゴ Pro W3.otf
Filename: HiraKakuPro-W3.otf

Name: HiraKakuPro-W6
Type: CID
Class: Japan
Provides: FutoGoB101-Bold(40)
Provides: A-OTF-FutoGoB101Pro-Bold(40)
Filename: ヒラギノ角ゴ Pro W6.otf
Filename: HiraKakuPro-W6.otf

Name: HiraKakuProN-W3
Type: CID
Class: Japan
Provides: GothicBBB-Medium(30)
Provides: A-OTF-GothicBBBPro-Medium(30)
Filename: ヒラギノ角ゴ ProN W3.otf
Filename: HiraKakuProN-W3.otf

Name: HiraKakuProN-W6
Type: CID
Class: Japan
Provides: FutoGoB101-Bold(30)
Provides: A-OTF-FutoGoB101Pro-Bold(30)
Filename: ヒラギノ角ゴ ProN W6.otf
Filename: HiraKakuProN-W6.otf

Name: HiraKakuStd-W8
Type: CID
Class: Japan
Filename: ヒラギノ角ゴ Std W8.otf
Filename: HiraKakuStd-W8.otf

Name: HiraKakuStdN-W8
Type: CID
Class: Japan
Filename: ヒラギノ角ゴ StdN W8.otf
Filename: HiraKakuStdN-W8.otf

Name: HiraMaruPro-W4
Type: CID
Class: Japan
Provides: Jun101-Light(40)
Provides: A-OTF-Jun101Pro-Light(40)
Filename: ヒラギノ丸ゴ Pro W4.otf
Filename: HiraMaruPro-W4.otf

Name: HiraMaruProN-W4
Type: CID
Class: Japan
Provides: Jun101-Light(30)
Provides: A-OTF-Jun101Pro-Light(30)
Filename: ヒラギノ丸ゴ ProN W4.otf
Filename: HiraMaruProN-W4.otf

Name: HiraMinPro-W3
Type: CID
Class: Japan
Provides: Ryumin-Light(40)
Provides: A-OTF-RyuminPro-Light(40)
Filename: ヒラギノ明朝 Pro W3.otf
Filename: HiraMinPro-W3.otf

Name: HiraMinPro-W6
Type: CID
Class: Japan
Provides: FutoMinA101-Bold(40)
Provides: A-OTF-FutoMinA101Pro-Bold(40)
Filename: ヒラギノ明朝 Pro W6.otf
Filename: HiraMinPro-W6.otf

Name: HiraMinProN-W3
Type: CID
Class: Japan
Provides: Ryumin-Light(30)
Provides: A-OTF-RyuminPro-Light(30)
Filename: ヒラギノ明朝 ProN W3.otf
Filename: HiraMinProN-W3.otf

Name: HiraMinProN-W6
Type: CID
Class: Japan
Provides: FutoMinA101-Bold(30)
Provides: A-OTF-FutoMinA101Pro-Bold(30)
Filename: ヒラギノ明朝 ProN W6.otf
Filename: HiraMinProN-W6.otf


Name: HiraginoSansGB-W3
Type: CID
Class: GB
Filename: Hiragino Sans GB W3.otf
Filename: HiraginoSansGB-W3.otf

Name: HiraginoSansGB-W6
Type: CID
Class: GB
Filename: Hiragino Sans GB W6.otf
Filename: HiraginoSansGB-W6.otf


# Yu-fonts MacOS version

Name: YuGo-Medium
Type: CID
Class: Japan
Provides: GothicBBB-Medium(50)
Provides: A-OTF-GothicBBBPro-Medium(50)
Filename: Yu Gothic Medium.otf
Filename: YuGo-Medium.otf

Name: YuGo-Bold
Type: CID
Class: Japan
Provides: FutoGoB101-Bold(50)
Provides: A-OTF-FutoGoB101Pro-Bold(50)
Provides: Jun101-Light(50)
Provides: A-OTF-Jun101Pro-Light(50)
Filename: Yu Gothic Bold.otf
Filename: YuGo-Bold.otf

Name: YuMin-Medium
Type: CID
Class: Japan
Provides: Ryumin-Light(50)
Provides: A-OTF-RyuminPro-Light(50)
Filename: Yu Mincho Medium.otf
Filename: YuMin-Medium.otf

Name: YuMin-Demibold
Type: CID
Class: Japan
Provides: FutoMinA101-Bold(50)
Provides: A-OTF-FutoMinA101Pro-Bold(50)
Filename: Yu Mincho Demibold.otf
Filename: YuMin-Demibold.otf

# Yu-fonts Windows version
Name: YuMincho-Regular
Type: TTF
Class: Japan
Provides: Ryumin-Light(60)
Provides: A-OTF-RyuminPro-Light(60)
Filename: yumin.ttf
Filename: YuMincho-Regular.ttf

Name: YuMincho-Light
Type: TTF
Class: Japan
Filename: yuminl.ttf
Filename: YuMincho-Light.ttf

Name: YuMincho-DemiBold
Type: TTF
Class: Japan
Provides: FutoMinA101-Bold(60)
Provides: A-OTF-FutoMinA101Pro-Bold(60)
Filename: yumindb.ttf
Filename: YuMincho-DemiBold.ttf

Name: YuGothic-Regular
Type: TTF
Class: Japan
Provides: GothicBBB-Medium(60)
Provides: A-OTF-GothicBBBPro-Medium(60)
Filename: yugothic.ttf
Filename: YuGothic-Regular.ttf

Name: YuGothic-Light
Type: TTF
Class: Japan
Filename: yugothil.ttf
Filename: YuGothic-Light.ttf

Name: YuGothic-Bold
Type: TTF
Class: Japan
Provides: FutoGoB101-Bold(60)
Provides: A-OTF-FutoGoB101Pro-Bold(60)
Provides: Jun101-Light(60)
Provides: A-OTF-Jun101Pro-Light(60)
Filename: yugothib.ttf
Filename: YuGothic-Bold.ttf

# IPA fonts

Name: IPAMincho
Type: TTF
Class: Japan
Provides: Ryumin-Light(110)
Provides: A-OTF-RyuminPro-Light(110)
Filename: ipam.ttf
Filename: IPAMincho.ttf

Name: IPAGothic
Type: TTF
Class: Japan
Provides: GothicBBB-Medium(110)
Provides: A-OTF-GothicBBBPro-Medium(110)
Provides: FutoMinA101-Bold(110)
Provides: A-OTF-FutoMinA101Pro-Bold(110)
Provides: FutoGoB101-Bold(110)
Provides: A-OTF-FutoGoB101Pro-Bold(110)
Provides: Jun101-Light(110)
Provides: A-OTF-Jun101Pro-Light(110)
Filename: ipag.ttf
Filename: IPAGothic.ttf

Name: IPAexMincho
Type: TTF
Class: Japan
Provides: Ryumin-Light(100)
Provides: A-OTF-RyuminPro-Light(100)
Filename: ipaexm.ttf
Filename: IPAexMincho.ttf

Name: IPAexGothic
Type: TTF
Class: Japan
Provides: GothicBBB-Medium(100)
Provides: A-OTF-GothicBBBPro-Medium(100)
Provides: FutoMinA101-Bold(100)
Provides: A-OTF-FutoMinA101Pro-Bold(100)
Provides: FutoGoB101-Bold(100)
Provides: A-OTF-FutoGoB101Pro-Bold(100)
Provides: Jun101-Light(100)
Provides: A-OTF-Jun101Pro-Light(100)
Filename: ipaexg.ttf
Filename: IPAexGothic.ttf

# Kozuka fonts

Name: KozGoPr6N-Bold
Type: CID
Class: Japan
Provides: FutoGoB101-Bold(70)
Provides: A-OTF-FutoGoB101Pro-Bold(70)
Filename: KozGoPr6N-Bold.otf

Name: KozGoPr6N-Heavy
Type: CID
Class: Japan
Provides: Jun101-Light(70)
Provides: A-OTF-Jun101Pro-Light(70)
Filename: KozGoPr6N-Heavy.otf

Name: KozGoPr6N-Medium
Type: CID
Class: Japan
Provides: GothicBBB-Medium(70)
Provides: A-OTF-GothicBBBPro-Medium(70)
Filename: KozGoPr6N-Medium.otf

Name: KozGoPr6N-Regular
Type: CID
Class: Japan
Filename: KozGoPr6N-Regular.otf

Name: KozGoPro-Bold
Type: CID
Class: Japan
Provides: FutoGoB101-Bold(90)
Provides: A-OTF-FutoGoB101Pro-Bold(90)
Filename: KozGoPro-Bold.otf

Name: KozGoPro-Heavy
Type: CID
Class: Japan
Provides: Jun101-Light(90)
Provides: A-OTF-Jun101Pro-Light(90)
Filename: KozGoPro-Heavy.otf

Name: KozGoPro-Medium
Type: CID
Class: Japan
Provides: GothicBBB-Medium(90)
Provides: A-OTF-GothicBBBPro-Medium(90)
Filename: KozGoPro-Medium.otf

Name: KozGoPro-Regular
Type: CID
Class: Japan
Filename: KozGoPro-Regular.otf

Name: KozGoProVI-Bold
Type: CID
Class: Japan
Provides: FutoGoB101-Bold(80)
Provides: A-OTF-FutoGoB101Pro-Bold(80)
Filename: KozGoProVI-Bold.otf

Name: KozGoProVI-Heavy
Type: CID
Class: Japan
Provides: Jun101-Light(80)
Provides: A-OTF-Jun101Pro-Light(80)
Filename: KozGoProVI-Heavy.otf

Name: KozGoProVI-Medium
Type: CID
Class: Japan
Provides: GothicBBB-Medium(80)
Provides: A-OTF-GothicBBBPro-Medium(80)
Filename: KozGoProVI-Medium.otf

Name: KozGoProVI-Regular
Type: CID
Class: Japan
Filename: KozGoProVI-Regular.otf

Name: KozMinPr6N-Bold
Type: CID
Class: Japan
Provides: FutoMinA101-Bold(70)
Provides: A-OTF-FutoMinA101Pro-Bold(70)
Filename: KozMinPr6N-Bold.otf

Name: KozMinPr6N-Light
Type: CID
Class: Japan
Filename: KozMinPr6N-Light.otf

Name: KozMinPr6N-Regular
Type: CID
Class: Japan
Provides: Ryumin-Light(70)
Provides: A-OTF-RyuminPro-Light(70)
Filename: KozMinPr6N-Regular.otf

Name: KozMinPro-Bold
Type: CID
Class: Japan
Provides: FutoMinA101-Bold(90)
Provides: A-OTF-FutoMinA101Pro-Bold(90)
Filename: KozMinPro-Bold.otf

Name: KozMinPro-Light
Type: CID
Class: Japan
Filename: KozMinPro-Light.otf

Name: KozMinPro-Regular
Type: CID
Class: Japan
Provides: Ryumin-Light(90)
Provides: A-OTF-RyuminPro-Light(90)
Filename: KozMinPro-Regular.otf

Name: KozMinProVI-Bold
Type: CID
Class: Japan
Provides: FutoMinA101-Bold(80)
Provides: A-OTF-FutoMinA101Pro-Bold(80)
Filename: KozMinProVI-Bold.otf

Name: KozMinProVI-Light
Type: CID
Class: Japan
Filename: KozMinProVI-Light.otf

Name: KozMinProVI-Regular
Type: CID
Class: Japan
Provides: Ryumin-Light(80)
Provides: A-OTF-RyuminPro-Light(80)
Filename: KozMinProVI-Regular.otf

#
# CHINESE FONTS
#

Name: LiHeiPro
Type: TTF
Class: CNS
Provides: MHei-Medium(20)
Filename: 儷黑 Pro.ttf
Filename: LiHeiPro.ttf

Name: LiSongPro
Type: TTF
Class: CNS
Provides: MSungStd-Light(20)
Filename: 儷宋 Pro.ttf
Filename: LiSongPro.ttf

Name: STXihei
Type: TTF
Class: GB
Provides: STHeiti-Light(20)
Filename: 华文细黑.ttf
Filename: STXihei.ttf

Name: STHeiti
Type: TTF
Class: GB
Provides: STHeiti-Regular(20)
Filename: 华文黑体.ttf
Filename: STHeiti.ttf

Name: STHeitiSC-Light
Type: TTF
Class: GB
Provides: STHeiti-Light(10)
Filename: STHeiti Light.ttc(1)
Filename: STHeitiSC-Light.ttf

Name: STHeitiSC-Medium
Type: TTF
Class: GB
Provides: STHeiti-Regular(10)
Filename: STHeiti Medium.ttc(1)
Filename: STHeitiSC-Medium.ttf

Name: STHeitiTC-Light
Type: TTF
Class: CNS
Filename: STHeiti Light.ttc(0)
Filename: STHeitiTC-Light.ttf

Name: STHeitiTC-Medium
Type: TTF
Class: CNS
Provides: MHei-Medium(10)
Filename: STHeiti Medium.ttc(0)
Filename: STHeitiTC-Medium.ttf

Name: STFangsong
Type: TTF
Class: GB
Filename: 华文仿宋.ttf
Filename: STFangsong.ttf

Name: STSong
Type: TTF
Class: GB
Provides: STSongStd-Light(20)
Filename: Songti.ttc(4)
Filename: 宋体.ttc(3)
Filename: 华文宋体.ttf
Filename: STSong.ttf

Name: STSongti-SC-Light
Type: TTF
Class: GB
Provides: STSongStd-Light(10)
Filename: Songti.ttc(3)
Filename: 宋体.ttc(2)
Filename: STSongti-SC-Light.ttf

Name: STSongti-SC-Regular
Type: TTF
Class: GB
Filename: Songti.ttc(6)
Filename: 宋体.ttc(4)
Filename: STSongti-SC-Regular.ttf

Name: STSongti-SC-Bold
Type: TTF
Class: GB
Filename: Songti.ttc(1)
Filename: 宋体.ttc(1)
Filename: STSongti-SC-Bold.ttf

Name: STSongti-SC-Black
Type: TTF
Class: GB
Filename: Songti.ttc(0)
Filename: 宋体.ttc(0)
Filename: STSongti-SC-Black.ttf

Name: STSongti-TC-Light
Type: TTF
Class: CNS
Provides: MSungStd-Light(10)
Filename: Songti.ttc(5)
Filename: STSongti-TC-Light.ttf

Name: STSongti-TC-Regular
Type: TTF
Class: CNS
Filename: Songti.ttc(7)
Filename: STSongti-TC-Regular.ttf

Name: STSongti-TC-Bold
Type: TTF
Class: CNS
Filename: Songti.ttc(2)
Filename: STSongti-TC-Bold.ttf

Name: STKaiti
Type: TTF
Class: GB
Provides: STKaiti-Regular(20)
Filename: Kaiti.ttc(4)
Filename: 楷体.ttc(3)
Filename: 华文楷体.ttf
Filename: STKaiti.ttf

Name: STKaiti-SC-Regular
Type: TTF
Class: GB
Provides: STKaiti-Regular(10)
Filename: Kaiti.ttc(3)
Filename: 楷体.ttc(2)
Filename: STKaiti-SC-Regular.ttf

Name: STKaiti-SC-Bold
Type: TTF
Class: GB
Filename: Kaiti.ttc(1)
Filename: 楷体.ttc(1)
Filename: STKaiti-SC-Bold.ttf

Name: STKaiti-SC-Black
Type: TTF
Class: GB
Filename: Kaiti.ttc(0)
Filename: 楷体.ttc(0)
Filename: STKaiti-SC-Black.ttf

Name: STKaiTi-TC-Regular
Type: TTF
Class: CNS
Provides: MKai-Medium(10)
Filename: Kaiti.ttc(5)
Filename: STKaiTi-TC-Regular.ttf

Name: STKaiTi-TC-Bold
Type: TTF
Class: CNS
Filename: Kaiti.ttc(2)
Filename: STKaiTi-TC-Bold.ttf

Name: STKaiti-Adobe-CNS1
Type: TTF
Class: CNS
Provides: MKai-Medium(20)
Filename: STKaiti.ttf

#
# KOREAN FONTS
#
Name: AppleMyungjo
Type: TTF
Class: Korean
Provides: HYSMyeongJoStd-Medium(50)
Filename: AppleMyungjo.ttf

Name: AppleGothic
Type: TTF
Class: Korean
Provides: HYGoThic-Medium(50)
Filename: AppleGothic.ttf



### Local Variables:
### perl-indent-level: 2
### tab-width: 2
### indent-tabs-mode: nil
### End:
# vim: set tabstop=2 expandtab autoindent:
