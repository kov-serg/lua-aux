#!/bin/sh

# ffmpeg -y -v 0 -i f1655_AlissaFoxy_01.webm -q:v 6 2.ogv
# -c:v libtheora -q:v 7 -c:a libvorbis -q:a 4 output.ogv
# ffmpeg -y -loglevel warning -hide_banner -stats -vcodec libvpx-vp9 -i f1655_AlissaFoxy_01.webm -c:v libtheora -q:v 6 1.ogv

ffmpeg -y -loglevel warning -hide_banner -stats \
-vcodec libvpx-vp9 -i f1655_AlissaFoxy_01.webm \
-vf "split [a], pad=iw*2:ih [b], [a] alphaextract, [b] overlay=w" \
-c:v libtheora -q:v 6 girl.ogv
