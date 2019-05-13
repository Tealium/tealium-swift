/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The view controller that demonstrates how to use UIAlertController.
*/

import UIKit

class AlertControllerViewController : UITableViewController {
    // MARK: - Properties

    weak var secureTextAlertAction: UIAlertAction?
    
    /*
        A matrix of closures that should be invoked based on which table view
        cell is tapped (index by section, row).
    */
    var actionMap: [[(_ selectedIndexPath: IndexPath) -> Void]] {
        return [
            // Alert style alerts.
            [
                showSimpleAlert,
                showOkayCancelAlert,
                showOtherAlert,
                showTextEntryAlert,
                showSecureTextEntryAlert
            ],
            // Action sheet style alerts.
            [
                showOkayCancelActionSheet,
                showOtherActionSheet
            ]
        ]
    }
    
    override func viewDidAppear(_ animated: Bool) {
        TealiumHelper.shared.trackView(title: self.title ?? "View Controller", data: nil)
        super.viewDidAppear(animated)
    }
    
    // MARK: - UIAlertControllerStyleAlert Style Alerts

    /// Show an alert with an "Okay" button.
    func showSimpleAlert(_: IndexPath) {
        let title = NSLocalizedString("A Short Title is Best", comment: "")
        let message = NSLocalizedString("A message should be a short, complete sentence.", comment: "")
        let cancelButtonTitle = NSLocalizedString("OK", comment: "")

        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)

        // Create the action.
        let cancelAction = UIAlertAction(title: cancelButtonTitle, style: .cancel) { action in
            NSLog("The simple alert's cancel action occured.")
        }

        // Add the action.
        alertController.addAction(cancelAction)

        present(alertController, animated: true) {
            TealiumHelper.shared.track(title: "Simple Alert", data: nil)
        }
    }
    
    /// Show an alert with an "Okay" and "Cancel" button.
    func showOkayCancelAlert(_: IndexPath) {
        let title = NSLocalizedString("A Short Title is Best", comment: "")
        let message = NSLocalizedString("A message should be a short, complete sentence.", comment: "")
        let cancelButtonTitle = NSLocalizedString("Cancel", comment: "")
        let otherButtonTitle = NSLocalizedString("OK", comment: "")
        
        let alertCotroller = UIAlertController(title: title, message: message, preferredStyle: .alert)

        // Create the actions.
        let cancelAction = UIAlertAction(title: cancelButtonTitle, style: .cancel) { _ in
            NSLog("The \"Okay/Cancel\" alert's cancel action occured.")
        }
        
        let otherAction = UIAlertAction(title: otherButtonTitle, style: .default) { _ in
            NSLog("The \"Okay/Cancel\" alert's other action occured.")
        }
        
        // Add the actions.
        alertCotroller.addAction(cancelAction)
        alertCotroller.addAction(otherAction)

        present(alertCotroller, animated: true) {
            TealiumHelper.shared.track(title: "OK Cancel Alert", data: nil)
        }
    }

    /// Show an alert with two custom buttons.
    func showOtherAlert(_: IndexPath) {
        let title = NSLocalizedString("A Short Title is Best", comment: "")
        let message = NSLocalizedString("A message should be a short, complete sentence.", comment: "")
        let cancelButtonTitle = NSLocalizedString("Cancel", comment: "")
        let otherButtonTitleOne = NSLocalizedString("Choice One", comment: "")
        let otherButtonTitleTwo = NSLocalizedString("Choice Two", comment: "")
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        // Create the actions.
        let cancelAction = UIAlertAction(title: cancelButtonTitle, style: .cancel) { action in
            NSLog("The \"Other\" alert's cancel action occured.")
        }
        
        let otherButtonOneAction = UIAlertAction(title: otherButtonTitleOne, style: .default) { _ in
            NSLog("The \"Other\" alert's other button one action occured.")
        }
        
        let otherButtonTwoAction = UIAlertAction(title: otherButtonTitleTwo, style: .default) { _ in
            NSLog("The \"Other\" alert's other button two action occured.")
        }
        
        // Add the actions.
        alertController.addAction(cancelAction)
        alertController.addAction(otherButtonOneAction)
        alertController.addAction(otherButtonTwoAction)
        
        present(alertController, animated: true) {
            TealiumHelper.shared.track(title: "Custom Alert", data: nil)
        }
    }

    /// Show a text entry alert with two custom buttons.
    func showTextEntryAlert(_: IndexPath) {
        let title = NSLocalizedString("A Short Title is Best", comment: "")
        let message = NSLocalizedString("A message should be a short, complete sentence.", comment: "")
        let cancelButtonTitle = NSLocalizedString("Cancel", comment: "")
        let otherButtonTitle = NSLocalizedString("OK", comment: "")
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        // Add the text field for text entry.
        alertController.addTextField { textField in
            // If you need to customize the text field, you can do so here.
        }

        // Create the actions.
        let cancelAction = UIAlertAction(title: cancelButtonTitle, style: .cancel) { _ in
            NSLog("The \"Text Entry\" alert's cancel action occured.")
        }
        
        let otherAction = UIAlertAction(title: otherButtonTitle, style: .default) { _ in
            NSLog("The \"Text Entry\" alert's other action occured.")
        }
        
        // Add the actions.
        alertController.addAction(cancelAction)
        alertController.addAction(otherAction)
        
        present(alertController, animated: true) {
            TealiumHelper.shared.track(title: "Text Entry Alert", data: nil)
        }
    }
    
    /// Show a secure text entry alert with two custom buttons.
    func showSecureTextEntryAlert(_: IndexPath) {
        let title = NSLocalizedString("A Short Title is Best", comment: "")
        let message = NSLocalizedString("A message should be a short, complete sentence.", comment: "")
        let cancelButtonTitle = NSLocalizedString("Cancel", comment: "")
        let otherButtonTitle = NSLocalizedString("OK", comment: "")
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        // Add the text field for the secure text entry.
        alertController.addTextField { textField in
            /*
                Listen for changes to the text field's text so that we can toggle the current
                action's enabled property based on whether the user has entered a sufficiently
                secure entry.
            */
            NotificationCenter.default.addObserver(self, selector: #selector(AlertControllerViewController.handleTextFieldTextDidChangeNotification(_:)), name: UITextField.textDidChangeNotification, object: textField)
            
            textField.isSecureTextEntry = true
        }
        
        /*
            Stop listening for text change notifications on the text field. This
            closure will be called in the two action handlers.
        */
        let removeTextFieldObserver: () -> Void = {
            NotificationCenter.default.removeObserver(self, name: UITextField.textDidChangeNotification, object: alertController.textFields!.first)
        }

        // Create the actions.
        let cancelAction = UIAlertAction(title: cancelButtonTitle, style: .cancel) { _ in
            NSLog("The \"Secure Text Entry\" alert's cancel action occured.")
            
            removeTextFieldObserver()
        }
        
        let otherAction = UIAlertAction(title: otherButtonTitle, style: .default) { _ in
            NSLog("The \"Secure Text Entry\" alert's other action occured.")
            
            removeTextFieldObserver()
        }
        
        // The text field initially has no text in the text field, so we'll disable it.
        otherAction.isEnabled = false
        
        /*
            Hold onto the secure text alert action to toggle the enabled / disabled 
            state when the text changed.
        */
        secureTextAlertAction = otherAction
        
        // Add the actions.
        alertController.addAction(cancelAction)
        alertController.addAction(otherAction)
        
        present(alertController, animated: true) {
            TealiumHelper.shared.track(title: "Secure Text Entry Alert", data: nil)
        }
    }
    
    // MARK: - UIAlertControllerStyleActionSheet Style Alerts
    
    /// Show a dialog with an "Okay" and "Cancel" button.
    func showOkayCancelActionSheet(_ selectedIndexPath: IndexPath) {
        let cancelButtonTitle = NSLocalizedString("Cancel", comment: "OK")
        let destructiveButtonTitle = NSLocalizedString("OK", comment: "")
        
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        // Create the actions.
        let cancelAction = UIAlertAction(title: cancelButtonTitle, style: .cancel) { _ in
            NSLog("The \"Okay/Cancel\" alert action sheet's cancel action occured.")
        }
        
        let destructiveAction = UIAlertAction(title: destructiveButtonTitle, style: .destructive) { _ in
            NSLog("The \"Okay/Cancel\" alert action sheet's destructive action occured.")
        }
        
        // Add the actions.
        alertController.addAction(cancelAction)
        alertController.addAction(destructiveAction)
        
        // Configure the alert controller's popover presentation controller if it has one.
        if let popoverPresentationController = alertController.popoverPresentationController {
            // This method expects a valid cell to display from.
            let selectedCell = tableView.cellForRow(at: selectedIndexPath)!
            popoverPresentationController.sourceRect = selectedCell.frame
            popoverPresentationController.sourceView = view
            popoverPresentationController.permittedArrowDirections = .up
        }
        
        present(alertController, animated: true) {
            TealiumHelper.shared.track(title: "OK Cancel Action Sheet Alert", data: nil)
        }
    }

    /// Show a dialog with two custom buttons.
    func showOtherActionSheet(_ selectedIndexPath: IndexPath) {
        let destructiveButtonTitle = NSLocalizedString("Destructive Choice", comment: "")
        let otherButtonTitle = NSLocalizedString("Safe Choice", comment: "")
        
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        // Create the actions.
        let destructiveAction = UIAlertAction(title: destructiveButtonTitle, style: .destructive) { _ in
            NSLog("The \"Other\" alert action sheet's destructive action occured.")
        }
        
        let otherAction = UIAlertAction(title: otherButtonTitle, style: .default) { _ in
            NSLog("The \"Other\" alert action sheet's other action occured.")
        }
        
        // Add the actions.
        alertController.addAction(destructiveAction)
        alertController.addAction(otherAction)
        
        // Configure the alert controller's popover presentation controller if it has one.
        if let popoverPresentationController = alertController.popoverPresentationController {
            // This method expects a valid cell to display from.
            let selectedCell = tableView.cellForRow(at: selectedIndexPath)!
            popoverPresentationController.sourceRect = selectedCell.frame
            popoverPresentationController.sourceView = view
            popoverPresentationController.permittedArrowDirections = .up
        }
        
        present(alertController, animated: true) {
            TealiumHelper.shared.track(title: "Other Action Sheet Alert", data: nil)
        }
    }
    
    // MARK: - UITextFieldTextDidChangeNotification

    @objc func handleTextFieldTextDidChangeNotification(_ notification: Notification) {
        let textField = notification.object as! UITextField

        // Enforce a minimum length of >= 5 characters for secure text alerts.
        if let text = textField.text {
            secureTextAlertAction!.isEnabled = text.count >= 5
        }
        else {
            secureTextAlertAction!.isEnabled = false
        }
    }
    
    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let action = actionMap[indexPath.section][indexPath.row]
        
        action(indexPath)

        tableView.deselectRow(at: indexPath, animated: true)
    }
}
