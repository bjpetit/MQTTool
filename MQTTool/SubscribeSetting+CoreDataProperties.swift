//
//  SubscribeSetting+CoreDataProperties.swift
//  MQTTool
//
//  Created by Brent Petit on 1/13/18.
//  Copyright © 2018-2019 Brent Petit. All rights reserved.
//
//

import Foundation
import CoreData


extension SubscribeSetting {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SubscribeSetting> {
        let request = NSFetchRequest<SubscribeSetting>(entityName: "SubscribeSetting")
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        return request
    }

    @NSManaged public var qos: Int16
    @NSManaged public var timestamp: NSDate?
    @NSManaged public var topic: String?
    @NSManaged public var usersetting: UserSetting?

}
