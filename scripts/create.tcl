# create.tcl - builds the Lab 3 Vivado project (modeled on Nanas's multiplier_example/scripts/create.tcl)
# Written by Claude (Anthropic) - cited in README.md
# Run from the repo folder:   vivado -mode batch -source scripts/create.tcl
set proj_name sc_fifo_proj
set current_dir [file normalize [file dirname [info script]]]
set repo_dir [file dirname $current_dir]
set proj_dir [file join $repo_dir proj]

set input_data_path [file join $repo_dir sim input_data.txt]
if {![file exists $input_data_path]} {
    error "sim/input_data.txt not found at $input_data_path. Run scripts/generate_fifo_data.py first."
}
if {[file exists $proj_dir]} {
    error "proj/ already exists at $proj_dir. Remove it before re-running this script."
}

# Zybo Z7-10
create_project $proj_name $proj_dir -part xc7z010clg400-1
set_property target_language Verilog [current_project]
set board_part [lindex [get_board_parts -quiet "digilentinc.com:zybo-z7-10:part0:*"] 0]
if {$board_part ne ""} {
    set_property board_part $board_part [current_project]
}

# design: src/sc_fifo.v
add_files -norecurse [glob -nocomplain [file join $repo_dir src *.v]]
set_property top sc_fifo [current_fileset]

# testbench: sim/tb_sc_fifo.v
add_files -fileset sim_1 -norecurse [glob -nocomplain [file join $repo_dir sim *.v]]
set_property top tb_sc_fifo [get_filesets sim_1]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

# put the Python data where the simulator looks for it ($readmemh)
set sim_run_dir [file join $proj_dir "$proj_name.sim" sim_1 behav xsim]
file mkdir $sim_run_dir
file copy -force $input_data_path $sim_run_dir
