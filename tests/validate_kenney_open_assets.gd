extends SceneTree

const STATION_ROOT := "res://assets/vendor/kenney_space_station_kit"
const AUDIO_ROOT := "res://assets/audio/kenney_interface_sounds"
const STATION_MODELS := [
	"floor", "floor-panel", "wall", "wall-corner", "wall-window", "wall-door",
	"door-single", "computer", "display-wall-wide", "table-display-planet",
	"table-inset", "chair", "rail", "pipe", "structure", "container",
	"wall-switch", "wall-pillar"
]
const INTERFACE_AUDIO := ["click_001.wav", "open_001.wav", "bong_001.wav"]

var _errors: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var texture_path := STATION_ROOT + "/Textures/colormap.png"
	if not ResourceLoader.exists(texture_path):
		_errors.append("Missing shared Kenney colormap texture used by the GLB models.")
	elif not (ResourceLoader.load(texture_path) is Texture2D):
		_errors.append("Kenney shared colormap did not import as Texture2D.")

	for model_id in STATION_MODELS:
		var path: String = STATION_ROOT + "/" + str(model_id) + ".glb"
		if not ResourceLoader.exists(path):
			_errors.append("Missing staged Kenney station model: " + model_id)
			continue
		var packed := ResourceLoader.load(path) as PackedScene
		if packed == null:
			_errors.append("Kenney GLB did not import as a PackedScene: " + model_id)
			continue
		var instance := packed.instantiate()
		if not (instance is Node3D):
			_errors.append("Kenney station model root is not Node3D: " + model_id)
		else:
			var has_mesh := instance is MeshInstance3D
			if not has_mesh:
				has_mesh = not instance.find_children("*", "MeshInstance3D", true, false).is_empty()
			if not has_mesh:
				_errors.append("Kenney station model contains no MeshInstance3D: " + model_id)
		instance.free()

	for sound_name in INTERFACE_AUDIO:
		var sound_path: String = AUDIO_ROOT + "/" + str(sound_name)
		if not ResourceLoader.exists(sound_path):
			_errors.append("Missing staged Kenney interface sound: " + sound_name)
			continue
		if not (ResourceLoader.load(sound_path) is AudioStream):
			_errors.append("Kenney interface sound failed to import as AudioStream: " + sound_name)

	if _errors.is_empty():
		print("PASS: 18 Kenney CC0 station modules instantiate with visible meshes; 3 Kenney CC0 interface sounds import.")
		quit(0)
		return
	for error in _errors:
		push_error(error)
	quit(1)
