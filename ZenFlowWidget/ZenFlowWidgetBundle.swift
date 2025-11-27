//
//  ZenFlowWidgetBundle.swift
//  ZenFlowWidget
//
//  Created by Cem Kaya on 11/24/25.
//
// ZenFlowWidget/ZenFlowWidgetBundle.swift

import WidgetKit
import SwiftUI

@main
struct ZenFlowWidgetBundle: WidgetBundle {
    var body: some Widget {
        // iOS 16.0 ve üzeri tüm sürümlerde çalışanlar
        ZenFlowWidget()
        ZenFlowLockScreenWidget()
        ZenFlowLockScreenCircularWidget()
        ZenFlowLockScreenInlineWidget()
        
        // Sadece iOS 16.1 ve üzeri (Live Activities)
        if #available(iOS 16.1, *) {
            ZenFlowWidgetLiveActivity()
        }
        
        // Sadece iOS 18.0 ve üzeri (Control Center Widgets)
        if #available(iOS 18.0, *) {
            ZenFlowWidgetControl()
        }
    }
}
