onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /Segway_auth_flow_tb/SS_n
add wave -noupdate /Segway_auth_flow_tb/SCLK
add wave -noupdate /Segway_auth_flow_tb/MOSI
add wave -noupdate /Segway_auth_flow_tb/MISO
add wave -noupdate /Segway_auth_flow_tb/INT
add wave -noupdate /Segway_auth_flow_tb/A2D_SS_n
add wave -noupdate /Segway_auth_flow_tb/A2D_SCLK
add wave -noupdate /Segway_auth_flow_tb/A2D_MOSI
add wave -noupdate /Segway_auth_flow_tb/A2D_MISO
add wave -noupdate /Segway_auth_flow_tb/RX_TX
add wave -noupdate /Segway_auth_flow_tb/PWM1_rght
add wave -noupdate /Segway_auth_flow_tb/PWM2_rght
add wave -noupdate /Segway_auth_flow_tb/PWM1_lft
add wave -noupdate /Segway_auth_flow_tb/PWM2_lft
add wave -noupdate /Segway_auth_flow_tb/piezo
add wave -noupdate /Segway_auth_flow_tb/piezo_n
add wave -noupdate /Segway_auth_flow_tb/cmd_sent
add wave -noupdate /Segway_auth_flow_tb/rst_n
add wave -noupdate /Segway_auth_flow_tb/clk
add wave -noupdate /Segway_auth_flow_tb/RST_n
add wave -noupdate /Segway_auth_flow_tb/cmd
add wave -noupdate /Segway_auth_flow_tb/send_cmd
add wave -noupdate /Segway_auth_flow_tb/rider_lean
add wave -noupdate /Segway_auth_flow_tb/ld_cell_lft
add wave -noupdate /Segway_auth_flow_tb/ld_cell_rght
add wave -noupdate /Segway_auth_flow_tb/steerPot
add wave -noupdate /Segway_auth_flow_tb/batt
add wave -noupdate /Segway_auth_flow_tb/OVR_I_lft
add wave -noupdate /Segway_auth_flow_tb/OVR_I_rght
add wave -noupdate -format Analog-Step -height 84 -max 47.999999999999993 -min -56.0 -radix decimal /Segway_auth_flow_tb/iDUT/lft_spd
add wave -noupdate -format Analog-Step -height 84 -max 47.999999999999993 -min -56.0 -radix decimal /Segway_auth_flow_tb/iDUT/rght_spd
add wave -noupdate -divider Physics
add wave -noupdate -format Analog-Step -height 84 -max 48.000000000000007 -min -60.0 -radix decimal /Segway_auth_flow_tb/iPHYS/lft_duty
add wave -noupdate -format Analog-Step -height 84 -max 48.000000000000007 -min -60.0 -radix decimal /Segway_auth_flow_tb/iPHYS/rght_duty
add wave -noupdate /Segway_auth_flow_tb/iPHYS/rst_n
add wave -noupdate /Segway_auth_flow_tb/iPHYS/rst_synch
add wave -noupdate /Segway_auth_flow_tb/iPHYS/time_since_rise_lft
add wave -noupdate /Segway_auth_flow_tb/iPHYS/time_since_rise_rght
add wave -noupdate /Segway_auth_flow_tb/iPHYS/time_since_calc
add wave -noupdate /Segway_auth_flow_tb/iPHYS/az
add wave -noupdate -format Analog-Step -height 84 -max 176.0 -min -176.0 -radix decimal /Segway_auth_flow_tb/iPHYS/torque_lft
add wave -noupdate -format Analog-Step -height 84 -max 176.0 -min -176.0 -radix decimal /Segway_auth_flow_tb/iPHYS/torque_rght
add wave -noupdate /Segway_auth_flow_tb/iPHYS/any_are_one_ff1
add wave -noupdate /Segway_auth_flow_tb/iPHYS/calc_physics
add wave -noupdate -format Analog-Step -height 84 -max 352.0 -min -352.0 -radix decimal /Segway_auth_flow_tb/iPHYS/net_torque
add wave -noupdate -format Analog-Step -height 84 -max 80.0 -radix decimal /Segway_auth_flow_tb/iPHYS/omega_lft
add wave -noupdate -format Analog-Step -height 84 -max 80.0 -radix decimal /Segway_auth_flow_tb/iPHYS/omega_rght
add wave -noupdate -format Analog-Step -height 84 -max 80.0 -radix decimal /Segway_auth_flow_tb/iPHYS/theta_lft
add wave -noupdate -format Analog-Step -height 84 -max 80.0 -radix decimal /Segway_auth_flow_tb/iPHYS/theta_rght
add wave -noupdate -format Analog-Step -height 84 -max 80.0 -radix decimal /Segway_auth_flow_tb/iPHYS/rotation_platform
add wave -noupdate -format Analog-Step -height 74 -max 65.000000000000014 -min -2.0 -radix decimal /Segway_auth_flow_tb/iPHYS/omega_platform
add wave -noupdate -format Analog-Step -height 500 -max 0.99999999999999989 -min -4.0 -radix decimal /Segway_auth_flow_tb/iPHYS/theta_platform
add wave -noupdate /Segway_auth_flow_tb/iDUT/en_steer
add wave -noupdate /Segway_auth_flow_tb/iDUT/rider_off
add wave -noupdate /Segway_auth_flow_tb/iDUT/batt_low
add wave -noupdate /Segway_auth_flow_tb/iDUT/too_fast
add wave -noupdate /Segway_auth_flow_tb/iDUT/pwr_up
add wave -noupdate -divider PID
add wave -noupdate /Segway_auth_flow_tb/iDUT/iBAL/pid/clk
add wave -noupdate /Segway_auth_flow_tb/iDUT/iBAL/pid/rst_n
add wave -noupdate /Segway_auth_flow_tb/iDUT/iBAL/pid/vld
add wave -noupdate /Segway_auth_flow_tb/iDUT/iBAL/pid/pwr_up
add wave -noupdate /Segway_auth_flow_tb/iDUT/iBAL/pid/rider_off
add wave -noupdate /Segway_auth_flow_tb/iDUT/iBAL/pid/ptch
add wave -noupdate /Segway_auth_flow_tb/iDUT/iBAL/pid/ptch_rt
add wave -noupdate /Segway_auth_flow_tb/iDUT/iBAL/pid/PID_cntrl
add wave -noupdate /Segway_auth_flow_tb/iDUT/iBAL/pid/ss_tmr
add wave -noupdate /Segway_auth_flow_tb/iDUT/iBAL/pid/ptch_err_sat
add wave -noupdate /Segway_auth_flow_tb/iDUT/iBAL/pid/integrator
add wave -noupdate /Segway_auth_flow_tb/iDUT/iBAL/pid/integrator_next
add wave -noupdate /Segway_auth_flow_tb/iDUT/iBAL/pid/should_accumulate
add wave -noupdate /Segway_auth_flow_tb/iDUT/iBAL/pid/ss_counter
add wave -noupdate /Segway_auth_flow_tb/iDUT/iBAL/pid/P_term
add wave -noupdate /Segway_auth_flow_tb/iDUT/iBAL/pid/I_term
add wave -noupdate /Segway_auth_flow_tb/iDUT/iBAL/pid/D_term
add wave -noupdate /Segway_auth_flow_tb/iDUT/iBAL/pid/PID_SUM_16
add wave -noupdate -divider SegwayMath
add wave -noupdate /Segway_auth_flow_tb/iDUT/iBAL/segMath/clk
add wave -noupdate /Segway_auth_flow_tb/iDUT/iBAL/segMath/rst_n
add wave -noupdate /Segway_auth_flow_tb/iDUT/iBAL/segMath/PID_cntrl
add wave -noupdate /Segway_auth_flow_tb/iDUT/iBAL/segMath/ss_tmr
add wave -noupdate /Segway_auth_flow_tb/iDUT/iBAL/segMath/steer_pot
add wave -noupdate /Segway_auth_flow_tb/iDUT/iBAL/segMath/en_steer
add wave -noupdate /Segway_auth_flow_tb/iDUT/iBAL/segMath/pwr_up
add wave -noupdate /Segway_auth_flow_tb/iDUT/iBAL/segMath/lft_spd
add wave -noupdate /Segway_auth_flow_tb/iDUT/iBAL/segMath/rght_spd
add wave -noupdate /Segway_auth_flow_tb/iDUT/iBAL/segMath/too_fast
add wave -noupdate /Segway_auth_flow_tb/iDUT/iBAL/segMath/PID_ss_unscaled
add wave -noupdate /Segway_auth_flow_tb/iDUT/iBAL/segMath/PID_ss
add wave -noupdate /Segway_auth_flow_tb/iDUT/iBAL/segMath/PID_ss_sext
add wave -noupdate /Segway_auth_flow_tb/iDUT/iBAL/segMath/PID_ss_pipelined
add wave -noupdate /Segway_auth_flow_tb/iDUT/iBAL/segMath/steer_pot_saturated
add wave -noupdate /Segway_auth_flow_tb/iDUT/iBAL/segMath/steering_offset
add wave -noupdate /Segway_auth_flow_tb/iDUT/iBAL/segMath/steering_offset_scaled
add wave -noupdate /Segway_auth_flow_tb/iDUT/iBAL/segMath/lft_torque_steering
add wave -noupdate /Segway_auth_flow_tb/iDUT/iBAL/segMath/lft_torque
add wave -noupdate /Segway_auth_flow_tb/iDUT/iBAL/segMath/rght_torque_steering
add wave -noupdate /Segway_auth_flow_tb/iDUT/iBAL/segMath/rght_torque
add wave -noupdate /Segway_auth_flow_tb/iDUT/iBAL/segMath/lft_torque_pipelined
add wave -noupdate /Segway_auth_flow_tb/iDUT/iBAL/segMath/rght_torque_pipelined
add wave -noupdate /Segway_auth_flow_tb/iDUT/iBAL/segMath/lft_shaped
add wave -noupdate /Segway_auth_flow_tb/iDUT/iBAL/segMath/rhgt_shaped
add wave -noupdate -divider {Inertial Integrator}
add wave -noupdate -radix decimal /Segway_auth_flow_tb/iDUT/iNEMO/iINT/clk
add wave -noupdate -radix decimal /Segway_auth_flow_tb/iDUT/iNEMO/iINT/rst_n
add wave -noupdate -radix decimal /Segway_auth_flow_tb/iDUT/iNEMO/iINT/vld
add wave -noupdate -radix decimal /Segway_auth_flow_tb/iDUT/iNEMO/iINT/ptch_rt
add wave -noupdate -radix decimal /Segway_auth_flow_tb/iDUT/iNEMO/iINT/AZ
add wave -noupdate -radix decimal /Segway_auth_flow_tb/iDUT/iNEMO/iINT/ptch
add wave -noupdate -radix decimal /Segway_auth_flow_tb/iDUT/iNEMO/iINT/ptch_int
add wave -noupdate -radix decimal /Segway_auth_flow_tb/iDUT/iNEMO/iINT/ptch_rt_comp
add wave -noupdate -radix decimal /Segway_auth_flow_tb/iDUT/iNEMO/iINT/ptch_rt_comp_ext
add wave -noupdate -radix decimal /Segway_auth_flow_tb/iDUT/iNEMO/iINT/AZ_comp
add wave -noupdate -radix decimal /Segway_auth_flow_tb/iDUT/iNEMO/iINT/ptch_acc_product
add wave -noupdate -radix decimal /Segway_auth_flow_tb/iDUT/iNEMO/iINT/ptch_acc
add wave -noupdate -radix decimal /Segway_auth_flow_tb/iDUT/iNEMO/iINT/fusion_ptch_offset
add wave -noupdate -radix decimal /Segway_auth_flow_tb/iDUT/iNEMO/iINT/ptch_acc_piped
add wave -noupdate -radix decimal /Segway_auth_flow_tb/iDUT/iNEMO/iINT/ptch_rt_comp_ext_piped
add wave -noupdate -radix decimal /Segway_auth_flow_tb/iDUT/iNEMO/iINT/fusion_ptch_offset_piped
add wave -noupdate -divider A2D
add wave -noupdate /Segway_auth_flow_tb/iDUT/iA2D/clk
add wave -noupdate /Segway_auth_flow_tb/iDUT/iA2D/rst_n
add wave -noupdate /Segway_auth_flow_tb/iDUT/iA2D/nxt
add wave -noupdate /Segway_auth_flow_tb/iDUT/iA2D/lft_ld
add wave -noupdate /Segway_auth_flow_tb/iDUT/iA2D/rght_ld
add wave -noupdate /Segway_auth_flow_tb/iDUT/iA2D/steer_pot
add wave -noupdate /Segway_auth_flow_tb/iDUT/iA2D/batt
add wave -noupdate /Segway_auth_flow_tb/iDUT/iA2D/SS_n
add wave -noupdate /Segway_auth_flow_tb/iDUT/iA2D/SCLK
add wave -noupdate /Segway_auth_flow_tb/iDUT/iA2D/MOSI
add wave -noupdate /Segway_auth_flow_tb/iDUT/iA2D/MISO
add wave -noupdate /Segway_auth_flow_tb/iDUT/iA2D/currState
add wave -noupdate /Segway_auth_flow_tb/iDUT/iA2D/nextState
add wave -noupdate /Segway_auth_flow_tb/iDUT/iA2D/robin_cnt
add wave -noupdate /Segway_auth_flow_tb/iDUT/iA2D/wt_data
add wave -noupdate /Segway_auth_flow_tb/iDUT/iA2D/rd_data
add wave -noupdate /Segway_auth_flow_tb/iDUT/iA2D/wrt
add wave -noupdate /Segway_auth_flow_tb/iDUT/iA2D/done
add wave -noupdate /Segway_auth_flow_tb/iDUT/iA2D/count_en
add wave -noupdate /Segway_auth_flow_tb/iDUT/iA2D/nextLeftLoadLevel
add wave -noupdate /Segway_auth_flow_tb/iDUT/iA2D/nextRightLoadLevel
add wave -noupdate /Segway_auth_flow_tb/iDUT/iA2D/nextSteeringPotentiometer
add wave -noupdate /Segway_auth_flow_tb/iDUT/iA2D/nextBatteryVoltage
add wave -noupdate /Segway_auth_flow_tb/iDUT/INERT_MISO
add wave -noupdate /Segway_auth_flow_tb/iDUT/INERT_INT
add wave -noupdate /Segway_auth_flow_tb/iDUT/INERT_MOSI
add wave -noupdate /Segway_auth_flow_tb/iDUT/INERT_SCLK
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {40386810 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 385
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
WaveRestoreZoom {112612 ns} {47410020 ns}
