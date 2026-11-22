//
//  LocalDataManager.swift
//  ZenFlow
//
//  Created by Cem Kaya on 11/16/25.
//

import Foundation
import Combine

class LocalDataManager: ObservableObject {
    // MARK: - Singleton

    static let shared = LocalDataManager()

    // MARK: - UserDefaults Keys

    private enum Keys {
        static let totalMinutes = "zenflow_total_minutes"
        static let totalSessions = "zenflow_total_sessions"
        static let lastSessionDate = "zenflow_last_session_date"
        static let currentStreak = "zenflow_current_streak"
        static let longestStreak = "zenflow_longest_streak"
        static let sessionHistory = "zenflow_session_history"
        static let focusSessionHistory = "zenflow_focus_session_history"
        static let totalFocusSessions = "zenflow_total_focus_sessions"
        static let moodHistory = "zenflow_mood_history"
        static let frozenDays = "zenflow_frozen_days"
        static let weeklyGoalDays = "zenflow_weekly_goal_days"
    }

    // MARK: - Properties

    private let defaults: UserDefaults

    /// Whether the user currently has premium. Overridable for tests.
    var isPremiumProvider: () -> Bool = { StoreManager.cachedPremiumStatus }

    // Cache for decoded session history to avoid repeated decoding
    private var cachedSessionHistory: [SessionData]?
    private var cachedFocusSessionHistory: [FocusSessionData]?

    // MARK: - Initialization

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: - Session Data Model

    struct SessionData: Codable {
        let date: Date
        let durationMinutes: Int

        var dateString: String {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
    }

    // MARK: - Computed Properties

    /// Toplam egzersiz süresi (dakika)
    var totalMinutes: Int {
        get {
            return defaults.integer(forKey: Keys.totalMinutes)
        }
        set {
            objectWillChange.send()
            defaults.set(newValue, forKey: Keys.totalMinutes)
            print("💾 Total minutes updated: \(newValue)")
        }
    }

    /// Toplam seans sayısı
    var totalSessions: Int {
        get {
            return defaults.integer(forKey: Keys.totalSessions)
        }
        set {
            objectWillChange.send()
            defaults.set(newValue, forKey: Keys.totalSessions)
            print("💾 Total sessions updated: \(newValue)")
        }
    }

    /// Son egzersiz tarihi
    var lastSessionDate: Date? {
        get {
            return defaults.object(forKey: Keys.lastSessionDate) as? Date
        }
        set {
            objectWillChange.send()
            defaults.set(newValue, forKey: Keys.lastSessionDate)
            if let date = newValue {
                print("💾 Last session date updated: \(date)")
            }
        }
    }

    /// Mevcut seri (streak)
    var currentStreak: Int {
        get {
            return defaults.integer(forKey: Keys.currentStreak)
        }
        set {
            objectWillChange.send()
            defaults.set(newValue, forKey: Keys.currentStreak)

            // En uzun seriyi güncelle
            if newValue > longestStreak {
                longestStreak = newValue
            }

            print("💾 Current streak updated: \(newValue)")
        }
    }

    /// En uzun seri (longest streak)
    var longestStreak: Int {
        get {
            return defaults.integer(forKey: Keys.longestStreak)
        }
        set {
            objectWillChange.send()
            defaults.set(newValue, forKey: Keys.longestStreak)
            print("💾 Longest streak updated: \(newValue)")
        }
    }

    /// Seans geçmişi
    var sessionHistory: [SessionData] {
        get {
            // Return cached value if available
            if let cached = cachedSessionHistory {
                return cached
            }

            // Decode from UserDefaults and cache
            guard let data = defaults.data(forKey: Keys.sessionHistory),
                  let sessions = try? JSONDecoder().decode([SessionData].self, from: data) else {
                cachedSessionHistory = []
                return []
            }

            cachedSessionHistory = sessions
            return sessions
        }
        set {
            objectWillChange.send()
            cachedSessionHistory = newValue // Update cache
            if let data = try? JSONEncoder().encode(newValue) {
                defaults.set(data, forKey: Keys.sessionHistory)
                print("💾 Session history updated: \(newValue.count) sessions")
            }
        }
    }

    // MARK: - CRUD Operations

    /// Yeni bir seans kaydet
    /// - Parameters:
    ///   - durationMinutes: Seansın dakika cinsinden süresi
    ///   - date: Seans tarihi (varsayılan: şu an)
    func saveSession(durationMinutes: Int, date: Date = Date()) {
        // Toplam değerleri güncelle
        totalMinutes += durationMinutes
        totalSessions += 1

        // Seans geçmişine ekle
        let session = SessionData(date: date, durationMinutes: durationMinutes)
        var history = sessionHistory
        history.append(session)
        sessionHistory = history

        // Seriyi güncelle
        updateStreak(for: date)

        // Son seans tarihini güncelle
        lastSessionDate = date
        
        // WidgetCenter.shared.reloadAllTimelines() // KALDIRILDI

        print("✅ Session saved: \(durationMinutes) minutes on \(session.dateString)")
        print("📊 Stats - Total: \(totalSessions) sessions, \(totalMinutes) minutes, Streak: \(currentStreak) days")
    }

    /// Seans geçmişini getir
    /// - Parameter limit: Maksimum seans sayısı (varsayılan: tümü)
    /// - Returns: Seans listesi (en yeniden en eskiye)
    func getSessions(limit: Int? = nil) -> [SessionData] {
        let sessions = sessionHistory.sorted { $0.date > $1.date }
        if let limit = limit {
            return Array(sessions.prefix(limit))
        }
        return sessions
    }

    /// Belirli bir tarih aralığındaki seansları getir
    /// - Parameters:
    ///   - startDate: Başlangıç tarihi
    ///   - endDate: Bitiş tarihi
    /// - Returns: Tarih aralığındaki seanslar
    func getSessions(from startDate: Date, to endDate: Date) -> [SessionData] {
        return sessionHistory.filter { session in
            session.date >= startDate && session.date <= endDate
        }.sorted { $0.date > $1.date }
    }

    /// Bugünkü seansları getir
    /// - Returns: Bugünün seansları
    func getTodaySessions() -> [SessionData] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

        return getSessions(from: today, to: tomorrow)
    }

    /// Tüm verileri sıfırla
    func resetAllData() {
        totalMinutes = 0
        totalSessions = 0
        lastSessionDate = nil
        currentStreak = 0
        longestStreak = 0
        sessionHistory = []

        print("🗑️ All data has been reset")
    }

    /// Seans geçmişini temizle (istatistikler korunur)
    func clearHistory() {
        sessionHistory = []
        print("🗑️ Session history cleared")
    }

    // MARK: - Streak Calculation

    /// Seriyi (streak) güncelle
    /// - Parameter date: Kontrol edilecek tarih
    private func updateStreak(for date: Date) {
        let calendar = Calendar.current

        // Son seans tarihi yoksa, yeni seri başlat
        guard let lastDate = lastSessionDate else {
            currentStreak = 1
            return
        }

        // Tarihleri karşılaştır (sadece gün bazında)
        let lastDateDay = calendar.startOfDay(for: lastDate)
        let currentDateDay = calendar.startOfDay(for: date)

        let daysDifference = calendar.dateComponents([.day], from: lastDateDay, to: currentDateDay).day ?? 0

        switch daysDifference {
        case 0:
            // Aynı gün - seri değişmez
            break
        case 1:
            // Ardışık gün - seri devam ediyor
            currentStreak += 1
        case 2...:
            // Bir veya daha fazla gün kaçırıldı: seri koruma hakkı varsa seriyi koru
            let missedDays = Self.missedDays(between: lastDateDay, and: currentDateDay, calendar: calendar)
            if canFreeze(missedDays) {
                frozenDays = frozenDays + missedDays
                currentStreak += 1
                print("❄️ Streak freeze used for \(missedDays.count) day(s)")
            } else {
                currentStreak = 1
            }
        default:
            // Seri kırıldı - yeni seri başlat
            currentStreak = 1
        }
    }

    /// Seriyi manuel olarak yeniden hesapla (tüm geçmişe bakarak).
    /// Seri koruma ile atlanan günler seriyi bozmaz.
    func recalculateStreak() {
        let calendar = Calendar.current
        let sessionDays = Set(sessionHistory.map { calendar.startOfDay(for: $0.date) })

        guard let latest = sessionDays.max() else {
            currentStreak = 0
            return
        }

        let frozen = Set(frozenDays.map { calendar.startOfDay(for: $0) })
        let streak = Self.computeStreak(sessionDays: sessionDays, frozenDays: frozen, endingAt: latest, calendar: calendar)

        // Bugün veya dün seans yapılmadıysa (ve koruma da yetmiyorsa) seri kırılmıştır
        currentStreak = isStreakActive() ? streak : 0

        print("🔄 Streak recalculated: \(currentStreak) days")
    }

    /// Counts the consecutive practice days ending at `endingAt`. A single
    /// frozen day between two practice days keeps the run alive without
    /// adding to the count.
    static func computeStreak(
        sessionDays: Set<Date>,
        frozenDays: Set<Date>,
        endingAt latest: Date,
        calendar: Calendar = .current
    ) -> Int {
        guard sessionDays.contains(latest) else { return 0 }

        var streak = 1
        var cursor = latest

        while true {
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }

            if sessionDays.contains(previous) {
                streak += 1
                cursor = previous
                continue
            }

            // Walk back through a run of frozen days to the next practice day
            var gapCursor = previous
            var foundBridge = false
            while frozenDays.contains(gapCursor),
                  let beforeGap = calendar.date(byAdding: .day, value: -1, to: gapCursor) {
                if sessionDays.contains(beforeGap) {
                    streak += 1
                    cursor = beforeGap
                    foundBridge = true
                    break
                }
                gapCursor = beforeGap
            }

            if !foundBridge { break }
        }

        return streak
    }

    /// Seri durumunu kontrol et
    /// - Returns: Seri hala geçerli mi? (Kaçırılan günler seri koruma ile
    ///   karşılanabiliyorsa seri hala geçerli sayılır.)
    func isStreakActive() -> Bool {
        guard let lastDate = lastSessionDate else {
            return false
        }

        let calendar = Calendar.current
        let lastDateDay = calendar.startOfDay(for: lastDate)
        let today = calendar.startOfDay(for: Date())

        let daysDifference = calendar.dateComponents([.day], from: lastDateDay, to: today).day ?? 0

        if daysDifference <= 1 {
            return true
        }

        // Kaçırılan günleri (bugün hariç) koruma hakkıyla karşılayabilir miyiz?
        let missed = Self.missedDays(between: lastDateDay, and: today, calendar: calendar)
        return canFreeze(missed)
    }

    // MARK: - Streak Freeze

    /// Freezes granted per calendar month
    static let freezesPerMonthFree = 1
    static let freezesPerMonthPremium = 3

    /// Monthly freeze allowance for the current user
    var monthlyFreezeAllowance: Int {
        isPremiumProvider() ? Self.freezesPerMonthPremium : Self.freezesPerMonthFree
    }

    /// Days (start-of-day) on which a streak freeze was consumed
    var frozenDays: [Date] {
        get {
            guard let data = defaults.data(forKey: Keys.frozenDays),
                  let days = try? JSONDecoder().decode([Date].self, from: data) else {
                return []
            }
            return days
        }
        set {
            objectWillChange.send()
            let unique = Array(Set(newValue)).sorted()
            if let data = try? JSONEncoder().encode(unique) {
                defaults.set(data, forKey: Keys.frozenDays)
            }
        }
    }

    /// Freezes already used in the calendar month of `date`
    func freezesUsed(inMonthOf date: Date = Date()) -> Int {
        let calendar = Calendar.current
        return frozenDays.filter {
            calendar.isDate($0, equalTo: date, toGranularity: .month)
        }.count
    }

    /// Freezes still available in the current calendar month
    var freezesRemaining: Int {
        max(0, monthlyFreezeAllowance - freezesUsed())
    }

    /// Whether yesterday's gap was covered by a freeze
    var didUseFreezeYesterday: Bool {
        let calendar = Calendar.current
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: Date())) else {
            return false
        }
        return frozenDays.contains { calendar.isDate($0, inSameDayAs: yesterday) }
    }

    /// Start-of-day dates strictly between `from` and `to`
    static func missedDays(between from: Date, and to: Date, calendar: Calendar = .current) -> [Date] {
        let diff = calendar.dateComponents([.day], from: from, to: to).day ?? 0
        guard diff >= 2 else { return [] }
        return (1..<diff).compactMap { calendar.date(byAdding: .day, value: $0, to: from) }
    }

    /// Whether the given missed days can all be covered by the remaining
    /// monthly freezes (each month has its own allowance).
    func canFreeze(_ missedDays: [Date]) -> Bool {
        guard !missedDays.isEmpty else { return true }
        let calendar = Calendar.current
        let allowance = monthlyFreezeAllowance
        var neededPerMonth: [DateComponents: Int] = [:]

        for day in missedDays {
            let key = calendar.dateComponents([.year, .month], from: day)
            neededPerMonth[key, default: 0] += 1
        }

        for (key, needed) in neededPerMonth {
            guard let monthDate = calendar.date(from: key) else { return false }
            if freezesUsed(inMonthOf: monthDate) + needed > allowance {
                return false
            }
        }
        return true
    }

    // MARK: - Weekly Goal

    /// Target number of active days per week (1...7)
    var weeklyGoalDays: Int {
        get {
            let stored = defaults.integer(forKey: Keys.weeklyGoalDays)
            return stored == 0 ? 5 : min(max(stored, 1), 7)
        }
        set {
            objectWillChange.send()
            defaults.set(min(max(newValue, 1), 7), forKey: Keys.weeklyGoalDays)
        }
    }

    /// Start-of-day dates of all days with a meditation or completed focus session
    private func practiceDays() -> Set<Date> {
        let calendar = Calendar.current
        var days = Set(sessionHistory.map { calendar.startOfDay(for: $0.date) })
        for focus in focusSessionHistory where focus.mode == .work && focus.completed {
            days.insert(calendar.startOfDay(for: focus.date))
        }
        return days
    }

    /// Practice days in the calendar week containing `date`, keyed by start-of-day
    func practiceDaysInWeek(of date: Date = Date()) -> Set<Date> {
        let calendar = Calendar.current
        guard let week = calendar.dateInterval(of: .weekOfYear, for: date) else { return [] }
        return practiceDays().filter { week.contains($0) }
    }

    /// Number of active days in the current week
    var activeDaysThisWeek: Int {
        practiceDaysInWeek().count
    }

    /// Progress towards the weekly goal, 0...1
    var weeklyGoalProgress: Double {
        min(1.0, Double(activeDaysThisWeek) / Double(weeklyGoalDays))
    }

    // MARK: - Statistics

    /// İstatistikleri yazdır
    func printStatistics() {
        print("📊 === MyZenFlow İstatistikler ===")
        print("📊 Toplam Seans: \(totalSessions)")
        print("📊 Toplam Süre: \(totalMinutes) dakika (\(totalMinutes / 60) saat)")
        print("📊 Mevcut Seri: \(currentStreak) gün")
        print("📊 En Uzun Seri: \(longestStreak) gün")

        if let lastDate = lastSessionDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            print("📊 Son Seans: \(formatter.string(from: lastDate))")
        }

        if totalSessions > 0 {
            let averageMinutes = totalMinutes / totalSessions
            print("📊 Ortalama Seans Süresi: \(averageMinutes) dakika")
        }

        print("📊 Seri Durumu: \(isStreakActive() ? "✅ Aktif" : "❌ Kırıldı")")
        print("📊 ============================")
    }

    // MARK: - Focus Session Management

    /// Tüm odaklanma seansı geçmişi
    var focusSessionHistory: [FocusSessionData] {
        get {
            // Return cached value if available
            if let cached = cachedFocusSessionHistory {
                return cached
            }

            // Decode from UserDefaults and cache
            guard let data = defaults.data(forKey: Keys.focusSessionHistory),
                  let sessions = try? JSONDecoder().decode([FocusSessionData].self, from: data) else {
                cachedFocusSessionHistory = []
                return []
            }

            cachedFocusSessionHistory = sessions
            return sessions
        }
        set {
            objectWillChange.send()
            cachedFocusSessionHistory = newValue // Update cache
            if let data = try? JSONEncoder().encode(newValue) {
                defaults.set(data, forKey: Keys.focusSessionHistory)
                print("💾 Focus session history updated: \(newValue.count) sessions")
            }
        }
    }

    /// Toplam odaklanma seansı sayısı
    var totalFocusSessions: Int {
        get {
            return defaults.integer(forKey: Keys.totalFocusSessions)
        }
        set {
            objectWillChange.send()
            defaults.set(newValue, forKey: Keys.totalFocusSessions)
            print("💾 Total focus sessions updated: \(newValue)")
        }
    }

    /// Bugünkü tamamlanan odaklanma seansı sayısı
    var todayFocusSessions: Int {
        let sessions = getTodayFocusSessions()
        return sessions.filter { $0.mode == .work && $0.completed }.count
    }

    /// Odaklanma seansı kaydet
    /// - Parameter session: Kaydedilecek odaklanma seansı
    func saveFocusSession(_ session: FocusSessionData) {
        var history = focusSessionHistory
        history.append(session)
        focusSessionHistory = history

        // Only count completed work sessions towards total
        if session.mode == .work && session.completed {
            totalFocusSessions += 1
        }

        print("✅ Focus session saved: \(session.mode.displayName) - \(session.durationMinutes) minutes on \(session.dateString)")
        print("📊 Total focus sessions: \(totalFocusSessions)")
    }

    /// Bugünkü odaklanma seanslarını getir
    /// - Returns: Bugünün odaklanma seansları
    func getTodayFocusSessions() -> [FocusSessionData] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

        return focusSessionHistory.filter { session in
            session.date >= today && session.date < tomorrow
        }.sorted { $0.date > $1.date }
    }

    /// Belirli bir tarih aralığındaki odaklanma seanslarını getir
    /// - Parameters:
    ///   - startDate: Başlangıç tarihi
    ///   - endDate: Bitiş tarihi
    /// - Returns: Tarih aralığındaki odaklanma seansları
    func getFocusSessions(from startDate: Date, to endDate: Date) -> [FocusSessionData] {
        return focusSessionHistory.filter { session in
            session.date >= startDate && session.date <= endDate
        }.sorted { $0.date > $1.date }
    }

    /// Tüm odaklanma seanslarını getir
    /// - Parameter limit: Maksimum seans sayısı (varsayılan: tümü)
    /// - Returns: Odaklanma seansları (en yeniden en eskiye)
    func getFocusSessions(limit: Int? = nil) -> [FocusSessionData] {
        let sessions = focusSessionHistory.sorted { $0.date > $1.date }
        if let limit = limit {
            return Array(sessions.prefix(limit))
        }
        return sessions
    }

    /// Odaklanma seansı geçmişini temizle
    func clearFocusHistory() {
        focusSessionHistory = []
        print("🗑️ Focus session history cleared")
    }

    // MARK: - Mood Management

    /// Tüm mood geçmişi
    var moodHistory: [MoodEntry] {
        get {
            guard let data = defaults.data(forKey: Keys.moodHistory),
                  let moods = try? JSONDecoder().decode([MoodEntry].self, from: data) else {
                return []
            }
            return moods
        }
        set {
            objectWillChange.send()
            if let data = try? JSONEncoder().encode(newValue) {
                defaults.set(data, forKey: Keys.moodHistory)
                print("💾 Mood history updated: \(newValue.count) entries")
            }
        }
    }

    /// Mood kaydı kaydet
    /// - Parameters:
    ///   - mood: Kaydedilecek mood
    ///   - date: Mood tarihi (varsayılan: şu an)
    ///   - preMood: Mood before the session, if the user recorded one
    ///   - exerciseType: Breathing exercise identifier practiced in the session
    ///   - durationMinutes: Session length in minutes
    func saveMood(
        _ mood: Mood,
        preMood: Mood? = nil,
        exerciseType: String? = nil,
        durationMinutes: Int? = nil,
        date: Date = Date()
    ) {
        let entry = MoodEntry(
            date: date,
            mood: mood,
            preMood: preMood,
            exerciseType: exerciseType,
            durationMinutes: durationMinutes
        )
        var history = moodHistory
        history.append(entry)
        moodHistory = history

        print("✅ Mood saved: \(mood.displayName) (\(mood.emoji)) on \(entry.dateString)")
    }

    /// Belirli bir tarih aralığındaki mood kayıtlarını getir
    /// - Parameters:
    ///   - startDate: Başlangıç tarihi
    ///   - endDate: Bitiş tarihi
    /// - Returns: Tarih aralığındaki mood kayıtları
    func getMoods(from startDate: Date, to endDate: Date) -> [MoodEntry] {
        return moodHistory.filter { entry in
            entry.date >= startDate && entry.date <= endDate
        }.sorted { $0.date > $1.date }
    }

    /// Bugünkü mood kayıtlarını getir
    /// - Returns: Bugünün mood kayıtları
    func getTodayMoods() -> [MoodEntry] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

        return getMoods(from: today, to: tomorrow)
    }

    /// Tüm mood kayıtlarını getir
    /// - Parameter limit: Maksimum kayıt sayısı (varsayılan: tümü)
    /// - Returns: Mood kayıtları (en yeniden en eskiye)
    func getMoods(limit: Int? = nil) -> [MoodEntry] {
        let moods = moodHistory.sorted { $0.date > $1.date }
        if let limit = limit {
            return Array(moods.prefix(limit))
        }
        return moods
    }

    /// Mood geçmişini temizle
    func clearMoodHistory() {
        moodHistory = []
        print("🗑️ Mood history cleared")
    }
}
