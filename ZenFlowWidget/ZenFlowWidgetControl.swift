//
//  ZenFlowWidgetControl.swift
//  ZenFlowWidget
//
//  Created by Cem Kaya on 11/24/25.
//
// ZenFlowWidget/ZenFlowWidgetControl.swift

import AppIntents
import SwiftUI
import WidgetKit

// iOS 18.0 kontrolü ekleyin
@available(iOS 18.0, *)
struct ZenFlowWidgetControl: ControlWidget {
    static let kind: String = "ZenFlowControl"

    var body: some ControlWidgetConfiguration {
        AppIntentControlConfiguration(
            kind: Self.kind,
            provider: Provider()
        ) { value in
            ControlWidgetToggle(
                "Start Timer",
                isOn: value.isRunning,
                action: StartTimerIntent(value.name)
            ) { isRunning in
                Label(isRunning ? "On" : "Off", systemImage: "timer")
            }
        }
        .displayName("Timer")
        .description("A an example control that runs a timer.")
    }
}

@available(iOS 18.0, *)
extension ZenFlowWidgetControl {
    struct Value {
        var isRunning: Bool
        var name: String
    }

    struct Provider: AppIntentControlValueProvider {
        func previewValue(configuration: TimerConfiguration) -> Value {
            ZenFlowWidgetControl.Value(isRunning: false, name: configuration.timerName)
        }

        func currentValue(configuration: TimerConfiguration) async throws -> Value {
            let isRunning = true
            return ZenFlowWidgetControl.Value(isRunning: isRunning, name: configuration.timerName)
        }
    }
}

@available(iOS 18.0, *)
struct TimerConfiguration: ControlConfigurationIntent {
    static let title: LocalizedStringResource = "Timer Name Configuration"

    @Parameter(title: "Timer Name", default: "Timer")
    var timerName: String
}

@available(iOS 18.0, *)
struct StartTimerIntent: SetValueIntent {
    static let title: LocalizedStringResource = "Start a timer"

    @Parameter(title: "Timer Name")
    var name: String

    @Parameter(title: "Timer is running")
    var value: Bool

    init() {}

    init(_ name: String) {
        self.name = name
    }

    func perform() async throws -> some IntentResult {
        return .result()
    }
}
