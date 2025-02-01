@echo off
rem http://download.savannah.gnu.org/releases/tinycc

tcc -o mykfn.dll -L. -llua\lua -Ilua\include -shared mykfn.c
