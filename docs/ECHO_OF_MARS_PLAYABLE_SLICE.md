# صدى المريخ — تنفيذ الشريحة القابلة للعب

**المشروع:** مستكشفو الكون  
**الفرع:** \`echo-mars-playable-slice-v1\`  
**أساس المحتوى:** \`FLAGSHIP_STORY_ECHO_OF_MARS.md\`  
**المحرك:** Godot 4.7.2 / GDScript / Compatibility  
**النطاق:** تجربة مستقلة قابلة للإطلاق والاختبار، ولا تستبدل المشهد الرئيسي.

## ما أُضيف في هذا الفرع

- مهمة بيانات \`mission.mars.echo_of_mars\` بفصل المريخ و11 هدفاً محدداً وأحداث allow-listed.
- خمسة مخططات حوار عربية تستخدم \`DialogueDirector\`.
- مكافأة تفتح مرة واحدة عند اكتمال المهمة.
- مشهد مستقل \`scenes/prototypes/echo_of_mars_vertical_slice.tscn\` يستخدم:
  - \`ContentRegistry\`
  - \`MissionDirector\`
  - \`DialogueDirector\`
  - \`CharacterRoster\`
  - \`InteractionRouter\`
  - \`RewardService\`
- استضافة مشهد الروفر الموجود داخل الشريحة بدلاً من نسخ منطق قيادته.
- إشارة \`site_scanned\` لتمرير الاكتشافات إلى المهمة.
- نمط embedded للروفر يعطل ملف حفظ الروفر المستقل ويتيح للأب إدارة التقدم، دون تغيير سلوك المشهد المنفصل افتراضياً.
- بطاقة في Prototype Showcase.
- اختبار تكاملي يغطي المحتوى، الحوار، الأحداث، الأدوار، الروفر، محطة الترحيل، إكمال المهمة والمكافأة.
- خطوة تصدير APK مستقل للشريحة، بمعرّف تطبيق منفصل عن التطبيق الرئيسي.

## تسلسل اللعب

1. فحص النبضات.
2. معايرة الأدوات.
3. اختيار موقع الهبوط.
4. قيادة الروفر وفحص ثلاثة مواقع.
5. التقاط صورتين من زاويتين.
6. تنفيذ مساهمات ريم وسليم ولولو.
7. مقارنة الحزم الثلاث.
8. إصلاح الطاقة والطبق والمشبك.
9. إرسال تأكيد الاستلام.
10. استكمال صفحة الرحلة ومكافأتها.

## إعادة استخدام المشاريع والأصول المفتوحة

- يعتمد البناء على مجموعة KayKit Space Base Bits المثبتة مسبقاً في خط CI على commit \`6dfbcac9927d06283752c4defd4882cfe0d29666\`؛ سجل المشروع يوثق رخصة CC0 1.0.
- نماذج GLTF الثمانية المحددة تُجهّز بواسطة خطوة CI الموجودة: \`basemodule_A\`, \`lander_A\`, \`landingpad_small\`, \`rocks_A\`, \`rocks_B\`, \`solarpanel\`, \`spacetruck\`, \`structure_low\`.
- لا تُضاف حزمة خارجية جديدة أو تنزيل جديد إلى هذا الفرع.
- بناء المقصورة والوادي ومحطة الترحيل يستعمل أشكالاً ومواد إجرائية خفيفة مع النماذج المتاحة.
- لا إضافة GDExtension أو مكتبة أصلية إلى APK.

## عزل الحفظ والبيانات

- ملف حفظ الشريحة: \`user://echo_of_mars_vertical_slice_v1.json\`.
- لا يتغير \`SaveService\` العام ولا إصدار الحفظ الرئيسي.
- عند تضمين مشهد الروفر، يتوقف حفظه المنفصل وتُدار معرفات المواقع المكتشفة في حفظ الشريحة.
- الاختبار يعطل حفظ الشريحة والروفر حتى لا يعدل بيانات المستخدم.
- لا تعديل على \`scenes/main.tscn\` أو \`scripts/main.gd\` أو إعداد المشهد الشمسي.

## ما يجب إثباته قبل اعتماد الشريحة

- نجاح Godot 4.7.2 على رأس الفرع نفسه.
- استيراد KayKit داخل الشريحة، ونجاح الاختبار الآلي، وتصدير APK.
- تثبيت APK وتجربة التسلسل كاملاً على Android فعلي.
- مراجعة وضوح العربية وأحجام اللمس، وقياس frame pacing والذاكرة والحرارة.
- فحص اتساق الشخصية: هذه النسخة تستخدم ملفات roster وقدراتها، وتعرض أشكالاً إجرائية مؤقتة لا نماذج نهائية أو هياكل Rig معتمدة.

**حالة التوثيق عند إعداد الملف:** كود الشريحة واختبارها وخط APK أضيفت إلى الفرع؛ لا تُعد Device Verified أو جاهزة للنشر حتى ينجح CI الدقيق وتتم مراجعة APK على جهاز فعلي.

## Visual foundation update — 7 November 2026

- Added a shared procedural Mars landscape builder used by the story and rover scenes.
- Replaced the flat floor and box-wall horizon with a subtle terrain grid, five layered mesa formations, six boulder clusters, a sun disc, and a shared procedural atmosphere.
- Added a dedicated headless test and a matching GitHub Actions validation step.
- No new third-party packages or asset downloads were added.
- Physical Android visual, touch, and performance validation remains required.