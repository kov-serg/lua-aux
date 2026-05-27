@echo off

ffmpeg -y -loglevel warning -hide_banner -stats ^
-vcodec libvpx-vp9 -i f1655_AlissaFoxy_01.webm ^
-vf "split [a], pad=iw*2:ih [b], [a] alphaextract, [b] overlay=w" ^
-c:v libtheora -q:v 6 girl.ogv
