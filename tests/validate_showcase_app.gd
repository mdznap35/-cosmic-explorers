extends SceneTree

const ShowcaseScene = preload("res://scenes/prototypes/showcase_app.tscn")
const EXPECTED := {
	"sana": "res://scenes/prototypes/sana_hub_prototype.tscn",
	"mars": "res://scenes/prototypes/mars_rover_survey.tscn",
	"lunar_builder": "res://scenes/prototypes/lunar_outpost_builder.tscn",
	"rover_routes": "res://scenes/prototypes/lunar_rover_route_planner.tscn",
	"solar_system": "res://scenes/main.tscn"
}

var _errors: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var showcase = ShowcaseScene.instantiate()
	root.add_child(showcase)
	await process_frame

	var ids: PackedStringArray = showcase.get_demo_ids()
	if ids.size() != EXPECTED.size():
		_errors.append("Showcase must expose every expected prototype exactly once.")

	for demo_id in EXPECTED:
		if not ids.has(demo_id):
			_errors.append("Missing showcase entry: " + demo_id)
		var scene_path: String = showcase.get_demo_scene_path(demo_id)
		if scene_path != str(EXPECTED[demo_id]):
			_errors.append("Incorrect scene mapping for " + demo_id)
		if not ResourceLoader.exists(scene_path):
			_errors.append("Showcase scene resource is missing: " + scene_path)

	showcase.queue_free()
	await process_frame

	if _errors.is_empty():
		print("PASS: showcase lists all five verified scenes and every scene path resolves.")
		quit(0)
		return

	for error in _errors:
		push_error(error)
	quit(1)
