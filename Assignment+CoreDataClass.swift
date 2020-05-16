//
//  Assignment+CoreDataClass.swift
//  CW2-assignment-manager
//
//  Created by Devon Wijesinghe on 5/16/20.
//  Copyright © 2020 Devon Wijesinghe. All rights reserved.
//
//

import Foundation
import UIKit
import CoreData

enum AssignmentLevel: Int {
    case three, four, five, six, seven
    
    func getAsString() -> String {
        switch self {
        case .three:
            return "3"
        case .four:
            return "4"
        case .five:
            return "5"
        case .six:
            return "6"
        case .seven:
            return "7"
        }
    }
}

@objc(Assignment)
public class Assignment: NSManagedObject {
    
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
    
    var level: AssignmentLevel {
        get {
            return AssignmentLevel(rawValue: Int(rawLevel))!
        }
        set(newLevel) {
            rawLevel = Int16(newLevel.rawValue)
        }
    }
    
    var progress: (value: Float, color: UIColor) {
        get {
            let tasks = rawTasks?.allObjects as! [Task]
            let value = tasks.count == 0 ? Float(0) : (tasks.map({$0.progress}).reduce(Float(0), +)) / Float(tasks.count)
            return (value, Utilities.getColorFor(value: value * 100))
        }
    }
    
    var daysRemaining: (value: CGFloat, color: UIColor) {
        get {
            let days = Float(Utilities.getDaysDifference(between: Date(), and: dueDateRaw!) / 100)
            return (CGFloat(days), Utilities.getColorFor(value: days * 100))
        }
    }
}

extension Assignment {
    override public func awakeFromInsert() {
        setPrimitiveValue(UUID().uuidString, forKey: "projectId")
    }
}

