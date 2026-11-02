extends RefCounted

# Short, positive questions. Every answer is grounded in a primary NASA fact page.
const QUESTIONS := [
	{
		"id": "sun_star",
		"prompt": "ما نوع الشمس؟",
		"options": ["نجم", "كوكب", "قمر"],
		"correct_index": 0,
		"explanation": "أحسنت الاستكشاف! الشمس نجم، والكواكب تدور حولها.",
		"source_url": "https://science.nasa.gov/sun/facts/"
	},
	{
		"id": "mercury_nearest",
		"prompt": "أي كوكب هو الأقرب إلى الشمس؟",
		"options": ["الأرض", "عطارد", "المريخ"],
		"correct_index": 1,
		"explanation": "عطارد هو أول الكواكب من جهة الشمس.",
		"source_url": "https://science.nasa.gov/mercury/facts/"
	},
	{
		"id": "venus_hottest",
		"prompt": "أي كوكب هو الأشد حرارة على سطحه؟",
		"options": ["الزهرة", "نبتون", "أورانوس"],
		"correct_index": 0,
		"explanation": "الزهرة شديد الحرارة بسبب غلافه الجوي الكثيف.",
		"source_url": "https://science.nasa.gov/venus/venus-facts/"
	},
	{
		"id": "earth_home",
		"prompt": "على أي كوكب نعيش؟",
		"options": ["زحل", "المشتري", "الأرض"],
		"correct_index": 2,
		"explanation": "الأرض بيتنا، وهي العالم الوحيد الذي نعرف حتى الآن أنه يحتضن حياة.",
		"source_url": "https://science.nasa.gov/earth/facts/"
	},
	{
		"id": "mars_red",
		"prompt": "أي كوكب نلقبه بالكوكب الأحمر؟",
		"options": ["المريخ", "عطارد", "الزهرة"],
		"correct_index": 0,
		"explanation": "يبدو المريخ أحمر بسبب مواد غنية بالحديد على سطحه وغباره.",
		"source_url": "https://science.nasa.gov/mars/facts/"
	},
	{
		"id": "jupiter_largest",
		"prompt": "ما أكبر كواكب المجموعة الشمسية؟",
		"options": ["الأرض", "المشتري", "المريخ"],
		"correct_index": 1,
		"explanation": "المشتري عملاق غازي، وهو أكبر كواكب المجموعة الشمسية.",
		"source_url": "https://science.nasa.gov/jupiter/jupiter-facts/"
	},
	{
		"id": "saturn_rings",
		"prompt": "أي كوكب تشتهر حلقاته الواسعة؟",
		"options": ["زحل", "عطارد", "الأرض"],
		"correct_index": 0,
		"explanation": "حلقات زحل تتكون من قطع كثيرة من الجليد والصخور والغبار.",
		"source_url": "https://science.nasa.gov/saturn/facts/"
	},
	{
		"id": "uranus_tilt",
		"prompt": "أي كوكب يميل محور دورانه كثيراً؟",
		"options": ["الزهرة", "أورانوس", "المشتري"],
		"correct_index": 1,
		"explanation": "محور أورانوس مائل بشدة، لذلك يبدو كأنه يتدحرج حول الشمس.",
		"source_url": "https://science.nasa.gov/uranus/facts/"
	},
	{
		"id": "neptune_far",
		"prompt": "أي كوكب هو الأبعد عن الشمس بين الكواكب الثمانية؟",
		"options": ["الأرض", "زحل", "نبتون"],
		"correct_index": 2,
		"explanation": "نبتون هو أبعد الكواكب الثمانية عن الشمس.",
		"source_url": "https://science.nasa.gov/neptune/neptune-facts/"
	}
]


static func get_questions() -> Array:
	return QUESTIONS.duplicate(true)
