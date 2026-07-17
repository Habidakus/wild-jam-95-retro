extends Node


var _tracks: Array = [
	preload("res://Sounds/Music/Electronic Vol2 Defcon Main.wav"),
	preload("res://Sounds/Music/Electronic Vol2 Digitist Main.wav"),
	preload("res://Sounds/Music/Electronic Vol2 Hybrid Theory Main.wav"),
	preload("res://Sounds/Music/Electronic Vol2 Tech Junkie Main.wav"),
	preload("res://Sounds/Music/HeavyElectronic Vol4 Cake Main.wav"),
	preload("res://Sounds/Music/HeavyElectronic Vol4 Double Or Nothing Main.wav"), 
	preload("res://Sounds/Music/HeavyElectronic Vol4 Killtacular Main.wav")
]
var _current_track: int = 0
var _audio_player: AudioStreamPlayer2D = AudioStreamPlayer2D.new()

const MIN_PITCH: float = 0.91
const MAX_PITCH: float = 1.09
const PITCH_DELTA: float = 0.03


func _ready() -> void:
	_tracks.shuffle()
	_audio_player.bus = "Music"
	add_child(_audio_player)


func play_next_track(speed: int = 0) -> void:
	_current_track = (1 + _current_track) % _tracks.size()
	_audio_player.stream = _tracks[_current_track]
	_audio_player.pitch_scale = clamp(1.0 + speed * PITCH_DELTA, MIN_PITCH, MAX_PITCH)
	_audio_player.play()


func IncreaseSpeed(inc: int) -> void:
	var new_pitch: float = clamp(_audio_player.pitch_scale + inc * PITCH_DELTA, MIN_PITCH, MAX_PITCH)
	var tween: Tween = create_tween()
	tween.tween_property(_audio_player, "pitch_scale", new_pitch, 2)
