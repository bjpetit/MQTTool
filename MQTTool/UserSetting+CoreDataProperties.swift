//
//  UserSetting+CoreDataProperties.swift
//  MQTTool
//
//  Created by Brent Petit on 1/13/18.
//  Copyright © 2018-2019 Brent Petit. All rights reserved.
//
//

import Foundation
import CoreData


extension UserSetting {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserSetting> {
        return NSFetchRequest<UserSetting>(entityName: "UserSetting")
    }

    @NSManaged public var timestamp: NSDate?
    @NSManaged public var connect: ConnectSetting?
    @NSManaged public var publish: PublishSetting?
    @NSManaged public var subscribe: SubscribeSetting?

}
