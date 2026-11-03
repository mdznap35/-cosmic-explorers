extends SceneTree

const ContentRegistry = preload("res://scripts/content_registry.gd")
const InteractionRouter = preload("res://scripts/interaction_router.gd")

var _received: Array[Dictionary] = []


func _initialize() -> void:
	_run_interaction_router_tests()


func _run_interaction_router_tests() -> void:
	var errors: Array[String] = []
	var bundle: Dictionary = ContentRegistry.load_bundle()
	errors.append_array(ContentRegistry.validate_bundle(bundle))

	var router = InteractionRouter.new()
	errors.append_array(router.configure(bundle))
	router.interaction_received.connect(_on_interaction_received)

	if not router.is_event_allowed("mars.site.selected"):
		errors.append("Mission-authored interaction events must be allow-listed.")
	if router.is_event_allowed("untrusted.execute_script"):
		errors.append("Unknown interaction events must not be allow-listed.")
	if not router.publish("mars.site.selected", {"source": "test", "index": 2}):
		errors.append("A known event with a data-only payload should be accepted.")
	if _received.size() != 1 or _received[0].get("event_id", "") != "mars.site.selected":
		errors.append("Accepted events must be emitted exactly once.")
	if router.publish("untrusted.execute_script", {}):
		errors.append("Unknown events must be rejected.")
	if router.publish("mars.site.selected", {"unsafe": Node.new()}):
		errors.append("Object instances must not pass through data-only payload validation.")
	if _received.size() != 1:
		errors.append("Rejected events must not emit interaction signals.")

	if errors.is_empty():
		print("PASS: allow-listed interaction events, data-only payloads, and rejection behavior.")
		quit(0)
		return
	for error in errors:
		push_error(error)
	quit(1)


func _on_interaction_received(event_id: String, payload: Dictionary) -> void:
	var event := payload.duplicate(true)
	event["event_id"] = event_id
	_received.append(event)
