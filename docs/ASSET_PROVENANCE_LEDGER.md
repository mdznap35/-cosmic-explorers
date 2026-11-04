# سجل نسب الأصول ومراجعة التراخيص
> الحالة الابتدائية: مرشحون فقط — 3 نوفمبر 2026  
> لا يوجد أصل جديد في هذا السجل مثبت على أنه مستورد داخل التطبيق.

## 1. السجل

| المعرّف | المورد/الحزمة | المصدر الأصلي | الرخصة المنشورة | الاستخدام المخطط | الحالة |
|---|---|---|---|---|---|
| ASSET-KENNEY-STATION | Kenney Space Station Kit | https://kenney.nl/assets/space-station-kit | CC0 1.0 | 80+ نموذجاً؛ ZIP معلن 1.7 MB؛ OBJ/FBX/glTF؛ بناء غرفة سفينة ومحطة اختبار | candidate — لم ينزّل بعد؛ SHA-256 غير مسجل |
| ASSET-KAYKIT-SPACE-BASE-BITS | KayKit Space Base Bits 1.0 | https://github.com/KayKit-Game-Assets/KayKit-Space-Base-Bits-1.0 | CC0 1.0 Universal (LICENSE.txt in pinned repository) | عينة من 8 نماذج GLTF مع buffers وخامة أطلس؛ lander/outpost/rocks/solar panel/truck | staged and imported by GitHub Actions from commit `6dfbcac9927d06283752c4defd4882cfe0d29666`; the eight-model load test passed in run #86; SHA-256 manifest generated per run; Android device verification pending |
| ASSET-KENNEY-SFX | Kenney Interface Sounds | https://kenney.nl/assets/interface-sounds | CC0 | مؤثرات واجهة مختارة | candidate |
| ASSET-QUATERNIUS-ANIM | Quaternius Universal Animation Library | https://quaternius.com/packs/universalanimationlibrary.html | CC0 | اختبار حركات ريم وسليم | candidate |
| ASSET-POLYHAVEN | Poly Haven | https://polyhaven.com/license | CC0 حسب صفحة الترخيص العامة | خامات أو HDRI مختارة | candidate |
| ASSET-SOLARSYSTEMSCOPE | Solar System Scope textures | https://www.solarsystemscope.com/textures/ | CC BY 4.0 | خرائط كوكبية موجودة في مسار PR #2 | branch-dependent |
| ASSET-NASA-3D | NASA 3D Resources | https://science.nasa.gov/3d-resources/ | فحص كل ملف وإرشادات NASA | نماذج علمية محددة | candidate |

## 2. سجل الملفات الفعلية — يُملأ بعد الاستيراد

لكل ملف أو مجموعة ملفات، أضف سجلاً يتضمن:
- asset_id:
- اسم الملف الأصلي:
- اسم الملف داخل المشروع:
- رابط الصفحة الأصلية:
- اسم الناشر/المؤلف:
- نص الرخصة ورابطها:
- هل هناك مواد طرف ثالث:
- رقم الإصدار أو commit:
- تاريخ التنزيل:
- حجم التنزيل:
- SHA-256:
- الصيغة الأصلية:
- الصيغة بعد التحويل:
- التعديلات التي أجريت:
- المشاهد التي تستخدم الأصل:
- حالة فحص Godot:
- حالة فحص Android:
- الملاحظات والقيود:

## 3. أدلة التراخيص المعروفة

- Kenney يعلن أن أصول صفحات الحزم مرخصة CC0، ويطلب الرجوع إلى صفحة كل حزمة أو ملف الرخصة المرفق: https://kenney.nl/support
- صفحة Kenney Space Station Kit تعرض 90 ملفاً ورخصة CC0: https://kenney.nl/assets/space-station-kit
- Poly Haven يعلن CC0 لجميع أصوله المنشورة، مع إتاحة الاستخدام التجاري وإعادة التوزيع: https://polyhaven.com/license
- Solar System Scope يعلن CC BY 4.0، ويذكر وجود مناطق غير مكتملة ممثلة بتضاريس خيالية وتشبع لوني أكبر في بعض الخرائط: https://www.solarsystemscope.com/textures/
- NASA تذكر أن كثيراً من موادها لا تخضع عادة لحقوق النشر في الولايات المتحدة، لكن توجد مواد لطرف ثالث يجب تدقيقها، وشعارات وهوية NASA لها قيود خاصة: https://www.nasa.gov/nasa-brand-center/images-and-media/

## 4. نطاق الاختيار الفني\n\nتُعطى الأولوية للمحطات والبيئات الداخلية والمركبات العلمية وأدوات الرصد والاستكشاف والخامات والحركات. لا نُدخل محتوى لا يخدم تجربة الاستكشاف السلمي والتعلم والمرح الآمن.\n\n## 5. قاعدة التغيير

- لا تحول candidate إلى imported بمجرد التنزيل.
- لا تحول imported إلى approved قبل اكتمال الحقوق والاستيراد والاختبار.
- لا تستخدم رابطاً متحركاً لفرع main في البناء؛ ثبّت إصداراً أو commit.
- لا تسجل SHA-256 قبل الحصول على الملف الفعلي وحسابه.
- إذا تعذر إثبات الرخصة، ارفض الأصل أو اطلب إذناً واضحاً.
- احتفظ بإشعارات الرخصة وشروط النسب ضمن حزمة التسليم.
- عند إزالة أصل، أبقِ سجل قرار الإزالة حتى لا يعاد إدخاله لاحقاً بالخطأ.

## 6. الحالات المسموحة

- candidate: مصدر مناسب مبدئياً، لم ينزل بعد.
- downloaded: تم تنزيله والتحقق من المصدر والحجم والـhash.
- imported: أضيف إلى شجرة المشروع.
- tested: نجح استيراده واختباره في مشهد.
- device_verified: اجتاز تجربة Android موثقة.
- approved: مقبول للاستخدام في النسخة المحددة.
- rejected: مرفوض، مع توثيق السبب.

هذا السجل إداري وحقوقي. لا يمثل رأياً قانونياً، وتجب إعادة مراجعة الرخصة عند اعتماد إصدار نهائي.

## 7. إدخال KayKit Space Base Bits — عينة مربوطة بالبناء

- المستودع الرسمي: https://github.com/KayKit-Game-Assets/KayKit-Space-Base-Bits-1.0
- commit ثابت: `6dfbcac9927d06283752c4defd4882cfe0d29666`.
- الرخصة المرفقة داخل المصدر: CC0 1.0 Universal.
- المسارات التي ينسخها CI فقط: `basemodule_A`, `lander_A`, `landingpad_small`, `rocks_A`, `rocks_B`, `solarpanel`, `spacetruck`, `structure_low` مع ملفات GLTF وBIN وخامة الأطلس وLICENSE.
- لا تنسخ الحزمة كاملة ولا ملفات لا تخدم تجربة الاستكشاف. يحسب CI SHA-256 فعلياً للملفات المنسوخة في كل تشغيل.
- الحالة بعد التحقق: tested in GitHub Actions run #86 (code commit `d18c5c08486d15b85b3f7fb1b24da9abd9e3d392`); ما زالت device_verified غير مكتملة حتى اختبار Android فعلي.
