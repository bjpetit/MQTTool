//
//  SettingsBundleHelper.swift
//  MQTTool
//
//  Created by Brent Petit on 5/11/18.
//  Copyright © 2018-2019 Brent Petit. All rights reserved.
//

import Foundation
class SettingsBundleHelper {
    
    struct SettingsBundleKeys {
        static let AppVersionKey = "version_preference"
        static let IdleSleepDelay = "sleep_delay_preference"
    }
    
    class func idleSleepDelayEnabled() -> Bool {
        if UserDefaults.standard.bool(forKey: SettingsBundleKeys.IdleSleepDelay) {
            return true
        } else {
            return false
        }
    }
}
