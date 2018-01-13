External Database for cjk-gs-integrate
=============================================

Due to frequent incompatible changes in font file names by Apple,
the built-in database in cjk-gs-integrate doesn't support
OS X 10.8 Mountain Lion or later versions. Support for these
releases are provided in additional databases included in the
current package.

Usage
-----

Either install `cjk-gs-integrate-macos` from 
[TLContrib](https://contrib.texlive.info) or download the 
required database files directly from the 
[GitHub account](https://github.com/texjporg/cjk-gs-support).

We provide the following additional databases:

- for Mountain Lion (10.8):
  [cjkgs-macos-mountainlion.dat](https://raw.githubusercontent.com/texjporg/cjk-gs-support/master/cjkgs-macos-mountainlion.dat)
- for Mavericks (10.9) and Yosemite (10.10):
  [cjkgs-macos-mavericks.dat](https://raw.githubusercontent.com/texjporg/cjk-gs-support/master/cjkgs-macos-mavericks.dat)
- for El Capitan (10.11):
  [cjkgs-macos-elcapitan.dat](https://raw.githubusercontent.com/texjporg/cjk-gs-support/master/cjkgs-macos-elcapitan.dat)
- for Sierra (10.12):
  [cjkgs-macos-sierra.dat](https://raw.githubusercontent.com/texjporg/cjk-gs-support/master/cjkgs-macos-sierra.dat)
- for High Sierra (10.13):
  [cjkgs-macos-highsierra.dat](https://raw.githubusercontent.com/texjporg/cjk-gs-support/master/cjkgs-macos-highsierra.dat)

Download the database file (`*.dat`) which is suitable for
your OS version. Either place it in the current working directory
or into the directory `$TEXMF/fonts/misc/cjk-gs-integrate` where
`$TEXMF` is one of the TEXMF trees/.

Then execute the script in the usual way (see main documentation) and add
the option `--fontdef-add`. For macOS 10.13 High Sierra this would be:

`````
cjk-gs-integrate[.pl] --fontdef-add=cjkgs-macos-highsierra.dat
`````

For macOS 10.12 Sierra, use `cjkgs-macos-sierra.dat`.
For OS X 10.11 El Capitan, use `cjkgs-macos-elcapitan.dat`.

We also provide a wrapper `cjk-gs-integrate-macos.pl`, which detects your
macOS version and use the suitable database:

`````
cjk-gs-integrate-macos[.pl]
`````

Authors, Contributors, and Copyright
------------------------------------

Maintained by Japanese TeX Development Community. For development, see
  https://github.com/texjporg/cjk-gs-support

The script is licensed under GNU General Public License Version 3 or later.
The contained font data is not copyrightable.

