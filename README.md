CID and TTF font setup tools for ghostscript
============================================

definition of CID fonts
-----------------------

needed:
* short definition file in Resource/Font/CIDFONT-CMAP
* link in Resource/CIDFont

questions:
* why does the auto-construction not work (Use.html 8.3)
	/CIDFont-CMap findfont
* why does explicite cid font substitution in cidfmap not work (Use.html 8.4)
	/CIDFont (/path/to/foo.otf) ;
  I would have expected that this defines a CID resource named CIDFont
  in the same way as Resource/CIDFont.
  But it does not work with the combination


definition of TTF fonts
-----------------------

needed:
* entry in cidfmap definition



Problems
--------

* ghostscript does not allow to change the CIDFont search path
	I faintly remember having seen some PS code that does that
	for the Resource directory



package ghostscript-cjk-integration (or similar)
================================================

aim
---
provide tools and commands to integrate available CJK fonts
into a present GhostScript (gs) installation.

principle operation of the main script
--------------------------------------
possible commands:
- list: only search for and list available fonts
- status: list the currently selected fonts
- sync(?): searches for local fonts and updates gs

The script when run would do the following in normal mode
- searches for all available fonts
	. in TEXMFDIST, TEXMFMAIN, TEXMFLOCAL
	. in system directories
- searches for an installed ghostscript and determines its Resource dir
  (can be overriden by command line option)
- creates the Font definition files for CID fonts based on the found fonts
  in Resource/Font, and adds a identifying header (for removal)
- symlinks the CID fonts to Resource/Font
- generates the cidfmap entries for the found TTF fonts in cidfmap.local

optionally
- tries to add (cidfmap.loca) .runlib... to the main cidfmap
  (if not there already)


multiple invocations
--------------------
This script can be run several times, in case new fonts are installed
into TEXMFLOCAL or font dirs.

If run a second time it does also:
- check all files in Resource/CIDFont that are links into TEXMF trees
  whether they got dangling (and remove them in this case)
  (don't do this for links to outside the TEXMF trees)
- check the Resource/Font files for the comment header of the script
  remove/sync with newly found fonts
- regenerate the cidfmap.local


generation of aliases
=====================

Japanese
--------
aliases for
	Ryumin-Light GothicBBB-Medium FutoMinA101-Bold 
	FutoGoB101-Bold Jun101-Light
	A-OTF-RyuminPro-Light A-OTF-GothicBBBPro-Medium 
	A-OTF-FutoMinA101Pro-Bold A-OTF-FutoGoB101Pro-Bold 
	A-OTF-Jun101Pro-Light
are *ONLY* generated when the original fonts are not found (morisawa).

(comment: probably needs some trickery in case partial fonts are found)


interoperation with kanji-config-updmap
=======================================

(open - not clear if this is an aim at all)

