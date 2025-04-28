#!/bin/sh

# ubuntu
# gcc -shared -o mykfn.so -O2 mykfn.c

# openSuse
# sudo zypper --no-refresh install -y lua53-devel 

gcc -shared -o mykfn.so -O2 mykfn.c -I/usr/include/lua5.3 -fpic
