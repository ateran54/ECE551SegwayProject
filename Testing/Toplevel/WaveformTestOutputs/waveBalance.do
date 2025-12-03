onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -format Analog-Step -height 74 -max 595.0 -min -10.0 -radix decimal /Segway_balance_tb/iPHYS/theta_platform
add wave -noupdate /Segway_balance_tb/cmd
add wave -noupdate /Segway_balance_tb/iDUT/iSTR/en_steer
add wave -noupdate -format Analog-Step -height 74 -max 700.0 -radix decimal /Segway_balance_tb/iA2D/ld_cell_lft
add wave -noupdate -format Analog-Step -height 74 -max 499.99999999999994 -radix decimal /Segway_balance_tb/iA2D/ld_cell_rght
add wave -noupdate /Segway_balance_tb/iPHYS/theta/omega
add wave -noupdate /Segway_balance_tb/iPHYS/theta/theta1
add wave -noupdate -format Analog-Step -height 74 -max 17156.0 /Segway_balance_tb/iPHYS/theta/theta
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {880690 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 300
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
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ns} {77060378 ns}
