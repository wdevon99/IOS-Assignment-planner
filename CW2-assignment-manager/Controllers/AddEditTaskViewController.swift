//
//  AddEditTaskViewController.swift
//  CW2-assignment-manager
//
//  Created by Devon Wijesinghe on 5/16/20.
//  Copyright © 20202 Devon Wijesinghe. All rights reserved.
//

import UIKit

class AddEditTaskViewController: UIViewController {
    @IBOutlet weak var viewTitleLabel: UILabel!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var notesTextField: UITextField!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var progressSlider: UISlider!
    @IBOutlet weak var addNotificationToggle: UISwitch!
    @IBOutlet weak var progressTitleLabel: UILabel!
    @IBOutlet weak var dateSegmentControl: UISegmentedControl!
    
    var hasPriorityStackView: Bool? = true
    var saveFunction: Utilities.saveFunctionType?
    var resetToDefaults: Utilities.resetToDefaultsFunctionType?
    var taskPlaceholder: Task?
    var isEditView: Bool?
    var startDate: Date?
    var dueDate: Date?
    
    weak var delegate: ItemActionDelegate?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let isEditMode = isEditView else { return }
        
        viewTitleLabel.text = isEditMode ? "Edit Task" : "Add Task"
        datePicker.timeZone = TimeZone(identifier: "UTC")
        
        startDate = Calendar.current.date(bySetting: .hour, value: 0, of: Date())
        dueDate = Calendar.current.date(bySetting: .hour, value: 1, of: Date())
        
        datePicker.date = startDate!
        
        if let task = taskPlaceholder  {
            titleTextField.text = task.title
            notesTextField.text = task.notes
            datePicker.date = task.startDate
            progressTitleLabel.text = "Progress = " + String((task.progress * 100).rounded()) + "%"
            progressSlider.value = task.progress * 100
            addNotificationToggle.isOn = !task.isAddedNotification
            addNotificationToggle.isEnabled = !task.isAddedNotification
            
            startDate = task.startDate
            dueDate = task.dueDate
            
            datePicker.minimumDate = task.assignment?.startDate
            datePicker.maximumDate = task.assignment?.dueDate
        }
        
        titleTextField.becomeFirstResponder()
    }
    
    @IBAction func dateSegmentControlValueChanged(_ sender: UISegmentedControl) {
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
    
    @IBAction func progressSliderValueChanged(_ sender: UISlider) {
        progressTitleLabel.text = "Progress = " + String(sender.value.rounded()) + "%"
    }
    
    @IBAction func cancelButtonPressed(_ sender: Any) {
        if let reset = resetToDefaults {
            reset()
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    func validateFields() -> Bool {
        if titleTextField.text == "" {
            Utilities.showInformationAlert(title: "Error", message: "Task name can't be empty", caller: self)
            return false
        } else if startDate! > dueDate! {
            Utilities.showInformationAlert(title: "Error", message: "Task start date must be before the due date", caller: self)
            return false
        }
        return true
    }
    
    @IBAction func saveButtonPressed(_ sender: Any) {
        guard let save = saveFunction else {
            preconditionFailure("Save function not defined")
        }
        
        if validateFields() {
            save(self)
            if let reset = resetToDefaults {
                reset()
            }
            self.dismiss(animated: true, completion: nil)
            isEditView! ? delegate?.itemEdited(title: self.titleTextField.text!) : delegate?.itemAdded(title: self.titleTextField.text!)
        }
    }
    
}
