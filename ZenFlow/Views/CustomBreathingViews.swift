//
//  CustomBreathingViews.swift
//  ZenFlow
//
//  Copyright © 2026 ZenFlow. All rights reserved.
//
//  Premium: design your own breathing rhythm. A list of the user's patterns
//  and an editor with steppers for inhale, hold, exhale and hold-after.
//

import SwiftUI

// MARK: - List

struct CustomBreathingListView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var manager = BreathingExerciseManager.shared

    @State private var editing: CustomBreathingPattern?

    var body: some View {
        NavigationStack {
            ZStack {
                ZenTheme.backgroundGradient
                    .ignoresSafeArea()

                List {
                    Section {
                        if manager.customPatterns.isEmpty {
                            Text(String(localized: "custom_exercise_empty", defaultValue: "Henüz kendi egzersizin yok. Sağ üstteki + ile ilkini oluştur.", comment: "Empty state of the custom exercise list"))
                                .font(.subheadline)
                                .foregroundColor(ZenTheme.softPurple)
                        }

                        ForEach(manager.customPatterns) { pattern in
                            Button {
                                editing = pattern
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(pattern.displayName)
                                            .font(.headline)
                                            .foregroundColor(ZenTheme.lightLavender)
                                        Text(String(localized: "custom_exercise_row_detail", defaultValue: "\(pattern.ratioText) · \(pattern.cycleSeconds) sn döngü", comment: "Ratio and cycle length of a custom exercise"))
                                            .font(.caption)
                                            .foregroundColor(ZenTheme.softPurple)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.footnote)
                                        .foregroundColor(ZenTheme.softPurple)
                                }
                            }
                            .listRowBackground(Color.white.opacity(0.06))
                        }
                        .onDelete { offsets in
                            let ids = offsets.map { manager.customPatterns[$0].id }
                            ids.forEach { manager.deleteCustomPattern(id: $0) }
                        }
                    } footer: {
                        Text(String(localized: "custom_exercise_list_footer", defaultValue: "En fazla \(CustomBreathingPattern.maxPatterns) egzersiz oluşturabilirsin. Silmek için sola kaydır.", comment: "Footer of the custom exercise list"))
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(String(localized: "custom_exercise_title", defaultValue: "Kendi Egzersizlerim", comment: "Custom exercises title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(String(localized: "daily_zen_done", defaultValue: "Tamam", comment: "Done button")) {
                        dismiss()
                    }
                    .foregroundColor(ZenTheme.lightLavender)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        editing = CustomBreathingPattern()
                    } label: {
                        Image(systemName: "plus")
                    }
                    .disabled(!manager.canAddCustomPattern)
                    .foregroundColor(ZenTheme.lightLavender)
                    .accessibilityLabel(String(localized: "custom_exercise_add", defaultValue: "Yeni egzersiz", comment: "Add a custom exercise"))
                }
            }
            .sheet(item: $editing) { pattern in
                CustomBreathingEditorView(pattern: pattern)
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Editor

struct CustomBreathingEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var manager = BreathingExerciseManager.shared

    @State private var pattern: CustomBreathingPattern

    init(pattern: CustomBreathingPattern) {
        _pattern = State(initialValue: pattern)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(
                        String(localized: "custom_exercise_name_placeholder", defaultValue: "İsim (isteğe bağlı)", comment: "Name placeholder of a custom exercise"),
                        text: $pattern.name
                    )
                    .onChange(of: pattern.name) { _, newValue in
                        if newValue.count > CustomBreathingPattern.maxNameLength {
                            pattern.name = String(newValue.prefix(CustomBreathingPattern.maxNameLength))
                        }
                    }
                } header: {
                    Text(String(localized: "custom_exercise_name_header", defaultValue: "İsim", comment: "Name section header"))
                }

                Section {
                    phaseStepper(
                        String(localized: "custom_exercise_inhale", defaultValue: "Nefes al", comment: "Inhale"),
                        value: $pattern.inhale,
                        range: CustomBreathingPattern.inhaleRange
                    )
                    phaseStepper(
                        String(localized: "custom_exercise_hold", defaultValue: "Tut", comment: "Hold"),
                        value: $pattern.hold,
                        range: CustomBreathingPattern.holdRange
                    )
                    phaseStepper(
                        String(localized: "custom_exercise_exhale", defaultValue: "Nefes ver", comment: "Exhale"),
                        value: $pattern.exhale,
                        range: CustomBreathingPattern.exhaleRange
                    )
                    phaseStepper(
                        String(localized: "custom_exercise_hold_after", defaultValue: "Boşken tut", comment: "Hold after exhale"),
                        value: $pattern.holdAfter,
                        range: CustomBreathingPattern.holdAfterRange
                    )
                } header: {
                    Text(String(localized: "custom_exercise_rhythm_header", defaultValue: "Ritim", comment: "Rhythm section header"))
                } footer: {
                    Text(String(localized: "custom_exercise_rhythm_footer", defaultValue: "Tutma sürelerini 0 yaparak atlayabilirsin.", comment: "Rhythm section footer"))
                }

                Section {
                    HStack {
                        Text(String(localized: "custom_exercise_preview_ratio", defaultValue: "Ritim", comment: "Rhythm"))
                        Spacer()
                        Text(pattern.ratioText)
                            .font(.system(.body, design: .rounded).weight(.semibold))
                    }
                    HStack {
                        Text(String(localized: "custom_exercise_preview_cycle", defaultValue: "Bir döngü", comment: "One cycle"))
                        Spacer()
                        Text(String(localized: "custom_exercise_seconds", defaultValue: "\(pattern.cycleSeconds) sn", comment: "Seconds"))
                    }
                    HStack {
                        Text(String(localized: "custom_exercise_preview_rate", defaultValue: "Dakikada nefes", comment: "Breaths per minute"))
                        Spacer()
                        Text(String(format: "%.1f", pattern.breathsPerMinute))
                    }
                } header: {
                    Text(String(localized: "custom_exercise_preview_header", defaultValue: "Özet", comment: "Preview section header"))
                }
            }
            .navigationTitle(String(localized: "custom_exercise_editor_title", defaultValue: "Egzersiz Tasarla", comment: "Custom exercise editor title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "zen_coach_cancel", defaultValue: "İptal", comment: "Cancel button")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "custom_exercise_save", defaultValue: "Kaydet", comment: "Save")) {
                        if manager.saveCustomPattern(pattern) {
                            HapticManager.shared.playNotification(type: .success)
                        }
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func phaseStepper(_ title: String, value: Binding<Int>, range: ClosedRange<Int>) -> some View {
        Stepper(value: value, in: range) {
            HStack {
                Text(title)
                Spacer()
                Text(String(localized: "custom_exercise_seconds", defaultValue: "\(value.wrappedValue) sn", comment: "Seconds"))
                    .monospacedDigit()
                    .foregroundColor(.secondary)
            }
        }
    }
}
