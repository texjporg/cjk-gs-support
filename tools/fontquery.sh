#!/bin/sh
#
# Generate partial font database from a fontlist.
# Note: require fc-query command from fontconfig
#
# Copyright 2017-2018 Hironobu Yamashita
# The script is released under the MIT License.
#
# Usage:
# [1] Edit fontlist.txt (e.g. obtained from fontlist_mac.sh):
#   * Each line should contain only CJK font file path.
#     (from my experience, all CJK fonts have 500+ KB.
#      the minimum is Korean "HeadlineA.ttf" = size 504 from "du" output)
#     -- 要するに，fontlist_mac.sh で作った fontlist.txt の場合，
#        Excel に貼り付けてファイルサイズ（一行目）で降順にソートし，
#        ファイルサイズやファイル名で CJK らしいものを残してから
#        一行目のファイルサイズを削除すれば，ファイル名だけのリストになる。
#        経験上，韓国語の HeadlineA.ttf が du の出力サイズが 504 となって最小。
#        （ファイル名で CJK かどうかわからなければ，残しておいて良い。
#          その場合，少々 fc-query を呼び出す回数が増えて時間がかかるだけ。）
#     -- ただし，Excel を使う場合，最終的に保存する fontlist.txt を
#        改行コード CRLF でなく LF で保存することに注意。
# [2] Run
#   $ ./fontquery.sh fontlist.txt >fontdata.txt
# [3] Edit the resulting fontdata.txt and make cjkgs-*.dat.
#     -- 例えば
#          File: /System/Library/Fonts/STHeiti Medium.ttc
#          id 0
#          Name: STHeitiTC-Medium
#          Format: TrueType
#          Lang: aa|af|av|..|zh-cn|..|za
#          id 1
#          Name: STHeitiSC-Medium
#          Format: TrueType
#          Lang: aa|af|av|..|zh-cn|..|za
#        のように表示される。
#      (1) File: のところをベース名だけにして，
#         * Format: CFF ならば OTFname または OTCname
#         * Format: TrueType ならば TTFname または TTCname
#        とする。コレクションかどうかは拡張子 (.ttc) で判断。
#      (2) id はコレクションの場合のインデックス。
#         * OTCname / TTCname のファイル名末尾に
#             STHeiti Medium.ttc(0)
#           のように付ける。
#         * OTFname / TTFname では使わない。
#      (3) Name: はそのまま使える場合が多いが，
#         * OTF の場合で，かつ，リンクファイル名と PSName が違う場合
#        は，これを PSName: に使用し，Name: はリンクファイル名にする。
#      (4) Lang: の情報は Class: に用いる。
#         * |ja| があれば Japan
#         * |ko| があれば Korea
#         * |zh-cn| があれば GB
#         * |zh-tw| があれば CNS
#        となる場合が多いが，時々フォントによっては正しくない場合がある。

filename=$1
if [ -z "$filename" ]; then
   echo "Needs one filename argument."
   exit 1
fi
cat ${filename} | while read l; do
  echo "\nFile: $l"
  fc-query --format="Name: %{postscriptname}\nFormat: %{fontformat}\nLang: %{lang}\n" "$l"
done
