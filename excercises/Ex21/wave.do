onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -format Analog-Interpolated -height 300 -max 1000.0 -min -1000.0 -radix decimal /intertial_integrator_tb/ptch
add wave -noupdate /intertial_integrator_tb/AZ
add wave -noupdate /intertial_integrator_tb/clk
add wave -noupdate /intertial_integrator_tb/cycles
add wave -noupdate /intertial_integrator_tb/ptch_rt
add wave -noupdate /intertial_integrator_tb/PTCH_RT_OFFSET
add wave -noupdate /intertial_integrator_tb/rst_n
add wave -noupdate /intertial_integrator_tb/vld
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {3895000 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 181
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 2
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ps} {43337977 ps}
