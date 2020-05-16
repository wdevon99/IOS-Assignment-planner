//
//  MasterViewController.swift
//  CW2-assignment-manager
//
//  Created by Devon Wijesinghe on 5/16/20.
//  Copyright © 20202 Devon Wijesinghe. All rights reserved.
//

import UIKit
import EventKit

protocol AssignmentSelectionDelegate: class {
    func assignmentSelected(_ newAssignment: Assignment)
}

class AssignmentCell: UITableViewCell {
    @IBOutlet weak var moduleLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dueDateLabel: UILabel!
    @IBOutlet weak var priorityLabel: UILabel!
    @IBOutlet weak var progressIndicatorView: UIView!
}

class MasterViewController: UITableViewController {
    
    @IBOutlet weak var addAssignmentButton: UIBarButtonItem!
    
    weak var delegate: AssignmentSelectionDelegate?
    var assignments: [Assignment]!
    var assignmentPlaceholder: Assignment?
    var isEditView: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        assignments = Utilities.fetchFromDBContext(entityName: "Assignment")
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is AddEditAssignmentViewController {
            let popover = segue.destination as? AddEditAssignmentViewController
            
            popover?.isEditView = isEditView ? true : false
            popover?.assignmentPlaceholder = assignmentPlaceholder
            popover?.delegate = self
            popover?.saveFunction = {(popoverViewController) in
                self.saveAssignment(popoverViewController as! AddEditAssignmentViewController)
            }
            popover?.resetToDefaults = { () in
                self.isEditView = false
                self.assignmentPlaceholder = nil
                self.addAssignmentButton.image = UIImage(named: "add")
            }
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return assignments.count
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedAssignment = assignments[indexPath.row]
        delegate?.assignmentSelected(selectedAssignment)
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AssignmentCell") as! AssignmentCell
        
        cell.moduleLabel.text = assignments[indexPath.row].module
        cell.titleLabel.text = assignments[indexPath.row].title
        cell.dueDateLabel.text = Utilities.getFormattedDateString(for: assignments[indexPath.row].dueDate, format: "dd/MM/yy")
        cell.priorityLabel.text = assignments[indexPath.row].level.getAsString()
        cell.progressIndicatorView.backgroundColor = assignments[indexPath.row].progress.color
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let delete = deleteAction(at: indexPath)
        let edit = editAction(at: indexPath)
        return UISwipeActionsConfiguration(actions: [delete, edit])
    }
    
    func editAction (at indexPath: IndexPath) -> UIContextualAction {
        let action = UIContextualAction(style: .normal, title: "Edit") { (action, view, completion) in
            self.isEditView = true
            self.assignmentPlaceholder = self.assignments[indexPath.row]
            self.addAssignmentButton.image = UIImage(named: "edit")
            self.performSegue(withIdentifier: "assignmentViewSegue", sender: self)
            completion(true)
        }
        action.image = UIImage(named: "edit")
        action.image = action.image?.withTintColor(.white)
        action.backgroundColor = .systemBlue
        return action
    }
    
    func deleteAction (at indexPath: IndexPath) -> UIContextualAction {
        let action = UIContextualAction(style: .normal, title: "Delete") { (action, view, completion) in
            Utilities.showConfirmationAlert(title: "Are you sure?", message: "Delete assignment: " + self.assignments[indexPath.row].title!, yesAction: {() in
                Utilities.getDBContext().delete(self.assignments[indexPath.row])
                Utilities.saveDBContext()
                self.assignments.remove(at: indexPath.row)
                self.tableView.deleteRows(at: [indexPath], with: .automatic)
                }, caller: self)
            completion(true)
        }
        action.image = UIImage(named: "delete")
        action.image = action.image?.withTintColor(.white)
        action.backgroundColor = .systemRed
        return action
    }
    
    func saveAssignment(_ data: AddEditAssignmentViewController) {
        if let assignment = assignmentPlaceholder {
            assignment.module = data.moduleTextField.text!
            assignment.title = data.titleTextField.text!
            assignment.value = data.valueTextField.text!
            assignment.markAwarded = data.markAwardedTextField.text!
            assignment.startDate = data.startDate!
            assignment.dueDate = data.dueDate!
            assignment.level = assignPriority(for: data.levelSegmentControl.selectedSegmentIndex)
            assignment.notes = data.notesTextField.text!

            if !assignment.isAddedToCalendar && data.addToCalendarToggle.isOn {
                addEventToCalendar(for: assignment)
                assignment.isAddedToCalendar = true
            }

            if let assignmentsIndex = assignments.firstIndex(where: {$0.assignmentId == assignment.assignmentId}) {
                assignments[assignmentsIndex] = assignment
            }
        } else {
            let assignment = Assignment(context: Utilities.getDBContext())
            assignment.module = data.moduleTextField.text!
            assignment.title = data.titleTextField.text!
            assignment.value = data.valueTextField.text!
            assignment.markAwarded = data.markAwardedTextField.text!
            assignment.startDate = data.startDate!
            assignment.dueDate = data.dueDate!
            assignment.level = assignPriority(for: data.levelSegmentControl.selectedSegmentIndex)
            assignment.notes = data.notesTextField.text!

            if data.addToCalendarToggle.isOn {
                addEventToCalendar(for: assignment)
                assignment.isAddedToCalendar = true
            }

            self.assignments.append(assignment)

        }
        Utilities.saveDBContext()
        self.tableView.reloadData()
    }
    
    func assignPriority(for index: Int) -> AssignmentLevel {
        switch index {
        case 1:
            return .four
        case 2:
            return .five
        case 3:
            return .six
        case 4:
            return .seven
        default:
            return .three
        }
    }
    
    func addEventToCalendar (for assignment: Assignment) {
        let eventStore : EKEventStore = EKEventStore()

        eventStore.requestAccess(to: .event) { (granted, error) in
            if (granted) && (error == nil) {
                let event: EKEvent = EKEvent(eventStore: eventStore)
                
                event.title = assignment.title
                event.startDate = assignment.startDate
                event.endDate = assignment.dueDate
                event.notes = assignment.notes
                event.calendar = eventStore.defaultCalendarForNewEvents 
                
                do {
                    try eventStore.save(event, span: .thisEvent)
                } catch let error as NSError {
                    fatalError("Failed to save event with error : \(error)")
                }
            }
            else {
                fatalError("Failed to save event with error : \(String(describing: error)) or access not granted")
            }
        }
    }
    
}

extension MasterViewController: TasksChangedDelegate {
    func tasksChanged() {
        let indexPath = tableView.indexPathForSelectedRow
        tableView.reloadData()
        tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
    }
}

extension MasterViewController: ItemActionDelegate {
    func itemAdded(title: String) {
        Utilities.showInformationAlert(title: "Alert", message: "New assignment: \(title)\nSuccessfully Added", caller: self)
    }
    
    func itemEdited(title: String) {
        Utilities.showInformationAlert(title: "Alert", message: "Assignment: \(title)\nSuccessfully Edited", caller: self)
    }
}
