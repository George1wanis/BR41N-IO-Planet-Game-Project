extends Node2D

## SSVEP Blinking Logic for Godot 4.4.1
## Ensures stable frequency regardless of frame rate.

@export var frequency: float = 10.0 
@export var active: bool = true

var _time_acc: float = 0.0

func _process(delta: float) -> void:
	if not active:
		visible = false
		return
		
	_time_acc += delta
	
	# Period = Time for one full On/Off cycle
	var period = 1.0 / frequency
	
	# Use fmod to determine if we are in the first or second half of the period
	# This prevents timing drift over long sessions.
	var current_phase = fmod(_time_acc, period)
	visible = current_phase < (period / 2.0)

## Optional: method to update frequency at runtime
func set_frequency(new_freq: float) -> void:
	frequency = new_freq
	_time_acc = 0.0 # Reset phase to avoid jarring jumps
