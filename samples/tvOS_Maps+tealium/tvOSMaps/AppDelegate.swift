/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The application's delegate class.
*/

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = [:]) -> Bool {
        // Add a search view controller to the root `UITabBarController`.
        if let tabController = window?.rootViewController as? UITabBarController {
            tabController.viewControllers?.append(packagedSearchController())
        }
        
        let extraData : [String:AnyObject] = ["customKey" : "customValue" as AnyObject]
        
        TealiumHelper.shared.start()
        TealiumHelper.shared.track(title: "testLaunch",
                                             data: extraData)
        return true
    }
    
    // MARK: Convenience
    
    /*
         A method demonstrating how to encapsulate a `UISearchController` for presentation in, for example, a `UITabBarController`
    */
    func packagedSearchController() -> UIViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let searchResultsController = storyboard.instantiateViewController(withIdentifier: SearchResultsViewController.storyboardIdentifier) as? SearchResultsViewController else { fatalError("Unable to instantiate a SearchResultsViewController.") }
        
        /*
            Create a UISearchController, passing the `searchResultsController` to
            use to display search results.
        */
        let searchController = UISearchController(searchResultsController: searchResultsController)
        searchController.searchResultsUpdater = searchResultsController
        searchController.searchBar.placeholder = NSLocalizedString("Enter keyword (e.g. bridge)", comment: "")
        
        // Contain the `UISearchController` in a `UISearchContainerViewController`.
        let searchContainer = UISearchContainerViewController(searchController: searchController)
        searchContainer.title = NSLocalizedString("Search", comment: "")
        
        // Finally contain the `UISearchContainerViewController` in a `UINavigationController`.
        let searchNavigationController = UINavigationController(rootViewController: searchContainer)
        return searchNavigationController
    }
}
