@echo off
set xv_path=D:\\DevelProgs\\Xilinx\\Vivado\\2014.4\\bin
call %xv_path%/xelab  -wto 46700780225a49dd98a5cc566ca5cfa8 -m64 --debug typical --relax -L xil_defaultlib -L secureip --snapshot fmc_adapter_idelay_behav xil_defaultlib.fmc_adapter_idelay -log elaborate.log
if "%errorlevel%"=="0" goto SUCCESS
if "%errorlevel%"=="1" goto END
:END
exit 1
:SUCCESS
exit 0
