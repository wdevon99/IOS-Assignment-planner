//
//  Commons.swift
//  project-manager
//
//  Created by Gayashan Bombuwala on 5/19/19.
//  Copyright © 2019 Gayashan Bombuwala. All rights reserved.
//

import UIKit
import CoreData

protocol ItemActionDelegate: class {
    func itemAdded(title: String)
    func itemEdited(title: String)
}

class Utilities {
    
    static var alert: UIAlertController!
    static let dateFormatter = DateFormatter()
    
    typealias actionHandler = ()  -> Void
    typealias saveFunctionType = (_ viewController: UIViewController) -> Void
    typealias resetToDefaultsFunctionType = () -> Void
    
    private static let container = (UIApplication.shared.delegate as! AppDelegate).persistentContainer
    
    static func getDBContext() -> NSManagedObjectContext  {
        return container.viewContext
    }
    
    static func saveDBContext()  {
        if Utilities.getDBContext().hasChanges {
            do {
                try Utilities.getDBContext().save()
            } catch {
                fatalError("Unresolved error while saving the context \(error)")
            }
        }
    }
    
    static func fetchFromDBContext<Entity>(entityName: String, predicate: NSPredicate? = nil, sortDescriptor: NSSortDescriptor? = nil) -> [Entity] where Entity: NSManagedObject {
        let request: NSFetchRequest<Entity> = NSFetchRequest<Entity>(entityName: entityName)
        
        if let selectedPredicate = predicate {
            request.predicate = selectedPredicate
        }
        
        if let selectedSortDescriptor = sortDescriptor {
            request.sortDescriptors = [selectedSortDescriptor]
        }
        
        do {
            let results = try Utilities.getDBContext().fetch(request)
            return results
        } catch {
            fatalError("Unresolved error while loading the context \(error)")
        }
    }
    
    static func showConfirmationAlert (title: String, message: String, yesAction: @escaping actionHandler = {() in}, noAction: @escaping actionHandler = {() in}, caller: UIViewController) {
        alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "No", style: .destructive, handler: { action in
            noAction()
        }))
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { action in
            yesAction()
        }))
        caller.present(alert, animated: true, completion: nil)
    }
    
    static func showInformationAlert (title: String, message: String, caller: UIViewController) {
        alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        caller.present(alert, animated: true, completion: nil)
    }
    
    static func getDaysDifference(between firstDate: Date, and secondDate: Date) -> Float {
        let calendar = Calendar.current
        
        let date1 = calendar.startOfDay(for: firstDate)
        let date2 = calendar.startOfDay(for: secondDate)
        
        return Float(calendar.dateComponents([.day], from: date1, to: date2).day!) - 1
    }
    
    static func getColorFor(value: Float) -> UIColor {
        if value >= 0 && value <= 25 {
            return .red
        } else if value > 25 && value <= 50 {
            return .orange
        } else if value > 50 && value <= 75 {
            return .green
        } else {
            return .blue
        }
    }
    
    static func getFormattedDateString(for date: Date, format: String) -> String {
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: date)
    }
}
