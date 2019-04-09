//
//  ConnectSetting+CoreDataProperties.swift
//  MQTTool
//
//  Created by Brent Petit on 1/13/18.
//  Copyright © 2018-2019 Brent Petit. All rights reserved.
//
//

import Foundation
import CoreData


extension ConnectSetting {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ConnectSetting> {
        let request = NSFetchRequest<ConnectSetting>(entityName: "ConnectSetting")
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        return request
    }

    @NSManaged public var clean: Bool
    @NSManaged public var hostname: String?
    @NSManaged public var password: String?
    @NSManaged public var port: Int64
    @NSManaged public var sessionID: String?
    @NSManaged public var timestamp: NSDate?
    @NSManaged public var username: String?
    @NSManaged public var savepassword: Bool
    @NSManaged public var usersetting: UserSetting?

}
