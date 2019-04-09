//
//  PublishSetting+CoreDataProperties.swift
//  MQTTool
//
//  Created by Brent Petit on 1/13/18.
//  Copyright © 2018-2019 Brent Petit. All rights reserved.
//
//

import Foundation
import CoreData


extension PublishSetting {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PublishSetting> {
        let request = NSFetchRequest<PublishSetting>(entityName: "PublishSetting")
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        return request
    }

    @NSManaged public var message: String?
    @NSManaged public var qos: Int16
    @NSManaged public var retainFlag: Bool
    @NSManaged public var timestamp: NSDate?
    @NSManaged public var topic: String?
    @NSManaged public var usersetting: UserSetting?

}
