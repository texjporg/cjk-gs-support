External Database for cjk-gs-integrate
=============================================

Due to frequent incompatible changes in font file names by Apple,
the built-in database in cjk-gs-integrate doesn't support
OS X 10.11 El Capitan or later versions.
Here we provide additional database for macOS-specific font files.

Usage
-----

First, download the database file (`*.dat`) which is suitable for
your OS version.
You don't need to install the database file, but you can place it
under `$TEXMF/fonts/misc/cjk-gs-integrate` if you like.

If you are using macOS 10.13 High Sierra, execute

`````
[perl] cjk-gs-integrate[.pl] --fontdef-add=cjk-gs-integrate-highsierra.dat
`````

For OS X 10.11 El Capitan, use `cjk-gs-integrate-elcapitan.dat`.
For macOS 10.12 Sierra, use `cjk-gs-integrate-sierra.dat`.

Authors, Contributors, and Copyright
------------------------------------

Maintained by Japanese TeX Development Community. For development, see
  https://github.com/texjporg/cjk-gs-support

The script is licensed under GNU General Public License Version 3 or later.
The contained font data is not copyrightable.
