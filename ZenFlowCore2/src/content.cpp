// ============================================================================
//  content.cpp — data tables ported 1:1 from the ZenFlow iOS app.
// ============================================================================
#include "content.h"

namespace zf {

// ---------------------------------------------------------------------------
//  Breathing patterns (seconds). Source: BreathingExercise.allExercises
// ---------------------------------------------------------------------------
static const BreathingPhase P_BOX[]     = {{Phase::Inhale,4},{Phase::Hold,4},{Phase::Exhale,4},{Phase::HoldAfterExhale,4}};
static const BreathingPhase P_478[]     = {{Phase::Inhale,4},{Phase::Hold,7},{Phase::Exhale,8}};
static const BreathingPhase P_CALMING[] = {{Phase::Inhale,4},{Phase::Exhale,6}};
static const BreathingPhase P_ENERGY[]  = {{Phase::Inhale,2},{Phase::Exhale,2}};
static const BreathingPhase P_DEEP[]    = {{Phase::Inhale,6},{Phase::Hold,2},{Phase::Exhale,8}};

const BreathingExercise BREATHING[] = {
    {"box",     "Kutu Nefesi",          "Box Breathing",     P_BOX,     4, 5},
    {"478",     "4-7-8 Tekniği",        "4-7-8 Technique",   P_478,     3, 5},
    {"calming", "Sakinleştirici Nefes", "Calming Breath",    P_CALMING, 2, 5},
    {"energy",  "Enerji Nefesi",        "Energy Breath",     P_ENERGY,  2, 3},
    {"deep",    "Derin Gevşeme",        "Deep Relaxation",   P_DEEP,    3, 10},
};
const size_t BREATHING_COUNT = sizeof(BREATHING) / sizeof(BREATHING[0]);

// ---------------------------------------------------------------------------
//  Intent keywords (lowercase, TR + EN). Source: UserIntent.keywords
// ---------------------------------------------------------------------------
static const char* KW_STRESS[]     = {"stres","kaygı","endişe","gergin","huzursuz","sinirli","panik","korku","stresli","sıkıntı","bunalım",
                                      "stress","anxiety","worry","nervous","restless","angry","panic","fear","overwhelmed","tension","help"};
static const char* KW_FOCUS[]      = {"odak","dikkat","konsantrasyon","dağınık","çalış","verim","ders","pomodoro","odaklan","konsantre",
                                      "focus","attention","concentrate","concentration","distracted","work","study","productive","efficiency"};
static const char* KW_SLEEP[]      = {"uyku","uyu","dinlen","yorgun","bitkin","gece","yat","uyumak","uykusuz",
                                      "sleep","insomnia","tired","exhausted","rest","night","awake","dream","nap","sleepy"};
static const char* KW_BREATHING[]  = {"nefes","soluk","derin nefes","nefes al","egzersiz","teknik",
                                      "breath","breathing","inhale","exhale","box breathing","4-7-8","deep breath","exercise","technique"};
static const char* KW_MOTIVATION[] = {"motivasyon","başla","enerji","güç","ilham","cesaret","tembellik","bahçe","ağaç","büyüme","bitki",
                                      "motivation","inspire","inspiration","energy","power","courage","lazy","procrastination","garden","tree","grow","plant"};
static const char* KW_MEDITATION[] = {"meditasyon","mindfulness","farkındalık","öğren","başlangıç","sakinleş","huzur",
                                      "meditation","mindfulness","awareness","meditate","learn","beginner","calm","peace"};
static const char* KW_PROGRESS[]   = {"ilerleme","gelişim","istatistik","rozet","başarı","seri","skor","puan",
                                      "progress","improvement","stats","statistics","badge","achievement","streak","score","status"};

const IntentDef INTENTS[] = {
    {Intent::Stress,     "Stres Yönetimi", KW_STRESS,     sizeof(KW_STRESS)/sizeof(char*),     "breathing:box"},
    {Intent::Focus,      "Odaklanma",      KW_FOCUS,      sizeof(KW_FOCUS)/sizeof(char*),      "focus"},
    {Intent::Sleep,      "Uyku",           KW_SLEEP,      sizeof(KW_SLEEP)/sizeof(char*),      "breathing:478"},
    {Intent::Breathing,  "Nefes Egzersizi",KW_BREATHING,  sizeof(KW_BREATHING)/sizeof(char*),  "breathing:box"},
    {Intent::Motivation, "Motivasyon",     KW_MOTIVATION, sizeof(KW_MOTIVATION)/sizeof(char*), "garden"},
    {Intent::Meditation, "Meditasyon",     KW_MEDITATION, sizeof(KW_MEDITATION)/sizeof(char*), "breathing:calming"},
    {Intent::Progress,   "İlerleme",       KW_PROGRESS,   sizeof(KW_PROGRESS)/sizeof(char*),   "garden"},
    {Intent::General,    "Genel",          nullptr,       0,                                   ""},
};
const size_t INTENT_COUNT = sizeof(INTENTS) / sizeof(INTENTS[0]);

// ---------------------------------------------------------------------------
//  Empathetic openings + Zen quotes. Source: ResponseGenerator.swift
// ---------------------------------------------------------------------------
const char* EMPATHETIC_OPENINGS[] = {
    "Seni tüm kalbimle duyuyorum ve anlıyorum.",
    "Bunu benimle paylaştığın için teşekkür ederim, yalnız değilsin.",
    "Bu duyguyu hissetmen çok insani, çözüm için yanındayım.",
    "Derin bir nefes alalım; hissettiklerin geçici, senin özün ise kalıcı.",
    "Seni anlıyorum. Bazen zihin gürültülü olabilir, ama sessizlik hep orada.",
    "Farkındalığın için seni tebrik ederim, bu ilk ve en önemli adım.",
    "Bazen sadece durup hissetmek gerekir. Seni yargısızca dinliyorum.",
    "Zihnin söylediklerini bir kenara bırakıp, kalbinin sesine kulak verelim.",
    "Şu an hissettiğin her neyse, ona yer aç. Geçip gitmesine izin ver.",
    "Yolculuğunda sana eşlik etmekten onur duyuyorum.",
};
const size_t EMPATHETIC_OPENINGS_COUNT = sizeof(EMPATHETIC_OPENINGS)/sizeof(char*);

const char* ZEN_QUOTES[] = {
    "\"Su akıştır, rüzgar esintir, akış ritmini bulmaktır.\"",
    "\"Şimdiki an, sahip olduğun tek andır. Onu kucakla.\"",
    "\"Zihin sakinleştiğinde, ruhun güzelliği parlar.\"",
    "\"Her nefes, yeni bir başlangıçtır.\"",
    "\"Sessizlik, tüm cevapları içerir.\"",
    "\"Aydınlanma, uzaktaki bir hedef değil, her adımdaki farkındalıktır.\"",
    "\"Düşünce bulutları gelir ve geçer. Sen gökyüzüsün.\"",
    "\"Tam burada, tam şimdi - sonsuzluk bu anda gizli.\"",
    "\"Boş bir zihin, her şeyin mümkün olduğu yerdir.\"",
    "\"Barış dışarıda aranmaz, içeride keşfedilir.\"",
    "\"Nefes, beden ve zihin arasındaki köprüdür.\"",
    "\"Gel, gör, kabul et. Bu Zen'in yoludur.\"",
    "\"Düşüşte bile zarafet vardır. Kalk ve devam et.\"",
    "\"Sabır, bilgeliğin meyveleridir.\"",
    "\"Her an meditasyon fırsatıdır.\"",
};
const size_t ZEN_QUOTES_COUNT = sizeof(ZEN_QUOTES)/sizeof(char*);

// ---------------------------------------------------------------------------
//  Tree stages. Source: Constants.TreeGrowth (minutes)
// ---------------------------------------------------------------------------
const TreeStage TREE_STAGES[] = {
    {"Tohum",       0},
    {"Filiz",       30},
    {"Fidan",       120},
    {"Genç Ağaç",   300},
    {"Olgun Ağaç",  600},
    {"Kadim Ağaç",  1200},
};
const size_t TREE_STAGE_COUNT = sizeof(TREE_STAGES)/sizeof(TREE_STAGES[0]);

// ---------------------------------------------------------------------------
//  Badges. Source: Constants.Badges + Constants.Pomodoro
// ---------------------------------------------------------------------------
const BadgeDef BADGES[] = {
    {"first_hour",   "İlk Saat",        BadgeMetric::Minutes,          60},
    {"mastery",      "Ustalık",         BadgeMetric::Minutes,          300},
    {"zen_master",   "Zen Ustası",      BadgeMetric::Minutes,          1000},
    {"week_streak",  "7 Gün Seri",      BadgeMetric::StreakDays,       7},
    {"month_streak", "30 Gün Seri",     BadgeMetric::StreakDays,       30},
    {"first_pomo",   "İlk Pomodoro",    BadgeMetric::PomodoroSessions, 1},
    {"focus_master", "Odak Ustası",     BadgeMetric::PomodoroSessions, 10},
};
const size_t BADGE_COUNT = sizeof(BADGES)/sizeof(BADGES[0]);

} // namespace zf
