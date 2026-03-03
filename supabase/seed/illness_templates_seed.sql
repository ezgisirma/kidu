begin;

insert into public.illness_templates (
  id,
  created_by,
  is_system,
  name,
  average_duration_days,
  common_symptoms,
  critical_notes,
  metadata,
  version
)
values
(
  '11111111-1111-1111-1111-111111111111',
  null,
  true,
  'İnfluenza',
  7,
  '[
    {"key":"fever","label":"Yüksek ateş","severity_scale":"0-10","typical_range":"38.0-40.0 C"},
    {"key":"cough","label":"Kuru öksürük","severity_scale":"0-10"},
    {"key":"sore_throat","label":"Boğaz ağrısı","severity_scale":"0-10"},
    {"key":"fatigue","label":"Halsizlik","severity_scale":"0-10"},
    {"key":"headache","label":"Baş ağrısı","severity_scale":"0-10"},
    {"key":"muscle_pain","label":"Kas ağrısı","severity_scale":"0-10"}
  ]'::jsonb,
  'İlk 48 saatte ateş ve genel durumda kötüleşme olabilir. 3 aydan küçük bebekte 38 C ve üzeri ateş acil değerlendirme gerektirir. Nefes darlığı, morarma, sıvı alamama veya bilinç değişikliği olursa acile başvurun.',
  '{
    "category":"viral",
    "contagious":true,
    "recommended_followup_hours":24,
    "hydration_priority":"high"
  }'::jsonb,
  1
),
(
  '22222222-2222-2222-2222-222222222222',
  null,
  true,
  'Beta',
  10,
  '[
    {"key":"fever","label":"Ateş","severity_scale":"0-10","typical_range":"37.8-39.5 C"},
    {"key":"sore_throat","label":"Şiddetli boğaz ağrısı","severity_scale":"0-10"},
    {"key":"tonsil_exudate","label":"Bademcik üzerinde beyaz plak","presence":true},
    {"key":"swollen_lymph_nodes","label":"Boyunda hassas lenf bezi","severity_scale":"0-10"},
    {"key":"headache","label":"Baş ağrısı","severity_scale":"0-10"},
    {"key":"nausea","label":"Bulantı","severity_scale":"0-10"}
  ]'::jsonb,
  'Antibiyotik başlandıysa hekim önerdiği süre tamamlanmalıdır. Tedaviye rağmen 48-72 saatte belirgin düzelme yoksa kontrol önerilir. Nefes alma güçlüğü, yutamama, döküntü veya idrar azalması gelişirse hızlı değerlendirme gerekir.',
  '{
    "category":"bacterial",
    "contagious":true,
    "requires_medical_confirmation":true,
    "school_return_after_hours":24
  }'::jsonb,
  1
),
(
  '33333333-3333-3333-3333-333333333333',
  null,
  true,
  'El-Ayak-Ağız',
  8,
  '[
    {"key":"fever","label":"Hafif-orta ateş","severity_scale":"0-10","typical_range":"37.5-39.0 C"},
    {"key":"mouth_ulcers","label":"Ağız içinde ağrılı yaralar","severity_scale":"0-10"},
    {"key":"hand_foot_rash","label":"El/ayak tabanında döküntü","severity_scale":"0-10"},
    {"key":"loss_of_appetite","label":"İştahsızlık","severity_scale":"0-10"},
    {"key":"irritability","label":"Huzursuzluk","severity_scale":"0-10"},
    {"key":"drooling","label":"Ağız ağrısına bağlı salya artışı","severity_scale":"0-10"}
  ]'::jsonb,
  'Ağız içi ağrı sıvı alımını azaltabilir; dehidratasyon belirtileri (az idrar, ağız kuruluğu, gözyaşı azalması) yakından izlenmelidir. Yüksek ateşin uzaması, ense sertliği, bilinç değişikliği veya nöbet acil değerlendirme gerektirir.',
  '{
    "category":"viral",
    "contagious":true,
    "hydration_priority":"very_high",
    "isolation_recommendation_days":7
  }'::jsonb,
  1
),
(
  '44444444-4444-4444-4444-444444444444',
  null,
  true,
  'Su Çiçeği',
  9,
  '[
    {"key":"fever","label":"Ateş","severity_scale":"0-10","typical_range":"37.5-39.0 C"},
    {"key":"itching_rash","label":"Kaşıntılı, içi sıvı dolu döküntü","severity_scale":"0-10"},
    {"key":"fatigue","label":"Halsizlik","severity_scale":"0-10"},
    {"key":"loss_of_appetite","label":"İştahsızlık","severity_scale":"0-10"},
    {"key":"headache","label":"Baş ağrısı","severity_scale":"0-10"},
    {"key":"sleep_disturbance","label":"Kaşıntıya bağlı uyku bozulması","severity_scale":"0-10"}
  ]'::jsonb,
  'Döküntüler kabuklanana kadar bulaştırıcılık sürebilir. Cilt enfeksiyonu bulguları (artan kızarıklık, akıntı, kötü koku), solunum sıkıntısı, devam eden yüksek ateş veya nörolojik belirtilerde acil başvuru gerekir. Tırnakların kısa tutulması ve cilt hijyeni önemlidir.',
  '{
    "category":"viral",
    "contagious":true,
    "isolation_until":"all_lesions_crusted",
    "skin_care_priority":"high"
  }'::jsonb,
  1
)
on conflict (id) do update
set
  name = excluded.name,
  average_duration_days = excluded.average_duration_days,
  common_symptoms = excluded.common_symptoms,
  critical_notes = excluded.critical_notes,
  metadata = excluded.metadata,
  version = excluded.version,
  updated_at = timezone('utc', now());

commit;
