onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider {Segway Physics Signals}
add wave -noupdate /Segway_lean_conv_tb/iPHYS/rider_lean
add wave -noupdate /Segway_lean_conv_tb/iPHYS/net_torque
add wave -noupdate /Segway_lean_conv_tb/iPHYS/omega_lft
add wave -noupdate /Segway_lean_conv_tb/iPHYS/omega_rght
add wave -noupdate /Segway_lean_conv_tb/iPHYS/theta_lft
add wave -noupdate /Segway_lean_conv_tb/iPHYS/theta_rght
add wave -noupdate /Segway_lean_conv_tb/iPHYS/rotation_platform
add wave -noupdate /Segway_lean_conv_tb/iPHYS/omega_platform
add wave -noupdate -format Analog-Step -height 150 -max 4320.9999999999991 -min -106.0 -radix decimal /Segway_lean_conv_tb/iPHYS/theta_platform
add wave -noupdate -divider {Balance Control Signals}
add wave -noupdate /Segway_lean_conv_tb/iDUT/iBAL/clk
add wave -noupdate /Segway_lean_conv_tb/iDUT/iBAL/rst_n
add wave -noupdate /Segway_lean_conv_tb/iDUT/iBAL/vld
add wave -noupdate -format Analog-Step -height 74 -max 22.000000000000004 -min -2.0 -radix decimal /Segway_lean_conv_tb/iDUT/iBAL/ptch
add wave -noupdate /Segway_lean_conv_tb/iDUT/iBAL/ptch_rt
add wave -noupdate /Segway_lean_conv_tb/iDUT/iBAL/pwr_up
add wave -noupdate /Segway_lean_conv_tb/iDUT/iBAL/rider_off
add wave -noupdate /Segway_lean_conv_tb/iDUT/iBAL/steer_pot
add wave -noupdate /Segway_lean_conv_tb/iDUT/iBAL/en_steer
add wave -noupdate /Segway_lean_conv_tb/iDUT/iBAL/lft_spd
add wave -noupdate /Segway_lean_conv_tb/iDUT/iBAL/rght_spd
add wave -noupdate /Segway_lean_conv_tb/iDUT/iBAL/too_fast
add wave -noupdate /Segway_lean_conv_tb/iDUT/iBAL/PID_cntrl
add wave -noupdate /Segway_lean_conv_tb/iDUT/iBAL/ss_tmr
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {25266182 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 546
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ps} {51285329 ps}
