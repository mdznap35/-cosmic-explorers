extends RefCounted

# Visual distances and speeds are compressed for a phone-sized educational scene.
# This is not an ephemeris or a true-scale orbital simulation.
static func position_for(distance: float, angle: float) -> Vector3:
	return Vector3(cos(angle) * distance, 0.0, sin(angle) * distance)


static func advance_angle(angle: float, angular_speed: float, delta: float) -> float:
	return fposmod(angle + angular_speed * delta, TAU)


static func clamp_camera_distance(distance: float) -> float:
	return clampf(distance, 1.2, 70.0)
