extends RefCounted
## Read-only summary of progress stored by the independent offline activities.
## Existing activity save files remain owned by their original scenes.

const SANA_STATIONS := ["bridge", "workshop", "laboratory", "observatory", "lulu_nook"]
const RELAY_STEPS := ["moon_relay", "sana_station", "mars_rover"]
const CUBESAT_STEPS := ["central_bus", "solar_panels", "communication_antenna", "science_camera"]
const LULU_STARS := ["star_bridge", "star_workshop", "star_lab", "star_observatory", "star_corridor"]
const OBSERVATORY_TARGETS := ["moon", "mars", "saturn"]
const MARS_SITES := ["layered_rock", "sand_ripples", "crater_rim"]
const LUNAR_COMPONENTS := ["landing_zone", "habitat", "solar_array", "communications_module"]
const ROVER_LEVELS := ["route_01", "route_02", "route_03"]


static func build_snapshot(sana_state: Dictionary, save_directory: String = "user://") -> Dictionary:
    var entries: Array[Dictionary] = []

    _append_entry(entries, "station_visits", "استكشاف سفينة سَنا",
        _count_unique_known(sana_state.get("visited_station_ids", []), SANA_STATIONS), SANA_STATIONS.size())
    _append_entry(entries, "relay_message", "رسالة مرقاب",
        clampi(int(sana_state.get("relay_progress", 0)), 0, RELAY_STEPS.size()), RELAY_STEPS.size())
    _append_entry(entries, "cubesat", "القمر المصغّر",
        clampi(int(sana_state.get("cubesat_step", 0)), 0, CUBESAT_STEPS.size()), CUBESAT_STEPS.size())
    _append_entry(entries, "lulu_hunt", "نجوم لولو",
        _count_unique_known(sana_state.get("lulu_found_star_ids", []), LULU_STARS), LULU_STARS.size())
    _append_entry(entries, "observatory_album", "ألبوم مرصد ريم",
        _count_unique_known(sana_state.get("observatory_photo_ids", []), OBSERVATORY_TARGETS), OBSERVATORY_TARGETS.size())

    var mars_state := _read_versioned_state(save_directory, "mars_rover_survey_prototype.json", 1)
    _append_entry(entries, "mars_survey", "مسح سطح المريخ",
        _count_unique_known(mars_state.get("found_site_ids", []), MARS_SITES), MARS_SITES.size())

    var outpost_state := _read_versioned_state(save_directory, "lunar_outpost_builder.json", 1)
    _append_entry(entries, "lunar_outpost", "بناء القاعدة القمرية",
        _count_unique_known(outpost_state.get("placed_component_ids", []), LUNAR_COMPONENTS), LUNAR_COMPONENTS.size())

    var route_state := _read_versioned_state(save_directory, "lunar_rover_routes.json", 1)
    _append_entry(entries, "rover_routes", "برمجة مسارات الروفر",
        _count_unique_known(route_state.get("completed_level_ids", []), ROVER_LEVELS), ROVER_LEVELS.size())

    var total_progress := 0
    var total_points := 0
    var completed_entries := 0
    for entry in entries:
        total_progress += int(entry["progress"])
        total_points += int(entry["total"])
        if bool(entry["completed"]):
            completed_entries += 1

    var completion_percent := 0
    if total_points > 0:
        completion_percent = int(round(float(total_progress) * 100.0 / float(total_points)))

    return {
        "entries": entries,
        "progress": total_progress,
        "total": total_points,
        "completed_entries": completed_entries,
        "entry_count": entries.size(),
        "completion_percent": completion_percent
    }


static func _append_entry(entries: Array[Dictionary], entry_id: String, title: String,
        raw_progress: int, raw_total: int) -> void:
    var total := maxi(1, raw_total)
    var progress := clampi(raw_progress, 0, total)
    entries.append({
        "id": entry_id,
        "title": title,
        "progress": progress,
        "total": total,
        "completed": progress == total
    })


static func _count_unique_known(raw_values: Variant, allowed_ids: Array) -> int:
    if typeof(raw_values) != TYPE_ARRAY:
        return 0
    var seen: Dictionary = {}
    for raw_value in raw_values:
        var normalized_id := str(raw_value)
        if allowed_ids.has(normalized_id):
            seen[normalized_id] = true
    return seen.size()


static func _read_versioned_state(directory: String, file_name: String, expected_version: int) -> Dictionary:
    var save_path := directory.path_join(file_name)
    if not FileAccess.file_exists(save_path):
        return {}
    var file := FileAccess.open(save_path, FileAccess.READ)
    if file == null:
        return {}
    var parser := JSON.new()
    var parse_error := parser.parse(file.get_as_text())
    file.close()
    if parse_error != OK:
        return {}
    var parsed: Variant = parser.data
    if typeof(parsed) != TYPE_DICTIONARY:
        return {}
    if int(parsed.get("version", 0)) != expected_version:
        return {}
    return parsed
