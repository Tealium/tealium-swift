/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A `UIViewController` that implements the `UISearchResultsUpdating` protocol to display results from a `UISearchController` in a `UITableView`.
*/

import UIKit

class SearchResultsViewController: UIViewController {
    // MARK: State
    
    private enum State {
        case popularItems([SearchableItem])
        case searchResults([SearchableItem])
    }
    
    // MARK: Properties
    
    static let storyboardIdentifier = "SearchResultsViewController"
    
    static let tableViewCellIdentifier = "SearchResultsCell"
    
    private let searchableItems = SearchableItem.sampleItems
    
    private var state: State = .popularItems(SearchableItem.samplePopularItems) {
        didSet {
            guard isViewLoaded else { return }
            tableView.reloadData()
            updateHintLabel()
        }
    }

    fileprivate var tableViewItems: [SearchableItem] {
        switch state {
            case .popularItems(let items):
                return items
                
            case .searchResults(let items):
                return items
        }
    }
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var hintLabel: UILabel!

    var filterString = "" {
        didSet {
            // Return if the filter string hasn't changed.
            guard filterString != oldValue else { return }
            
            // Apply the filter or show all items if the filter string is empty.
            if filterString.isEmpty {
                state = .popularItems(SearchableItem.samplePopularItems)
            }
            else {
                let filteredItems = searchableItems.filter { $0.title.localizedCaseInsensitiveContains(filterString) }
                state = .searchResults(filteredItems)
            }
        }
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateHintLabel()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if let mapViewController = segue.destination as? MapViewController, let selectedIndexPath = tableView.indexPathForSelectedRow {
            mapViewController.items = tableViewItems
            mapViewController.selectedItem = tableViewItems[selectedIndexPath.row]
        }
    }

    // MARK: Convenience
    
    private func updateHintLabel() {
        switch state {
            case .popularItems(_):
                return hintLabel.text = NSLocalizedString("Popular Bay Area Locations", comment: "")
            
            case .searchResults(let searchResults) where searchResults.isEmpty:
                return hintLabel.text = NSLocalizedString("No points of interest found", comment: "")
            
            case .searchResults(_):
                return hintLabel.text = NSLocalizedString("Matching Points Of Interest", comment: "")
        }
    }
}

extension SearchResultsViewController: UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        // Check of the change is due to user input in the search bar.
        guard searchController.searchBar.isFirstResponder else { return }
        
        // Update the filter string with the text in the search bar.
        filterString = searchController.searchBar.text ?? ""
    }
}

extension SearchResultsViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableViewItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Dequeue a cell from the table view and configure it with the item details.
        let cell = tableView.dequeueReusableCell(withIdentifier: SearchResultsViewController.tableViewCellIdentifier, for: indexPath)
        let item = tableViewItems[indexPath.row]

        cell.textLabel?.text = item.title
        
        return cell
    }
}
