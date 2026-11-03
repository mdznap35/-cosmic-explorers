extends RefCounted

# Clues are intentionally short, positive, and tied to the visible planetary scene.
# The corresponding factual descriptions and primary sources live in PlanetCatalog.
const STAGES := [
	{"planet_id": "mercury", "clue": "اعثر على أقرب كوكب إلى الشمس."},
	{"planet_id": "venus", "clue": "اعثر على الكوكب الأشد حرارة على سطحه."},
	{"planet_id": "earth", "clue": "اعثر على بيتنا الأزرق الجميل."},
	{"planet_id": "mars", "clue": "اعثر على الكوكب الأحمر."},
	{"planet_id": "jupiter", "clue": "اعثر على أكبر كواكب المجموعة الشمسية."},
	{"planet_id": "saturn", "clue": "اعثر على الكوكب صاحب الحلقات الواسعة."},
	{"planet_id": "uranus", "clue": "اعثر على الكوكب الذي يميل كثيراً."},
	{"planet_id": "neptune", "clue": "اعثر على أبعد كواكب المجموعة الشمسية."}
]


static func get_stages() -> Array:
	return STAGES.duplicate(true)
