set output_dir "D:/0_FPGA/.codex_diagnostics/fmax150"
file mkdir $output_dir

open_checkpoint "D:/0-vivado-project/project_2/project_2.runs/synth_1/top.dcp"

set cpu_clock [get_clocks clk_out2_PLL]
if {[llength $cpu_clock] != 1} {
    error "Expected exactly one clk_out2_PLL clock, found [llength $cpu_clock]"
}

# The generated clock remains physically 50 MHz. This setup-only margin models
# a 6.667 ns timing budget so placement sees the CPU paths as 150 MHz targets.
set_clock_uncertainty -setup 13.333 $cpu_clock

opt_design -directive Explore
place_design -directive Explore
phys_opt_design -directive Explore
route_design -directive Explore
phys_opt_design -directive Explore

report_timing_summary -delay_type min_max -max_paths 20 -report_unconstrained \
    -file "$output_dir/timing_with_150mhz_pressure.rpt"
report_high_fanout_nets -timing -max_nets 50 \
    -file "$output_dir/high_fanout_nets.rpt"
report_utilization -file "$output_dir/utilization.rpt"
write_checkpoint -force "$output_dir/top_routed_150mhz_pressure.dcp"

set path_file [open "$output_dir/cpu_paths.tsv" w]
puts $path_file "slack\tdatapath_delay\tlogic_levels\tstartpoint\tendpoint"
foreach timing_path [get_timing_paths -from $cpu_clock -to $cpu_clock -delay_type max -max_paths 50 -nworst 10] {
    puts $path_file "[get_property SLACK $timing_path]\t[get_property DATAPATH_DELAY $timing_path]\t[get_property LOGIC_LEVELS $timing_path]\t[get_property STARTPOINT_PIN $timing_path]\t[get_property ENDPOINT_PIN $timing_path]"
}
close $path_file

exit
