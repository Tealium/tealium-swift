/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The view controllers used in the Detail storyboard.
*/

import UIKit

class NestedViewController: UIViewController {
   
    override func viewDidLoad() {
        super.viewDidLoad()
        
        #if AUTOTRACKING
        #else
//            let extraData : [String:Any] = ["autotracked" : "false" as Any]
//            
//            TealiumHelper.sharedInstance().track(title: "NestedViewController:viewDidLoad",
//                                             data: extraData)
        
        #endif
        
    }
    
    @IBAction func unwindToNested(_ segue: UIStoryboardSegue) {
        /* 
            Empty. Exists solely so that "unwind to nested" segues can find instances
            of this class.
        
            Notably, if an instance of this class is currently showing a Current
            Context presentation, unwinding to that instance via this action will
            only dismiss that presentation if the unwind source is contained within 
            the presentation.
        
            This is why the "Dismiss via Unwind" button in this app's storyboard
            will cause the containing presentation to be dismissed, while the "Unwind 
            to Nested" button will not.
        */
    }
}

class OuterViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        #if AUTOTRACKING
        #else
//            let extraData : [String:Any] = ["autotracked" : "false" as Any]
//            
//            TealiumHelper.sharedInstance().track(title: "DetailViewController:viewDidLoad",
//                                             data: extraData)
        #endif
    }
    @IBAction func unwindToOuter(_ segue: UIStoryboardSegue) {
        /*
            Empty. Exists solely so that "unwind to outer" segues can find 
            instances of this class.
        */
    }
    
    @IBAction func CrashTest(_ sender: Any) {
//        TealiumHelper.sharedInstance().crash()
    }
}

class NonAnimatingSegue: UIStoryboardSegue {
    override func perform() {
        UIView.performWithoutAnimation {
            super.perform()
        }
    }
}

class CustomAnimationPresentationSegue: UIStoryboardSegue, UIViewControllerTransitioningDelegate, UIViewControllerAnimatedTransitioning {
    
    override func perform() {
        /*
            Because this class is used for a Present Modally segue, UIKit will 
            maintain a strong reference to this segue object for the duration of
            the presentation. That way, this segue object will still be around to
            provide an animation controller for the eventual dismissal, as well 
            as for the initial presentation.
        */
        destination.transitioningDelegate = self

        super.perform()
    }
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return self
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return self
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.5
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView

        let toView = transitionContext.view(forKey: UITransitionContextViewKey.to)!
        
        if transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to) == destination {
            // Presenting.
            UIView.performWithoutAnimation {
                toView.alpha = 0
                containerView.addSubview(toView)
            }
            
            let transitionContextDuration = transitionDuration(using: transitionContext)
            
            UIView.animate(withDuration: transitionContextDuration, animations: {
                toView.alpha = 1
            }, completion: { success in
                transitionContext.completeTransition(success)
            })
        }
        else {
            // Dismissing.
            let fromView = transitionContext.view(forKey: UITransitionContextViewKey.from)!

            UIView.performWithoutAnimation {
                containerView.insertSubview(toView, belowSubview: fromView)
            }
            
            let transitionContextDuration = transitionDuration(using: transitionContext)
            
            UIView.animate(withDuration: transitionContextDuration, animations: {
                fromView.alpha = 0
            }, completion: { success in
                transitionContext.completeTransition(success)
            })
        }
    }
}
