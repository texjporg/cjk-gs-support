CID and TTF font setup tools for ghostscript
============================================

This script configures GhostScript for CJK CID/TTF fonts found
on the system.

Usage
-----

`````
[perl] cjk-gs-integrate[.pl] [OPTIONS]
`````

#### Options ####

`````
  -n, --dry-run         do not actually output anything
  -f, --fontdef FILE    specify alternate set of font definitions, if not
                        given, the built-in set is used
  -o, --output DIR      specifies the base output dir, if not provided,
                        the Resource directory of an install GhostScript
                        is searched and used.
  -a, --alias LL=RR     defines an alias, or overrides a given alias
                        illegal if LL is provided by a real font, or
                        RR is neither available as real font or alias
                        can be given multiple times
  -q, --quiet           be less verbose
  -d, --debug           output debug information, can be given multiple times
  -v, --version         outputs only the version information
  -h, --help            this help

`````

#### Command like options ####

`````
  --list-aliases        lists the aliases and their options, with the selected
                        option on top
  --list-fonts          lists the fonts found on the system
  --info                combines the above two information
`````


Operation:
----------

This script searches a list of directories (see below) for CJK fonts,
and makes them available to an installed GhostScript. In the simplest
case with sufficient privileges, a run without arguments should effect
in a complete setup of GhostScript.

For each found TrueType (TTF) font it creates a cidfmap entry in

    <Resource>/Init/cidfmap.local

and links the font to

    <Resource>/Font/

For each OTF font it creates a snippet in

    <Resource>/Font/

and links the font to 

    <Resource>/CIDFont

The `<Resource>` dir is either given by `-o`/`--output`, or otherwise searched
from an installed GhostScript (binary name is assumed to be 'gs').

Finally, it tries to add runlib call to

    <Resource>/Init/cidfmap

to load the cidfmap.local.

How and which directories are searched:
---------------------------------------

  Search is done using the kpathsea library, in particular using kpsewhich
  program. By default the following directories are searched:
  - all TEXMF trees
  - `/Library/Fonts` and `/System/Library/Fonts` (if available)
  - `c:/windows/fonts` (on Windows)
  - the directories in `OSFONTDIR` environment variable

In case you want to add some directories to the search path, adapt the
OSFONTDIR environment variable accordingly: Example:

`````
    OSFONTDIR="/usr/local/share/fonts/truetype//:/usr/local/share/fonts/opentype//" cjk-gs-integrate
`````

will result in fonts found in the above two given directories to be
searched in addition.

Output files:
-------------

  If no output option is given, the program searches for a GhostScript
  interpreter 'gs' and determines its Resource directory. This might
  fail, in which case one need to pass the output directory manually.

  Since the program adds files and link to this directory, sufficient
  permissions are necessary.

Aliases:
--------

Aliases are managed via the Provides values in the font database.
At the moment entries for the basic font names for CJK fonts
are added:

Japanese:

    Ryumin-Light GothicBBB-Medium FutoMinA101-Bold FutoGoB101-Bold Jun101-Light

Korean:

    HYGoThic-Medium HYSMyeongJo-Medium HYSMyeongJoStd-Medium

Chinese:

    MHei-Medium MKai-Medium MSungStd-Light 
    STHeiti-Light STHeiti-Regular STKaiti-Regular STSongStd-Light

In addition, we also includes provide entries for the OTF Morisawa names:

    A-OTF-RyuminPro-Light A-OTF-GothicBBBPro-Medium A-OTF-FutoMinA101Pro-Bold
    A-OTF-FutoGoB101Pro-Bold A-OTF-Jun101Pro-Light

The order is determined by the Provides setting in the font database,
and for the Japanese fonts it is currently:

    Morisawa Pr6, Morisawa, Hiragino ProN, Hiragino, 
    Yu OSX, Yu Win, Kozuka ProN, Kozuka, IPAex, IPA

That is, the first font found in this order will be used to provide the
alias if necessary.

#### Overriding aliases ####

Using the command line option `--alias LL=RR` one can add arbitrary aliases,
or override ones selected by the program. For this to work the following
requirements of `LL` and `RR` must be fulfilled:
  * `LL` is not provided by a real font
  * `RR` is available either as real font, or as alias (indirect alias)


Authors, Contributors, and Copyright:
-------------------------------------

The script and its documentation was written by Norbert Preining, based
on research and work by Yusuke Kuroki, Bruno Voisin, Munehiro Yamamoto
and the TeX Q&A wiki page.

The script is licensed under GNU General Public License Version 3 or later.
The contained font data is not copyrightable.


Questions and open problems
----------------------------

* why does the auto-construction not work (Use.html 8.3)
	/CIDFont-CMap findfont
* why does explicite cid font substitution in cidfmap not work (Use.html 8.4)
	/CIDFont (/path/to/foo.otf) ;
  I would have expected that this defines a CID resource named CIDFont
  in the same way as Resource/CIDFont.
  But it does not work with the combination
* ghostscript does not allow to change the CIDFont search path
	I faintly remember having seen some PS code that does that
	for the Resource directory


#### multiple invocations ####

This script can be run several times, in case new fonts are installed
into TEXMFLOCAL or font dirs.

If run a second time it does also:
- check all files in Resource/CIDFont that are links into TEXMF trees
  whether they got dangling (and remove them in this case)
  (don't do this for links to outside the TEXMF trees)
- check the Resource/Font files for the comment header of the script
  remove/sync with newly found fonts
- regenerate the cidfmap.local


#### interoperation with kanji-config-updmap ####

(open - not clear if this is an aim at all)

