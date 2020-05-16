//
//  AddEditProjectViewController.swift
//  CW2-assignment-manager
//
//  Created by Devon Wijesinghe on 5/16/20.
//  Copyright © 20202 Devon Wijesinghe. All rights reserved.
//

import UIKit

class AddEditAssignmentViewController: UIViewController {
    
    // ===== NEW =======
    @IBOutlet weak var moduleTextField: UITextField!
    @IBOutlet weak var valueTextField: UITextField!
    @IBOutlet weak var markAwardedTextField: UITextField!
    // =================
    
    @IBOutlet weak var viewTitleLabel: UILabel!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var notesTextField: UITextField!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var levelSegmentControl: UISegmentedControl!
    @IBOutlet weak var addToCalendarToggle: UISwitch!
    @IBOutlet weak var dateSegmentControl: UISegmentedControl!
    
    var saveFunction: Utilities.saveFunctionType?
    var resetToDefaults: Utilities.resetToDefaultsFunctionType?
    var assignmentPlaceholder: Assignment?
    var isEditView: Bool?
    var startDate: Date?
    var dueDate: Date?
    weak var delegate: ItemActionDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let isEditMode = isEditView else { return }
        
        datePicker.timeZone = TimeZone(identifier: "UTC")
        viewTitleLabel.text = isEditMode ? "Edit Assignment" : "Add Assignment"

        startDate = Calendar.current.date(bySetting: .hour, value: 0, of: Date())
        dueDate = Calendar.current.date(bySetting: .hour, value: 1, of: Date())
        
        datePicker.date = startDate!
        
        if let assignment = assignmentPlaceholder  {
            moduleTextField.text = assignment.module
            titleTextField.text = assignment.title
            notesTextField.text = assignment.notes
            datePicker.date = assignment.startDate
            levelSegmentControl.selectedSegmentIndex = assignment.level.rawValue
            addToCalendarToggle.isOn = !assignment.isAddedToCalendar
            addToCalendarToggle.isEnabled = !assignment.isAddedToCalendar
            
            startDate = assignment.startDate
            dueDate = assignment.dueDate
        }
        moduleTextField.becomeFirstResponder()
    }
    
    
    @IBAction func dataSegmentControlValueChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 1:
            datePicker.date = dueDate!
        default:
            datePicker.date = startDate!
        }
    }
    
    @IBAction func datePickerValueChanged(_ sender: UIDatePicker) {
        switch dateSegmentControl.selectedSegmentIndex {
        case 1:
                dueDate = sender.date
        default:
                startDate = sender.date
        }
    }
    
    @IBAction func saveButtonPressed(_ sender: Any) {
        guard let save = saveFunction else {
            preconditionFailure("Save function not defined")
        }
        
        if validateFields() {
            save(self)
            if let reset = resetToDefaults {
                datePicker.minimumDate = nil
                datePicker.maximumDate = nil
                reset()
            }
            self.dismiss(animated: true, completion: nil)
            isEditView! ? delegate?.itemEdited(title: self.titleTextField.text!) : delegate?.itemAdded(title: self.titleTextField.text!)
        }
    }
    
    func validateFields() -> Bool {

        if moduleTextField.text == "" {
            Utilities.showInformationAlert(title: "Error", message: "Module name can't be empty", caller: self)
            return false
        } else if titleTextField.text == "" {
            Utilities.showInformationAlert(title: "Error", message: "Assignment name can't be empty", caller: self)
            return false
        } else if startDate! > dueDate! {
            Utilities.showInformationAlert(title: "Error", message: "Assignment start date must be before the due date", caller: self)
            return false
        }
        return true
    }
    
    @IBAction func cancelButtonPressed(_ sender: Any) {
        if let reset = resetToDefaults {
            datePicker.minimumDate = nil
            datePicker.maximumDate = nil
            reset()
        }
        self.dismiss(animated: true, completion: nil)
    }
    
}
