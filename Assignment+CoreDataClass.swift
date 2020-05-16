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

enum ProjectPriority: Int {
    case Low, Medium, High
    
    func getAsString() -> String {
        switch self {
        case .High:
            return "High"
        case .Medium:
            return "Medium"
        default:
            return "Low"
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
    
    var priority: ProjectPriority {
        get {
            return ProjectPriority(rawValue: Int(rawPriority))!
        }
        set(newPriority) {
            rawPriority = Int16(newPriority.rawValue)
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

