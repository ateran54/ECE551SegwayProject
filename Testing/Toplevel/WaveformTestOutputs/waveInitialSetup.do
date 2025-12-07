onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /Segway_balance_tb/cmd
add wave -noupdate /Segway_balance_tb/steerPot
add wave -noupdate /Segway_balance_tb/ld_cell_rght
add wave -noupdate /Segway_balance_tb/ld_cell_lft
add wave -noupdate /Segway_balance_tb/iDUT/iSTR/next_state
add wave -noupdate -divider ATD
add wave -noupdate /Segway_balance_tb/iDUT/iA2D/nextLeftLoadLevel
add wave -noupdate /Segway_balance_tb/iDUT/iA2D/nextRightLoadLevel
add wave -noupdate /Segway_balance_tb/iDUT/iA2D/nextSteeringPotentiometer
add wave -noupdate /Segway_balance_tb/iDUT/iA2D/nextBatteryVoltage
add wave -noupdate /Segway_balance_tb/iDUT/iA2D/lft_ld
add wave -noupdate /Segway_balance_tb/iDUT/iA2D/done
add wave -noupdate -divider STRCONTOLL
add wave -noupdate /Segway_balance_tb/iDUT/iSTR/diff_gt_15_16
add wave -noupdate /Segway_balance_tb/iDUT/iSTR/diff_gt_1_4
add wave -noupdate /Segway_balance_tb/iDUT/iSTR/sum_lt_min
add wave -noupdate /Segway_balance_tb/iDUT/iSTR/sum_gt_min
add wave -noupdate /Segway_balance_tb/iDUT/iSTR/sum_13_14
add wave -noupdate /Segway_balance_tb/iDUT/iSTR/diff_12_abs
add wave -noupdate /Segway_balance_tb/iDUT/iSTR/diff_12
add wave -noupdate /Segway_balance_tb/iDUT/iSTR/sum_13_1516
add wave -noupdate /Segway_balance_tb/iDUT/iSTR/sum_13
add wave -noupdate /Segway_balance_tb/iDUT/iSTR/state
add wave -noupdate /Segway_balance_tb/iDUT/iSTR/tmr
add wave -noupdate -color Magenta /Segway_balance_tb/iDUT/iSTR/tmr_full
add wave -noupdate /Segway_balance_tb/iDUT/iSTR/clr_tmr
add wave -noupdate -divider {Intertial inteRface}
add wave -noupdate -format Analog-Step -height 84 -max 32767.0 -min -32768.0 /Segway_balance_tb/iDUT/iNEMO/timer
add wave -noupdate /Segway_balance_tb/iDUT/iNEMO/vld
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 327
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
WaveRestoreZoom {0 ns} {26278884 ns}
