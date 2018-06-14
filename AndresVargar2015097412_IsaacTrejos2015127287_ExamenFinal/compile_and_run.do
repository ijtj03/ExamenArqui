vlib work
vlog -sv cache_definitions_pkg.sv dm_cache_data.sv dm_cache_tag.sv dm_cache_fsm.sv cache_tb.sv
vsim cache_tb
do wave.do
log -r /*
run -a
echo "DO NOT QUIT SIMULATION"