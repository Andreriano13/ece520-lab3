# simulate.tcl - opens the project and runs the self-checking testbench
# (modeled on Nanas's multiplier_example/scripts/simulate.tcl)
# Written by Claude (Anthropic) - cited in README.md
# Run from the repo folder:   vivado -mode batch -source scripts/simulate.tcl
set current_dir [file normalize [file dirname [info script]]]
set repo_dir [file dirname $current_dir]
set proj_dir [file join $repo_dir proj]

set input_data_path [file join $repo_dir sim input_data.txt]
if {![file exists $input_data_path]} {
    error "sim/input_data.txt not found at $input_data_path. Run scripts/generate_fifo_data.py first."
}
set xpr_files [glob -nocomplain [file join $proj_dir *.xpr]]
if {[llength $xpr_files] == 0} {
    error "No Vivado project found in $proj_dir. Run create.tcl first."
}
open_project [lindex $xpr_files 0]

launch_simulation -simset sim_1 -mode behavioral

set proj_name [get_property NAME [current_project]]
set sim_run_dir [file join $proj_dir "$proj_name.sim" sim_1 behav xsim]
file copy -force $input_data_path $sim_run_dir

run all

# copy the PASS/FAIL report next to the testbench
set results_path [file join $sim_run_dir test_results.txt]
if {[file exists $results_path]} {
    file copy -force $results_path [file join $repo_dir sim test_results.txt]
}
close_sim
