# مستكشفو الكون | Cosmic Explorers

> تجربة فضائية تعليمية عربية، تفاعلية، تعمل دون اتصال، ومصممة للأطفال في بدايات التعلم.

**الحالة:** أساس الاستكشاف والجولة البصرية الثانية ورحلة البحث الثالثة مطبّقة على فرع التطوير؛ ما زال اختبار الجهاز الفعلي والدمج النهائي منفصلين.

## الرؤية

ليس هذا المشروع موسوعة نصية ولا عرضاً ثابتاً للكواكب. الهدف بناء متحف فضائي مصغّر داخل تطبيق Android: يستكشف الطفل الشمس والكواكب، يقترب من كل عالم، يكتشف حقيقة علمية قصيرة، ثم ينتقل إلى تجارب ومهمات في الجولات التالية.

## الجولات المنفذة على فرع التطوير

### الجولة الأولى — أساس الاستكشاف
- [x] مشهد المجموعة الشمسية التفاعلي وواجهة عربية وحفظ الاكتشافات.
- [x] مهمة تعليمية من ٩ أسئلة مع الشرح بعد كل إجابة.

### الجولة الثانية — ترقية المشهد الكوكبي
- [x] خامات إجرائية مختلفة للشمس والكواكب والقمر.
- [x] سحب السحب والغلاف الجوي للأرض، حلقات زحل، وهالة الشمس.
- [x] إيقاف حركة طبقات المؤثرات عند إيقاف الحركة.

### الجولة الثالثة — رحلة البحث الموجّهة
- [x] ثماني محطات لاكتشاف الكواكب باللمس أو من شريط الأسماء.
- [x] تلميح قصير لكل محطة، وتعزيز إيجابي دون مؤقت أو عقوبة.
- [x] حفظ عدد الرحلات المكتملة والمحطة الحالية محلياً، مع استئناف الرحلة بعد إغلاقها.

> اجتياز GitHub Actions يثبت استيراد المشروع والاختبارات الآلية وتصدير APK؛ ولا يثبت وحده جودة العرض أو الأداء على جهاز Android فعلي. لا تزال مراجعة اللمس، وترتيب الشفافية، ووضوح الواجهة، ومعدل الإطارات على الجهاز المستهدف مطلوبة. الجولات ٤–٩ لم تُنفذ بعد.

## رحلة الاستكشاف الموجّهة

- الطفل يتبع دليلاً واحداً في كل مرة للعثور على الكوكب الصحيح.
- يمكنه اختيار الكوكب من المشهد ثلاثي الأبعاد أو من شريط الأسماء.
- لا توجد مهلة زمنية أو نقاط سالبة عند اختيار عالم آخر.
- يبقى نشاط الأسئلة التسعة مستقلاً عن رحلة البحث.

## الجولة الأولى

- [x] إنشاء المستودع المستقل.
- [x] تثبيت Godot 4.7.2 stable وبنية المشروع.
- [x] مشهد ثلاثي الأبعاد إجرائي للشمس والكواكب الثمانية ومداراتها.
- [x] تنقل بالسحب واللمس والتقريب/الإبعاد، مع اختيار الكواكب.
- [x] واجهة عربية بخط محلي وشخصية رفيقة للاستكشاف.
- [x] حقائق علمية عربية قصيرة مع روابط مصادر NASA داخل بيانات المحتوى.
- [x] حفظ الكواكب المكتشفة محلياً مع ترحيل بيانات الحفظ القديمة.
- [x] مهمة أسئلة تعليمية من ٩ أسئلة مع شرح بعد الإجابة وحفظ أفضل نتيجة.
- [x] خيار إيقاف الحركة لتجربة أكثر هدوءاً.
- [x] اختبارات بيانات ومدخلات المهمة وحسابات المدارات.
- [x] إعداد GitHub Actions لبناء APK وفحص الحزمة والصلاحيات.
- [ ] اختبار APK فعلياً على جهاز Android مستهدف.

## أنشطة الجولة الأولى

- استكشاف حر للشمس والكواكب، مع تكبير وتدوير المشهد.
- تسع أسئلة قصيرة تغطي الشمس والكواكب الثمانية، بلا مؤقت أو عقوبة على الخطأ.
- تفسير بسيط يظهر بعد كل إجابة، مع حفظ أفضل نتيجة محلياً.
- يمكن إيقاف الحركة من الواجهة.

## التقنية

- **Engine:** Godot 4.7.2 stable (GDScript).
- **Renderer:** Compatibility / OpenGL ES 3.
- **Platform:** Android ARM64.
- **Offline-first:** لا حسابات، لا تحليلات، لا إعلانات، ولا طلبات شبكة في تجربة الطفل.
- **Build:** GitHub Actions؛ لا حاجة لبناء Android محلياً على هاتف المستخدم.

## البنية

`data/` بيانات الكواكب والمحتوى؛ `scripts/` منطق المشهد والواجهة والحفظ؛ `scenes/` مشاهد Godot؛ `tests/` فحوص آلية؛ `docs/` قرارات المنتج والمحتوى؛ `.github/workflows/` التحقق وبناء Android.

## الخصوصية وراحة الطفل

لا تطلب تجربة الطفل اتصالاً أو حساباً، ولا تحتوي على إعلانات أو تحليلات أو روابط خارجية قابلة للنقر. بيانات التقدم تحفظ محلياً على الجهاز فقط. لا يوجد مؤقت تنافسي أو عقوبة أو سلسلة استخدام يومية.

## مبدأ الدقة

الأبعاد والمسافات في المشهد مضغوطة بصرياً كي تظهر الكواكب على شاشة الهاتف. ترتيب الكواكب والحقائق التعليمية معلومة مستقلة عن هذا الضغط؛ ولا نعرض المشهد على أنه نموذج مقياس حقيقي. الحركة في المشهد توضيحية ومسرّعة وليست محاكاة فلكية دقيقة.

## مصادر علمية أساسية

- NASA Solar System Exploration: https://science.nasa.gov/solar-system/
- NASA Solar System Facts: https://science.nasa.gov/solar-system/solar-system-facts/
- NASA Space Place: https://spaceplace.nasa.gov/

تُراجع الحقائق قبل إدخالها إلى التطبيق، وتُحفظ الإحالات داخل ملفات التوثيق.

## الترخيص

المحتوى البرمجي الأصلي في هذا المستودع مرخّص بموجب MIT. الأصول الخارجية — إن أضيفت لاحقاً — يجب أن تحفظ نسبتها وترخيصها بصورة مستقلة.


## موسوعة اللعبة الكاملة — فرع تطوير المحتوى

بدأ إعداد المحتوى الموسع للعبة على فرع مستقل حتى لا يتداخل مع أساس التطوير الحالي أو مع `main`.

- [فهرس موسوعة اللعبة](docs/CONTENT_BIBLE_INDEX.md)
- [العالم والشخصيات والقصة](docs/WORLD_BIBLE.md)
- [الحملة والفصول](docs/CAMPAIGN_AND_EPISODES.md)
- [كتالوج المهمات](docs/MISSION_CATALOG.md)
- [الألعاب المصغرة والأنشطة](docs/MINIGAMES_AND_ACTIVITIES.md)
- [المكافآت والمجموعات](docs/REWARDS_AND_COLLECTIONS.md)
- [أطلس المحتوى العلمي](docs/SCIENCE_ATLAS.md)
- [دراسة الألعاب والمراجع](docs/RESEARCH_AND_INSPIRATION.md)
- [سجل الموارد والتقنيات](docs/ASSET_AND_TECH_REGISTER.md)
- [خطة الإنتاج ومعايير القبول](docs/PRODUCTION_BACKLOG.md)

هذه وثائق محتوى وتصميم وبحث؛ تنفيذ الشخصيات والمشاهد والأنشطة داخل التطبيق يأتي في مراحل إنتاج منفصلة.


## خطة الإنتاج والتنفيذ الجديد

- [خطة الإنتاج الشاملة](docs/MASTER_PRODUCTION_PLAN.md)
- [سجل التنفيذ والحالة الحالية](docs/IMPLEMENTATION_STATUS.md)
- [فهرس موسوعة اللعبة](docs/CONTENT_BIBLE_INDEX.md)
- خط محتوى JSON قابل للتحقق: الفصول والمهمات والحوارات والبطاقات العلمية والمكافآت داخل data/content.
- اختبار آلي لسجل المحتوى عبر Godot 4.7.2 في GitHub Actions.


### Gameplay systems implemented on the execution branch

- Event-driven mission progression with required and optional objectives: scripts/mission_director.gd
- Idempotent unlock ledger for non-repeatable rewards: scripts/reward_service.gd
- Integration test for mission completion, replay, optional objectives, reward uniqueness, and state round-trip: tests/validate_mission_runtime.gd
- GitHub Actions runs the mission runtime test before the main-scene smoke test.


### Mission progression, rewards and local saves
- Event-driven mission objectives and replay policy: `scripts/mission_director.gd`.
- Idempotent local reward ledger: `scripts/reward_service.gd`.
- Save schema v5 keeps legacy progress and adds mission/reward snapshots: `scripts/save_service.gd`.
- Integration and migration checks run in GitHub Actions before the main-scene smoke test.
- Current implementation is a tested systems foundation; the gameplay UI and 3D scenes are still pending.


### Integrated gameplay runtime
- `scripts/gameplay_runtime.gd` connects content loading, mission objectives, reward unlocking, and SaveService.
- Starting a mission, recording a valid objective event, and completing a mission persist local snapshots.
- `tests/validate_gameplay_runtime_integration.gd` checks integrated completion, reward persistence, runtime recreation, and replay idempotency.
- This is a gameplay service foundation. It is not yet connected to a new character or world scene.


### P2.1 — Character roster foundation
- Character profiles for Reem, Salim, and Lulu are data-driven.
- CharacterRoster resolves playable character selection and ability queries.
- Save schema v6 persists the selected character while preserving older progress.
- Automated tests cover roster order, ability lookup, invalid IDs, and save migration.
- This is a systems milestone; character meshes, rigs, animation, and in-world switching remain pending.


### خطة موجات التنفيذ والقبول
- [خطة التنفيذ ذات المراحل والبوابات والشرائح الرأسية](docs/EXECUTION_WAVE_PLAN.md)
- لا تُغلق ميزة قبل وجود commit واختبار CI؛ والميزات المرئية تحتاج تحققاً على Android الفعلي.

## خطة الاستفادة من المصادر المفتوحة والألعاب المترابطة

هذه الخطة موجودة على فرع مستقل فوق رأس فرع الإنتاج، ولا تعني أن الأصول أو الأنشطة قد نُفذت بعد.

- [الخطة التفصيلية للخطوات القادمة W0–W13](docs/IMPLEMENTATION_ROADMAP_NEXT_WAVES.md)
- [دليل الاستفادة من المشاريع والألعاب والأصول المفتوحة](docs/OPEN_SOURCE_REUSE_PLAYBOOK.md)
- [كتالوج الألعاب والأنشطة الفضائية المترابطة](docs/SPACE_ACTIVITY_CATALOG.md)
- [سجل نسب الأصول ومراجعة التراخيص](docs/ASSET_PROVENANCE_LEDGER.md)

كل نشاط جانبي يجب أن ينتمي إلى سفينة سَنا أو شخصية أو منطقة أو مهمة فضائية. نستفيد من المشاريع المفتوحة بعد تدقيق رخصة كل ملف ونسخته وحجمه وتوافقه، ولا نعتبر كلمة «مجاني» دليلاً كافياً على صلاحية الاستخدام. لا تعني هذه الوثائق أن الأصول أو الإضافات قد نُزّلت أو دُمجت.

## الشريحة القابلة للتجربة — سفينة سَنا

- [توثيق نموذج سفينة سَنا والألعاب الجانبية الأولى](docs/SANA_HUB_PROTOTYPE.md)
- [مواصفات الإنتاج البصري لسفينة سَنا والشخصيات والأصول](docs/SANA_HUB_VISUAL_PRODUCTION_SPEC.md)
- [نشاط بناء القاعدة القمرية — ورشة سليم](docs/LUNAR_OUTPOST_BUILDER.md)
- [نموذج بعثة الروفر الحمراء وعينة أصول KayKit CC0](docs/MARS_ROVER_SURVEY_PROTOTYPE.md)
- [تحويل ألعاب الفضاء المرجعية إلى أنشطة أصلية داخل عالمنا](docs/OPEN_SOURCE_GAMES_ADAPTATION.md)

هذه الشريحة على فرع تطوير مستقل. مشهد المجموعة الشمسية الأصلي يبقى كما هو، ويمكن بناء APK تجريبي مستقل لسفينة سَنا من GitHub Actions. النموذج الحالي يحتوي خمس محطات وثلاث ألعاب أولية: «رسالة مرقاب»، «ابنِ قمرك المصغّر»، و«أسرار لولو»؛ وما زال بحاجة إلى CI ناجح واختبار بصري ولمسي على Android.
