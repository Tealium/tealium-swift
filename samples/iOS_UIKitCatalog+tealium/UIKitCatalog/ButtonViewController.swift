/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A view controller that demonstrates how to use UIButton. The buttons are created using storyboards, but each of the system buttons can be created in code by using the UIButton.buttonWithType() initializer. See the UIButton interface for a comprehensive list of the various UIButtonType values.
*/

import UIKit

class ButtonViewController: UITableViewController {
    // MARK: - Properties

    @IBOutlet weak var systemTextButton: UIButton!
    
    @IBOutlet weak var systemContactAddButton: UIButton!
    
    @IBOutlet weak var systemDetailDisclosureButton: UIButton!
    
    @IBOutlet weak var imageButton: UIButton!
    
    @IBOutlet weak var attributedTextButton: UIButton!

    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // All of the buttons are created in the storyboard, but configured below.
        configureSystemTextButton()
        configureSystemContactAddButton()
        configureSystemDetailDisclosureButton()
        configureImageButton()
        configureAttributedTextSystemButton()
    }

    // MARK: - Configuration

    func configureSystemTextButton() {
        let buttonTitle = NSLocalizedString("Button", comment: "")

        systemTextButton.setTitle(buttonTitle, for: UIControl.State())

        systemTextButton.addTarget(self, action: #selector(ButtonViewController.buttonClicked(_:)), for: .touchUpInside)
    }

    func configureSystemContactAddButton() {
        systemContactAddButton.backgroundColor = UIColor.clear

        systemContactAddButton.addTarget(self, action: #selector(ButtonViewController.buttonClicked(_:)), for: .touchUpInside)
    }

    func configureSystemDetailDisclosureButton() {
        systemDetailDisclosureButton.backgroundColor = UIColor.clear

        systemDetailDisclosureButton.addTarget(self, action: #selector(ButtonViewController.buttonClicked(_:)), for: .touchUpInside)
    }

    func configureImageButton() {
        // To create this button in code you can use UIButton.buttonWithType() with a parameter value of .Custom.

        // Remove the title text.
        imageButton.setTitle("", for: UIControl.State())

        imageButton.tintColor = UIColor.applicationPurpleColor

        let imageButtonNormalImage = UIImage(named: "x_icon")
        imageButton.setImage(imageButtonNormalImage, for: UIControl.State())

        // Add an accessibility label to the image.
        imageButton.accessibilityLabel = NSLocalizedString("X Button", comment: "")

        imageButton.addTarget(self, action: #selector(ButtonViewController.buttonClicked(_:)), for: .touchUpInside)
    }

    func configureAttributedTextSystemButton() {
        let buttonTitle = NSLocalizedString("Button", comment: "")
        
        // Set the button's title for normal state.
        let normalTitleAttributes = [
            convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.applicationBlueColor,
            convertFromNSAttributedStringKey(NSAttributedString.Key.strikethroughStyle): NSUnderlineStyle.single.rawValue
        ] as [String : Any]
        let normalAttributedTitle = NSAttributedString(string: buttonTitle, attributes: convertToOptionalNSAttributedStringKeyDictionary(normalTitleAttributes))
        attributedTextButton.setAttributedTitle(normalAttributedTitle, for: UIControl.State())

        // Set the button's title for highlighted state.
        let highlightedTitleAttributes = [
            convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.green,
            convertFromNSAttributedStringKey(NSAttributedString.Key.strikethroughStyle): NSUnderlineStyle.thick.rawValue
        ] as [String : Any]
        let highlightedAttributedTitle = NSAttributedString(string: buttonTitle, attributes: convertToOptionalNSAttributedStringKeyDictionary(highlightedTitleAttributes))
        attributedTextButton.setAttributedTitle(highlightedAttributedTitle, for: .highlighted)

        attributedTextButton.addTarget(self, action: #selector(ButtonViewController.buttonClicked(_:)), for: .touchUpInside)
    }

    // MARK: - Actions

    @objc func buttonClicked(_ sender: UIButton) {
        NSLog("A button was clicked: \(sender).")
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromNSAttributedStringKey(_ input: NSAttributedString.Key) -> String {
	return input.rawValue
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
	guard let input = input else { return nil }
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value)})
}
