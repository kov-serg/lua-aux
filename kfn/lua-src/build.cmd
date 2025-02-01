@echo off
call env
set src=lua-5.3.6\src
set dst=..\lua
mkdir %dst%
mkdir %dst%\include
copy %src%\lua.h %dst%%\include 
copy %src%\luaconf.h %dst%%\include 
copy %src%\lauxlib.h %dst%%\include 
tcc -o ..\lua\lua.dll -I%src% -shared -DLUA_BUILD_AS_DLL ^
    %src%\lauxlib.c ^
    %src%\lbaselib.c ^
    %src%\lbitlib.c ^
    %src%\lcorolib.c ^
    %src%\ldblib.c ^
    %src%\liolib.c ^
    %src%\lmathlib.c ^
    %src%\loslib.c ^
    %src%\lstrlib.c ^
    %src%\ltablib.c ^
    %src%\lutf8lib.c ^
    %src%\loadlib.c ^
    %src%\linit.c ^
    %src%\lapi.c ^
    %src%\lcode.c ^
    %src%\lctype.c ^
    %src%\ldebug.c ^
    %src%\ldo.c ^
    %src%\ldump.c ^
    %src%\lfunc.c ^
    %src%\lgc.c ^
    %src%\llex.c ^
    %src%\lmem.c ^
    %src%\lobject.c ^
    %src%\lopcodes.c ^
    %src%\lparser.c ^
    %src%\lstate.c ^
    %src%\lstring.c ^
    %src%\ltable.c ^
    %src%\ltm.c ^
    %src%\lundump.c ^
    %src%\lvm.c ^
    %src%\lzio.c

tcc -o ..\lua\lua.exe -I%src% -DLUA_BUILD_AS_DLL -L. ..\lua\lua.def ^
    %src%\lua.c
