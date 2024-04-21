clear; close all;
path(path, './lib');
path(path, './mat_files');
path(path, './coal_plot_scripts');

run("./coal_plot_scripts/snr_perf_beamforming.m")
run("./coal_plot_scripts/snr_calibration_convergence.m")
run("./coal_plot_scripts/calibration_vector_convergence.m")
run("./coal_plot_scripts/calibration_effectiveness.m")
run("./coal_plot_scripts/non_uniform.m")
run("./coal_plot_scripts/larger_arrays.m")
run("./coal_plot_scripts/impact_reference_antenna.m")
run("./coal_plot_scripts/selection_strategy_for_nonuniform_distibution.m")