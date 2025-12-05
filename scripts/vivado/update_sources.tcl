set script_dir [file dirname [info script]]
set repo_root [file normalize [file join $script_dir .. ..]]
set project_path [file join $repo_root lab4_pcpi lab4_pcpi.xpr]

proc ensure_file_in_set {fileset path type} {
    if {![file exists $path]} {
        puts "WARNING: Missing file $path"
        return
    }
    set existing [get_files -quiet $path]
    if {[llength $existing] == 0} {
        add_files -norecurse -fileset $fileset $path
        set existing [get_files $path]
    }
    if {$type ne ""} {
        set_property file_type $type $existing
    }
}

open_project $project_path

set rtl_files [list \
    [file join $repo_root rtl unified_pcpi_module.sv] \
    [file join $repo_root rtl decoder_load_store_shift.sv] \
    [file join $repo_root rtl load_store_unit.sv] \
    [file join $repo_root rtl shifter_unit.sv]]

foreach f $rtl_files {
    ensure_file_in_set sources_1 $f SystemVerilog
}

set sim_files [list [file join $repo_root sim tb_unified_pcpi.sv]]
foreach f $sim_files {
    ensure_file_in_set sim_1 $f SystemVerilog
}

set fw_hex [file join $repo_root firmware firmware.hex]
if {[file exists $fw_hex]} {
    ensure_file_in_set sources_1 $fw_hex ""
}

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

close_project
