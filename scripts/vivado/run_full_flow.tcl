set script_dir [file dirname [info script]]
set repo_root [file normalize [file join $script_dir .. ..]]
set project_path [file join $repo_root lab4_pcpi lab4_pcpi.xpr]

open_project $project_path
reset_run synth_1
launch_runs synth_1 -jobs 4
wait_on_run synth_1
reset_run impl_1
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1
close_project
