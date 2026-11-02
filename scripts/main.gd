extends Node3D

const PlanetCatalog = preload("res://scripts/planet_catalog.gd")
const SolarSystemView = preload("res://scripts/solar_system_view.gd")
const UIController = preload("res://scripts/ui_controller.gd")
const SaveService = preload("res://scripts/save_service.gd")

var _solar_view: Node3D
var _ui: Control
var _discovered: Array[String] = []


func _ready() -> void:
	_discovered = SaveService.load_discovered()

	var view = SolarSystemView.new()
	view.configure(PlanetCatalog.get_all())
	view.planet_tapped.connect(_on_planet_selected)
	_solar_view = view
	add_child(_solar_view)

	var overlay := CanvasLayer.new()
	overlay.name = "InterfaceLayer"
	overlay.layer = 10
	add_child(overlay)

	var interface = UIController.new()
	interface.configure(PlanetCatalog.get_all(), _discovered)
	interface.planet_selected.connect(_on_planet_selected)
	interface.zoom_requested.connect(_on_zoom_requested)
	interface.reset_requested.connect(_on_reset_requested)
	_ui = interface
	overlay.add_child(_ui)

	_ui.show_planet("earth", _discovered)


func _on_planet_selected(planet_id: String) -> void:
	var planet := PlanetCatalog.get_planet(planet_id)
	if planet.is_empty():
		return
	_discovered = SaveService.mark_discovered(planet_id)
	_ui.show_planet(planet_id, _discovered)
	_solar_view.focus_on_planet(planet_id)


func _on_zoom_requested(amount: float) -> void:
	_solar_view.zoom_by(amount)


func _on_reset_requested() -> void:
	_solar_view.reset_camera()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		get_tree().quit()
