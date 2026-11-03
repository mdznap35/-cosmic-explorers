# سجل نسب الأصول ومراجعة التراخيص
> الحالة الابتدائية: مرشحون فقط — 3 نوفمبر 2026  
> لا يوجد أصل جديد في هذا السجل مثبت على أنه مستورد داخل التطبيق.

## 1. السجل

| المعرّف | المورد/الحزمة | المصدر الأصلي | الرخصة المنشورة | الاستخدام المخطط | الحالة |
|---|---|---|---|---|---|
| ASSET-KENNEY-SPACE | Kenney Space Kit | https://kenney.nl/assets/space-kit | CC0 | قطع فضائية ومركبات للـgraybox | candidate |
| ASSET-KENNEY-STATION | Kenney Space Station Kit | https://kenney.nl/assets/space-station-kit | CC0 | بناء غرفة سفينة ومحطة اختبار | candidate |
| ASSET-KENNEY-SFX | Kenney Interface Sounds | https://kenney.nl/assets/interface-sounds | CC0 | مؤثرات واجهة مختارة | candidate |
| ASSET-QUATERNIUS-SPACE | Quaternius Ultimate Space Kit | https://quaternius.com/packs/ultimatespacekit.html | CC0 | عناصر بيئة ومركبات منتقاة | candidate |
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
- صفحة Kenney Space Kit تعرض 150+ ملفاً ورخصة CC0؛ قائمة itch تعرض ملفاً مضغوطاً بحجم 6.3 MB: https://kenney.nl/assets/space-kit وhttps://kenney-assets.itch.io/space-kit
- صفحة Kenney Space Station Kit تعرض 90 ملفاً ورخصة CC0: https://kenney.nl/assets/space-station-kit
- Quaternius Ultimate Space Kit يعرض 92 نموذجاً وصيغ FBX/OBJ/Blend/glTF ورخصة CC0: https://quaternius.com/packs/ultimatespacekit.html
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
