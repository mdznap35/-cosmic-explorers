extends SceneTree

const Journal = preload("res://scripts/prototypes/discovery_journal.gd")
const FIXTURE_DIR := "user://discovery_journal_test"

var _errors: Array[String] = []


func _initialize() -> void:
    call_deferred("_run_tests")


func _run_tests() -> void:
    _remove_fixtures()
    var directory_error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(FIXTURE_DIR))
    if directory_error != OK and directory_error != ERR_ALREADY_EXISTS:
        _errors.append("Unable to create the discovery journal fixture directory.")
        _finish()
        return

    _write_state("mars_rover_survey_prototype.json", {
        "version": 1,
        "found_site_ids": ["layered_rock", "layered_rock", "unknown", "sand_ripples"]
    })
    _write_state("lunar_outpost_builder.json", {
        "version": 1,
        "placed_component_ids": ["landing_zone", "habitat", "habitat", "unknown"]
    })
    _write_state("lunar_rover_routes.json", {
        "version": 1,
        "completed_level_ids": ["route_01", "route_02", "route_02", "unknown"]
    })

    var partial_sana_state := {
        "visited_station_ids": ["bridge", "observatory", "bridge", "unknown"],
        "relay_progress": 2,
        "cubesat_step": 3,
        "lulu_found_star_ids": ["star_bridge", "star_workshop", "star_bridge", "unknown"],
        "observatory_photo_ids": ["moon", "moon", "unknown"]
    }
    var partial: Dictionary = Journal.build_snapshot(partial_sana_state, FIXTURE_DIR)
    if int(partial.get("entry_count", 0)) != 8:
        _errors.append("The journal must aggregate the eight exploration and activity tracks.")
    if int(partial.get("total", 0)) != 30:
        _errors.append("The unified journal must expose thirty stable progress points.")
    if int(partial.get("progress", 0)) != 16:
        _errors.append("The journal must count known unique progress and ignore duplicates/unknown IDs.")
    if int(partial.get("completed_entries", -1)) != 0:
        _errors.append("Partial activities must not be marked complete.")
    if int(_entry(partial, "mars_survey").get("progress", -1)) != 2:
        _errors.append("The Mars survey progress must be read from its existing version-1 save.")
    if int(_entry(partial, "lunar_outpost").get("progress", -1)) != 2:
        _errors.append("The lunar builder progress must be read from its existing version-1 save.")
    if int(_entry(partial, "rover_routes").get("progress", -1)) != 2:
        _errors.append("The route planner progress must be read from its existing version-1 save.")

    var full_sana_state := {
        "visited_station_ids": ["bridge", "workshop", "laboratory", "observatory", "lulu_nook"],
        "relay_progress": 3,
        "cubesat_step": 4,
        "lulu_found_star_ids": ["star_bridge", "star_workshop", "star_lab", "star_observatory", "star_corridor"],
        "observatory_photo_ids": ["moon", "mars", "saturn"]
    }
    _write_state("mars_rover_survey_prototype.json", {
        "version": 1,
        "found_site_ids": ["layered_rock", "sand_ripples", "crater_rim"]
    })
    _write_state("lunar_outpost_builder.json", {
        "version": 1,
        "placed_component_ids": ["landing_zone", "habitat", "solar_array", "communications_module"]
    })
    _write_state("lunar_rover_routes.json", {
        "version": 1,
        "completed_level_ids": ["route_01", "route_02", "route_03"]
    })
    var full: Dictionary = Journal.build_snapshot(full_sana_state, FIXTURE_DIR)
    if int(full.get("progress", 0)) != 30 or int(full.get("total", 0)) != 30:
        _errors.append("The completed activity set must reach 30 / 30 points.")
    if int(full.get("completed_entries", 0)) != 8:
        _errors.append("All eight activity tracks must be marked complete at full progress.")
    if int(full.get("completion_percent", 0)) != 100:
        _errors.append("The journal completion percentage must reach 100.")

    _write_state("mars_rover_survey_prototype.json", {"version": 99, "found_site_ids": ["layered_rock"]})
    var invalid_version: Dictionary = Journal.build_snapshot(partial_sana_state, FIXTURE_DIR)
    if int(_entry(invalid_version, "mars_survey").get("progress", -1)) != 0:
        _errors.append("An unsupported external save version must be ignored safely.")

    _write_raw("mars_rover_survey_prototype.json", "{not valid JSON")
    var malformed: Dictionary = Journal.build_snapshot(partial_sana_state, FIXTURE_DIR)
    if int(_entry(malformed, "mars_survey").get("progress", -1)) != 0:
        _errors.append("Malformed external JSON must not break the journal or count as progress.")

    _remove_fixtures()
    if _errors.is_empty():
        print("PASS: discovery journal aggregates eight existing progress tracks, validates IDs, ignores duplicates/unknown IDs, clamps counters, and safely ignores malformed or unsupported save files.")
        quit(0)
        return
    _finish()


func _entry(snapshot: Dictionary, entry_id: String) -> Dictionary:
    for value in snapshot.get("entries", []):
        if typeof(value) == TYPE_DICTIONARY and str(value.get("id", "")) == entry_id:
            return value
    return {}


func _write_state(file_name: String, state: Dictionary) -> void:
    _write_raw(file_name, JSON.stringify(state))


func _write_raw(file_name: String, content: String) -> void:
    var file := FileAccess.open(FIXTURE_DIR.path_join(file_name), FileAccess.WRITE)
    if file == null:
        _errors.append("Unable to write a discovery journal fixture: " + file_name)
        return
    file.store_string(content)
    file.close()


func _remove_fixtures() -> void:
    var directory := DirAccess.open(FIXTURE_DIR)
    if directory != null:
        for file_name in directory.get_files():
            DirAccess.remove_absolute(ProjectSettings.globalize_path(FIXTURE_DIR.path_join(file_name)))
    DirAccess.remove_absolute(ProjectSettings.globalize_path(FIXTURE_DIR))


func _finish() -> void:
    for error in _errors:
        push_error(error)
    quit(1)
