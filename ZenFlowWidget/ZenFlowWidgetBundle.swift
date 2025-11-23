//
//  ZenFlowWidgetBundle.swift
//  ZenFlowWidget
//
//  Created by Cem Kaya on 11/24/25.
//

import WidgetKit
import SwiftUI

@main
struct ZenFlowWidgetBundle: WidgetBundle {
    var body: some Widget {
        ZenFlowWidget()
        ZenFlowLockScreenWidget()
        ZenFlowLockScreenCircularWidget()
        ZenFlowLockScreenInlineWidget()
        ZenFlowWidgetControl()
        ZenFlowWidgetLiveActivity()
    }
}
