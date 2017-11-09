#!/usr/bin/env perl
#
# cjk-gs-integrate - setup Ghostscript for CID/TTF CJK fonts
#
# Copyright 2015-2017 by Norbert Preining
# Copyright 2016-2017 by Japanese TeX Development Community
#
# Written by Norbert Preining, based on research and work by
# Yusuke Kuroki, Bruno Voisin, Hironobu Yamashita, Munehiro Yamamoto
# and the TeX Q&A wiki page
#
# This file is licensed under GPL version 3 or any later version.
# For copyright statements see end of file.
#
# For development see
#  https://github.com/texjporg/cjk-gs-support
#
# TODO:
# - how to deal with MacTeX pre-shipped configuration files?
# - how to deal with tlgs.win32 pre-shipped configuration files?
# - interoperability with kanji-config-updmap
#
# Note that symlink names should be consistent with ptex-fontmaps!

$^W = 1;
use Getopt::Long qw(:config no_autoabbrev ignore_case_always);
use File::Basename;
use File::Path qw(make_path);
use Cwd 'abs_path';
use strict;

(my $prg = basename($0)) =~ s/\.pl$//;
my $version = '$VER$';

if (win32()) {
  # conversion between internal (utf-8) and console (cp932):
  # multibyte characters should be encoded in cp932 at least during
  #   * kpathsea file search
  #   * abs_path existence test
  #   * input/output on console
  #   * batch file output
  # routines. make sure all of these should be restricted to win32 mode!
  # TODO: what to do with $opt_fontdef, @opt_aliases and $opt_filelist,
  #       with regard to encodings?
  use utf8;
  use Encode;
  # some perl functions (symlink, -l test) does not work
  print_warning("Sorry, we have only partial support for Windows!\n");
}

my %encode_list = (
  Japan => [ qw/
    2004-H
    2004-V
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

#
# location where links to fonts in texmf are created, relative to TEXMF
my $otf_pathpart = "fonts/opentype/cjk-gs-integrate";
my $ttf_pathpart = "fonts/truetype/cjk-gs-integrate";

# location where cidfmap, cidfmap.local and cidfmap.aliases are placed
# when found gs is tlgs (win32), then files will be placed in lib/ instead of Resource/Init/
my $cidfmap_pathpart = "Init/cidfmap";
my $cidfmap_local_pathpart = "Init/cidfmap.local";
my $cidfmap_aliases_pathpart = "Init/cidfmap.aliases";

# support for ps2otfps by Akira Kakuto
my $akotfps_pathpart = "dvips/ps2otfps";
my $akotfps_datafilename = "psnames-for-otf";
my $akotfps_datacontent = '';

# if windows, we might create batch file for links
my $winbatch = "makefontlinks.bat";
my $winbatch_content = '';

# dump output for data file (for easy editing for users)
my $dump_datafile = "$prg-data.dat";

my $opt_output;
my $opt_fontdef;
my @opt_fontdef_add;
my @opt_aliases;
my $opt_filelist;
my $opt_texmflink;
my $opt_akotfps;
my $opt_force = 0;
my $opt_remove = 0;
my $opt_cleanup = 0;
my $opt_hardlink = 0;
my $opt_winbatch;
my $opt_dump_data;
my $opt_only_aliases = 0;
my $opt_listaliases = 0;
my $opt_listallaliases = 0;
my $opt_listfonts = 0;
my $opt_info = 0;
my $opt_machine = 0;
my $dry_run = 0;
my $opt_quiet = 0;
my $opt_debug = 0;
my $opt_help = 0;
my $opt_markdown = 0;

if (! GetOptions(
        "o|output=s"       => \$opt_output,
        "f|fontdef=s"      => \$opt_fontdef,
        "fontdef-add=s"    => \@opt_fontdef_add,
        "a|alias=s"        => \@opt_aliases,
        "filelist=s"       => \$opt_filelist,
        "link-texmf:s"     => \$opt_texmflink,
        "otfps:s"          => \$opt_akotfps,
        "force"            => \$opt_force,
        "remove"           => \$opt_remove,
        "cleanup"          => \$opt_cleanup,
        "hardlink"         => \$opt_hardlink,
        "winbatch:s"       => \$opt_winbatch,
        "dump-data:s"      => \$opt_dump_data,
        "only-aliases"     => \$opt_only_aliases,
        "list-aliases"     => \$opt_listaliases,
        "list-all-aliases" => \$opt_listallaliases,
        "list-fonts"       => \$opt_listfonts,
        "info"             => \$opt_info,
        "machine-readable" => \$opt_machine,
        "n|dry-run"        => \$dry_run,
        "q|quiet"          => \$opt_quiet,
        "d|debug+"         => \$opt_debug,
        "h|help"           => \$opt_help,
        "markdown"         => \$opt_markdown,
        "v|version"        => sub { print &version(); exit(0); }, ) ) {
  die "Try \"$0 --help\" for more information.\n";
}

sub win32 { return ($^O=~/^MSWin(32|64)$/i); }
sub macosx { return ($^O=~/^darwin$/i); }
my $nul = (win32() ? 'nul' : '/dev/null') ;
my $sep = (win32() ? ';' : ':');
my %fontdb;
my %aliases;
my %user_aliases;

if ($opt_help || $opt_markdown) {
  Usage();
  exit 0;
}

if ($opt_debug >= 2) {
  require Data::Dumper;
  $Data::Dumper::Indent = 1;
}

if (macosx()) {
  # due to frequent incompatible changes in font file names by Apple,
  # our built-in database doesn't support OS X 10.11 El Capitan or
  # later versions
  my $macos_ver = `sw_vers -productVersion`;
  my $macos_ver_major = $macos_ver;
  $macos_ver_major =~ s/^(\d+)\.(\d+).*/$1/;
  my $macos_ver_minor = $macos_ver;
  $macos_ver_minor =~ s/^(\d+)\.(\d+).*/$2/;
  if ($macos_ver_major==10 && $macos_ver_minor>=11) {
    if (!$opt_fontdef && !@opt_fontdef_add) { # if built-in only
      print_warning("Our built-in database does not support recent\n");
      print_warning("versions of Mac OS (10.11 El Capitan or later)!\n");
      print_warning("If you want to use Hiragino fonts bundled with\n");
      print_warning("your OS, obtain external database file and\n");
      print_warning("specify it with --fontdef-add option!\n");
      print_warning("I'll continue with my built-in database ...\n");
    }
  }
}

if (defined($opt_texmflink)) {
  my $foo;
  if ($opt_texmflink eq '') {
    # option was passed but didn't receive a value
    #  -> use TEXMFLOCAL
    chomp( $foo = `kpsewhich -var-value=TEXMFLOCAL`);
  } else {
    # option was passed with an argument
    #  -> use it
    $foo = $opt_texmflink;
  }
  $opt_texmflink = $foo;
}

if (defined($opt_akotfps)) {
  my $foo;
  if ($opt_akotfps eq '') {
    if (defined($opt_texmflink)) {
      $foo = $opt_texmflink;
    } else {
      chomp( $foo = `kpsewhich -var-value=TEXMFLOCAL`);
    }
  } else {
    $foo = $opt_akotfps;
  }
  $opt_akotfps = $foo;
}

if (defined($opt_winbatch)) {
  if ($opt_winbatch ne '') {
    $winbatch = $opt_winbatch;
  }
  if (win32()) {
    $opt_winbatch = 1;
    unlink $winbatch if (-f $winbatch);
  } else {
    print_warning("ignoring --winbatch option due to non-Windows\n");
    $opt_winbatch = 0;
  }
} else {
  $opt_winbatch = 0;
}
if ($opt_hardlink) {
  if (win32()) {
    $opt_hardlink = 1;
  } else {
    print_warning("ignoring --hardlink option due to non-Windows\n");
    $opt_hardlink = 0;
  }
}

if (defined($opt_dump_data)) {
  if ($opt_dump_data ne '') {
    $dump_datafile = $opt_dump_data;
  }
  $opt_dump_data = 1;
  unlink $dump_datafile if (-f $dump_datafile);
} else {
  $opt_dump_data = 0;
}

if ($opt_cleanup) {
  $opt_remove = 1;
}

if ($opt_info) {
  $opt_listfonts = 1;
  $opt_listaliases = 1;
}

# check exclusive options; unsafe due to make_all_available()
if ($opt_listallaliases && $opt_listaliases) {
  print_error("Both --list-all-aliases and --list-aliases!? I'm confused!\n");
  exit(1);
}
if ($opt_listallaliases && $opt_listfonts) {
  print_error("Options --list-all-aliases and --list-fonts cannot be used at the same time!\n");
  exit(1);
}
if ($opt_cleanup && $opt_listfonts) {
  print_error("Options --cleanup and --list-fonts cannot be used at the same time!\n");
  exit(1);
}
if ($opt_cleanup && $opt_listaliases) {
  print_error("Options --cleanup and --list-aliases cannot be used at the same time!\n");
  exit(1);
}

main(@ARGV);

#
# only sub definitions from here on
#
sub main {
  # first, read font database to obtain %fontdb
  print_info("reading font database ...\n");
  read_font_database();
  if ($opt_dump_data) {
    # with --dump-data, dump only effective database and exit
    dump_font_database();
    if (-f $dump_datafile) {
      print_info("*** Data dumped to $dump_datafile ***\n");
      exit(0);
    } else {
      print_error("Failed to dump data to $dump_datafile!\n");
      exit(1);
    }
  }
  # second, determine non-otf link name
  # this is actually required only by info_found_fonts() and do_nonotf_fonts()
  # operations, but it does no harm for other cases too
  determine_nonotf_link_name(); # see comments there

  # set 'available' flags and 'type' by kpsewhich search
  # if $opt_cleanup or $opt_listallaliases is given, treat all files
  # in the database as if they were actually available as OTF
  if (!$opt_cleanup && !$opt_listallaliases) {
    print_info("checking for files ...\n");
    check_for_files();
  } else {
    make_all_available();
  }
  # obtain %aliases and %user_aliases
  compute_aliases();

  # informative operations
  if ($opt_listfonts) {
    info_found_fonts();
  }
  if ($opt_listaliases || $opt_listallaliases) {
    info_list_aliases();
  }
  exit(0) if ($opt_listfonts || $opt_listaliases || $opt_listallaliases);
  # if $opt_machine is still alive after the above exit(0), it's useless
  if ($opt_machine) {
    print_error("Option --machine-readable should be used with at least one of the followings:\n");
    print_error("  --list-aliases, --list-all-aliases, --list-fonts, --info\n");
    print_error("terminating.\n");
    exit(1);
  }

  # do actual setup/removing operations
  if (! $opt_output) {
    print_info("searching for Ghostscript resource\n");
    my $gsres = find_gs_resource();
    if (!$gsres) {
      print_error("Cannot find Ghostscript, terminating!\n");
      exit(1);
    } else {
      $opt_output = $gsres;
    }
  }
  if (! -d $opt_output) {
    $dry_run || mkdir($opt_output) || 
      die("Cannot create directory $opt_output: $!");
  }
  if ($opt_cleanup) {
    print_info("going to clean up $opt_output\n");
  } else {
    print_info("output is going to $opt_output\n");
  }
  if (!$opt_only_aliases) {
    if ($opt_cleanup) {
      # all font types are handled at the same time
      print_info("cleaning up all links, snippets and cidfmap.local ...\n");
      do_all_fonts();
    } else {
      # OTF and TTF/TTC/OTC must be handled separately, depending on the found files
      print_info(($opt_remove ? "removing" : "generating") . " links and snippets for CID fonts ...\n");
      do_otf_fonts();
      print_info(($opt_remove ? "removing" : "generating") . " links, snippets and cidfmap.local for non-CID fonts ...\n");
      do_nonotf_fonts();
    }
    write_winbatch() if ($opt_winbatch);
  }
  print_info(($opt_remove ? "removing" : "generating") . " snippets and cidfmap.aliases for font aliases ...\n");
  do_aliases();
  write_akotfps_datafile() if ($opt_akotfps);
  print_info("finished\n");
  if ($opt_winbatch) {
    if (-f $winbatch) {
      print_info("*** Batch file $winbatch created ***\n");
      print_info("*** to complete, run it as administrator privilege.***\n");
    } else {
      print_error("Failed to create $winbatch!\n");
      exit(1);
    }
  }
}

sub do_all_fonts {
  # try to clean up all possible links/snippets/cidfmap which could have been
  # generated in the previous runs
  # previous versions of cjk-gs-integrate included following bugs:
  #   * the database sometimes identified GB/CNS classes wrongly
  #   * symlink names were sometimes invalid (some of which contained
  #     white-spaces, due to the absence of proper database entry) or
  #     inconsistent with ptex-fontmaps (Name <-> PSName or redundant Filename)
  #   * confused symlinks between TTF/TTC/OTC (including ttf <-> ttc links)
  # also, current version generates OTC links into $otf_pathpart instead of
  # $ttf_pathpart, which was not true in the older versions
  # we'd like to clean up all such files
  my $fontdest = "$opt_output/Font";
  my $ciddest  = "$opt_output/CIDFont";
  my $cidfsubst = "$opt_output/CIDFSubst";
  for my $k (sort keys %fontdb) {
    #
    # remove snippets: note that $class = $fontdb{$k}{'class'} is not enough
    # due to previous bugs
    for my $class (%encode_list) {
      for my $enc (@{$encode_list{$class}}) {
        unlink "$fontdest/$k-$enc" if (-f "$fontdest/$k-$enc");
      }
    }
    #
    # remove links; borrow link_font operation here for convenience
    # since we don't need target in cleanup mode, initialize with stub "none"
    #
    # for OTF/TTF fonts, first remove both $k[.otf,ttf] and $fontdb{$k}{'origname'}[.otf]
    # the links $k.otf and $fontdb{$k}{'origname'} are coming from previous bugs,
    # and the links $k.ttf are (sometimes) coming from inconsistency
    if ($fontdb{$k}{'origname'}) { # this test skips alias-only fonts (e.g. Ryumin-Light)
      link_font("none", $ciddest, $k);
      link_font("none", $cidfsubst, "$k.ttf");
      link_font("none", "$opt_texmflink/$otf_pathpart", "$k.otf")
        if $opt_texmflink;
      link_font("none", "$opt_texmflink/$ttf_pathpart", "$k.ttf")
        if $opt_texmflink;
      link_font("none", $ciddest, $fontdb{$k}{'origname'});
      link_font("none", "$opt_texmflink/$otf_pathpart", "$fontdb{$k}{'origname'}.otf")
        if $opt_texmflink;
    }
    # for OTF/TTF/TTC/OTC fonts, loop through all file candidates
    for my $f (keys %{$fontdb{$k}{'files'}}) {
      # check for subfont extension
      my $foo = $f;
      $foo =~ s/^(.*)\(\d*\)$/$1/;
      link_font("none", $cidfsubst, "$foo");
      link_font("none", "$opt_texmflink/$otf_pathpart", "$foo") if $opt_texmflink;
      link_font("none", "$opt_texmflink/$ttf_pathpart", "$foo") if $opt_texmflink;
    }
  }
  update_master_cidfmap('cidfmap.local');
  # we are in cleanup mode, also remove cidfmap.local itself
  if (-f "$opt_output/$cidfmap_local_pathpart") {
    unlink "$opt_output/$cidfmap_local_pathpart";
  }
}

sub do_otf_fonts {
  my $fontdest = "$opt_output/Font";
  my $ciddest  = "$opt_output/CIDFont";
  make_dir($fontdest, "cannot create CID snippets there!");
  make_dir($ciddest,  "cannot link CID fonts there!");
  make_dir("$opt_texmflink/$otf_pathpart",
           "cannot link fonts to it!")
    if $opt_texmflink;
  for my $k (sort keys %fontdb) {
    if ($fontdb{$k}{'available'} && $fontdb{$k}{'type'} eq 'OTF') {
      generate_font_snippet($fontdest,
        $k, $fontdb{$k}{'class'}, $fontdb{$k}{'target'});
      link_font($fontdb{$k}{'target'}, $ciddest, $k);
      link_font($fontdb{$k}{'target'}, "$opt_texmflink/$otf_pathpart", "$fontdb{$k}{'origname'}.otf")
        if $opt_texmflink;
    }
  }
}

sub do_nonotf_fonts {
  my $fontdest = "$opt_output/Font";
  my $cidfsubst = "$opt_output/CIDFSubst";
  my $outp = '';
  make_dir($fontdest, "cannot create CID snippets there!");
  make_dir($cidfsubst,  "cannot link TTF fonts there!");
  make_dir("$opt_texmflink/$ttf_pathpart",
           "cannot link fonts to it!")
    if $opt_texmflink;
  for my $k (sort keys %fontdb) {
    if ($fontdb{$k}{'available'} && $fontdb{$k}{'type'} eq 'TTF') {
      generate_font_snippet($fontdest,
        $k, $fontdb{$k}{'class'}, $fontdb{$k}{'target'});
      $outp .= generate_cidfmap_entry($k, $fontdb{$k}{'class'}, $fontdb{$k}{'ttfname'}, -1);
      link_font($fontdb{$k}{'target'}, $cidfsubst, $fontdb{$k}{'ttfname'});
      link_font($fontdb{$k}{'target'}, "$opt_texmflink/$ttf_pathpart", $fontdb{$k}{'ttfname'})
        if $opt_texmflink;
    } elsif ($fontdb{$k}{'available'} && $fontdb{$k}{'type'} eq 'TTC') {
      generate_font_snippet($fontdest,
        $k, $fontdb{$k}{'class'}, $fontdb{$k}{'target'});
      $outp .= generate_cidfmap_entry($k, $fontdb{$k}{'class'}, $fontdb{$k}{'ttcname'}, $fontdb{$k}{'subfont'});
      link_font($fontdb{$k}{'target'}, $cidfsubst, $fontdb{$k}{'ttcname'});
      link_font($fontdb{$k}{'target'}, "$opt_texmflink/$ttf_pathpart", $fontdb{$k}{'ttcname'})
        if $opt_texmflink;
    } elsif ($fontdb{$k}{'available'} && $fontdb{$k}{'type'} eq 'OTC') {
      # currently Ghostscript does not have OTC support; not creating gs resource
      print_debug("gs does not support OTC, not creating gs resource for $k\n");
    # generate_font_snippet($fontdest,
    #   $k, $fontdb{$k}{'class'}, $fontdb{$k}{'target'});
    # $outp .= generate_cidfmap_entry($k, $fontdb{$k}{'class'}, $fontdb{$k}{'otcname'}, $fontdb{$k}{'subfont'});
    # link_font($fontdb{$k}{'target'}, $cidfsubst, $fontdb{$k}{'otcname'});
      link_font($fontdb{$k}{'target'}, "$opt_texmflink/$otf_pathpart", $fontdb{$k}{'otcname'})
        if $opt_texmflink;
    }
  }
  return if $dry_run;
  if ($outp) {
    if (! -d "$opt_output/Init") {
      mkdir("$opt_output/Init") ||
        die("Cannot create directory $opt_output/Init: $!");
    }
    open(FOO, ">$opt_output/$cidfmap_local_pathpart") || 
      die("Cannot open $opt_output/$cidfmap_local_pathpart: $!");
    print FOO $outp;
    close(FOO);
  }
  update_master_cidfmap('cidfmap.local');
}

sub do_aliases {
  my $fontdest = "$opt_output/Font";
  my $cidfsubst = "$opt_output/CIDFSubst";
  my $outp = '';
  #
  # alias handling
  # we use two levels of aliases, one is for the default names that
  # are not actual fonts:
  # Ryumin-Light, GothicBBB-Medium, FutoMinA101-Bold, FutoGoB101-Bold, 
  # Jun101-Light which are the original Morisawa names.
  #
  # the second level of aliases is for Morisawa OTF font names:
  # RyuminPro-Light, GothicBBBPro-Medium,
  # FutoMinA101Pro-Bold, FutoGoB101Pro-Bold
  # Jun101Pro-Light
  #
  # the order of fonts selected is
  # defined in the Provides(Priority): Name in the font definiton
  #
  $outp .= "\n\n% Aliases\n";
  #
  my (@jal, @kal, @tal, @sal);
  #
  for my $al (sort keys %aliases) {
    my $target;
    my $class;
    if ($user_aliases{$al}) {
      $target = $user_aliases{$al};
      # determine class
      if ($fontdb{$target}{'available'}) {
        $class = $fontdb{$target}{'class'};
      } else {
        # must be an aliases, we checked this when initializing %user_aliases
        # reset the $al value
        # and since $class is still undefined we will use the next code below
        $al = $target;
      }
    }
    if (!$class) {
      if (!%{$aliases{$al}}) {
        print_warning("Alias candidate for $al is empty, skipping!\n");
        next;
      }
      # search lowest number
      my @ks = keys(%{$aliases{$al}});
      my $first = (sort { $a <=> $b} @ks)[0];
      $target = $aliases{$al}{$first};
      $class  = $fontdb{$target}{'class'};
    }
    # we also need to create font snippets in Font (or add configuration)
    # for the aliases!
    generate_font_snippet($fontdest, $al, $class, $target);
    if ($class eq 'Japan') {
      push @jal, "/$al /$target ;";
    } elsif ($class eq 'Korea') {
      push @kal, "/$al /$target ;";
    } elsif ($class eq 'GB') {
      push @sal, "/$al /$target ;";
    } elsif ($class eq 'CNS') {
      push @tal, "/$al /$target ;";
    } else {
      print STDERR "unknown class $class for $al\n";
    }
  }
  $outp .= "\n% Japanese fonts\n" . join("\n", @jal) . "\n" if @jal;
  $outp .= "\n% Korean fonts\n" . join("\n", @kal) . "\n" if @kal;
  $outp .= "\n% Traditional Chinese fonts\n" . join("\n", @tal) . "\n" if @tal;
  $outp .= "\n% Simplified Chinese fonts\n" . join("\n", @sal) . "\n" if @sal;
  #
  return if $dry_run;
  if ($outp && !$opt_remove) {
    if (! -d "$opt_output/Init") {
      mkdir("$opt_output/Init") ||
        die("Cannot create directory $opt_output/Init: $!");
    }
    open(FOO, ">$opt_output/$cidfmap_aliases_pathpart") || 
      die("Cannot open $opt_output/$cidfmap_aliases_pathpart: $!");
    print FOO $outp;
    close(FOO);
  }
  update_master_cidfmap('cidfmap.aliases');
  # if we are in cleanup mode, also remove cidfmap.aliases itself
  if (-f "$opt_output/$cidfmap_aliases_pathpart") {
    unlink "$opt_output/$cidfmap_aliases_pathpart" if ($opt_cleanup);
  }
}

sub update_master_cidfmap {
  my $add = shift;
  my $cidfmap_master = "$opt_output/$cidfmap_pathpart";
  print_info(sprintf("%s $add %s cidfmap file ...\n", 
    ($opt_remove ? "removing" : "adding"), ($opt_remove ? "from" : "to")));
  if (-r $cidfmap_master) {
    open(FOO, "<", $cidfmap_master) ||
      die("Cannot open $cidfmap_master for reading: $!");
    my $found = 0;
    my $newmaster = "";
    # in add mode: just search for the entry and set $found
    # in remove mode: collect all lines that do not match
    while(<FOO>) {
      if (m/^\s*\(\Q$add\E\)\s\s*\.runlibfile\s*$/) {
        $found = 1;
      } else {
        $newmaster .= $_;
      }
    }
    close(FOO);
    # if the master cidfmap has a new line at end of file,
    # then $newmaster should end with "\n".
    # otherwise we add a new line, since there is a possibility of %EOF comment
    # without trailing new line (e.g. TL before r44039)
    $newmaster =~ s/\n$//g;
    $newmaster =~ s/$/\n/g;
    if ($opt_remove) {
      if ($found) {
        return if $dry_run;
        open(FOO, ">", $cidfmap_master) ||
          die("Cannot clean up $cidfmap_master: $!");
        print FOO $newmaster;
        close FOO;
      }
    } else {
      if ($found) {
        print_info("$add already loaded in $cidfmap_master, no changes\n");
      } else {
        return if $dry_run;
        open(FOO, ">", $cidfmap_master) ||
          die("Cannot open $cidfmap_master for appending: $!");
        print FOO $newmaster;
        print FOO "($add) .runlibfile\n";
        close(FOO);
      }
    }
  } else {
    return if $dry_run;
    return if $opt_remove;
    open(FOO, ">", $cidfmap_master) ||
      die("Cannot open $cidfmap_master for writing: $!");
    print FOO "($add) .runlibfile\n";
    close(FOO);
  }
}

sub generate_cidfmap_entry {
  my ($n, $c, $f, $sf) = @_;
  return "" if $opt_remove;
  # $f is already the link target name 'ttfname' (or 'ttcname' or 'otcname')
  # as determined by minimal priority number
  # extract subfont
  my $s = "/$n << /FileType /TrueType 
  /Path pssystemparams /GenericResourceDir get 
  (CIDFSubst/$f) concatstrings\n";
  if ($sf >= 0) { # in this script, $sf < 0 represents TTF
    $s .= "  /SubfontID $sf\n";
  }
  $s .= "  /CSI [($c";
  if ($c eq "Japan") {
    $s .= "1) 6]";
  } elsif ($c eq "GB") {
    $s .= "1) 5]";
  } elsif ($c eq "CNS") {
    $s .= "1) 5]";
  } elsif ($c eq "Korea") {
    $s .= "1) 2]";
  } else {
    print_warning("unknown class $c for $n, skipping.\n");
    return '';
  }
  $s .= " >> ;\n";
  return $s;
}

sub generate_font_snippet {
  my ($fd, $n, $c, $f) = @_;
  return if $dry_run;
  if ($opt_akotfps) {
    add_akotfps_data($n);
    return;
  }
  for my $enc (@{$encode_list{$c}}) {
    if ($opt_remove) {
      unlink "$fd/$n-$enc" if (-f "$fd/$n-$enc");
      next;
    }
    open(FOO, ">$fd/$n-$enc") || 
      die("cannot open $fd/$n-$enc for writing: $!");
    print FOO "%!PS-Adobe-3.0 Resource-Font
%%DocumentNeededResources: $enc (CMap)
%%IncludeResource: $enc (CMap)
%%BeginResource: Font ($n-$enc)
($n-$enc)
($enc) /CMap findresource
[($n) /CIDFont findresource]
composefont
pop
%%EndResource
%%EOF
";
    close(FOO);
  }
}

sub add_akotfps_data {
  my ($fn) = @_;
  return if $dry_run;
  if (! $opt_remove) {
    $akotfps_datacontent .= "$fn\n";
  }
}

#
# link_font operation
# $opt_force is *not* treated first to warn only 
# at really critical cases
# case 1:
#   exists, is link, link targets agree
#     $opt_force is ignored
#     remove or remove+add according to $opt_remove
# case 2:
#   exists, is link, dangling symlink
#     $opt_force is ignored
#     remove or remove+add according to $opt_remove
# case 3:
#   exists, is link, link target different
#     if $opt_force
#       warn, remove or remove+add according to $opt_remove
#     else
#       error message
# case 4:
#   exists, not a link
#     if $opt_force
#       warn, remove or remove+add according to $opt_remove
#     else
#       error message
# case 5:
#   not exists
#     $opt_force is ignored
#     do nothing or add according to $opt_remove
#     
sub link_font {
  my ($f, $cd, $n) = @_;
  return if $dry_run;
  if (!$n) {
    $n = basename($f);
  }
  my $target = "$cd/$n";
  my $do_unlink = 0;
  if (-l $target) {
    if ($opt_cleanup) {
      $do_unlink = 1;
    } else {
      my $linkt = readlink($target);
      if ($linkt) {
        if ($linkt eq $f) {
          # case 1: exists, link, targets agree
          $do_unlink = 1;
        } elsif (-r $linkt) {
          # case 3: exists, link, targets different
          if ($opt_force) {
            print_info("Removing link $target due to --force!\n");
            $do_unlink = 1;
          } else {
            print_error("Link $target already existing, but target different from $f, exiting!\n");
            exit(1);
          }
        } else {
          # case 2: dangling symlink or link-to-link
          print_warning("Removing dangling symlink $target to $linkt\n");
          $do_unlink = 1;
        }
      } else {
        print_error("This should not happen, we have a link but cannot read the target?\n");
        exit(1);
      }
    }
  } elsif (-r $target) {
    # case 4: exists, but not link (NTFS hardlink on win32 falls into this)
    if (-s $target) {
      if ($opt_force) {
        print_info("Removing $target due to --force!\n");
        $do_unlink = 1;
      } else {
        print_error("$target already existing, exiting!\n");
        exit(1);
      }
    } else {
      # NTFS symlink on win32 has file size 0, we're safe to remove it
      $do_unlink = 1;
    }
  } # case 5: otherwise it is not existing!

  # if we are still here and $do_unlink is set, remove it
  maybe_unlink($target) if $do_unlink;
  # recreate link if we are not in the remove case
  if (! $opt_remove) {
    maybe_symlink($f, $target) || die("Cannot link font $f to $target: $!");
  }
}

sub make_dir {
  my ($d, $w) = @_;
  if (-r $d) {
    if (! -d $d) {
      print_error("$d is not a directory, $w\n");
      exit 1;
    }
  } else {
    $dry_run || make_path($d);
  }
}

# perl symlink function does not work on windows, so leave it to
# cmd.exe mklink function (or write to batch file).
# if target already exists, do not try to override it. otherwise
# "mklink error: Cannot create a file when that file already exists"
# is thrown many times
sub maybe_symlink {
  my ($realname, $targetname) = @_;
  if (win32()) {
    # hardlink vs. symlink -- HY 2017/04/26
    #   * readablitiy: hardlink is easier, but it seems that current gs can read
    #                  symlink properly, so it doesn't matter
    #   * permission:  hardlink creation does not require administrator privilege,
    #                  but is likely to fail for c:/windows/fonts/* system files
    #                  due to "Access denied"
    #                  symlink creation requires administrator privilege, but
    #                  it can link to all files in c:/windows/fonts/
    #   * versatility: symlink can point to a file on a different/remote volume
    # for these reasons, we try to create symlink by default.
    # if --hardlink option is given, we create hardlink instead.
    # also, if --winbatch option is given, we prepare batch file for link generation,
    # instead of creating links right away.
    $realname =~ s!/!\\!g;
    $targetname =~ s!/!\\!g;
    if ($opt_winbatch) {
      # re-encoding of $winbatch_content is done by write_winbatch()
      $winbatch_content .= "if not exist \"$targetname\" mklink ";
      $winbatch_content .= "/h " if ($opt_hardlink);
      $winbatch_content .= "\"$targetname\" \"$realname\"\n";
    } else {
      # should be encoded in cp932 for win32 console
      $realname = encode_utftocp($realname);
      $targetname = encode_utftocp($targetname);
      my $cmdl = "cmd.exe /c if not exist \"$targetname\" mklink ";
      $cmdl .= "/h " if ($opt_hardlink);
      $cmdl .= "\"$targetname\" \"$realname\"";
      my @ret = `$cmdl`;
      # sometimes hard link creation may fail due to "Access denied"
      # (especially when $realname is located in c:/windows/fonts).
      # TODO: what should we do to ensure resources, which might be
      #       different from $realname? -- HY (2017/03/21)
      # -- one possibility:
      # if (@ret) {
      #   @ret ="done";
      # } else {
      #   print_info("Hard link creation for $realname failed. I will copy this file instead.\n");
      #   $cmdl = "cmd.exe /c if not exist \"$targetname\" copy \"$realname\" \"$targetname\"";
      #   @ret = `$cmdl`;
      # }
      # -- however, both tlgs (TeX Live) and standalone gswin32/64 (built
      #    by Akira Kakuto) can search in c:/windows/fonts by default.
      #    Thus, copying such files is waste of memory
    }
  } else {
    symlink ($realname, $targetname);
  }
}

# unlink function actually works also on windows, however,
# leave it to batch file for consistency. otherwise
# option $opt_force may not work as expected
sub maybe_unlink {
  my ($targetname) = @_;
  if (win32()) {
    $targetname =~ s!/!\\!g;
    if ($opt_winbatch) {
      # re-encoding of $winbatch_content is done by write_winbatch()
      $winbatch_content .= "if exist \"$targetname\" del \"$targetname\"\n";
    } else {
      # should be encoded in cp932 for win32 console
      $targetname = encode_utftocp($targetname);
      my $cmdl = "cmd.exe /c if exist \"$targetname\" del \"$targetname\"";
      my @ret = `$cmdl`;
    }
  } else {
    unlink ($targetname);
  }
}

# write batch file (windows only)
sub write_winbatch {
  return if $dry_run;
  open(FOO, ">$winbatch") || 
    die("cannot open $winbatch for writing: $!");
  # $winbatch_content may contain multibyte characters, and they
  # should be encoded in cp932 in batch file
  $winbatch_content = encode_utftocp($winbatch_content);
  print FOO "\@echo off\n",
            "$winbatch_content",
            "\@echo symlink ", ($opt_remove ? "removed\n" : "generated\n"),
            "\@pause 1\n";
  close(FOO);
}

# write to psnames-for-otfps
sub write_akotfps_datafile {
  return if $dry_run;
  make_dir("$opt_akotfps/$akotfps_pathpart",
         "cannot create $akotfps_datafilename in it!");
  open(FOO, ">$opt_akotfps/$akotfps_pathpart/$akotfps_datafilename") || 
    die("cannot open $opt_akotfps/$akotfps_pathpart/$akotfps_datafilename for writing: $!");
  print FOO "% psnames-for-otf
%
% PostSctipt names for OpenType fonts
%
% This file is used by a program ps2otfps
% in order to add needed information to a ps file
% created by the dvips
%
$akotfps_datacontent";
  close(FOO);
}

#
# dump found files
sub info_found_fonts {
  print "List of found fonts:\n\n";
  for my $k (sort keys %fontdb) {
    my @foundfiles;
    if ($fontdb{$k}{'available'}) {
      print "Font:  $k\n";
      print "Type:  $fontdb{$k}{'type'}\n";
      print "Class: $fontdb{$k}{'class'}\n";
      my $fn = $fontdb{$k}{'target'};
      # cp932 for win32 console
      if (win32()) {
        $fn = encode_utftocp($fn);
      }
      if ($fontdb{$k}{'type'} eq 'TTC' || $fontdb{$k}{'type'} eq 'OTC') {
        $fn .= "($fontdb{$k}{'subfont'})";
      }
      print "File:  $fn\n";
      if ($fontdb{$k}{'type'} eq 'TTF') {
        print "Link:  $fontdb{$k}{'ttfname'}\n";
      } elsif ($fontdb{$k}{'type'} eq 'TTC') {
        print "Link:  $fontdb{$k}{'ttcname'}\n";
      } elsif ($fontdb{$k}{'type'} eq 'OTC') {
        print "Link:  $fontdb{$k}{'otcname'}\n";
      }
      my @ks = sort { $fontdb{$k}{'files'}{$a}{'priority'}
                      <=>
                      $fontdb{$k}{'files'}{$b}{'priority'} }
                    keys %{$fontdb{$k}{'files'}};
      # remove the top element which is the winner and shown above
      shift @ks;
      if (@ks) {
        print "Other candidates in decreasing order:\n";
        for my $f (@ks) {
          print "       ", $fontdb{$k}{'files'}{$f}{'target'}, "\n";
        }
      }
      print "\n";
    }
  }
}

#
# dump aliases
sub info_list_aliases {
  print "List of ", ($opt_listallaliases ? "all" : "available"), " aliases and their options (in decreasing priority):\n" unless $opt_machine;
  my (@jal, @kal, @tal, @sal);
  for my $al (sort keys %aliases) {
    my $cl;
    my @ks = sort { $a <=> $b} keys(%{$aliases{$al}});
    my $foo = '';
    $foo = "$al:\n" unless $opt_machine;
    for my $p (@ks) {
      my $t = $aliases{$al}{$p};
      my $fn = ($opt_listallaliases ? "-" : $fontdb{$t}{'target'} );
      # cp932 for win32 console
      if (win32()) {
        $fn = encode_utftocp($fn);
      }
      # should always be the same ;-)
      $cl = $fontdb{$t}{'class'};
      if (!$opt_listallaliases && ($fontdb{$t}{'type'} eq 'TTC' || $fontdb{$t}{'type'} eq 'OTC')) {
        $fn .= "($fontdb{$t}{'subfont'})";
      }
      if ($opt_machine) {
        $foo .= "$al:$p:$aliases{$al}{$p}:$fn\n";
      } else {
        $foo .= "\t($p) $aliases{$al}{$p} ($fn)\n";
      }
    }
    if ($cl eq 'Japan') {
      push @jal, $foo;
    } elsif ($cl eq 'Korea') {
      push @kal, $foo;
    } elsif ($cl eq 'GB') {
      push @sal, $foo;
    } elsif ($cl eq 'CNS') {
      push @tal, $foo;
    } else {
      print STDERR "unknown class $cl for $al\n";
    }
  }
  if ($opt_machine) {
    print @jal if @jal;
    print @kal if @kal;
    print @sal if @sal;
    print @tal if @tal;
  } else {
    print "Aliases for Japanese fonts:\n", @jal, "\n" if @jal;
    print "Aliases for Korean fonts:\n", @kal, "\n" if @kal;
    print "Aliases for Simplified Chinese fonts:\n", @sal, "\n" if @sal;
    print "Aliases for Traditional Chinese fonts:\n", @tal, "\n" if @tal;
  }
}

#
# make all fonts available for listing all aliases
sub make_all_available {
  for my $k (keys %fontdb) {
    $fontdb{$k}{'available'} = 1;
    $fontdb{$k}{'type'} = 'OTF';
    delete $fontdb{$k}{'files'} if (!$opt_cleanup);
  }
}

#
# checks all file names listed in %fontdb
# and sets
sub check_for_files {
  my @foundfiles;
  if ($opt_filelist) {
    open(FOO, "<", $opt_filelist) || die("Cannot open $opt_filelist: $!");
    @foundfiles = <FOO>;
    close(FOO) || warn "Cannot close $opt_filelist: $!";
  } else {
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
      for my $d (qw!/Library/Fonts /System/Library/Fonts /System/Library/Assets /Network/Library/Fonts /usr/share/fonts!) {
        push @extradirs, "$d//" if (-d $d); # recursive search
      }
      # macosx specific; the path contains white space, so hack required
      for my $d (qw!/Applications/Microsoft__Word.app /Applications/Microsoft__Excel.app /Applications/Microsoft__PowerPoint.app!) {
        my $sd = $d;
        $sd =~ s/__/ /;
        push @extradirs, "$sd/Contents/Resources/Fonts/" if (-d "$sd/Contents/Resources/Fonts");
        push @extradirs, "$sd/Contents/Resources/DFonts/" if (-d "$sd/Contents/Resources/DFonts");
      }
      my $home = $ENV{'HOME'};
      push @extradirs, "$home/Library/Fonts//" if (-d "$home/Library/Fonts");
    }
    #
    if (@extradirs) {
      # TODO: we want that files in OSFONTDIR are found first, before
      # links that we have created in TEXMFLOCAL
      # Thus, instead of setting OSFONTDIR which is at the *END* of
      # the kpsewhich variables OPENTYPEFONTS and TTFONTS, we'd like to
      # put all these fonts at the front of them
      #
      # There are problems with case-insensitive file systems like HFS
      # on MacOS, as we might catch different names (batang/Batang)
      # and identify them wrongly.
      # https://github.com/texjporg/cjk-gs-support/issues/9
      # For now until we have dealt with that, do not set the
      # two variables (HY 2016/09/27) and think about a different approach.
      push @extradirs, $ENV{'OSFONTDIR'} if $ENV{'OSFONTDIR'};
      if (@extradirs) {
        # comment out -- HY (2016/09/27)
        # my $newotf = join($sep, @extradirs) . $sep;
        # my $newttf = $newotf;
        # $newotf .= $ENV{'OPENTYPEFONTS'} if ($ENV{'OPENTYPEFONTS'});
        # $newttf .= $ENV{'TTFONTS'} if ($ENV{'TTFONTS'});
        # $ENV{'OPENTYPEFONTS'} = $newotf;
        # $ENV{'TTFONTS'} = $newttf;
        # new code for uppercase/lowercase workaround -- HY (2016/09/27)
        my $extrafontdir = join($sep, @extradirs) . $sep;
        $ENV{'OSFONTDIR'} = $extrafontdir;
      }
    }
    # prepare for kpsewhich call, we need to do quoting
    # we need as much candidate files as possible, so -all is needed
    my $cmdl = 'kpsewhich -all ';
    for my $f (@fn) {
      $cmdl .= " \"$f\" ";
    }
    # shoot up kpsewhich
    # this call (derived from the database) contains multibyte characters,
    # and they should be encoded in cp932 for win32 console
    if (win32()) {
      $cmdl = encode_utftocp($cmdl);
    }
    print_ddebug("checking for $cmdl\n");
    @foundfiles = `$cmdl`;
  }
  # at this point, on windows, @foundfiles is encoded in cp932
  # which is suitable for the next few lines
  chomp(@foundfiles);
  print_ddebug("Found files @foundfiles\n");
  # map basenames to filenames
  my %bntofn;
  for my $f (@foundfiles) {
    my $realf = abs_path($f);
    if (!$realf) {
      print_warning("dead link or strange file found: $f - ignored!\n");
      next;
    }
    if (win32()) {
      # abs_path cannot read NTFS symlink/hardlink, and it serves as
      # identity transformation.
      # this might lead to dangling links for multiple runs of cjk-gs-integrate,
      # when $opt_texmflink (in the previous run) is contained in the (current)
      # kpsewhich search path.
      # to avoid this, ignore targets which contain $otf_pathpart or $ttf_pathpart
      my $temp_realfdir = "$realf";
      $temp_realfdir =~ s!^(.*)/(.*)$!$1!;
      next if ($temp_realfdir =~ $otf_pathpart || $temp_realfdir =~ $ttf_pathpart);
    }
    # decode now on windows! (cp932 -> internal utf-8)
    if (win32()) {
      $f = encode_cptoutf($f);
      $realf = encode_cptoutf($realf);
    }
    my $bn = basename($f);
    # kpsewhich -all might return multiple files with the same basename;
    # choose the first one among them
    $bntofn{$bn} = $realf if (!$bntofn{$bn});
  }

  # show the %fontdb before file check
  if ($opt_debug >= 2) {
    print_ddebug("dumping font database before file check:\n");
    print_ddebug(Data::Dumper::Dumper(\%fontdb));
  }
  if ($opt_debug >= 3) {
    print_dddebug("dumping basename to filename list:\n");
    print_dddebug(Data::Dumper::Dumper(\%bntofn));
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
        $fontdb{$k}{'files'}{$f}{'target'} = $bntofn{$realfile};
        $fontdb{$k}{'available'} = 1;
      } else {
        # delete the entry for convenience
        delete $fontdb{$k}{'files'}{$f};
      }
    }
  }
  # second round to determine the winner in case of more targets
  for my $k (keys %fontdb) {
    if ($fontdb{$k}{'available'}) {
      my $mp = 1000000; my $mf;
      for my $f (keys %{$fontdb{$k}{'files'}}) {
        if ($fontdb{$k}{'files'}{$f}{'priority'} < $mp) {
          $mp = $fontdb{$k}{'files'}{$f}{'priority'};
          $mf = $f;
        }
      }
      # extract subfont if necessary
      my $sf = 0;
      if ($mf =~ m/^(.*)\((\d*)\)$/) { $sf = $2; }
      $fontdb{$k}{'target'} = $fontdb{$k}{'files'}{$mf}{'target'};
      $fontdb{$k}{'type'} = $fontdb{$k}{'files'}{$mf}{'type'};
      $fontdb{$k}{'subfont'} = $sf if ($fontdb{$k}{'type'} eq 'TTC' || $fontdb{$k}{'type'} eq 'OTC');
    }
    # not needed anymore
    # delete $fontdb{$k}{'files'};
  }
  if ($opt_debug >= 2) {
    print_ddebug("dumping font database:\n");
    print_ddebug(Data::Dumper::Dumper(\%fontdb));
  }
}

sub compute_aliases {
  # go through fontdb to check for provides
  # accumulate all provided fonts in @provides
  for my $k (keys %fontdb) {
    if ($fontdb{$k}{'available'}) {
      for my $p (keys %{$fontdb{$k}{'provides'}}) {
        # do not check alias if the real font is available in OTF/TTF/TTC format
        if ($fontdb{$p}{'available'}) {
          next if ($fontdb{$p}{'type'} ne 'OTC');
        }
        # use the priority as key
        # if priorities are double, this will pick one at chance
        if ($aliases{$p}{$fontdb{$k}{'provides'}{$p}}) {
          print_warning("duplicate provide levels:\n");
          print_warning("  current $p $fontdb{$k}{'provides'}{$p} $aliases{$p}{$fontdb{$k}{'provides'}{$p}}\n");
          print_warning("  ignored $p $fontdb{$k}{'provides'}{$p} $k\n");
        } else {
          # if OTC font is caught, then skip it as Ghostscript doesn't support it (2016/12/12)
          if ($fontdb{$k}{'type'} eq 'OTC') {
            print_debug("Currently Ghostscript does not support OTC font,\n");
            print_debug("not adding $fontdb{$k}{'otcname'} to alias candidates\n");
          } else {
            $aliases{$p}{$fontdb{$k}{'provides'}{$p}} = $k;
          }
        }
      }
    }
  }
  # check for user supplied aliases
  for my $a (@opt_aliases) {
    if ($a =~ m/^(.*)=(.*)$/) {
      my $ll = $1;
      my $rr = $2;
      # check for consistency of user provided aliases:
      # - ll must not be available
      # - rr needs to be available as font or alias
      # check whether $rr is available, either as real font or as alias
      if ($fontdb{$ll}{'available'}) {
        print_error("left side of alias spec is provided by a real font: $a\n");
        print_error("stopping here\n");
        exit(1);
      }
      if (!($fontdb{$rr}{'available'} || $aliases{$rr})) {
        print_error("right side of alias spec is not available as real font or alias: $a\n");
        print_error("stopping here\n");
        exit(1);
      }
      $user_aliases{$ll} = $rr;
    }
  }
  if ($opt_debug >= 2) {
    print_ddebug("dumping aliases:\n");
    print_ddebug(Data::Dumper::Dumper(\%aliases));
  }
}

# While the OTF link target is determined by the filename itself
# for TTF we can have ttc with several fonts.
# The following routine determines the link target by selecting
# the file name of the ttf candidates with the lowest priority
# as the link target name for TTF
sub determine_nonotf_link_name {
  for my $k (keys %fontdb) {
    my $ttfname = "";
    my $ttcname = "";
    my $otcname = "";
    my $mpttf = 10000000;
    my $mpttc = 10000000;
    my $mpotc = 10000000;
    for my $f (keys %{$fontdb{$k}{'files'}}) {
      if ($fontdb{$k}{'files'}{$f}{'type'} eq 'TTF') {
        my $p = $fontdb{$k}{'files'}{$f}{'priority'};
        if ($p < $mpttf) {
          $ttfname = $f;
          $ttfname =~ s/^(.*)\(\d*\)$/$1/;
          $mpttf = $p;
        }
      } elsif ($fontdb{$k}{'files'}{$f}{'type'} eq 'TTC') {
        my $p = $fontdb{$k}{'files'}{$f}{'priority'};
        if ($p < $mpttc) {
          $ttcname = $f;
          $ttcname =~ s/^(.*)\(\d*\)$/$1/;
          $mpttc = $p;
        }
      } elsif ($fontdb{$k}{'files'}{$f}{'type'} eq 'OTC') {
        my $p = $fontdb{$k}{'files'}{$f}{'priority'};
        if ($p < $mpotc) {
          $otcname = $f;
          $otcname =~ s/^(.*)\(\d*\)$/$1/;
          $mpotc = $p;
        }
      }
    }
    if ($ttfname) {
      $fontdb{$k}{'ttfname'} = $ttfname;
    }
    if ($ttcname) {
      $fontdb{$k}{'ttcname'} = $ttcname;
    }
    if ($otcname) {
      $fontdb{$k}{'otcname'} = $otcname;
    }
  }
}

sub read_font_database {
  my @dbl;
  # if --fontdef=foo is given, disregard built-in database and
  # use "foo" as a substitute; otherwise, use built-in database
  if ($opt_fontdef) {
    my $foo = kpse_miscfont($opt_fontdef);
    open(FDB, "<$foo") ||
      die("Cannot find $opt_fontdef: $!");
    @dbl = <FDB>;
    close(FDB);
  } else {
    @dbl = <DATA>;
  }
  read_each_font_database(@dbl);
  # if --fontdef-add=bar is given, use "bar" as an addition
  # to the current database; if the same Name entry appears,
  # overwrite existing one (that is, the addition wins)
  for (@opt_fontdef_add) {
    my $foo = kpse_miscfont($_);
    open(FDB, "<$foo") ||
      die("Cannot find $_: $!");
    @dbl = <FDB>;
    close(FDB);
    read_each_font_database(@dbl);
  }
}

sub read_each_font_database {
  my (@curdbl) = @_;
  my $fontname = "";
  my $fontclass = "";
  my %fontprovides = ();
  my %fontfiles;
  my $psname = "";
  my $lineno = 0;
  chomp(@curdbl);
  push @curdbl, ""; # add a "final empty line" to easy parsing
  for my $l (@curdbl) {
    $lineno++;
    next if ($l =~ m/^\s*#/); # skip comment line
    if ($l =~ m/^\s*$/) { # empty line is a separator between entries
      if ($fontname || $fontclass || keys(%fontfiles)) {
        if ($fontname && $fontclass && keys(%fontfiles)) {
          my $realfontname = ($psname ? $psname : $fontname);
          if ($fontdb{$realfontname}{'origname'}) {
            # needed for --fontdef-add, which allows overwriting with external database given by user
            print_debug("$fontdb{$realfontname}{'origname'} is already registered in database,\n");
            print_debug("overwriting with the new one ...\n");
          }
          $fontdb{$realfontname}{'origname'} = $fontname;
          $fontdb{$realfontname}{'class'} = $fontclass;
          $fontdb{$realfontname}{'files'} = { %fontfiles };
          $fontdb{$realfontname}{'provides'} = { %fontprovides };
          if ($opt_debug >= 3) {
            print_dddebug("Dumping fontfiles for $realfontname: " . Data::Dumper::Dumper(\%fontfiles));
          }
          # reset to start
          $fontname = $fontclass = $psname = "";
          %fontfiles = ();
          %fontprovides = ();
        } else {
          print_warning("incomplete entry above line $lineno for $fontname/$fontclass, skipping!\n");
          # reset to start
          $fontname = $fontclass = $psname = "";
          %fontfiles = ();
          %fontprovides = ();
        }
      } else {
        # no term is set, so nothing to warn about
      }
      next;
    }
    if ($l =~ m/^INCLUDE\s*(.*)$/) {
      my @dbl;
      my $foo = kpse_miscfont($1);
      if (!open(FDB, "<$foo")) {
        print_warning("Cannot find $1, skipping!\n");
        next;
      }
      @dbl = <FDB>;
      close(FDB);
      read_each_font_database(@dbl);
      next;
    }
    if ($l =~ m/^Name:\s*(.*)$/) { $fontname = $1; next; }
    if ($l =~ m/^PSName:\s*(.*)$/) { $psname = $1; next; }
    if ($l =~ m/^Class:\s*(.*)$/) { $fontclass = $1 ; next ; }
    if ($l =~ m/^Provides\((\d+)\):\s*(.*)$/) { $fontprovides{$2} = $1; next; }
    # new code: distinguish 4 types (otf, otc, ttf, ttc)
    if ($l =~ m/^OTFname(\((\d+)\))?:\s*(.*)$/) {
      my $fn = $3;
      $fontfiles{$fn}{'priority'} = ($2 ? $2 : 10);
      # cp932 for win32 console
      my $encoded_fn;
      if (win32()) {
        $encoded_fn = encode_utftocp($fn);
      }
      print_dddebug("filename: ", ($encoded_fn ? "$encoded_fn" : "$fn"), "\n");
      print_dddebug("type: otf\n");
      $fontfiles{$fn}{'type'} = 'OTF';
      next;
    }
    if ($l =~ m/^OTCname(\((\d+)\))?:\s*(.*)$/) {
      my $fn = $3;
      $fontfiles{$fn}{'priority'} = ($2 ? $2 : 10);
      # cp932 for win32 console
      my $encoded_fn;
      if (win32()) {
        $encoded_fn = encode_utftocp($fn);
      }
      print_dddebug("filename: ", ($encoded_fn ? "$encoded_fn" : "$fn"), "\n");
      print_dddebug("type: otc\n");
      $fontfiles{$fn}{'type'} = 'OTC';
      next;
    }
    if ($l =~ m/^TTFname(\((\d+)\))?:\s*(.*)$/) {
      my $fn = $3;
      $fontfiles{$fn}{'priority'} = ($2 ? $2 : 10);
      # cp932 for win32 console
      my $encoded_fn;
      if (win32()) {
        $encoded_fn = encode_utftocp($fn);
      }
      print_dddebug("filename: ", ($encoded_fn ? "$encoded_fn" : "$fn"), "\n");
      print_dddebug("type: ttf\n");
      $fontfiles{$fn}{'type'} = 'TTF';
      next;
    }
    if ($l =~ m/^TTCname(\((\d+)\))?:\s*(.*)$/) {
      my $fn = $3;
      $fontfiles{$fn}{'priority'} = ($2 ? $2 : 10);
      # cp932 for win32 console
      my $encoded_fn;
      if (win32()) {
        $encoded_fn = encode_utftocp($fn);
      }
      print_dddebug("filename: ", ($encoded_fn ? "$encoded_fn" : "$fn"), "\n");
      print_dddebug("type: ttc\n");
      $fontfiles{$fn}{'type'} = 'TTC';
      next;
    }
    # only for backward compatibility; guess type from the file extension
    if ($l =~ m/^Filename(\((\d+)\))?:\s*(.*)$/) {
      my $fn = $3;
      $fontfiles{$fn}{'priority'} = ($2 ? $2 : 10);
      # cp932 for win32 console
      my $encoded_fn;
      if (win32()) {
        $encoded_fn = encode_utftocp($fn);
      }
      print_dddebug("filename: ", ($encoded_fn ? "$encoded_fn" : "$fn"), "\n");
      if ($fn =~ m/\.otf$/i) {
        print_dddebug("type: otf\n");
        $fontfiles{$fn}{'type'} = 'OTF';
      } elsif ($fn =~ m/\.otc(\(\d+\))?$/i) {
        print_dddebug("type: otc\n");
        $fontfiles{$fn}{'type'} = 'OTC';
      } elsif ($fn =~ m/\.ttf$/i) {
        print_dddebug("type: ttf\n");
        $fontfiles{$fn}{'type'} = 'TTF';
      } elsif ($fn =~ m/\.ttc(\(\d+\))?$/i) {
        print_dddebug("type: ttc\n");
        $fontfiles{$fn}{'type'} = 'TTC';
      } else {
        print_warning("cannot determine font type of $fn at line $lineno, skipping!\n");
        delete $fontfiles{$fn};
      }
      next;
    }
    # we are still here??
    print_error("Cannot parse this file at line $lineno, exiting. Strange line: >>>$l<<<\n");
    exit (1);
  }
}

sub dump_font_database {
  open(FOO, ">$dump_datafile") || 
    die("cannot open $dump_datafile for writing: $!");
  for my $k (sort keys %fontdb) {
    print FOO "Name: $fontdb{$k}{'origname'}\n";
    print FOO "PSName: $k\n" if ($fontdb{$k}{'origname'} ne $k);
    print FOO "Class: $fontdb{$k}{'class'}\n";
    for my $p (sort keys %{$fontdb{$k}{'provides'}}) {
      print FOO "Provides($fontdb{$k}{'provides'}{$p}): $p\n";
    }
    for my $f (sort { $fontdb{$k}{'files'}{$a}{'priority'}
                      <=>
                      $fontdb{$k}{'files'}{$b}{'priority'} }
                    keys %{$fontdb{$k}{'files'}}) {
      print FOO "$fontdb{$k}{'files'}{$f}{'type'}name($fontdb{$k}{'files'}{$f}{'priority'}): $f\n";
    }
    print FOO "\n"; # empty line is a separator between entries
  }
  close(FOO);
}

sub find_gs_resource {
  my $foundres = '';
  if (win32()) {
    # determine tlgs or native gs
    chomp( my $foo = `kpsewhich -var-value=SELFAUTOPARENT`);
    if ( -d "$foo/tlpkg/tlgs" ) {
      # should be texlive with tlgs
      print_debug("Assuming tlgs win32 ...\n");
      $foundres = "$foo/tlpkg/tlgs/Resource";
      # for TL2016, tlgs binary has built-in Resource,
      # so we cannot set up CJK fonts correctly.
      # the following test forces to exit in such case
      if ( ! -d $foundres ) {
        print_error("No Resource directory available for tlgs,\n");
        print_error("we cannot support such gs, sorry.\n");
        $foundres = '';
      }
      # change output location
      $cidfmap_pathpart = "../lib/cidfmap";
      $cidfmap_local_pathpart = "../lib/cidfmap.local";
      $cidfmap_aliases_pathpart = "../lib/cidfmap.aliases";
    } else {
      # we assume gswin32c is in the path
      # TODO: what should we do for gswin64c?
      chomp( $foundres = `where gswin32c 2>$nul` ); # assume 'where' is available
      if ($?) {
        print_error("Cannot run where gswin32c ...\n");
      } else {
        # trial 1: assume the relative path
        # when C:\path\to\bin\gswin32c.exe is found, then there should be
        # C:\path\to\Resource (note that 'where' returns backslash-ed path)
        print_debug("Finding gs resource by assuming relative path ...\n");
        $foundres = encode_cptoutf($foundres); # 99.99% unnecessary
        $foundres =~ s!\\!/!g;
        $foundres =~ s!/bin/gswin32c\.exe$!/Resource!;
        if ( ! -d $foundres ) {
          $foundres = '';
        }
        if (!$foundres) {
          print_debug("Found gs but no resource, try another routine ...\n");
        }
      }
      if (!$foundres) {
        chomp( my $gsver = `gswin32c --version 2>$nul` );
        if ($?) {
          print_error("Cannot run gswin32c --version ...\n");
        } else {
          # trial 2: assume the fixed path, c:/gs/gs$gsver/Resource
          print_debug("Finding gs resource by assuming fixed path ...\n");
          $foundres = "c:/gs/gs$gsver/Resource";
          if ( ! -d $foundres ) {
            $foundres = '';
          }
          if (!$foundres) {
            print_error("Found gs but no resource???\n");
          }
        }
      }
    }
  } else {
    # we assume that gs is in the path
    chomp( my $gsver = `gs --version 2>$nul` );
    if ($?) {
      print_error("Cannot run gs --version ...\n");
    } else {
      # trial 1: assume the relative path
      # when /path/to/bin/gs is found, then there should be
      # /path/to/share/ghostscript/$(gs --version)/Resource
      print_debug("Finding gs resource by assuming relative path ...\n");
      chomp( $foundres = `which gs` );
      $foundres =~ s!/bin/gs$!/share/ghostscript/$gsver/Resource!;
      if ( ! -d $foundres ) {
        $foundres = '';
      }
      if (!$foundres) {
        print_debug("Found gs but no resource, try another routine ...\n");
      }
    }
    if (!$foundres) {
      chomp( my @ret = `gs --help 2>$nul` );
      if ($?) {
        print_error("Cannot run gs --help ...\n");
      } else {
        # trial 2: parse gs help message
        print_debug("Finding gs resource by parsing help message ...\n");
        $foundres = '';
        # try to find resource line
        for (@ret) {
          if (m!Resource/Font!) {
            $foundres = $_;
            # extract the first substring of non-space chars
            # up to Resource/Font and drop the /Font part
            $foundres =~ s!^.*\s(\S*Resource)/Font.*$!$1!;
            last;
          }
        }
        if (!$foundres) {
          print_error("Found gs but no resource???\n");
        }
      }
    }
  }
  return $foundres;
}

sub kpse_miscfont {
  my ($file) = @_;
  chomp( my $foo = `kpsewhich -format=miscfont $file`);
  return $foo;
}

sub encode_utftocp {
  my ($foo) = @_;
  $foo = Encode::decode('utf-8', $foo);
  $foo = Encode::encode('cp932', $foo);
  return $foo;
}

sub encode_cptoutf {
  my ($foo) = @_;
  $foo = Encode::decode('cp932', $foo);
  $foo = Encode::encode('utf-8', $foo);
  return $foo;
}

sub version {
  my $ret = sprintf "%s version %s\n", $prg, $version;
  return $ret;
}

sub Usage {
  my $headline = "Configuring Ghostscript for CJK CID/TTF fonts";
  my $usage = "[perl] $prg\[.pl\] [OPTIONS]";
  my $options = "
-o, --output DIR      specifies the base output dir, if not provided,
                      the Resource directory of an installed Ghostscript
                      is searched and used.
-f, --fontdef FILE    specify alternate set of font definitions, if not
                      given, the built-in set is used
--fontdef-add FILE    specify additional set of font definitions, to
                      overwrite subset of built-in definitions;
                      can be given multiple times
-a, --alias LL=RR     defines an alias, or overrides a given alias;
                      illegal if LL is provided by a real font, or
                      RR is neither available as real font or alias;
                      can be given multiple times
--filelist FILE       read list of available font files from FILE
                      instead of searching with kpathsea
--link-texmf [DIR]    link fonts into
                         DIR/$otf_pathpart
                      and
                         DIR/$ttf_pathpart
                      where DIR defaults to TEXMFLOCAL
--otfps [DIR]         generate configuration file (psnames-for-otf) into
                         DIR/$akotfps_pathpart
                      which is used by ps2otfps (developed by Akira Kakuto),
                      instead of generating snippets
--force               do not bail out if linked fonts already exist
--remove              try to remove instead of create
--cleanup             try to clean up all possible links/snippets and
                      cidfmap.local/cidfmap.aliases, which could have been
                      generated in the previous runs
-n, --dry-run         do not actually output anything
-q, --quiet           be less verbose
-d, --debug           output debug information, can be given multiple times
-v, --version         outputs only the version information
-h, --help            this help
";

  my $winonlyoptions = "
--hardlink            create hardlinks instead of symlinks
--winbatch [FILE]     prepare a batch file for link generation, instead of
                      generating links right away
                      the batch file name defaults to $winbatch
";

  my $commandoptions = "
--dump-data [FILE]    dump the set of font definitions which is currently
                      effective, where FILE (the dump output) defaults to
                      $dump_datafile; you can easily modify it,
                      and tell me with -f (or --fontdef) option
--only-aliases        regenerate only cidfmap.aliases file, instead of all
--list-aliases        lists the available aliases and their options, with the
                      selected option on top
--list-all-aliases    list all possible aliases without searching for
                      actually present files
--list-fonts          lists the fonts found on the system
--info                combines the information of --list-aliases and
                      --list-fonts
--machine-readable    output of --list-aliases is machine readable
";

  my $shortdesc = "
This script searches a list of directories for CJK fonts, and makes
them available to an installed Ghostscript. In the simplest case with
sufficient privileges, a run without arguments should effect in a
complete setup of Ghostscript.
";

my $operation = "
For each found TrueType (TTF) font it creates a cidfmap entry in

    <Resource>/Init/cidfmap.local
      -- if you are using tlgs win32, tlpkg/tlgs/lib/cidfmap.local instead

and links the font to

    <Resource>/CIDFSubst/

For each CID font it creates a snippet in

    <Resource>/Font/

and links the font to

    <Resource>/CIDFont/

The `<Resource>` dir is either given by `-o`/`--output`, or otherwise searched
from an installed Ghostscript (binary name is assumed to be 'gs' on unix,
'gswin32c' on win32).

Aliases are added to 

    <Resource>/Init/cidfmap.aliases
      -- if you are using tlgs win32, tlpkg/tlgs/lib/cidfmap.aliases instead

Finally, it tries to add runlib calls to

    <Resource>/Init/cidfmap
      -- if you are using tlgs win32, tlpkg/tlgs/lib/cidfmap

to load the cidfmap.local and cidfmap.aliases.
";

  my $dirsearch = '
Search is done using the kpathsea library, in particular using kpsewhich
program. By default the following directories are searched:
  - all TEXMF trees
  - `/Library/Fonts`, `/Library/Fonts/Microsoft`, `/System/Library/Fonts`,
    `/System/Library/Assets`, `/Network/Library/Fonts`,
    `~/Library/Fonts` and `/usr/share/fonts` (all if available)
  - `/Applications/Microsoft Word.app/Contents/Resources/{Fonts,DFonts}`,
    `/Applications/Microsoft Excel.app/Contents/Resources/{Fonts,DFonts}`,
    `/Applications/Microsoft PowerPoint.app/Contents/Resources/{Fonts,DFonts}`
     (all if available, meant for Office for Mac 2016)
  - `c:/windows/fonts` (on Windows)
  - the directories in `OSFONTDIR` environment variable

In case you want to add some directories to the search path, adapt the
`OSFONTDIR` environment variable accordingly: Example:

`````
    OSFONTDIR="/usr/local/share/fonts/truetype//:/usr/local/share/fonts/opentype//" $prg
`````

will result in fonts found in the above two given directories to be
searched in addition.
';

  my $outputfile = "
If no output option is given, the program searches for a Ghostscript
interpreter 'gs' and determines its Resource directory. This might
fail, in which case one need to pass the output directory manually.

Since the program adds files and link to this directory, sufficient
permissions are necessary.
";

  my $aliases = "
Aliases are managed via the Provides values in the font database.
At the moment entries for the basic font names for CJK fonts
are added:

Japanese:

    Ryumin-Light GothicBBB-Medium FutoMinA101-Bold FutoGoB101-Bold Jun101-Light

Korean:

    HYSMyeongJo-Medium HYGoThic-Medium HYRGoThic-Medium

Simplified Chinese:

    STSong-Light STSong-Regular STHeiti-Regular STHeiti-Light
    STKaiti-Regular STFangsong-Light STFangsong-Regular

Traditional Chinese:

    MSung-Light MSung-Medium MHei-Medium MKai-Medium

In addition, we also include provide entries for the OTF Morisawa names:
    RyuminPro-Light GothicBBBPro-Medium FutoMinA101Pro-Bold
    FutoGoB101Pro-Bold Jun101Pro-Light

The order is determined by the `Provides` setting in the font database.
That is, the first font found in this order will be used to provide the
alias if necessary.

For the Japanese fonts:
    Morisawa Pr6N, Morisawa, Hiragino ProN, Hiragino,
    Kozuka Pr6N, Kozuka ProVI, Kozuka Pro, Kozuka Std,
    Yu OS X, Yu Win, MS, Moga-Mobo-ex, Moga-Mobo, IPAex, IPA, Ume

For the Korean fonts:
    (Hanyang,) Adobe, Solaris-hanyang, MS, Unfonts, Baekmuk

For the Simplified Chinese:
    Adobe, Fandol, Hiragino, Founder, MS, CJKUnifonts, Arphic, CJKUnifonts-ttf

For the Traditional Chinese:
    Adobe, MS, CJKUnifonts, Arphic, CJKUnifonts-ttf

#### Overriding aliases ####

Using the command line option `--alias LL=RR` one can add arbitrary aliases,
or override ones selected by the program. For this to work the following
requirements of `LL` and `RR` must be fulfilled:
  * `LL` is not provided by a real font
  * `RR` is available either as real font, or as alias (indirect alias)
";

  my $authors = "
The script and its documentation was written by Norbert Preining, based
on research and work by Yusuke Kuroki, Yusuke Terada, Bruno Voisin,
Hironobu Yamashita, Munehiro Yamamoto and the TeX Q&A wiki page.

Maintained by Japanese TeX Development Community. For development, see
  https://github.com/texjporg/cjk-gs-support

The script is licensed under GNU General Public License Version 3 or later.
The contained font data is not copyrightable.
";


  if ($opt_markdown) {
    print "$headline\n";
    print ("=" x length($headline));
    print "\n$shortdesc\nUsage\n-----\n\n`````\n$usage\n`````\n\n";
    print "#### Options ####\n\n`````";
    print_for_out($options, "  ");
    print "`````\n\n#### Windows only options ####\n\n`````";
    print_for_out($winonlyoptions, "  ");
    print "`````\n\n#### Command like options ####\n\n`````";
    print_for_out($commandoptions, "  ");
    print "`````\n\nOperation\n---------\n$operation\n";
    print "How and which directories are searched\n";
    print "--------------------------------------\n$dirsearch\n";
    print "Output files\n";
    print "------------\n$outputfile\n";
    print "Aliases\n";
    print "-------\n$aliases\n";
    print "Authors, Contributors, and Copyright\n";
    print "------------------------------------\n$authors\n";
  } else {
    print "\nUsage: $usage\n\n$headline\n$shortdesc";
    print "\nOptions:\n";
    print_for_out($options, "  ");
    if (win32()) {
      print "\nWindows only options:\n";
      print_for_out($winonlyoptions, "  ");
    }
    print "\nCommand like options:\n";
    print_for_out($commandoptions, "  ");
    print "\nOperation:\n";
    print_for_out($operation, "  ");
    print "\nHow and which directories are searched:\n";
    print_for_out($dirsearch, "  ");
    print "\nOutput files:\n";
    print_for_out($outputfile, "  ");
    print "\nAliases:\n";
    print_for_out($aliases, "  ");
    print "\nAuthors, Contributors, and Copyright:\n";
    print_for_out($authors, "  ");
    print "\n";
  }
  exit 0;
}

sub print_for_out {
  my ($what, $indent) = @_;
  for (split /\n/, $what) { 
    next if m/`````/;
    s/\s*####\s*//g;
    if ($_ eq '') {
      print "\n";
    } else {
      print "$indent$_\n";
    }
  }
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
sub print_dddebug {
  print STDERR "$prg [DEBUG]: ", @_ if ($opt_debug >= 3);
}


__DATA__
#
# CJK FONT DEFINITIONS
#

#
# JAPANESE FONTS
#

# Morisawa -- Provides level 10(Pr6N), 15(Pr6), 18(Pr5), 20(Pro)
INCLUDE cjkgs-morisawa-standard.dat
INCLUDE cjkgs-morisawa-extra.dat

# Hiragino -- Provides level 30(ProN), 40(Pro)
INCLUDE cjkgs-hiragino.dat

# Kozuka (Adobe) -- Provides level 50(Pr6N), 55(ProVI), 60(Pro), 65(Std)
INCLUDE cjkgs-kozuka.dat
INCLUDE cjkgs-ryokana.dat

# Yu-fonts MacOS version -- Provides level 80
INCLUDE cjkgs-yu-osx.dat

# Yu-fonts Windows/MSOffice version -- Provides level 90
INCLUDE cjkgs-yu-win.dat

# other Mac OS X fonts

# Note about Mac (Mac OS X 10.6 -- macOS 10.13)
#   Klee.ttc
#   Tsukushi{A,B}MaruGothic.ttc
# are bundled with OS X 10.11 El Capitan or later versions.
#   Kyokasho.ttc
# is bundled with macOS 10.12 Sierra or later versions.
#   ToppanBunkyuMincho-Regular.otf
#   ToppanBunkyuGothic.ttc
#   ToppanBunkyuMidashiMincho-ExtraBold.otf
#   ToppanBunkyuMidashiGothic-ExtraBold.otf
# are bundled with macOS 10.12 -- 10.12.6 Sierra.
#   ToppanBunkyuMinchoPr6N-Regular.otf
#   ToppanBunkyuGothicPr6N.ttc
#   ToppanBunkyuMidashiMinchoStdN-ExtraBold.otf
#   ToppanBunkyuMidashiGothicStdN-ExtraBold.otf
# are bundled with macOS 10.13 High Sierra or later versions.

# IPA (free)

Name: IPAMincho
Class: Japan
Provides(130): Ryumin-Light
Provides(130): RyuminPro-Light
Provides(130): HiraMinProN-W3
Provides(130): HiraMinPro-W3
Provides(130): FutoMinA101-Bold
Provides(130): FutoMinA101Pro-Bold
Provides(130): HiraMinProN-W6
Provides(130): HiraMinPro-W6
TTFname(20): ipam.ttf
#TTFname(21): IPAMincho.ttf

Name: IPAGothic
Class: Japan
Provides(130): GothicBBB-Medium
Provides(130): GothicBBBPro-Medium
Provides(130): HiraKakuProN-W3
Provides(130): HiraKakuPro-W3
Provides(130): FutoGoB101-Bold
Provides(130): FutoGoB101Pro-Bold
Provides(130): HiraKakuProN-W6
Provides(130): HiraKakuPro-W6
Provides(130): Jun101-Light
Provides(130): Jun101Pro-Light
Provides(130): HiraMaruProN-W4
Provides(130): HiraMaruPro-W4
Provides(130): MidashiGo-MB31
Provides(130): MidashiGoPro-MB31
Provides(130): HiraKakuStdN-W8
Provides(130): HiraKakuStd-W8
TTFname(20): ipag.ttf
#TTFname(21): IPAGothic.ttf

Name: IPAexMincho
Class: Japan
Provides(120): Ryumin-Light
Provides(120): RyuminPro-Light
Provides(120): HiraMinProN-W3
Provides(120): HiraMinPro-W3
Provides(120): FutoMinA101-Bold
Provides(120): FutoMinA101Pro-Bold
Provides(120): HiraMinProN-W6
Provides(120): HiraMinPro-W6
TTFname(20): ipaexm.ttf
#TTFname(21): IPAexMincho.ttf

Name: IPAexGothic
Class: Japan
Provides(120): GothicBBB-Medium
Provides(120): GothicBBBPro-Medium
Provides(120): HiraKakuProN-W3
Provides(120): HiraKakuPro-W3
Provides(120): FutoGoB101-Bold
Provides(120): FutoGoB101Pro-Bold
Provides(120): HiraKakuProN-W6
Provides(120): HiraKakuPro-W6
Provides(120): Jun101-Light
Provides(120): Jun101Pro-Light
Provides(120): HiraMaruProN-W4
Provides(120): HiraMaruPro-W4
Provides(120): MidashiGo-MB31
Provides(120): MidashiGoPro-MB31
Provides(120): HiraKakuStdN-W8
Provides(120): HiraKakuStd-W8
TTFname(20): ipaexg.ttf
#TTFname(21): IPAexGothic.ttf

# IPA proportional (free)

Name: IPAPMincho
Class: Japan
TTFname(20): ipamp.ttf
#TTFname(21): IPAPMincho.ttf

Name: IPAPGothic
Class: Japan
TTFname(20): ipagp.ttf
#TTFname(21): IPAPGothic.ttf

# IPA MJ (free)

Name: IPAmjMincho
Class: Japan
TTFname: ipamjm.ttf

# Moga-Mobo from Y.Oz Vox (free)

Name: MogaMincho-Regular
Class: Japan
Provides(110): Ryumin-Light
Provides(110): RyuminPro-Light
Provides(110): HiraMinProN-W3
Provides(110): HiraMinPro-W3
TTCname: mogam.ttc(0)

Name: MogaExMincho-Regular
Class: Japan
Provides(100): Ryumin-Light
Provides(100): RyuminPro-Light
Provides(100): HiraMinProN-W3
Provides(100): HiraMinPro-W3
TTCname: mogam.ttc(1)

Name: MogaExMincho-Italic
Class: Japan
TTCname: mogam.ttc(2)

Name: Moga90Mincho-Regular
Class: Japan
TTCname: mogam.ttc(3)

Name: MogaEx90Mincho-Regular
Class: Japan
TTCname: mogam.ttc(4)

Name: MogaEx90Mincho-Italic
Class: Japan
TTCname: mogam.ttc(5)

Name: MogaMincho-Bold
Class: Japan
Provides(110): FutoMinA101-Bold
Provides(110): FutoMinA101Pro-Bold
Provides(110): HiraMinProN-W6
Provides(110): HiraMinPro-W6
TTCname: mogamb.ttc(0)

Name: MogaExMincho-Bold
Class: Japan
Provides(100): FutoMinA101-Bold
Provides(100): FutoMinA101Pro-Bold
Provides(100): HiraMinProN-W6
Provides(100): HiraMinPro-W6
TTCname: mogamb.ttc(1)

Name: Moga90Mincho-Bold
Class: Japan
TTCname: mogamb.ttc(2)

Name: MogaEx90Mincho-Bold
Class: Japan
TTCname: mogamb.ttc(3)

Name: MogaHMincho-Regular
Class: Japan
TTCname: mogahm.ttc(0)

Name: MogaExHMincho-Regular
Class: Japan
TTCname: mogahm.ttc(1)

Name: MogaExHMincho-Italic
Class: Japan
TTCname: mogahm.ttc(2)

Name: Moga90HMincho-Regular
Class: Japan
TTCname: mogahm.ttc(3)

Name: MogaEx90HMincho-Regular
Class: Japan
TTCname: mogahm.ttc(4)

Name: MogaEx90HMincho-Italic
Class: Japan
TTCname: mogahm.ttc(5)

Name: MogaHMincho-Bold
Class: Japan
TTCname: mogahmb.ttc(0)

Name: MogaExHMincho-Bold
Class: Japan
TTCname: mogahmb.ttc(1)

Name: Moga90HMincho-Bold
Class: Japan
TTCname: mogahmb.ttc(2)

Name: MogaEx90HMincho-Bold
Class: Japan
TTCname: mogahmb.ttc(3)

Name: MogaGothic-Regular
Class: Japan
Provides(110): GothicBBB-Medium
Provides(110): GothicBBBPro-Medium
Provides(110): HiraKakuProN-W3
Provides(110): HiraKakuPro-W3
TTCname: mogag.ttc(0)

Name: MogaExGothic-Regular
Class: Japan
Provides(100): GothicBBB-Medium
Provides(100): GothicBBBPro-Medium
Provides(100): HiraKakuProN-W3
Provides(100): HiraKakuPro-W3
TTCname: mogag.ttc(1)

Name: Moga90Gothic-Regular
Class: Japan
TTCname: mogag.ttc(2)

Name: MogaEx90Gothic-Regular
Class: Japan
TTCname: mogag.ttc(3)

Name: MogaGothic-Bold
Class: Japan
Provides(110): FutoGoB101-Bold
Provides(110): FutoGoB101Pro-Bold
Provides(110): HiraKakuProN-W6
Provides(110): HiraKakuPro-W6
Provides(110): MidashiGo-MB31
Provides(110): MidashiGoPro-MB31
Provides(110): HiraKakuStdN-W8
Provides(110): HiraKakuStd-W8
TTCname: mogagb.ttc(0)

Name: MogaExGothic-Bold
Class: Japan
Provides(100): FutoGoB101-Bold
Provides(100): FutoGoB101Pro-Bold
Provides(100): HiraKakuProN-W6
Provides(100): HiraKakuPro-W6
Provides(100): MidashiGo-MB31
Provides(100): MidashiGoPro-MB31
Provides(100): HiraKakuStdN-W8
Provides(100): HiraKakuStd-W8
TTCname: mogagb.ttc(1)

Name: Moga90Gothic-Bold
Class: Japan
TTCname: mogagb.ttc(2)

Name: MogaEx90Gothic-Bold
Class: Japan
TTCname: mogagb.ttc(3)

Name: MoboGothic-Regular
Class: Japan
Provides(110): Jun101-Light
Provides(110): Jun101Pro-Light
Provides(110): HiraMaruProN-W4
Provides(110): HiraMaruPro-W4
TTCname: mobog.ttc(0)

Name: MoboExGothic-Regular
Class: Japan
Provides(100): Jun101-Light
Provides(100): Jun101Pro-Light
Provides(100): HiraMaruProN-W4
Provides(100): HiraMaruPro-W4
TTCname: mobog.ttc(1)

Name: Mobo90Gothic-Regular
Class: Japan
TTCname: mobog.ttc(2)

Name: MoboEx90Gothic-Regular
Class: Japan
TTCname: mobog.ttc(3)

Name: MoboGothic-Bold
Class: Japan
TTCname: mobogb.ttc(0)

Name: MoboExGothic-Bold
Class: Japan
TTCname: mobogb.ttc(1)

Name: Mobo90Gothic-Bold
Class: Japan
TTCname: mobogb.ttc(2)

Name: MoboEx90Gothic-Bold
Class: Japan
TTCname: mobogb.ttc(3)

# Ume-font (free)
# note: in the current release (2016-09-03 umefont_660.7z),
# ume-tms.ttf and ume-pms.ttf ("studybook" family) share the same PSName
# as ume-tmo.ttf and ume-pmo.ttf; we don't add these database
# intentionally -- HY (2017/01/17)

Name: Ume-Mincho
Class: Japan
Provides(140): Ryumin-Light
Provides(140): RyuminPro-Light
Provides(140): HiraMinProN-W3
Provides(140): HiraMinPro-W3
Provides(140): FutoMinA101-Bold
Provides(140): FutoMinA101Pro-Bold
Provides(140): HiraMinProN-W6
Provides(140): HiraMinPro-W6
TTFname(10): ume-tmo3.ttf
#TTFname(11): ume-tms3.ttf

Name: Ume-Gothic
Class: Japan
Provides(140): GothicBBB-Medium
Provides(140): GothicBBBPro-Medium
Provides(140): HiraKakuProN-W3
Provides(140): HiraKakuPro-W3
Provides(140): FutoGoB101-Bold
Provides(140): FutoGoB101Pro-Bold
Provides(140): HiraKakuProN-W6
Provides(140): HiraKakuPro-W6
Provides(140): Jun101-Light
Provides(140): Jun101Pro-Light
Provides(140): HiraMaruProN-W4
Provides(140): HiraMaruPro-W4
Provides(140): MidashiGo-MB31
Provides(140): MidashiGoPro-MB31
Provides(140): HiraKakuStdN-W8
Provides(140): HiraKakuStd-W8
TTFname(10): ume-tgo4.ttf

Name: Ume-Gothic-O5
Class: Japan
TTFname(10): ume-tgo5.ttf

Name: Ume-Gothic-C4
Class: Japan
TTFname(10): ume-tgc4.ttf

Name: Ume-Gothic-C5
Class: Japan
TTFname(10): ume-tgc5.ttf

Name: Ume-Gothic-S4
Class: Japan
TTFname(10): ume-tgs4.ttf

Name: Ume-Gothic-S5
Class: Japan
TTFname(10): ume-tgs5.ttf

Name: Ume-P-Mincho
Class: Japan
TTFname(10): ume-pmo3.ttf
#TTFname(11): ume-pms3.ttf

Name: Ume-P-Gothic
Class: Japan
TTFname(10): ume-pgo4.ttf

Name: Ume-P-Gothic-O5
Class: Japan
TTFname(10): ume-pgo5.ttf

Name: Ume-P-Gothic-C4
Class: Japan
TTFname(10): ume-pgc4.ttf

Name: Ume-P-Gothic-C5
Class: Japan
TTFname(10): ume-pgc5.ttf

Name: Ume-P-Gothic-S4
Class: Japan
TTFname(10): ume-pgs4.ttf

Name: Ume-P-Gothic-S5
Class: Japan
TTFname(10): ume-pgs5.ttf

Name: Ume-UI-Gothic
Class: Japan
TTFname(10): ume-ugo4.ttf

Name: Ume-UI-Gothic-O5
Class: Japan
TTFname(10): ume-ugo5.ttf

Name: Ume-Hy-Gothic
Class: Japan
TTFname(10): ume-hgo4.ttf

# Sazanami (free)

Name: Sazanami-Mincho-Regular
Class: Japan
TTFname: sazanami-mincho.ttf

Name: Sazanami-Gothic-Regular
Class: Japan
TTFname: sazanami-gothic.ttf

# Osaka (Apple)

Name: Osaka
Class: Japan
TTFname: Osaka.ttf

Name: Osaka-Mono
Class: Japan
TTFname: OsakaMono.ttf

#
# CHINESE FONTS
#

# Hiragino -- Provides level 50
# (already included in JAPANESE section)

# DynaComware (OS X)

Name: LiHeiPro
Class: CNS
#Provides(??): MHei-Medium # fails
TTFname(20): 儷黑 Pro.ttf
TTFname(10): LiHeiPro.ttf

Name: LiSongPro
Class: CNS
#Provides(??): MSung-Medium # fails
#Provides(??): MSung-Light # fails
TTFname(20): 儷宋 Pro.ttf
TTFname(10): LiSongPro.ttf

Name: PingFangTC-Regular
Class: CNS
OTCname: PingFang.ttc(1)

Name: PingFangSC-Regular
Class: GB
OTCname: PingFang.ttc(2)

Name: PingFangTC-Medium
Class: CNS
OTCname: PingFang.ttc(4)

Name: PingFangSC-Medium
Class: GB
OTCname: PingFang.ttc(5)

Name: PingFangTC-Semibold
Class: CNS
OTCname: PingFang.ttc(7)

Name: PingFangSC-Semibold
Class: GB
OTCname: PingFang.ttc(8)

Name: PingFangTC-Light
Class: CNS
OTCname: PingFang.ttc(10)

Name: PingFangSC-Light
Class: GB
OTCname: PingFang.ttc(11)

Name: PingFangTC-Thin
Class: CNS
OTCname: PingFang.ttc(13)

Name: PingFangSC-Thin
Class: GB
OTCname: PingFang.ttc(14)

Name: PingFangTC-Ultralight
Class: CNS
OTCname: PingFang.ttc(16)

Name: PingFangSC-Ultralight
Class: GB
OTCname: PingFang.ttc(17)

# Changzhou SinoType -- Provides level ??
INCLUDE cjkgs-sinotype.dat

# Beijing Founder Electronics
# note:
#   FZ****.TTF (13 files)
# are bundled with with WPS Office (formerly Kingsoft Office) Linux.
#   Lantinghei.ttc
# is bundled with OS X 10.9 Mavericks or later versions.

# FZShuSong-Z01
Name: FZSSK--GBK1-0
Class: GB
Provides(55): STSong-Light
TTFname: FZSSK.TTF

# FZXiaoBiaoSong-B05
Name: FZXBSK--GBK1-0
Class: GB
Provides(55): STSong-Regular
TTFname: FZXBSK.TTF

# FZXiHeiI-Z08
Name: FZXH1K--GBK1-0
Class: GB
Provides(55): STHeiti-Light
TTFname: FZXH1K.TTF

# FZHei-B01
Name: FZHTK--GBK1-0
Class: GB
Provides(55): STHeiti-Regular
TTFname: FZHTK.TTF

# FZKai-Z03
Name: FZKTK--GBK1-0
Class: GB
Provides(55): STKaiti-Regular
TTFname: FZKTK.TTF

# FZFangSong-Z02
Name: FZFSK--GBK1-0
Class: GB
Provides(55): STFangsong-Light
Provides(55): STFangsong-Regular
TTFname: FZFSK.TTF

# FZXingKai-S04
Name: FZXKK--GBK1-0
Class: GB
TTFname: FZXKK.TTF

# FZWeiBei-S03
Name: FZWBK--GBK1-0
Class: GB
TTFname: FZWBK.TTF

# FZChaoCuHei-M10
Name: FZCCHK--GBK1-0
Class: GB
TTFname: FZCCHK.TTF

# FZLiShu-S01
Name: FZLSK--GBK1-0
Class: GB
TTFname: FZLSK.TTF

# FZYaoTi-M06
Name: FZYTK--GBK1-0
Class: GB
TTFname: FZYTK.TTF

# FZSongS-Extended
Name: FZSONGS--GB1-5
Class: GB
TTFname: FZSongS_20100603.TTF

# FZSongS-Extended(SIP)
Name: FZSONGS_SIP--GB1-5
Class: GB
TTFname: FZSongS(SIP)_2010603.TTF

# Lantinghei SC Demibold
Name: FZLTZHK--GBK1-0
Class: GB
TTCname: Lantinghei.ttc(0)

# Lantinghei SC Extralight
Name: FZLTXHK--GBK1-0
Class: GB
TTCname: Lantinghei.ttc(1)

# Lantinghei SC Heavy
Name: FZLTTHK--GBK1-0
Class: GB
TTCname: Lantinghei.ttc(2)

# Lantinghei TC Demibold
Name: FZLTZHB--B51-0
Class: CNS
TTCname: Lantinghei.ttc(3)

# Lantinghei TC Extralight
Name: FZLTXHB--B51-0
Class: CNS
TTCname: Lantinghei.ttc(4)

# Lantinghei TC Heavy
Name: FZLTTHB--B51-0
Class: CNS
TTCname: Lantinghei.ttc(5)

# Arphic Font Design Team (OS X)

Name: WeibeiSC-Bold
PSName: Weibei-SC-Bold
Class: GB
OTFname: WeibeiSC-Bold.otf

Name: WeibeiTC-Bold
PSName: Weibei-TC-Bold
Class: CNS
OTFname: WeibeiTC-Bold.otf

# Monotype Imaging (OS X)

Name: YuppySC-Regular
Class: GB
OTFname: YuppySC-Regular.otf

Name: YuppyTC-Regular
Class: CNS
OTFname: YuppyTC-Regular.otf

# Monotype Hong Kong (OS X)

Name: LingWaiSC-Medium
PSName: MLingWaiMedium-SC
Class: GB
OTFname: LingWaiSC-Medium.otf

Name: LingWaiTC-Medium
PSName: MLingWaiMedium-TC
Class: CNS
OTFname: LingWaiTC-Medium.otf

# DynaComware Taiwan (OS X)

Name: WawaSC-Regular
PSName: DFWaWaSC-W5
Class: GB
OTFname: WawaSC-Regular.otf

Name: WawaTC-Regular
PSName: DFWaWaTC-W5
Class: CNS
OTFname: WawaTC-Regular.otf

Name: HannotateSC-W5
Class: GB
OTCname: Hannotate.ttc(0)

Name: HannotateTC-W5
Class: CNS
OTCname: Hannotate.ttc(1)

Name: HannotateSC-W7
Class: GB
OTCname: Hannotate.ttc(2)

Name: HannotateTC-W7
Class: CNS
OTCname: Hannotate.ttc(3)

Name: HanziPenSC-W3
Class: GB
OTCname: Hanzipen.ttc(0)

Name: HanziPenTC-W3
Class: CNS
OTCname: Hanzipen.ttc(1)

Name: HanziPenSC-W5
Class: GB
OTCname: Hanzipen.ttc(2)

Name: HanziPenTC-W5
Class: CNS
OTCname: Hanzipen.ttc(3)

# Shanghai Ikarus Ltd./URW Software & Type GmbH

Name: SIL-Hei-Med-Jian
Class: GB
TTFname: Hei.ttf

Name: SIL-Kai-Reg-Jian
Class: GB
TTFname: Kai.ttf

# Apple

Name: LiSungLight
Class: CNS
TTFname(20): Apple LiSung Light.ttf
TTFname(10): LiSungLight.ttf

Name: LiGothicMed
Class: CNS
TTFname(20): Apple LiGothic Medium.ttf
TTFname(10): LiGothicMed.ttf

# Adobe chinese fonts

# simplified chinese

Name: AdobeSongStd-Light
Class: GB
Provides(30): STSong-Light
Provides(30): STSong-Regular
OTFname(10): AdobeSongStd-Light.otf

Name: AdobeHeitiStd-Regular
Class: GB
Provides(30): STHeiti-Regular
Provides(30): STHeiti-Light
OTFname(20): AdobeHeitiStd-Regular.otf

Name: AdobeKaitiStd-Regular
Class: GB
Provides(30): STKaiti-Regular
OTFname(20): AdobeKaitiStd-Regular.otf

Name: AdobeFangsongStd-Regular
Class: GB
Provides(30): STFangsong-Light
Provides(30): STFangsong-Regular
OTFname(20): AdobeFangsongStd-Regular.otf

# traditional chinese

Name: AdobeMingStd-Light
Class: CNS
Provides(30): MSung-Light
Provides(30): MSung-Medium
OTFname(20): AdobeMingStd-Light.otf

Name: AdobeFanHeitiStd-Bold
Class: CNS
Provides(30): MHei-Medium
Provides(30): MKai-Medium
OTFname(20): AdobeFanHeitiStd-Bold.otf

# Fandol (free)

Name: FandolSong-Regular
Class: GB
Provides(40): STSong-Light
OTFname(10): FandolSong-Regular.otf

Name: FandolSong-Bold
Provides(40): STSong-Regular
Class: GB
OTFname(10): FandolSong-Bold.otf

Name: FandolKai-Regular
Class: GB
Provides(40): STKaiti-Regular
OTFname(10): FandolKai-Regular.otf

Name: FandolHei-Regular
Class: GB
Provides(40): STHeiti-Regular
Provides(40): STHeiti-Light
OTFname(10): FandolHei-Regular.otf

Name: FandolHei-Bold
Class: GB
OTFname(10): FandolHei-Bold.otf

Name: FandolFang-Regular
Class: GB
Provides(40): STFangsong-Light
Provides(40): STFangsong-Regular
OTFname(10): FandolFang-Regular.otf

# Arphic (free)

Name: BousungEG-Light-GB
Class: GB
Provides(80): STSong-Light
Provides(80): STSong-Regular
Provides(80): STFangsong-Light
Provides(80): STFangsong-Regular
TTFname: gbsn00lp.ttf

Name: GBZenKai-Medium
Class: GB
Provides(80): STKaiti-Regular
Provides(80): STHeiti-Regular
Provides(80): STHeiti-Light
TTFname: gkai00mp.ttf

Name: ShanHeiSun-Light
Class: CNS
Provides(80): MSung-Light
Provides(80): MSung-Medium
TTFname: bsmi00lp.ttf

Name: ZenKai-Medium
Class: CNS
Provides(80): MKai-Medium
Provides(80): MHei-Medium
TTFname: bkai00mp.ttf

# CJK-Unifonts new ttc edition (free)

Name: UMingCN
Class: GB
Provides(70): STSong-Light
Provides(70): STSong-Regular
Provides(70): STFangsong-Light
Provides(70): STFangsong-Regular
TTCname: uming.ttc(0)

Name: UMingTW
Class: CNS
Provides(70): MSung-Light
Provides(70): MSung-Medium
TTCname: uming.ttc(2)

Name: UKaiCN
Class: GB
Provides(70): STKaiti-Regular
Provides(70): STHeiti-Regular
Provides(70): STHeiti-Light
TTCname: ukai.ttc(0)

Name: UKaiTW
Class: CNS
Provides(70): MKai-Medium
Provides(70): MHei-Medium
TTCname: ukai.ttc(2)

# CJK-Unifonts old ttf edition (free)

# CNS
Name: ShanHeiSun-Uni
Class: CNS
Provides(90): MSung-Light
Provides(90): MSung-Medium
TTFname: uming.ttf

# GB
Name: ShanHeiSun-Uni-Adobe-GB1
Class: GB
Provides(90): STSong-Light
Provides(90): STSong-Regular
Provides(90): STFangsong-Light
Provides(90): STFangsong-Regular
TTFname: uming.ttf

# CNS
Name: ZenKai-Uni
Class: CNS
Provides(90): MKai-Medium
Provides(90): MHei-Medium
TTFname: ukai.ttf

# GB
Name: ZenKai-Uni-Adobe-GB1
Class: GB
Provides(90): STKaiti-Regular
Provides(90): STHeiti-Regular
Provides(90): STHeiti-Light
TTFname: ukai.ttf

# WenQuanYi (free)

# GB
Name: WenQuanYiMicroHei
Class: GB
TTCname(10): wqy-microhei.ttc(0)

# CNS
Name: WenQuanYiMicroHei-Adobe-CNS1
Class: CNS
TTCname(10): wqy-microhei.ttc(0)

# GB
Name: WenQuanYiMicroHeiMono
Class: GB
TTCname(10): wqy-microhei.ttc(1)

# CNS
Name: WenQuanYiMicroHeiMono-Adobe-CNS1
Class: CNS
TTCname(10): wqy-microhei.ttc(1)

# GB
Name: WenQuanYiZenHei
Class: GB
TTCname(10): wqy-zenhei.ttc(0)
TTFname(20): wqy-zenhei.ttf

# CNS
Name: WenQuanYiZenHei-Adobe-CNS1
Class: CNS
TTCname(10): wqy-zenhei.ttc(0)
TTFname(20): wqy-zenhei.ttf

# GB
Name: WenQuanYiZenHeiMono
Class: GB
TTCname(10): wqy-zenhei.ttc(1)

# CNS:
Name: WenQuanYiZenHeiMono-Adobe-CNS1
Class: CNS
TTCname(10): wqy-zenhei.ttc(1)

# GB
Name: WenQuanYiZenHeiSharp
Class: GB
TTCname(10): wqy-zenhei.ttc(2)

# CNS
Name: WenQuanYiZenHeiSharp-Adobe-CNS1
Class: CNS
TTCname(10): wqy-zenhei.ttc(2)

# cwTeX (free)

Name: cwTeXMing
Class: CNS
TTFname: cwming.ttf

Name: cwTeXHeiBold
Class: CNS
TTFname: cwheib.ttf

Name: cwTeXKai
Class: CNS
TTFname: cwkai.ttf

Name: cwTeXYen
Class: CNS
TTFname: cwyen.ttf

Name: cwTeXFangSong
Class: CNS
TTFname: cwfs.ttf

#
# KOREAN FONTS
#

# Solaris-hanyang (Solaris 10, 11)

Name: Myeongjo
Class: Korea
Provides(40): HYSMyeongJo-Medium
TTFname: h2mjsm.ttf

Name: Gothic
Class: Korea
Provides(40): HYGoThic-Medium
TTFname: h2gtrm.ttf

Name: RoundedGothic
Class: Korea
Provides(40): HYRGoThic-Medium
TTFname: h2drrm.ttf

Name: Haeseo
Class: Korea
TTFname: h2hsrm.ttf

Name: SunDotum
Class: Korea
TTFname: sundotump.ttf

Name: SunDotumChe
Class: Korea
TTFname: sundotumf.ttf

# Baekmuk (free)
# This is a special case, because "batang.ttf" in baekmuk and
# "Batang.ttf" in Microsoft Mac Office font share the same filename;
# symlink name should be "Baekmuk-Batang.ttf"
# similar for "Gulim.ttf" -- HY (2016/09/29)

Name: Baekmuk-Batang
Class: Korea
Provides(70): HYSMyeongJo-Medium
TTFname(20): batang.ttf
TTFname(10): Baekmuk-Batang.ttf

Name: Baekmuk-Dotum
Class: Korea
Provides(70): HYGoThic-Medium
TTFname(20): dotum.ttf
TTFname(10): Baekmuk-Dotum.ttf

Name: Baekmuk-Gulim
Class: Korea
Provides(70): HYRGoThic-Medium
TTFname(20): gulim.ttf
TTFname(10): Baekmuk-Gulim.ttf

Name: Baekmuk-Headline
Class: Korea
TTFname(20): hline.ttf
TTFname(10): Baekmuk-Headline.ttf

# Unfonts-core (free)

Name: UnBatang
Class: Korea
Provides(60): HYSMyeongJo-Medium
TTFname: UnBatang.ttf

Name: UnBatang-Bold
Class: Korea
TTFname: UnBatangBold.ttf

Name: UnDotum
Class: Korea
Provides(60): HYGoThic-Medium
TTFname: UnDotum.ttf

Name: UnDotum-Bold
Class: Korea
TTFname: UnDotumBold.ttf

Name: UnDinaru
Class: Korea
Provides(60): HYRGoThic-Medium
TTFname: UnDinaru.ttf

Name: UnDinaru-Bold
Class: Korea
TTFname: UnDinaruBold.ttf

Name: UnDinaru-Light
Class: Korea
TTFname: UnDinaruLight.ttf

Name: UnGraphic
Class: Korea
TTFname: UnGraphic.ttf

Name: UnGraphic-Bold
Class: Korea
TTFname: UnGraphicBold.ttf

Name: UnGungseo
Class: Korea
TTFname: UnGungseo.ttf

Name: UnPilgi
Class: Korea
TTFname: UnPilgi.ttf

Name: UnPilgi-Bold
Class: Korea
TTFname: UnPilgiBold.ttf

# Unfonts-extra (free)

Name: UnBom
Class: Korea
TTFname: UnBom.ttf

Name: UnPen
Class: Korea
TTFname: UnPen.ttf

Name: UnPenheulim
Class: Korea
TTFname: UnPenheulim.ttf

Name: UnPilgia
Class: Korea
TTFname: UnPilgia.ttf

Name: UnShinmun
Class: Korea
TTFname: UnShinmun.ttf

Name: UnVada
Class: Korea
TTFname: UnVada.ttf

Name: UnYetgul
Class: Korea
TTFname: UnYetgul.ttf

Name: UnTaza
Class: Korea
TTFname: UnTaza.ttf

# UnJamo... family has proportional metrics
Name: UnJamoBatang
Class: Korea
TTFname: UnJamoBatang.ttf

Name: UnJamoDotum
Class: Korea
TTFname: UnJamoDotum.ttf

Name: UnJamoNovel
Class: Korea
TTFname: UnJamoNovel.ttf

Name: UnJamoSora
Class: Korea
TTFname: UnJamoSora.ttf

# Nanum (free - TTF files) and Nanum OS X (free - TTC files)
# note that all fonts have narrow metrics

Name: NanumMyeongjo
Class: Korea
TTFname(10): NanumMyeongjo.ttf
TTCname(20): NanumMyeongjo.ttc(0)

Name: NanumMyeongjoBold
Class: Korea
TTFname(10): NanumMyeongjoBold.ttf
TTCname(20): NanumMyeongjo.ttc(1)

Name: NanumMyeongjoExtraBold
Class: Korea
TTFname(10): NanumMyeongjoExtraBold.ttf
TTCname(20): NanumMyeongjo.ttc(2)

Name: NanumGothic
Class: Korea
TTFname(10): NanumGothic.ttf
TTCname(20): NanumGothic.ttc(0)

Name: NanumGothicBold
Class: Korea
TTFname(10): NanumGothicBold.ttf
TTCname(20): NanumGothic.ttc(1)

Name: NanumGothicExtraBold
Class: Korea
TTFname(10): NanumGothicExtraBold.ttf
TTCname(20): NanumGothic.ttc(2)

Name: NanumGothicLight
Class: Korea
TTFname(10): NanumGothicLight.ttf

Name: NanumBarunGothic
Class: Korea
TTFname(10): NanumBarunGothic.ttf

Name: NanumBarunGothicBold
Class: Korea
TTFname(10): NanumBarunGothicBold.ttf

Name: NanumBarunGothicLight
Class: Korea
TTFname(10): NanumBarunGothicLight.ttf

Name: NanumBarunGothicUltraLight
Class: Korea
TTFname(10): NanumBarunGothicUltraLight.ttf

Name: NanumBarunpen
Class: Korea
TTFname(10): NanumBarunpenR.ttf

Name: NanumBarunpen-Bold
Class: Korea
TTFname(10): NanumBarunpenB.ttf

Name: NanumBrush
Class: Korea
TTFname(10): NanumBrush.ttf
TTCname(20): NanumScript.ttc(0)

Name: NanumPen
Class: Korea
TTFname(10): NanumPen.ttf
TTCname(20): NanumScript.ttc(1)

# Design font by Ho-Seok Ee, aka. "ALee's font" (free)

Name: Bandal
Class: Korea
TTFname: Bandal.ttf

Name: Bangwool
Class: Korea
TTFname: Bangwool.ttf

Name: Eunjin
Class: Korea
TTFname: Eunjin.ttf

Name: EunjinNakseo
Class: Korea
TTFname: EunjinNakseo.ttf

Name: Guseul
Class: Korea
TTFname: Guseul.ttf

# Woowa Brothers (free)

Name: BMHANNA
Class: Korea
TTFname: BM-HANNA.ttf

# Hancom HCR (free)
# note that all fonts have narrow metrics

Name: HCRBatang
Class: Korea
TTFname: HANBatang.ttf

Name: HCRBatang-Bold
Class: Korea
TTFname: HANBatangB.ttf

Name: HCRDotum
Class: Korea
TTFname: HANDotum.ttf

Name: HCRDotum-Bold
Class: Korea
TTFname: HANDotumB.ttf

# Apple

Name: AppleMyungjo
Class: Korea
#Provides(??): HYSMyeongJo-Medium # fails
TTFname: AppleMyungjo.ttf

Name: AppleGothic
Class: Korea
#Provides(??): HYGoThic-Medium # fails
#Provides(??): HYRGoThic-Medium # fails
TTFname: AppleGothic.ttf

Name: AppleSDGothicNeo-Regular
Class: Korea
OTFname(10): AppleSDGothicNeo-Regular.otf
OTCname(20): AppleSDGothicNeo.ttc(0)

Name: AppleSDGothicNeo-Medium
Class: Korea
OTFname(10): AppleSDGothicNeo-Medium.otf
OTCname(20): AppleSDGothicNeo.ttc(2)

Name: AppleSDGothicNeo-SemiBold
Class: Korea
OTFname(10): AppleSDGothicNeo-SemiBold.otf
OTCname(20): AppleSDGothicNeo.ttc(4)

Name: AppleSDGothicNeo-Bold
Class: Korea
OTFname(10): AppleSDGothicNeo-Bold.otf
OTCname(20): AppleSDGothicNeo.ttc(6)

Name: AppleSDGothicNeo-Light
Class: Korea
OTFname(10): AppleSDGothicNeo-Light.otf
OTCname(20): AppleSDGothicNeo.ttc(8)

Name: AppleSDGothicNeo-Thin
Class: Korea
OTFname(10): AppleSDGothicNeo-Thin.otf
OTCname(20): AppleSDGothicNeo.ttc(10)

Name: AppleSDGothicNeo-UltraLight
Class: Korea
OTFname(10): AppleSDGothicNeo-UltraLight.otf
OTCname(20): AppleSDGothicNeo.ttc(12)

Name: AppleSDGothicNeo-ExtraBold
Class: Korea
OTFname(10): AppleSDGothicNeo-ExtraBold.otf
OTCname(20): AppleSDGothicNeo.ttc(14)

Name: AppleSDGothicNeo-Heavy
Class: Korea
OTFname(10): AppleSDGothicNeo-Heavy.otf
OTCname(20): AppleSDGothicNeo.ttc(16)

Name: JCsmPC
Class: Korea
TTFname: PCmyoungjo.ttf

Name: JCfg
Class: Korea
TTFname: Pilgiche.ttf

Name: JCkg
Class: Korea
TTFname: Gungseouche.ttf

Name: JCHEadA
Class: Korea
TTFname: HeadlineA.ttf

# Adobe korean fonts

Name: AdobeMyungjoStd-Medium
Class: Korea
Provides(30): HYSMyeongJo-Medium
OTFname: AdobeMyungjoStd-Medium.otf

Name: AdobeGothicStd-Bold
Class: Korea
Provides(30): HYGoThic-Medium
Provides(80): HYRGoThic-Medium
OTFname: AdobeGothicStd-Bold.otf

Name: AdobeGothicStd-Light
Class: Korea
OTFname: AdobeGothicStd-Light.otf

#
# Microsoft Windows, Windows/Mac Office fonts
#

# korea

Name: Batang
Class: Korea
TTFname(50): Batang.ttf
TTCname(20): batang.ttc(0)

Name: BatangChe
Class: Korea
Provides(50): HYSMyeongJo-Medium
TTCname(20): batang.ttc(1)

Name: Dotum
Class: Korea
TTCname(20): gulim.ttc(2)

Name: DotumChe
Class: Korea
Provides(50): HYGoThic-Medium
TTCname(20): gulim.ttc(3)

Name: Gulim
Class: Korea
TTFname(50): Gulim.ttf
TTCname(20): gulim.ttc(0)

Name: GulimChe
Class: Korea
Provides(50): HYRGoThic-Medium
Provides(90): HYGoThic-Medium
TTCname(20): gulim.ttc(1)

Name: Gungsuh
Class: Korea
TTCname(20): batang.ttc(2)

Name: GungsuhChe
Class: Korea
TTCname(20): batang.ttc(3)

Name: MalgunGothicRegular
Class: Korea
TTFname: malgun.ttf

Name: MalgunGothicBold
Class: Korea
TTFname: malgunbd.ttf

Name: MalgunGothic-Semilight
Class: Korea
TTFname: malgunsl.ttf

# simplified chinese

Name: SimHei
Class: GB
Provides(60): STHeiti-Regular
Provides(60): STHeiti-Light
TTFname(50): SimHei.ttf
TTFname(20): simhei.ttf

Name: SimSun
Class: GB
Provides(60): STSong-Light
Provides(60): STSong-Regular
TTFname(50): SimSun.ttf
TTFname(21): simsun.ttf
TTCname(20): simsun.ttc(0)

Name: NSimSun
Class: GB
TTCname(20): simsun.ttc(1)

Name: KaiTi
Class: GB
Provides(60): STKaiti-Regular
TTFname(40): Kaiti.ttf
TTFname(20): simkai.ttf

Name: FangSong
Class: GB
Provides(60): STFangsong-Light
Provides(60): STFangsong-Regular
TTFname(40): Fangsong.ttf
TTFname(20): simfang.ttf

Name: MicrosoftYaHei
Class: GB
TTFname(20): msyh.ttf
TTCname(30): msyh.ttc(0)

Name: MicrosoftYaHei-Bold
Class: GB
TTFname(20): msyhbd.ttf
TTCname(30): msyhbd.ttc(0)

Name: MicrosoftYaHeiLight
Class: GB
TTFname(20): msyhl.ttf
TTCname(30): msyhl.ttc(0)

Name: DengXian-Regular
Class: GB
TTFname: Deng.ttf

Name: DengXian-Bold
Class: GB
TTFname: Dengb.ttf

Name: DengXian-Light
Class: GB
TTFname: Dengl.ttf

# traditional chinese

Name: MingLiU
Class: CNS
Provides(60): MSung-Medium
Provides(60): MSung-Light
TTFname(50): MingLiU.ttf
TTCname(20): mingliu.ttc(0)

Name: PMingLiU
Class: CNS
TTFname(50): PMingLiU.ttf
TTCname(20): mingliu.ttc(1)

Name: DFKaiShu-SB-Estd-BF
Class: CNS
Provides(60): MKai-Medium
TTFname(50): BiauKai.ttf
TTFname(20): kaiu.ttf

Name: MicrosoftJhengHeiRegular
Class: CNS
Provides(60): MHei-Medium
TTFname(40): MSJH.ttf
TTFname(20): msjh.ttf
TTCname(30): msjh.ttc(0)

Name: MicrosoftJhengHeiBold
Class: CNS
TTFname(40): MSJHBD.ttf
TTFname(20): msjhbd.ttf
TTCname(30): msjhbd.ttc(0)

Name: MicrosoftJhengHeiLight
Class: CNS
TTCname(30): msjhl.ttc(0)

Name: MicrosoftMHei
Class: CNS
Provides(65): MHei-Medium
TTFname(10): MSMHei.ttf

Name: MicrosoftMHei-Bold
Class: CNS
TTFname(10): MSMHei-Bold.ttf

# japanese

Name: MS-Gothic
Class: Japan
Provides(95): GothicBBB-Medium
Provides(95): GothicBBBPro-Medium
Provides(95): HiraKakuProN-W3
Provides(95): HiraKakuPro-W3
Provides(95): FutoGoB101-Bold
Provides(95): FutoGoB101Pro-Bold
Provides(95): HiraKakuProN-W6
Provides(95): HiraKakuPro-W6
Provides(95): MidashiGo-MB31
Provides(95): MidashiGoPro-MB31
Provides(95): HiraKakuStdN-W8
Provides(95): HiraKakuStd-W8
Provides(95): Jun101-Light
Provides(95): Jun101Pro-Light
Provides(95): HiraMaruProN-W4
Provides(95): HiraMaruPro-W4
TTFname(50): MS Gothic.ttf
TTFname(30): MS-Gothic.ttf
TTCname(20): msgothic.ttc(0)

Name: MS-Mincho
Class: Japan
Provides(95): Ryumin-Light
Provides(95): RyuminPro-Light
Provides(95): HiraMinProN-W3
Provides(95): HiraMinPro-W3
Provides(95): FutoMinA101-Bold
Provides(95): FutoMinA101Pro-Bold
Provides(95): HiraMinProN-W6
Provides(95): HiraMinPro-W6
TTFname(50): MS Mincho.ttf
TTFname(30): MS-Mincho.ttf
TTCname(20): msmincho.ttc(0)

Name: MS-PGothic
Class: Japan
TTFname(50): MS PGothic.ttf
TTFname(30): MS-PGothic.ttf
TTCname(20): msgothic.ttc(1)

Name: MS-PMincho
Class: Japan
TTFname(50): MS PMincho.ttf
TTFname(30): MS-PMincho.ttf
TTCname(20): msmincho.ttc(1)

Name: MS-UIGothic
Class: Japan
TTCname(20): msgothic.ttc(2)

Name: Meiryo
Class: Japan
TTFname(50): Meiryo.ttf
TTCname(20): meiryo.ttc(0)

Name: Meiryo-Bold
Class: Japan
TTFname(50): Meiryo Bold.ttf
TTFname(40): MeiryoBold.ttf
TTFname(30): Meiryo-Bold.ttf
TTCname(20): meiryob.ttc(0)

Name: Meiryo-BoldItalic
Class: Japan
TTFname(50): Meiryo Bold Italic.ttf
TTFname(40): MeiryoBoldItalic.ttf
TTFname(30): Meiryo-BoldItalic.ttf
TTCname(20): meiryob.ttc(1)

Name: Meiryo-Italic
Class: Japan
TTFname(50): Meiryo Italic.ttf
TTFname(40): MeiryoItalic.ttf
TTFname(30): Meiryo-Italic.ttf
TTCname(20): meiryo.ttc(1)

Name: MeiryoUI
Class: Japan
TTCname(20): meiryo.ttc(2)

Name: MeiryoUI-Bold
Class: Japan
TTCname(20): meiryob.ttc(2)

Name: MeiryoUI-BoldItalic
Class: Japan
TTCname(20): meiryob.ttc(3)

Name: MeiryoUI-Italic
Class: Japan
TTCname(20): meiryo.ttc(3)

Name: HGGothicE
Class: Japan
TTCname(50): HGRGE.ttc(0)
TTCname(20): HGRGE.TTC(0)

Name: HGPGothicE
Class: Japan
TTCname(50): HGRGE.ttc(1)
TTCname(20): HGRGE.TTC(1)

Name: HGSGothicE
Class: Japan
TTCname(50): HGRGE.ttc(2)
TTCname(20): HGRGE.TTC(2)

Name: HGGothicM
Class: Japan
TTCname(20): HGRGM.TTC(0)

Name: HGPGothicM
Class: Japan
TTCname(20): HGRGM.TTC(1)

Name: HGSGothicM
Class: Japan
TTCname(20): HGRGM.TTC(2)

Name: HGMinchoE
Class: Japan
TTCname(50): HGRME.ttc(0)
TTCname(20): HGRME.TTC(0)

Name: HGPMinchoE
Class: Japan
TTCname(50): HGRME.ttc(1)
TTCname(20): HGRME.TTC(2)

Name: HGSMinchoE
Class: Japan
TTCname(50): HGRME.ttc(2)
TTCname(20): HGRME.TTC(2)

Name: HGMinchoB
Class: Japan
TTCname(20): HGRMB.TTC(0)

Name: HGPMinchoB
Class: Japan
TTCname(20): HGRMB.TTC(1)

Name: HGSMinchoB
Class: Japan
TTCname(20): HGRMB.TTC(2)

Name: HGSoeiKakugothicUB
Class: Japan
TTCname(50): HGRSGU.ttc(0)
TTCname(20): HGRSGU.TTC(0)

Name: HGPSoeiKakugothicUB
Class: Japan
TTCname(50): HGRSGU.ttc(1)
TTCname(20): HGRSGU.TTC(1)

Name: HGSSoeiKakugothicUB
Class: Japan
TTCname(50): HGRSGU.ttc(2)
TTCname(20): HGRSGU.TTC(2)

Name: HGSoeiKakupoptai
Class: Japan
TTCname(20): HGRPP1.TTC(0)

Name: HGPSoeiKakupoptai
Class: Japan
TTCname(20): HGRPP1.TTC(1)

Name: HGSSoeiKakupoptai
Class: Japan
TTCname(20): HGRPP1.TTC(2)

Name: HGSoeiPresenceEB
Class: Japan
TTCname(20): HGRPRE.TTC(0)

Name: HGPSoeiPresenceEB
Class: Japan
TTCname(20): HGRPRE.TTC(1)

Name: HGSSoeiPresenceEB
Class: Japan
TTCname(20): HGRPRE.TTC(2)

Name: HGKyokashotai
Class: Japan
TTCname(20): HGRKK.TTC(0)

Name: HGPKyokashotai
Class: Japan
TTCname(20): HGRKK.TTC(1)

Name: HGSKyokashotai
Class: Japan
TTCname(20): HGRKK.TTC(2)

Name: HGGyoshotai
Class: Japan
TTCname(20): HGRGY.TTC(0)

Name: HGPGyoshotai
Class: Japan
TTCname(20): HGRGY.TTC(1)

Name: HGSGyoshotai
Class: Japan
TTCname(20): HGRGY.TTC(2)

Name: HGMaruGothicMPRO
Class: Japan
TTFname(40): HGRSMP.ttf
TTFname(20): HGRSMP.TTF

Name: HGSeikaishotaiPRO
Class: Japan
TTFname(20): HGRSKP.TTF


### Local Variables:
### perl-indent-level: 2
### tab-width: 2
### indent-tabs-mode: nil
### End:
# vim: set tabstop=2 expandtab autoindent:
