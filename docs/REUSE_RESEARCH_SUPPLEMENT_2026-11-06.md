# ملحق البحث: مرشحون إضافيون لإعادة الاستخدام

**تاريخ التحقق:** 6 نوفمبر 2026  
**الغرض:** توسيع قائمة الجولة الثانية بمصادر إضافية مفيدة، خصوصاً أنظمة المركبات والتضاريس وأمثلة المحرك.  
**الحالة:** بحث وفرز مكتبي فقط. لم يتم تنزيل هذه الحزم أو إدخالها في APK في هذه الإضافة.

## 1. إضافات فنية صغيرة وعالية القيمة

| المورد | حقائق من صفحة الناشر | الترخيص والحجم المنشور | قرارنا |
|---|---|---|---|
| [Kenney Space Kit](https://kenney.nl/assets/space-kit) | أكثر من 150 نموذجاً، وصيغ OBJ/FBX/DAE/STL/glTF | CC0؛ ZIP على صفحة itch نحو 6.3 MB | اختبار أولي لسفينة سَنا والعناصر الخارجية. نقارن الجودة والتناسق مع Quaternius modular kit، ولا نضم الحزمتين كاملتين |
| [Kenney UI Pack](https://kenney.nl/assets/ui-pack) | أكثر من 400 sprite ومصادر منفصلة/vector | CC0؛ ZIP نحو 1.1 MB | نستعمله كمادة خام للأيقونات وحالات الأزرار فقط، ونبني نظام واجهة عربي أصلي |
| [Kenney Interface Sounds](https://kenney.nl/assets/interface-sounds) | 100 مؤثر واجهة منفصل، بصيغة OGG وفق صفحة الحزمة/المرآة المعروفة | CC0؛ الحجم غير مثبت من صفحة الناشر | نختار أصواتاً قليلة للتفاعل؛ لا نستخدمه بديلاً عن تصميم صوتي وموسيقى أصلية |
| [Poly Haven License](https://polyhaven.com/license) | نماذج وخامات وHDRI | الموقع يعلن CC0 لكل الأصول التي ينشرها | مصدر موثوق لخامات محددة؛ نختار كل ملف باسمه وإصداره ودقته ونحفظ بصمته |
| [ambientCG](https://ambientcg.com/) | مكتبة خامات PBR وHDRI ونماذج | CC0 حسب الموقع | مصدر بديل للخامات. لا نخلط خامات photoreal مع أسلوب stylized دون معالجة وتوحيد |

### قيود استخدام الحزم
- أرقام الملفات والأحجام هي بيانات نشر، وليست قياسات تنزيل أجريت في هذه الجولة.
- لا يتم تضمين أي حزمة كاملة تلقائياً.
- نحتفظ بالملفات المنتقاة فقط، ونوثق LICENSE وSHA-256 وحجم APK قبل/بعد.
- لا نعيد محاولة أرشيف Kenney Space Station Kit الذي فشل تحقق البصمة سابقاً. Space Kit مورد مستقل وليس نفس الأرشيف.

## 2. أنظمة جاهزة للمركبة والتضاريس

### 2.1 Godot Easy Vehicle Physics
- المصدر: https://github.com/DAShoe1/Godot-Easy-Vehicle-Physics
- الرخصة المنشورة: MIT.
- التنفيذ قائم على ray casts ويعمل مع Godot Physics وJolt بحسب وصف المستودع.
- القرار: **مرشح اختبار منفصل للروفر**. نحتاج فقط توجيهاً ناعماً وتعليقاً مبسطاً وحركة عجلات مقنعة. لا ننقل إعدادات السباق أو gearbox أو drift أو أي نظام غير مطلوب.
- بوابة القبول: تشغيل عينة أربع عجلات في Godot 4.7.2 Compatibility، اختبار لمس، قياس frame pacing، ثم مقارنة مع kinematic rover. نختار الأبسط الذي يعطي إحساساً بصرياً مقنعاً.

### 2.2 Godot Mobile Terrain Editor
- المصدر: https://github.com/stfnlacio/godot-mobile-terrain-editor
- الرخصة المنشورة: MIT.
- يذكر المستودع أنه مكتوب بـGDScript وshader واحد، دون GDExtension أو مكتبات native، ويحتوي heightmaps وتصادماً تكيفياً وطبقات خامات.
- القرار: **أداة تأليف خارجية محتملة** لبناء منطقة المريخ، وليس أداة runtime داخل APK. نختبر إنشاء تضاريس صغيرة ثم تصديرها كـmesh وخامة وتصادم ثابت.
- بوابة القبول: لا تدخل إضافة المحرر إلى نسخة الطفل؛ تدخل فقط ملفات المنطقة النهائية بعد تحسينها واختبارها.

### 2.3 Godot Official Demo Projects
- المصدر: https://github.com/godotengine/godot-demo-projects
- الرخصة المنشورة: MIT.
- إصدار 4.7 يتضمن أمثلة حديثة مفيدة مثل Visibility Ranges/HLOD وSky Shaders وPhysics Interpolation وTonemapping/Color Correction وNavigation Mesh Chunks.
- القرار: **مرجع هندسي أول** قبل إضافة plugin خارجي. نأخذ المثال المحدد أو النمط اللازم فقط، ونثبت إصدار 4.7/commit بدلاً من تتبع master.

### 2.4 Jeheno Third Person Controller
- المصدر: https://github.com/Jeh3no/Godot-Third-Person-Controller
- الرخصة المنشورة: MIT؛ صفحة Asset Library تشير إلى توافق Godot 4.4–4.7.
- يقدم FSM للحركة وتسارعاً وتباطؤاً وكاميرا وحركات ومؤثرات نموذجية، لكن صفحة المتجر تضع علامة unstable.
- القرار: **مصدر مراجعة واختبار، لا اعتماد مباشر**. نستخرج ما يلزم من FSM أو الكاميرا بعد فحص ملفات المصدر، ونختبر اللمس على Android. لا نضم النموذج التجريبي كاملاً.

## 3. إعادة ترتيب الأولويات بعد البحث الإضافي

| الأولوية | التجربة | لماذا الآن؟ | مخرج الاختبار |
|---|---|---|---|
| P0 | Kenney Space Kit مقابل Quaternius Modular Sci-Fi | جودة جسر القيادة هي أكبر فجوة فنية في النسخة الحالية | غرفة قيادة واحدة مع مقارنة صور فعلية |
| P0 | Quaternius Universal Base Characters + Animation Library | الشخصية البشرية والحركة عنصران بطوليان مفقودان | شخصية بشرية واحدة مع 6–8 حركات مجربة |
| P1 | Vehicle Physics مقابل Kinematic Rover | حركة الروفر الحالية مباشرة وبسيطة جداً | نموذج قيادة صغير قابل للعب على Android |
| P1 | Mobile Terrain Editor كأداة تأليف | نحتاج تضاريس مريخية مميزة دون إضافة محرك تضاريس ثقيل | منطقة صغيرة baked إلى أصول ثابتة |
| P1 | Godot 4.7 demo examples | قد توفر HLOD وSky/tonemapping/interpolation دون اعتماد جديد | اختبار تأثير محدد داخل مشهد الإنتاج |
| P2 | UI Pack وInterface Sounds | تحسين الإحساس والتناسق بعد تثبيت التصميم العام | عينة HUD عربية وطبقة أصوات قصيرة |
| P2 | Poly Haven/ambientCG | تحسين سطح الصخور والمعادن | خامتان/ثلاث خامات منخفضة الدقة |

## 4. قواعد التنزيل والتحقق

قبل أي تنزيل:
1. يكتب اسم الحزمة والنسخة والحجم المتوقع في طلب التنفيذ.
2. يجلب الملف على GitHub Actions أو بيئة سحابية؛ لا يستخدم اتصال الهاتف.
3. يتحقق من HTTP status ونوع الملف وZIP magic وعدد البايتات.
4. يحسب SHA-256 بعد التنزيل.
5. يفحص قائمة الملفات وLICENSE قبل الاستخراج أو النسخ.
6. يستورد فقط subset محدداً، مع إبقاء الأصل الكامل خارج مجلد runtime.
7. يسجل عدد المثلثات وأبعاد textures والخامات والذاكرة التقديرية.
8. يختبر الأصل في مشهد معزول على Godot 4.7.2 Compatibility.
9. يقارن أثره على APK وعلى الأداء.
10. يرفض أي أصل لا يرفع جودة المشهد النهائي بصورة مرئية ومقاسة.

## 5. مراجع المصدر

- Kenney Space Kit: https://kenney.nl/assets/space-kit
- Kenney UI Pack: https://kenney.nl/assets/ui-pack
- Kenney Interface Sounds: https://kenney.nl/assets/interface-sounds
- Poly Haven license: https://polyhaven.com/license
- ambientCG: https://ambientcg.com/
- DAShoe Vehicle Physics: https://github.com/DAShoe1/Godot-Easy-Vehicle-Physics
- Mobile Terrain Editor: https://github.com/stfnlacio/godot-mobile-terrain-editor
- Godot Demo Projects: https://github.com/godotengine/godot-demo-projects
- Jeheno Third Person Controller: https://github.com/Jeh3no/Godot-Third-Person-Controller
- Quaternius Universal Animation Library: https://quaternius.com/packs/universalanimationlibrary.html

**الخلاصة:** القيمة ليست في عدد الحزم التي نضيفها؛ بل في اختيار نظام بيئي أساسي واحد لكل مجال، واختبار عينة حقيقية منه، ثم إعادة استخدام ما نجح فقط.
