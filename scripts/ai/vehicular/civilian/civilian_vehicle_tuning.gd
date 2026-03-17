class_name CivilianVehicleTuning
extends Resource

@export_range(40.0, 400.0, 1.0) var cruise_speed := 240.0
@export_range(24.0, 240.0, 1.0) var turn_speed := 120.0
@export_range(24.0, 220.0, 1.0) var lane_change_speed := 150.0
@export_range(24.0, 180.0, 1.0) var u_turn_speed := 100.0
@export_range(40.0, 600.0, 1.0) var acceleration := 220.0
@export_range(40.0, 800.0, 1.0) var brake_power := 360.0
@export_range(24.0, 120.0, 1.0) var vehicle_look_ahead := 54.0
@export_range(24.0, 160.0, 1.0) var police_look_ahead := 120.0
@export_range(24.0, 96.0, 1.0) var pedestrian_look_ahead := 44.0
@export_range(24.0, 144.0, 1.0) var obstacle_look_ahead := 84.0
@export_range(8.0, 64.0, 1.0) var vehicle_stop_buffer := 22.0
@export_range(8.0, 64.0, 1.0) var pedestrian_stop_buffer := 22.0
@export_range(8.0, 64.0, 1.0) var dynamic_obstacle_stop_buffer := 22.0
@export_range(16.0, 128.0, 1.0) var police_stop_buffer := 88.0
@export_range(16.0, 96.0, 1.0) var barrier_stop_buffer := 48.0
@export_range(0.2, 8.0, 0.1) var blockage_threshold := 1.25
@export_range(0.2, 8.0, 0.1) var recovery_cooldown := 1.0
@export_range(0.2, 6.0, 0.1) var reroute_focus_time := 2.5
@export_range(0.0, 3.0, 0.05) var incident_exit_delay := 0.6
@export_range(0.0, 5.0, 0.05) var incident_settle_timeout := 2.0
@export_range(0.0, 6.0, 0.05) var incident_victim_still_time := 3.0
@export_range(0.0, 10.0, 0.1) var driver_exit_after_stop_time := 5.0
