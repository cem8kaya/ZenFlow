//
//  LocalDataManager.swift
//  ZenFlow
//
//  Created by Cem Kaya on 11/16/25.
//

import Foundation
import Combine
import WidgetKit

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
    }

    // MARK: - Properties

    private let defaults: UserDefaults

    // MARK: - Initialization

    private init() {
            // Use App Group UserDefaults
            if let appGroupDefaults = UserDefaults(suiteName: "group.com.zenflow.app") {
                self.defaults = appGroupDefaults
            } else {
                self.defaults = UserDefaults.standard
            }
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
            guard let data = defaults.data(forKey: Keys.sessionHistory),
                  let sessions = try? JSONDecoder().decode([SessionData].self, from: data) else {
                return []
            }
            return sessions
        }
        set {
            objectWillChange.send()
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
        
        WidgetCenter.shared.reloadAllTimelines()

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
        default:
            // Seri kırıldı - yeni seri başlat
            currentStreak = 1
        }
    }

    /// Seriyi manuel olarak yeniden hesapla (tüm geçmişe bakarak)
    func recalculateStreak() {
        let calendar = Calendar.current
        let sortedSessions = sessionHistory.sorted { $0.date > $1.date }

        guard !sortedSessions.isEmpty else {
            currentStreak = 0
            return
        }

        var streak = 1
        var previousDate = calendar.startOfDay(for: sortedSessions[0].date)

        for i in 1..<sortedSessions.count {
            let currentDate = calendar.startOfDay(for: sortedSessions[i].date)
            let daysDifference = calendar.dateComponents([.day], from: currentDate, to: previousDate).day ?? 0

            if daysDifference == 1 {
                streak += 1
            } else if daysDifference > 1 {
                break
            }

            previousDate = currentDate
        }

        // Bugün seans yapılmadıysa seri kırılmış olabilir
        let today = calendar.startOfDay(for: Date())
        let lastSessionDay = calendar.startOfDay(for: sortedSessions[0].date)
        let daysSinceLastSession = calendar.dateComponents([.day], from: lastSessionDay, to: today).day ?? 0

        if daysSinceLastSession > 1 {
            currentStreak = 0
        } else {
            currentStreak = streak
        }

        print("🔄 Streak recalculated: \(currentStreak) days")
    }

    /// Seri durumunu kontrol et
    /// - Returns: Seri hala geçerli mi?
    func isStreakActive() -> Bool {
        guard let lastDate = lastSessionDate else {
            return false
        }

        let calendar = Calendar.current
        let lastDateDay = calendar.startOfDay(for: lastDate)
        let today = calendar.startOfDay(for: Date())

        let daysDifference = calendar.dateComponents([.day], from: lastDateDay, to: today).day ?? 0

        return daysDifference <= 1
    }

    // MARK: - Statistics

    /// İstatistikleri yazdır
    func printStatistics() {
        print("📊 === ZenFlow İstatistikler ===")
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
            guard let data = defaults.data(forKey: Keys.focusSessionHistory),
                  let sessions = try? JSONDecoder().decode([FocusSessionData].self, from: data) else {
                return []
            }
            return sessions
        }
        set {
            objectWillChange.send()
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
    func saveMood(_ mood: Mood, date: Date = Date()) {
        let entry = MoodEntry(date: date, mood: mood)
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
