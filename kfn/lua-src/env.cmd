@echo off
if not [%tcc%]==[] goto :EOF
set tcc=%~dp0\..\..\tcc
set path=%tcc%;%path%
