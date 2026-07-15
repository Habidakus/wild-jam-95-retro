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


func _ready() -> void:
	_tracks.shuffle()
	_audio_player.bus = "Music"
	add_child(_audio_player)


func play_next_track() -> void:
	_current_track = (1 + _current_track) % _tracks.size()
	_audio_player.stream = _tracks[_current_track]
	_audio_player.play()
