/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A viw controller that displays an array of `SearchableItem`s on an `MKMapView` and in `UITableView`.
*/

import UIKit
import MapKit

class MapViewController: UIViewController {
    static let tableViewCellIdentifier = "SearchResultCell"
    
    // MARK: Interface builder outlets
    
    @IBOutlet var mapView: MKMapView!
    
    @IBOutlet var tableView: UITableView!
    
    @IBOutlet var tableViewTrailingConstraint: NSLayoutConstraint!

    // MARK: Properties
    
    /// Array of items to show on the map.
    var items = [SearchableItem]()
    
    /// The selected item currently selected by the user.
    var selectedItem: SearchableItem?
    
    var highlightedItem: SearchableItem? {
        didSet {
            guard oldValue != highlightedItem else { return }
            
            if let oldValue = oldValue {
                reloadAnnotation(for: oldValue)
            }

            if let newValue = highlightedItem {
                reloadAnnotation(for: newValue)
            }
        }
    }
    
    /// Gesture recognizer to handle re-displaying the table view.
    private var menuGestureRecognizer: UITapGestureRecognizer?
    
    /// Gesture recognizer to detect selecting when an annotation has focos
    fileprivate var selectGestureRecognizer: UITapGestureRecognizer?
    
    /// The hidden state of the table view.
    fileprivate var tableViewHidden = false {
        didSet {
            // Check if the value has changed and the view has loaded.
            guard isViewLoaded && tableViewHidden != oldValue else { return }
            
            /*
                Update the constraint to position the table view on or off the
                screen and mark the view as needing to be laid out.
            */
            tableViewTrailingConstraint.constant = tableViewHidden ? -tableViewOverlapWidth : 0
            view.layoutIfNeeded()
            
            /*
                Enable the gesture recognizer to detect the menu button being
                pressed if the table view is hidden. Pressing the menu button
                in this state should re-show the table view.
            */
            menuGestureRecognizer?.isEnabled = tableViewHidden
            
            selectGestureRecognizer?.isEnabled = tableViewHidden
        }
    }
    
    private var tableViewOverlapWidth: CGFloat {
        return tableView.superview!.bounds.size.width
    }
    
    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        get {
            /*
                The focus should default to the selected table view cell if the
                table view is visible.
            */
            if !tableViewHidden {
                if let indexPath = tableView.indexPathForSelectedRow, let cell = tableView.cellForRow(at: indexPath) {
                    return [cell]
                }
                else {
                    return [tableView]
                }
            }
            
            // Fall back to the default preferred focused view.
            return super.preferredFocusEnvironments
        }
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.layoutIfNeeded()
        
        guard let selectedItem = selectedItem else { fatalError("No item selected") }
        
        // Set the table view's initial state to hidden.
        tableViewHidden = true
        
        /*
            Create a gesture recognizer to detect the menu button being pressed
            and add it to the map view. This will be used to re-show the table
            view if it's hidden.
        */
        menuGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleMenuGestureRecognizer(_:)))
        menuGestureRecognizer?.allowedPressTypes = [NSNumber(integerLiteral: UIPress.PressType.menu.rawValue)]
        mapView.addGestureRecognizer(menuGestureRecognizer!)

        /*
            Create a gesture recogniser to detect the selecte button being pressed
            and add it to the map view. This will be used to detect when the
            user clicks a selected annotation.
        */
        selectGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleSelectGestureRecognizer(_:)))
        selectGestureRecognizer?.allowedPressTypes = [NSNumber(integerLiteral: UIPress.PressType.select.rawValue)]
        selectGestureRecognizer?.delegate = self
        mapView.addGestureRecognizer(selectGestureRecognizer!)

        // Populate the map view with annotations for each item.
        let newAnnotations: [MKAnnotation] = items.map { SearchResultMapAnnotation(item: $0) }
        mapView.showAnnotations(newAnnotations, animated: false)
        
        // Select the annotation for the currently selected item.
        let annotation = self.annotation(for: selectedItem)
        mapView.selectAnnotation(annotation, animated: false)

        // Select the table view cell for the currently selected item.
        if let row = items.index(of: selectedItem) {
            let indexPath = IndexPath(row: row, section: 0)
            tableView.selectRow(at: indexPath, animated: false, scrollPosition: .middle)
        }
    }
    
    // MARK: UIFocusEnvironment
    
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        guard let nextFocusedView = context.nextFocusedView, let previouslyFocusedView = context.previouslyFocusedView else { return }
        
        /*
            If the focus has moved from the table view to the map view, hide the
            table view.
        */
        if nextFocusedView.isDescendant(of: mapView) && previouslyFocusedView.isDescendant(of: tableView) {
            animateTableView(hidden: true)
            
            // Select the annotation for the currently selected item.
            if let selectedItem = selectedItem {
                let annotation = self.annotation(for: selectedItem)
                mapView.selectAnnotation(annotation, animated: false)
            }
        }
    }
    
    // MARK: Gesture recognizer handlers
    
    @objc func handleMenuGestureRecognizer(_ recognizer: UITapGestureRecognizer) {
        // Hide the table view if the menu button has been tapped.
        if recognizer.state == .ended {
            animateTableView(hidden: false)
        }
    }
    
    @objc func handleSelectGestureRecognizer(_ recognizer: UITapGestureRecognizer) {
        // If the recognizer state is `Ended`, the user selected an annotation.
        if let selectedItem = selectedItem, recognizer.state == .ended {
            print("Selected \(selectedItem.title)")
        }
    }

    // MARK: Convenience
    
    /// Animates the table view, ensuring the correct selection state for map annotations.
    fileprivate func animateTableView(hidden: Bool) {
        // If the requested state is the same as the current state, do nothing.
        guard tableViewHidden != hidden else { return }
        
        guard let selectedItem = selectedItem else { fatalError("Mo item selected") }
        
        /*
            Determine an appropriate animation curve to used depending on
            whether the table view is being shown or hidden.
        */
        let animationCurve: UIView.AnimationOptions = hidden ? .curveEaseIn : .curveEaseOut

        let selectedItemAnnotation = annotation(for: selectedItem)
        
        if hidden {
            // Select the annotation for the selected item.
            highlightedItem = nil
            mapView.selectAnnotation(selectedItemAnnotation, animated: true)
        }
        else {
            /*
                Prevent the focus engine selecting an annotation during the
                animation.
            */
            setAnnotationSelectionEnabled(false)
            
            // De-select the annotation for the selected item.
            mapView.deselectAnnotation(selectedItemAnnotation, animated: true)
        }
        
        // Wrap a call to set the hidden state in an `UIView` animation block.
        UIView.animate(withDuration: 0.25, delay: 0, options: [animationCurve], animations: {
            self.tableViewHidden = hidden
        }, completion: { _ in
            // Trigger a focus update.
            self.setNeedsFocusUpdate()
            self.updateFocusIfNeeded()

            // Re-enable the annotation views.
            self.setAnnotationSelectionEnabled(true)
        })
        
        // If the table view has been show, make sure all the annotations are visible.
        if !hidden {
            mapView.layoutMargins.right = tableViewOverlapWidth
            mapView.showAnnotations(mapView.annotations, animated: true)
        }
        else {
            mapView.layoutMargins.right = mapView.layoutMargins.left
        }
    }
    
    /// Returns the `SearchResultMapAnnotation` instance that represents the passed `SearchableItem`.
    private func annotation(for item: SearchableItem) -> SearchResultMapAnnotation {
        let foundAnnotation = mapView.annotations.compactMap { annotation in
            return annotation as? SearchResultMapAnnotation
        }.filter { annotation in
            return annotation.item == item
        }.first
        
        guard let annotation = foundAnnotation else { fatalError("Unable to find annotation for item") }
        
        return annotation
    }
    
    private func reloadAnnotation(for item: SearchableItem) {
        let annotation = self.annotation(for: item)
        mapView.removeAnnotation(annotation)
        mapView.addAnnotation(annotation)
    }
    
    /**
        Sets the enabled state of all annotation views on the map.
     
        If annotation views are enabled they can become focused when the map is
        in the annotation selection mode and focus moves from the map to the
        table view or vice verca.
    */
    private func setAnnotationSelectionEnabled(_ enabled: Bool) {
        /*
            Set the map view'd delegate depending on whether we want notifications
            of changes to selection.
        */
        mapView.delegate = enabled ? self : nil
        
        for annotation in mapView.annotations {
            mapView.view(for: annotation)?.isEnabled = enabled
        }
    }
}



extension MapViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: MapViewController.tableViewCellIdentifier, for: indexPath)
        
        let item = items[indexPath.row]
        cell.textLabel?.text = item.title
        
        return cell
    }
}



extension MapViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Update the currently selected item.
        let item = items[indexPath.row]
        selectedItem = item

        // Hide the table view.
        animateTableView(hidden: true)
    }
    
    func tableView(_ tableView: UITableView, didUpdateFocusIn context: UITableViewFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        if let indexPath = context.nextFocusedIndexPath {
            let item = items[indexPath.row]
            highlightedItem = item
        }
        else {
            highlightedItem = nil
        }
    }
}



extension MapViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let searchResultMapAnnotation = annotation as? SearchResultMapAnnotation else { return nil }
        
        let annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "pin")
        annotationView.canShowCallout = true
        
        if searchResultMapAnnotation.item == highlightedItem {
            annotationView.pinTintColor = MKPinAnnotationView.purplePinColor()
        }
        else {
            annotationView.pinTintColor = MKPinAnnotationView.redPinColor()
        }

        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let annotation = view.annotation as? SearchResultMapAnnotation, tableViewHidden else { return }
        
        // Update the currently selected item.
        selectedItem = annotation.item
        
        // Update the table view selection.
        if let row = items.index(of: annotation.item) {
            let indexPath = IndexPath(row: row, section: 0)
            tableView.selectRow(at: indexPath, animated: false, scrollPosition: .middle)
        }
    }
}



extension MapViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        /*
            Only allow the select button recognizer to begin if the selected
            annotation's is also selected.
        */
        guard let annotation = mapView.selectedAnnotations.first as? SearchResultMapAnnotation, let annotationView = mapView.view(for: annotation), gestureRecognizer == selectGestureRecognizer else {
            return true
        }
        
        return annotationView.isSelected
    }
}
