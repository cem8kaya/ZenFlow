//
//  ZenFlowWidgetBundle.swift
//  ZenFlowWidget
//
//  Copyright © 2026 ZenFlow. All rights reserved.
//
//  Entry point of the widget extension: the progress widget (home screen and
//  lock screen) and the session Live Activity.
//

import SwiftUI
import WidgetKit

@main
struct ZenFlowWidgetBundle: WidgetBundle {
    var body: some Widget {
        ZenProgressWidget()
        ZenSessionLiveActivity()
    }
}
