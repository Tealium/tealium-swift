/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A view controller that demonstrates how to use UISegmentedControl.
*/

import UIKit

class SegmentedControlViewController: UITableViewController {
    // MARK: - Properties

    @IBOutlet weak var defaultSegmentedControl: UISegmentedControl!
    
    @IBOutlet weak var tintedSegmentedControl: UISegmentedControl!
    
    @IBOutlet weak var customSegmentsSegmentedControl: UISegmentedControl!
    
    @IBOutlet weak var customBackgroundSegmentedControl: UISegmentedControl!

    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        configureDefaultSegmentedControl()
        configureTintedSegmentedControl()
        configureCustomSegmentsSegmentedControl()
        configureCustomBackgroundSegmentedControl()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        TealiumHelper.shared.trackView(title: self.title ?? "View Controller", data: nil)
        super.viewDidAppear(animated)
    }

    // MARK: - Configuration

    func configureDefaultSegmentedControl() {

        defaultSegmentedControl.setEnabled(false, forSegmentAt: 0)

        defaultSegmentedControl.addTarget(self, action: #selector(SegmentedControlViewController.selectedSegmentDidChange(_:)), for: .valueChanged)
    }

    func configureTintedSegmentedControl() {
        tintedSegmentedControl.tintColor = UIColor.applicationBlueColor

        tintedSegmentedControl.selectedSegmentIndex = 1

        tintedSegmentedControl.addTarget(self, action: #selector(SegmentedControlViewController.selectedSegmentDidChange(_:)), for: .valueChanged)
    }

    func configureCustomSegmentsSegmentedControl() {
        let imageToAccessibilityLabelMappings = [
            "checkmark_icon": NSLocalizedString("Done", comment: ""),
            "search_icon": NSLocalizedString("Search", comment: ""),
            "tools_icon": NSLocalizedString("Settings", comment: "")
        ]

        // Guarantee that the segments show up in the same order.
        var sortedSegmentImageNames = Array(imageToAccessibilityLabelMappings.keys)
        sortedSegmentImageNames.sort { lhs, rhs in
            return lhs.localizedStandardCompare(rhs) == ComparisonResult.orderedAscending
        }

        for (idx, segmentImageName) in sortedSegmentImageNames.enumerated() {
            let image = UIImage(named: segmentImageName)!

            image.accessibilityLabel = imageToAccessibilityLabelMappings[segmentImageName]

            customSegmentsSegmentedControl.setImage(image, forSegmentAt: idx)
        }

        customSegmentsSegmentedControl.selectedSegmentIndex = 0

        customSegmentsSegmentedControl.addTarget(self, action: #selector(SegmentedControlViewController.selectedSegmentDidChange(_:)), for: .valueChanged)
    }


    func configureCustomBackgroundSegmentedControl() {
        customBackgroundSegmentedControl.selectedSegmentIndex = 2

        // Set the background images for each control state.
        let normalSegmentBackgroundImage = UIImage(named: "stepper_and_segment_background")
        customBackgroundSegmentedControl.setBackgroundImage(normalSegmentBackgroundImage, for: UIControl.State(), barMetrics: .default)

        let disabledSegmentBackgroundImage = UIImage(named: "stepper_and_segment_background_disabled")
        customBackgroundSegmentedControl.setBackgroundImage(disabledSegmentBackgroundImage, for: .disabled, barMetrics: .default)

        let highlightedSegmentBackgroundImage = UIImage(named: "stepper_and_segment_background_highlighted")
        customBackgroundSegmentedControl.setBackgroundImage(highlightedSegmentBackgroundImage, for: .highlighted, barMetrics: .default)

        // Set the divider image.
        let segmentDividerImage = UIImage(named: "stepper_and_segment_divider")
        customBackgroundSegmentedControl.setDividerImage(segmentDividerImage, forLeftSegmentState: UIControl.State(), rightSegmentState: UIControl.State(), barMetrics: .default)

        // Create a font to use for the attributed title (both normal and highlighted states).
        let captionFontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: UIFont.TextStyle.caption1)
        let font = UIFont(descriptor: captionFontDescriptor, size: 0)

        let normalTextAttributes = [
            NSAttributedString.Key.foregroundColor: UIColor.applicationPurpleColor,
            NSAttributedString.Key.font: font
        ]
        customBackgroundSegmentedControl.setTitleTextAttributes(normalTextAttributes, for: UIControl.State())

        let highlightedTextAttributes = [
            NSAttributedString.Key.foregroundColor: UIColor.applicationGreenColor,
            NSAttributedString.Key.font: font
        ]
        customBackgroundSegmentedControl.setTitleTextAttributes(highlightedTextAttributes, for: .highlighted)

        customBackgroundSegmentedControl.addTarget(self, action: #selector(SegmentedControlViewController.selectedSegmentDidChange(_:)), for: .valueChanged)
    }

    // MARK: - Actions

    @objc func selectedSegmentDidChange(_ segmentedControl: UISegmentedControl) {
        NSLog("The selected segment changed for: \(segmentedControl).")
    }
}
