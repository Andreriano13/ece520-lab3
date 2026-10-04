# create_project.tcl - builds the Lab 3 Vivado project and runs the testbench
# Written by Claude (Anthropic) - cited in README.md
#
# How to run (from the repo folder, in the Vivado Tcl Shell):
#     vivado -mode batch -source scripts/create_project.tcl
# or inside the Vivado GUI Tcl Console:
#     cd C:/Users/andre/ece520-lab3
#     source scripts/create_project.tcl

# --- where am I? (so the script works from any folder) ---
set repo [file normalize [file join [file dirname [info script]] ..]]

# --- 1. make the project (Zybo Z7-10 = xc7z010clg400-1) ---
create_project sc_fifo_proj $repo/vivado_proj -part xc7z010clg400-1 -force

# --- 2. add the design file and the testbench ---
add_files -norecurse $repo/src/sc_fifo.v
add_files -fileset sim_1 -norecurse $repo/sim/tb_sc_fifo.v
add_files -fileset sim_1 -norecurse $repo/sim/input_data.txt         ;# the Python data, so $readmemh finds it

# --- 3. tell Vivado which module is on top ---
set_property top sc_fifo    [get_filesets sources_1]
set_property top tb_sc_fifo [get_filesets sim_1]

# --- 4. run the simulation all the way to $finish ---
set_property -name {xsim.simulate.runtime} -value {all} -objects [get_filesets sim_1]
launch_simulation
puts "Done - look for the PASS / FAIL line above."
