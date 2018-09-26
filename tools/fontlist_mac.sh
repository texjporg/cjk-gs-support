#!/bin/sh
#
# Generate font list with file size on macOS.
# Note: require BSD du command (not GNU!)
# [DU - BSD General Commands Manual]
#  -a: Display an entry for each file in a file hierarchy.
#  -k: Display block counts in 1024-byte (1-Kbyte) blocks.
#
# Copyright 2017-2018 Hironobu Yamashita
# The script is released under the MIT License.
#
# Usage:
# [1] Edit directory list below
# [2] Run
#   $ ./fontlist_mac.sh >fontlist.txt
# [3] Edit the resulting fontlist.txt for input of fontquery.sh.

for d in \
  "/System/Library/Fonts" \
  "/Library/Fonts" \
  "/System/Library/Assets/com_apple_MobileAsset_Font3" \
  "/System/Library/Assets/com_apple_MobileAsset_Font4" \
  "/System/Library/Assets/com_apple_MobileAsset_Font5" \
  "/Library/Application Support/Apple/Fonts" \
  "/Applications/Microsoft Word.app/Contents/Resources/Fonts" \
  "/Applications/Microsoft Word.app/Contents/Resources/DFonts" \
  "/Applications/Microsoft Excel.app/Contents/Resources/Fonts" \
  "/Applications/Microsoft Excel.app/Contents/Resources/DFonts" \
  "/Applications/Microsoft PowerPoint.app/Contents/Resources/Fonts" \
  "/Applications/Microsoft PowerPoint.app/Contents/Resources/DFonts" \
  "/usr/share/fonts" \
  "$HOME/Library/fonts" \
; do
  if [ -d "$d" ]; then
    du -ak "$d" | grep -e .otf -e .ttf -e .ttc -e .OTF -e .TTF -e TTC
  fi
done
