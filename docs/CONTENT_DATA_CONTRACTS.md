# عقود بيانات المحتوى — تحويل الموسوعة إلى بيانات لعبة

## الهدف

نفصل النصوص والمهام والحوار والمكافآت عن كود المشاهد. هذا يجعل إضافة فصل أو ترجمة أو تعديل حقيقة علمية ممكناً دون تعديل منطق اللعبة في كل مرة.

هذا المستند **اقتراح عقد بيانات**؛ لم يُنفّذ بعد كمحلل أو Resource في Godot.

## 1. قواعد عامة

- كل سجل له معرف ثابت lowercase ASCII لا يتغير عند تعديل العنوان.
- كل علاقة تشير إلى معرف موجود، ويجب أن يفشل فحص المحتوى إن كان المرجع مكسوراً.
- النص العربي هو المصدر الأساسي في النسخة الأولى، لكن نترك حقول الترجمة قابلة للتوسع.
- لا نحفظ نصاً حساساً أو بيانات شخصية للطفل.
- لا نضع URL خارجي قابل للنقر داخل واجهة الطفل؛ الروابط تبقى في metadata للمراجعة.
- كل محتوى علمي يحمل مصدره ودرجة اليقين وتاريخ المراجعة.
- لا تُحفظ المكافأة أكثر من مرة لنفس حدث الإنجاز إلا إذا صُممت صراحة كمكافأة قابلة للتكرار.

## 2. عقد بطاقة اكتشاف

~~~yaml
id: science.mars.iron_oxide
kind: science_card
topic: mars
title_ar: لماذا يبدو المريخ أحمر؟
child_text_ar: يرتبط اللون الأحمر في كثير من غبار وصخور المريخ بأكاسيد الحديد.
more_text_ar: تشبه هذه المواد الصدأ في ارتباط اللون بأكاسيد الحديد، لكن بيئة المريخ مختلفة عن الأرض.
certainty: established_fact
source:
  url: https://science.nasa.gov/mars/facts/
  checked_on: 2026-11-03
visual:
  asset_id: planet.mars.surface_01
  caption_ar: تصور بصري لسطح المريخ
interaction:
  type: sample_compare
  activity_id: activity.mars.sample_lab
~~~

## 3. عقد مهمة

~~~yaml
id: mission.mars.rover_tracks
chapter_id: chapter.mars
title_ar: آثار على الرمال الحمراء
summary_ar: قُد الروفر إلى منطقة المسح والتقط صوراً للسطح.
scene_id: scene.mars_rover_field
lead_character: reem
available_characters: [reem, salim, lulu]
objectives:
  - id: objective.scan_rocks
    required: true
    event: scanner.sample_recorded
    target_count: 2
  - id: objective.find_hidden_mark
    required: false
    event: discovery.hidden_mark_found
    target_count: 1
completion:
  event: mission.completed
  reward_ids:
    - reward.badge.mars_field_scientist
  science_card_ids:
    - science.mars.iron_oxide
feedback:
  retry_text_ar: جرّب زاوية أخرى. لا يزال لدينا وقت للملاحظة.
  completion_text_ar: سجلنا ملاحظتين جديدتين في أطلس الضوء.
replay:
  enabled: true
  variation_pool: [mars.sample_set_a, mars.sample_set_b, mars.sample_set_c]
~~~

## 4. عقد حوار

~~~yaml
id: dialogue.mars.first_sample
speaker: reem
start_node: observe_color
nodes:
  observe_color:
    text_ar: لاحظ لون هذه العينة. ماذا ترى؟
    choices:
      - text_ar: لون أحمر صدئ
        next: explain_iron
      - text_ar: أريد تكبير الصورة
        next: magnify_sample
  explain_iron:
    text_ar: يرتبط هذا اللون بأكاسيد الحديد في كثير من مواد سطح المريخ.
    next: ask_more
  magnify_sample:
    text_ar: فكرة جيدة. لنقرب الصورة ونلاحظ التفاصيل.
    effects: [ui.open_sample_zoom]
    next: explain_iron
  ask_more:
    text_ar: الصورة دليل يساعدنا، لكننا نحتاج إلى أدوات أخرى لفهم العينة.
    next: end
~~~

## 5. عقد لعبة مصغرة

~~~yaml
id: minigame.zero_g_bubbles
category: pure_fun
title_ar: فقاعات في كل مكان
description_ar: حرّك الفقاعات الملونة داخل الغرفة واجمعها في أشكال لطيفة.
learning_objective: null
scene_id: scene.arcade.zero_g_bubbles
controls:
  primary: touch_drag
  secondary: tap
modes:
  - free_play
  - pattern_cards
difficulty:
  default: gentle
  options: [gentle, standard, challenge]
timer:
  enabled_by_default: false
rewards:
  first_completion: reward.sticker.bubble_lulu
save:
  persist_best_score: false
  persist_unlocked_patterns: true
~~~

## 6. عقد المكافأة

~~~yaml
id: reward.badge.mars_field_scientist
kind: badge
title_ar: محقق المريخ
description_ar: أكملت رحلة مسح المريخ وسجلت ملاحظاتك.
icon_asset: ui.badges.mars_detective
unlock:
  event: mission.completed
  mission_id: mission.mars.rover_tracks
repeatable: false
~~~

## 7. عقد مجموعة

~~~yaml
id: collection.solar_moons
title_ar: ألبوم الأقمار
entry_ids:
  - discovery.moon.earth
  - discovery.moon.phobos
  - discovery.moon.deimos
  - discovery.moon.europa
  - discovery.moon.ganymede
  - discovery.moon.callisto
  - discovery.moon.titan
  - discovery.moon.enceladus
completion_reward: reward.decor.moon_gallery
display:
  show_missing_entries: true
  show_count: true
~~~

## 8. أحداث اللعبة الموحدة

الأحداث المقترحة للتواصل بين أنظمة الحركة والمهمات والحفظ:
- player.interacted
- character.switched
- dialogue.started
- dialogue.choice_selected
- scanner.sample_recorded
- photo.captured
- rover.waypoint_reached
- puzzle.completed
- discovery.unlocked
- mission.objective_updated
- mission.completed
- collection.entry_added
- reward.unlocked
- scene.entered
- save.requested

لا يسمح لنص حوار أو ملف محتوى بتنفيذ كود عام أو استدعاء دوال اعتباطية. الأحداث والآثار قائمة مسموحة ومحدودة يفسرها منطق اللعبة.

## 9. فحوص آلية مطلوبة

1. عدم تكرار ID.
2. كل chapter_id وscene_id وreward_id وscience_card_id موجود.
3. كل مهمة لها هدف رئيسي على الأقل.
4. كل بطاقة علمية لها source URL وchecked_on وcertainty.
5. كل اختيار حوار يصل إلى عقدة موجودة أو نهاية.
6. لا يوجد مسار حوار لا يمكن الوصول إليه.
7. كل لعبة مصغرة لها طريقة خروج واضحة.
8. كل مكافأة فريدة لا تُمنح مراراً.
9. كل النصوص تظهر دون قص في واجهة العربية RTL.
10. لا يُسمح بمورد خارجي runtime-required في وضع اللعب دون اتصال.

## 10. سياسة التحديث والترحيل

- كل حزمة محتوى تحمل schema_version.
- عند تغيير بنية البيانات يضاف migration واضح.
- لا يُحذف تقدم محفوظ عند تحديث إصدار اللعبة.
- إذا اختفى ID قديم، يحتفظ النظام بسجل إكماله أو يربطه بمعرف بديل.
- تُختبر ملفات المحتوى قبل تصدير APK في GitHub Actions.
- لا يتطلب تعديل النصوص تحديث كل المشاهد إذا بقي العقد مستقراً.
