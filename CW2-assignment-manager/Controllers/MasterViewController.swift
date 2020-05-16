//
//  MasterViewController.swift
//  CW2-assignment-manager
//
//  Created by Devon Wijesinghe on 5/16/20.
//  Copyright © 20202 Devon Wijesinghe. All rights reserved.
//

import UIKit
import EventKit

protocol ProjectSelectionDelegate: class {
    func projectSelected(_ newProject: Assignment)
}

class ProjectCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dueDateLabel: UILabel!
    @IBOutlet weak var priorityLabel: UILabel!
    @IBOutlet weak var notesLabel: UILabel!
    @IBOutlet weak var progressIndicatorView: UIView!
}

class MasterViewController: UITableViewController {
    
    @IBOutlet weak var addProjectButton: UIBarButtonItem!
    
    weak var delegate: ProjectSelectionDelegate?
    var projects: [Assignment]!
    var projectPlaceholder: Assignment?
    var isEditView: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        projects = Utilities.fetchFromDBContext(entityName: "Assignment")
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is AddEditAssignmentViewController {
            let popover = segue.destination as? AddEditAssignmentViewController
            
            popover?.isEditView = isEditView ? true : false
            popover?.projectPlaceholder = projectPlaceholder
            popover?.delegate = self
            popover?.saveFunction = {(popoverViewController) in
                self.saveProject(popoverViewController as! AddEditAssignmentViewController)
            }
            popover?.resetToDefaults = { () in
                self.isEditView = false
                self.projectPlaceholder = nil
                self.addProjectButton.image = UIImage(named: "add")
            }
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return projects.count
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedProject = projects[indexPath.row]
        delegate?.projectSelected(selectedProject)
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ProjectCell") as! ProjectCell
        
        cell.titleLabel.text = projects[indexPath.row].title
        cell.dueDateLabel.text = Utilities.getFormattedDateString(for: projects[indexPath.row].dueDate, format: "dd/MM/yy")
        cell.priorityLabel.text = projects[indexPath.row].level.getAsString()
        cell.notesLabel.text = projects[indexPath.row].notes
        cell.progressIndicatorView.backgroundColor = projects[indexPath.row].progress.color
        
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
            self.projectPlaceholder = self.projects[indexPath.row]
            self.addProjectButton.image = UIImage(named: "edit")
            self.performSegue(withIdentifier: "projectViewSegue", sender: self)
            completion(true)
        }
        action.image = UIImage(named: "edit")
        action.backgroundColor = .brown
        return action
    }
    
    func deleteAction (at indexPath: IndexPath) -> UIContextualAction {
        let action = UIContextualAction(style: .normal, title: "Delete") { (action, view, completion) in
            Utilities.showConfirmationAlert(title: "Are you sure?", message: "Delete assignment: " + self.projects[indexPath.row].title!, yesAction: {() in
                Utilities.getDBContext().delete(self.projects[indexPath.row])
                Utilities.saveDBContext()
                self.projects.remove(at: indexPath.row)
                self.tableView.deleteRows(at: [indexPath], with: .automatic)
                }, caller: self)
            completion(true)
        }
        action.image = UIImage(named: "delete")
        action.backgroundColor = .red
        return action
    }
    
    func saveProject(_ data: AddEditAssignmentViewController) {
        if let assignment = projectPlaceholder {
            assignment.title = data.titleTextField.text!
            assignment.startDate = data.startDate!
            assignment.dueDate = data.dueDate!
            assignment.level = assignPriority(for: data.prioritySegmentControl.selectedSegmentIndex)
            assignment.notes = data.notesTextField.text!

            if !assignment.isAddedToCalendar && data.addToCalendarToggle.isOn {
                addEventToCalendar(for: assignment)
                assignment.isAddedToCalendar = true
            }

            if let projectIndex = projects.firstIndex(where: {$0.projectId == assignment.projectId}) {
                projects[projectIndex] = assignment
            }
        } else {
            let assignment = Assignment(context: Utilities.getDBContext())
            assignment.title = data.titleTextField.text!
            assignment.startDate = data.startDate!
            assignment.dueDate = data.dueDate!
            assignment.level = assignPriority(for: data.prioritySegmentControl.selectedSegmentIndex)
            assignment.notes = data.notesTextField.text!

            if data.addToCalendarToggle.isOn {
                addEventToCalendar(for: assignment)
                assignment.isAddedToCalendar = true
            }

            self.projects.append(assignment)

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
