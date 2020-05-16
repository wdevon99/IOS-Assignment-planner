//
//  Task.swift
//  project-manager
//
//  Created by Gayashan Bombuwala on 5/26/19.
//  Copyright © 2019 Gayashan Bombuwala. All rights reserved.
//

import UIKit
import CoreData


@objc(Task)
public class Task: NSManagedObject {
    
    var startDate: Date {
        get {
            return Calendar.current.date(bySetting: .hour, value: 0, of: startDateRaw!)!
        }
        set(newDate) {
            startDateRaw = Calendar.current.date(bySetting: .hour, value: 0, of: newDate)!
        }
    }
    
    var dueDate: Date {
        get {
            return Calendar.current.date(bySetting: .hour, value: 1, of: dueDateRaw!)!
        }
        set(newDate) {
            dueDateRaw = Calendar.current.date(bySetting: .hour, value: 1, of: newDate)!
        }
    }
    
    var progressColor: UIColor {
        get {
            return Utilities.getColorFor(value: progress * 100)
        }
    }
    
    var daysRemaining: (value: CGFloat, color: UIColor) {
        get {
            let days = Float(Utilities.getDaysDifference(between: Date(), and: dueDateRaw!) / 100)
            return (CGFloat(days), Utilities.getColorFor(value: days * 100))
        }
    }
    
}

extension Task {
    override public func awakeFromInsert() {
        setPrimitiveValue(UUID().uuidString, forKey: "taskId")
    }
}
