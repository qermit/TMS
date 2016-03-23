# 
# Synthesis run script generated by Vivado
# 

set_param gui.test TreeTableDev
debug::add_scope template.lib 1
set_msg_config -id {HDL 9-1061} -limit 100000
set_msg_config -id {HDL 9-1654} -limit 100000

create_project -in_memory -part xc7vx485tffg1157-1
set_param project.compositeFile.enableAutoGeneration 0
set_param synth.vivado.isSynthRun true
set_msg_config -id {IP_Flow 19-2162} -severity warning -new_severity info
set_property webtalk.parent_dir D:/Devel/projekty/TMS/lnls_out/lnls_bpm/lnls_bpm.cache/wt [current_project]
set_property parent.project_path D:/Devel/projekty/TMS/lnls_out/lnls_bpm/lnls_bpm.xpr [current_project]
set_property default_lib xil_defaultlib [current_project]
set_property target_language VHDL [current_project]
read_ip D:/Devel/projekty/TMS/lnls_out/lnls_bpm/lnls_bpm.srcs/sources_1/ip/vio_boot/vio_boot.xci
set_property is_locked true [get_files D:/Devel/projekty/TMS/lnls_out/lnls_bpm/lnls_bpm.srcs/sources_1/ip/vio_boot/vio_boot.xci]

catch { write_hwdef -file vio_boot.hwdef }
synth_design -top vio_boot -part xc7vx485tffg1157-1 -mode out_of_context
rename_ref -prefix_all vio_boot_
write_checkpoint -noxdef vio_boot.dcp
catch { report_utilization -file vio_boot_utilization_synth.rpt -pb vio_boot_utilization_synth.pb }
if { [catch {
  file copy -force D:/Devel/projekty/TMS/lnls_out/lnls_bpm/lnls_bpm.runs/vio_boot_synth_1/vio_boot.dcp D:/Devel/projekty/TMS/lnls_out/lnls_bpm/lnls_bpm.srcs/sources_1/ip/vio_boot/vio_boot.dcp
} _RESULT ] } { 
  error "ERROR: Unable to successfully create or copy the sub-design checkpoint file."
}
if { [catch {
  write_verilog -force -mode synth_stub D:/Devel/projekty/TMS/lnls_out/lnls_bpm/lnls_bpm.srcs/sources_1/ip/vio_boot/vio_boot_stub.v
} _RESULT ] } { 
  puts "CRITICAL WARNING: Unable to successfully create a Verilog synthesis stub for the sub-design. This may lead to errors in top level synthesis of the design. Error reported: $_RESULT"
}
if { [catch {
  write_vhdl -force -mode synth_stub D:/Devel/projekty/TMS/lnls_out/lnls_bpm/lnls_bpm.srcs/sources_1/ip/vio_boot/vio_boot_stub.vhdl
} _RESULT ] } { 
  puts "CRITICAL WARNING: Unable to successfully create a VHDL synthesis stub for the sub-design. This may lead to errors in top level synthesis of the design. Error reported: $_RESULT"
}
if { [catch {
  write_verilog -force -mode funcsim D:/Devel/projekty/TMS/lnls_out/lnls_bpm/lnls_bpm.srcs/sources_1/ip/vio_boot/vio_boot_funcsim.v
} _RESULT ] } { 
  puts "CRITICAL WARNING: Unable to successfully create the Verilog functional simulation sub-design file. Post-Synthesis Functional Simulation with this file may not be possible or may give incorrect results. Error reported: $_RESULT"
}
if { [catch {
  write_vhdl -force -mode funcsim D:/Devel/projekty/TMS/lnls_out/lnls_bpm/lnls_bpm.srcs/sources_1/ip/vio_boot/vio_boot_funcsim.vhdl
} _RESULT ] } { 
  puts "CRITICAL WARNING: Unable to successfully create the VHDL functional simulation sub-design file. Post-Synthesis Functional Simulation with this file may not be possible or may give incorrect results. Error reported: $_RESULT"
}
