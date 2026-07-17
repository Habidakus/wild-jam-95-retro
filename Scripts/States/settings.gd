class_name Settings extends StateMachineState


@onready var master_volume: HSlider = $GridContainer/MasterVolumeSlider
@onready var master_value: Label = $GridContainer/MasterVolumeValue
@onready var vfx_volume: HSlider = $GridContainer/VFXVolumeSlider
@onready var vfx_value: Label = $GridContainer/VFXVolumeValue
@onready var music_volume: HSlider = $GridContainer/MusicVolumeSlider
@onready var music_value: Label = $GridContainer/MusicVolumeValue
@onready var ui_volume: HSlider = $GridContainer/UIVolumeSlider
@onready var ui_value: Label = $GridContainer/UIVolumeValue
@onready var acceleration_button: CheckButton = $GridContainer/UseAccelerationButton
@onready var acceleration_value: Label = $GridContainer/UseAccelerationValue

func _ready() -> void:
	_init_slider(master_volume, "Master", master_value)
	_init_slider(vfx_volume, "VFX", vfx_value)
	_init_slider(music_volume, "Music", music_value)
	_init_slider(ui_volume, "UI", ui_value)
	_init_acceleration()


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		our_state_machine.switch_state("MainMenu")


static func _linear_to_slider(linear: float) -> float:
	return linear * 100.0


static func _slider_to_linear(slider: float) -> float:
	return slider / 100.0


func _init_slider(slider: HSlider, bus_name: String, value_label: Label) -> void:
	var bus_index: int = AudioServer.get_bus_index(bus_name)
	assert(bus_index != -1, "Bus %s does not exist" % [bus_name])
	const initial_value: float = 50
	slider.value = initial_value
	_on_value_changed(initial_value, bus_index, slider, value_label)
	slider.value_changed.connect(Callable(self, "_on_value_changed").bind(bus_index, slider, value_label))


func _init_acceleration() -> void:
	if PlayerStats.get_use_acceleration():
		acceleration_button.button_pressed = true
		acceleration_value.text = "Smooth"
	else:
		acceleration_value.text = "Instant"
		acceleration_button.button_pressed = false
	acceleration_button.toggled.connect(Callable(self, "_on_acceleration_toggle"))


func _on_acceleration_toggle(value: bool) -> void:
	PlayerStats.set_use_acceleration(value)
	if value:
		acceleration_value.text = "Smooth"
	else:
		acceleration_value.text = "Instant"


func _on_value_changed(new_value: float, bus_index: int, _slider: HSlider, value_label: Label) -> void:
	if new_value < 5:
		AudioServer.set_bus_mute(bus_index, true)
		value_label.text = "Mute"
	else:
		AudioServer.set_bus_mute(bus_index, false)
		var new_db: float = linear_to_db(new_value / 100.0)
		value_label.text = str(int(round(new_value)))
		AudioServer.set_bus_volume_db(bus_index, new_db)
