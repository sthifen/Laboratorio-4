set script_dir [file dirname [info script]]
set repo_root [file normalize [file join $script_dir .. ..]]
set project_path [file join $repo_root lab4_pcpi lab4_pcpi.xpr]

open_project $project_path
report_property [get_files {lab4_pcpi.srcs/sources_1/new/firmware.coe}]
report_property [get_files lab4_pcpi.srcs/sources_1/imports/lab4s/firmware.hex]
report_mem_init -cell {rom_inst/inst} -depth 40
close_project
