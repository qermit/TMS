@echo off
set xv_path=D:\\DevelProgs\\Xilinx\\Vivado\\2014.4\\bin
call %xv_path%/xsim fmc_adapter_idelay_behav -key {Behavioral:sim_1:Functional:fmc_adapter_idelay} -tclbatch fmc_adapter_idelay.tcl -log simulate.log
if "%errorlevel%"=="0" goto SUCCESS
if "%errorlevel%"=="1" goto END
:END
exit 1
:SUCCESS
exit 0
