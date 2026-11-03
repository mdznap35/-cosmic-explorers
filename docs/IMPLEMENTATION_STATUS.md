# سجل التنفيذ والحالة الحالية

## Current state — 2026-11-03

- Active work branch: cosmic-production-roadmap-v1.
- Base branch: world-bible-content-v1.
- main لم يُعدّل.
- PR #2 ما زال مفتوحاً وغير مدمج.
- PR #3 مسودة مفتوحة على world-bible-content-v1، وليس على main.
- النظام الأصلي: مشهد تفاعلي للمجموعة الشمسية، كتالوج كواكب، مهمة أسئلة أولية، استكشاف موجّه، حفظ محلي، وبناء Android آلي.
- ما زال غير منفذ في runtime: متحكمات الشخصيات الثلاث، سفينة سَنا، حلقة الصاروخ والسفر، استكشاف السطح، وواجهات ربط المهمات بالمشاهد.
- فرع world-bible-content-v1 يحوي 13 وثيقة للمحتوى والقصة والحملة والمهمات والأنشطة والعلوم والموارد.
- الخطة الرئيسية: docs/MASTER_PRODUCTION_PLAN.md.

## الأنظمة المنفذة

### P1 — خط المحتوى
- [x] ContentRegistry لقراءة JSON ذات schema version.
- [x] بيانات 3 فصول، 4 مهمات، 4 بطاقات علمية، سلسلتي حوار، و4 مكافآت.
- [x] فحص المعرفات والمراجع والمصادر وعقد الحوار وإمكانية الوصول.
- [x] اختبار إيجابي وسلبي مربوط بـ GitHub Actions.

### P6 — قلب المهمات والجوائز
- [x] MissionDirector event-driven للأهداف المطلوبة والاختيارية.
- [x] عدّ الأهداف ذات target_count ومنع الإكمال المبكر.
- [x] استئناف مهمة نشطة من لقطة بيانات.
- [x] إعادة لعب المهمات دون تكرار مكافأة الإنجاز الأول.
- [x] RewardService مع منح idempotent.

### Persistence — الحفظ المحلي
- [x] ترقية SAVE_VERSION من 4 إلى 5.
- [x] ترحيل يحافظ على الكواكب والإحصاءات والتقدم الموجّه.
- [x] تخزين واستعادة mission_runtime وreward_runtime.
- [x] اختبارات ترحيل الإصدارات 1 و4 و5 وكتابة/قراءة اللقطات من ملف الحفظ.

### Integrated Gameplay Runtime — ربط الأنظمة
- [x] GameplayRuntime يحمّل المحتوى ويهيئ MissionDirector وRewardService من SaveService.
- [x] بدء المهمة يحفظ الحالة النشطة.
- [x] استقبال حدث هدف يحفظ التقدم.
- [x] إكمال المهمة يمنح المكافآت المقررة ثم يحفظ سجلها.
- [x] إرسال الإشارات لتحديث الواجهة لاحقاً.
- [ ] اختبار Godot/CI على رأس PR الحالي.

## أدلة CI مكتملة

- Run 41659623657 — success: اختبار مدير المهمات والجوائز وتصدير APK.
  https://github.com/mdznap35/-cosmic-explorers/actions/runs/41659623657
- Run 41661150681 — success: اختبارات المحتوى والمهمات والجوائز وترحيل SAVE_VERSION 5 والحفظ من/إلى الملف وسموك المشهد وتصدير APK.
  Exact tested commit: 7321a7bf2b0c313f88a1a1879951c19c240cf92a
  https://github.com/mdznap35/-cosmic-explorers/actions/runs/41661150681
  Artifact ID: 13241922286; size: 42,243,608 bytes; SHA-256 archive digest: 6acef1b6309a5a126fff6ddfec0203fc2a7de1e65e6bd7fa8ec166baa59d196b.

## الدفعة الحالية — Integrated Gameplay Runtime

- scripts/gameplay_runtime.gd ينسق نظام المحتوى والمهمات والجوائز والحفظ.
- tests/validate_gameplay_runtime_integration.gd يفحص التدفق الكامل من بدء المهمة إلى استعادة التقدم وإعادة اللعب.
- أضيف اختبار التكامل إلى GitHub Actions.
- الحالة: التغييرات رُفعت؛ CI الجديد لم يثبت بعد.

## الحدود الصريحة

- أنظمة المحتوى والمهمات والجوائز والحفظ تعمل كخدمات قابلة للاختبار، لكنها لم تُربط بعد بواجهة طفل أو مشاهد عالم جديدة.
- لم تُنفذ الشخصيات الثلاثية الأبعاد أو سفينة سَنا أو الصاروخ أو بيئة المريخ الجديدة في هذه الدفعات.
- لا يوجد اختبار فعلي على Galaxy A15 حتى الآن.
- نجاح CI لا يثبت الجودة البصرية أو الأداء الحراري على الهاتف.
- PR #3 لا يزال مسودة ولم يُدمج؛ لا تغييرات على main.

## الخطوة التالية الأعلى قيمة

بناء واجهة مهمة قابلة للعب على المشهد المستقل، ثم CharacterController والتحكم اللمسي وغرفة قيادة سَنا، ثم شريحة المريخ من السفر حتى العودة.


## P2.1 — بيانات الشخصيات ونظام الاختيار (دفعة قيد التحقق)

- [x] إضافة ملفات تعريف مستقلة لريم وسليم ولولو في `data/content/characters.json`.
- [x] توحيد تعريف قدرات اللعب بمعرفات مستقرة لكل شخصية.
- [x] إضافة `CharacterRoster` لاختيار الشخصية والاستعلام عن قدراتها.
- [x] حفظ الشخصية المختارة محلياً مع ترحيل آمن إلى `SAVE_VERSION 6`.
- [x] توسيع `ContentRegistry` للتحقق من ملفات الشخصيات ومراجع المهمات والحوار.
- [x] إضافة اختبارات للشخصيات والقدرات والاختيارات غير الصالحة وترحيل الحفظ.
- [x] إضافة اختبار roster إلى GitHub Actions.
- [x] CI نجح على commit `783f60b0d3abd76b17a6b8db683c4e4611095ad1` بعد إضافة اختبارات roster وInteractionRouter، وتصدير APK. [Run 41666153049](https://github.com/mdznap35/-cosmic-explorers/actions/runs/41666153049).
- [ ] ربط الاختيار بمشهد 3D وتحكم لمسي واختبار تبديل حي على الجهاز.

**الحد:** هذه بيانات ونظام اختيار قابلان للاختبار، وليسا نماذج شخصيات ثلاثية الأبعاد أو Rig أو حركات جاهزة. حالة النماذج مسجلة صراحة بأنها لم تُنتج بعد.


## P2.2 — بوابة أحداث التفاعل

- [x] إضافة `InteractionRouter` يستخرج قائمة الأحداث المسموح بها من أهداف المهمات.
- [x] منع تمرير أحداث غير معرّفة أو payloads تحتوي Objects/كائنات تنفيذية.
- [x] إضافة اختبار قبول ورفض وربطه بخط CI.
- [x] CI نجح على commit `783f60b0d3abd76b17a6b8db683c4e4611095ad1`؛ اختبار التفاعل وتصدير APK اجتازا التشغيل رقم 41666153049.
- [ ] توصيل نقاط التفاعل في المشاهد بالـrouter ثم بـGameplayRuntime.


## Evidence — CI after P2.1 and P2.2

- Tested commit: `783f60b0d3abd76b17a6b8db683c4e4611095ad1`.
- GitHub Actions run: https://github.com/mdznap35/-cosmic-explorers/actions/runs/41666153049 — success.
- Automated checks passed: project import, planet catalog/orbit math, existing missions, visual resources, guided exploration, content registry, character roster, interaction router, mission/reward runtime, save migration, gameplay runtime integration, and main-scene smoke test.
- Android debug APK exported and uploaded as artifact ID `13244823318`.
- Artifact archive: 42,262,863 bytes; SHA-256 digest: `12540e6c8b56bbbdb04307623b8c24e87907133ee6dd8d9d0a12c8042fb64ae6`.
- This verifies CI and export only. It does not verify visual quality, touch feel, frame rate, thermal behavior, or playability on Galaxy A15.


## P2.3 — DialogueDirector

- [x] إضافة مفسّر حوار runtime للحوارات المتفرعة المعرّفة في JSON.
- [x] دعم البدء والتنقل الخطي والاختيارات والنهايات والتخطي وإعادة التشغيل.
- [x] منع تشغيل حوار غير معروف أو متابعة حوار منتهٍ.
- [x] إضافة اختبار للمسارات المتفرعة والنهاية والتخطي وربطه بـ CI.
- [ ] ربطه بواجهة حوار عربية وصوت اختياري ومشاهد الشخصيات.


## Evidence — DialogueDirector CI

- Tested commit: `d5dd1ddbb739bb82c8447129ee9f66978dc46194`.
- GitHub Actions run: https://github.com/mdznap35/-cosmic-explorers/actions/runs/41666671001 — success.
- Dialogue graph runtime tests passed: branching choices, linear progression, terminal completion, skip, and invalid-state rejection.
- Full project import, all content/roster/router/mission/reward/save/integration tests, main-scene smoke test, and Android debug export passed.
- APK artifact ID: `13245977458`; archive size: 42,268,647 bytes; SHA-256: `1fdcf4ced6b779c15f25c2c1a1118b1bcbb143d6c2181a997f57caafd5810966`.
- This is CI/export evidence only; visual and device verification remain open.
