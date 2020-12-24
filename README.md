Configuring Ghostscript for CJK CID/TTF fonts
=============================================

This script searches a list of directories for CJK fonts, and makes
them available to an installed Ghostscript. In the simplest case with
sufficient privileges, a run without arguments should effect in a
complete setup of Ghostscript.
Search is done using the kpathsea library, in particular `kpsewhich`
program. To run this script, you will need some TeX distribution in
your system.

Usage
-----

`````
[perl] cjk-gs-integrate[.pl] [OPTIONS]
`````

#### Options ####

`````
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
                           DIR/fonts/opentype/cjk-gs-integrate
                        and
                           DIR/fonts/truetype/cjk-gs-integrate
                        where DIR defaults to TEXMFLOCAL
  --otfps [DIR]         generate configuration file (psnames-for-otf) into
                           DIR/dvips/ps2otfps
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
`````

#### Command like options ####

`````
  --dump-data [FILE]    dump the set of font definitions which is currently
                        effective, where FILE (the dump output) defaults to
                        cjk-gs-integrate-data.dat; you can easily modify it,
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
`````

Operation
---------

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

How and which directories are searched
--------------------------------------

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

Output files
------------

If no output option is given, the program searches for a Ghostscript
interpreter 'gs' and determines its Resource directory. This might
fail, in which case one need to pass the output directory manually.

Since the program adds files and link to this directory, sufficient
permissions are necessary.

Aliases
-------

Aliases are managed via the Provides values in the font database.
At the moment entries for the basic font names for CJK fonts
are added:

Japanese:

    Ryumin-Light GothicBBB-Medium FutoMinA101-Bold FutoGoB101-Bold
    MidashiMin-MA31 MidashiGo-MB31 Jun101-Light

Korean:

    HYSMyeongJo-Medium HYGoThic-Medium HYRGoThic-Medium

Simplified Chinese:

    STSong-Light STSong-Regular STHeiti-Regular STHeiti-Light
    STKaiti-Regular STFangsong-Light STFangsong-Regular

Traditional Chinese:

    MSung-Light MSung-Medium MHei-Medium MKai-Medium

In addition, we also include provide entries for the OTF Morisawa names:

    RyuminPro-Light GothicBBBPro-Medium
    FutoMinA101Pro-Bold FutoGoB101Pro-Bold
    MidashiMinPro-MA31 MidashiGoPro-MB31 Jun101Pro-Light

The order is determined by the `Provides` setting in the font database.
That is, the first font found in this order will be used to provide the
alias if necessary.

For the Japanese fonts:
    Morisawa Pr6N, Morisawa, Hiragino ProN, Hiragino,
    Kozuka Pr6N, Kozuka ProVI, Kozuka Pro, Kozuka Std,
    HaranoAji, Yu OS X, Yu Win, MS,
    Moga-Mobo-ex, Moga-Mobo, IPAex, IPA, Ume

For the Korean fonts:
    (Hanyang,) Adobe, Solaris, MS, Unfonts, Baekmuk

For the Simplified Chinese:
    Adobe, Fandol, HaranoAji, Hiragino, Founder, MS,
    CJKUnifonts, Arphic, CJKUnifonts-ttf

For the Traditional Chinese:
    Adobe, HaranoAji, MS,
    CJKUnifonts, Arphic, CJKUnifonts-ttf

#### Overriding aliases ####

Using the command line option `--alias LL=RR` one can add arbitrary aliases,
or override ones selected by the program. For this to work the following
requirements of `LL` and `RR` must be fulfilled:
  * `LL` is not provided by a real font
  * `RR` is available either as real font, or as alias (indirect alias)

Authors, Contributors, and Copyright
------------------------------------

The script and its documentation was written by Norbert Preining, based
on research and work by Masamichi Hosoda, Yusuke Kuroki, Yusuke Terada,
Bruno Voisin, Hironobu Yamashita, Munehiro Yamamoto and the TeX Q&A wiki
page.

Maintained by Japanese TeX Development Community. For development, see
  https://github.com/texjporg/cjk-gs-support

The script is licensed under GNU General Public License Version 3 or later.
The contained font data is not copyrightable.

