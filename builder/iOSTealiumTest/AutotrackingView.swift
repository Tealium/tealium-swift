//
//  AutotrackingView.swift
//  iOSTealiumTest
//
//  Created by Christina Schell on 3/23/21.
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import SwiftUI
import TealiumSwiftUI
import TealiumAutotracking

struct AutotrackingView: View {
    
    @Environment(\.presentationMode) var presentationMode
    @State private var showAutotrackedViewControllerModal = false
    @State private var showAutotrackedTealiumTrackableModal = false
    
    @AutoTracked var viewName = "Autotracked View with Property Wrapper"
    
    // Options for blocklisting autotracked views:
    @AutoTracked var viewNameTwo = "BlockedViewName" // see blocklist.json
    @AutoTracked(false) var viewNameThree = "This autotracked view will not be tracked"
    
    var body: some View {
        VStack(spacing: 25) {
            
            Text("""
                This view was autotracked using the property wrapper @AutoTracked.

                The dataLayer should contain:
                {screen_title: \"Autotracked View with Property Wrapper\"}
                """)
                .multilineTextAlignment(.center)
                .padding(20)
                .foregroundColor(.tealBlue)
            
            TealiumTextButton(title: "TealiumTrackable") {
                self.showAutotrackedTealiumTrackableModal.toggle()
            }.sheet(isPresented: $showAutotrackedTealiumTrackableModal, content: {
                AutotrackingTealiumTrackableView()
            })
            
            TealiumTextButton(title: "ViewController") {
                self.showAutotrackedViewControllerModal.toggle()
            }.sheet(isPresented: $showAutotrackedViewControllerModal, content: {
                ViewControllerWrapper()
            })
            
            TealiumTextButton(title: "Back") {
                presentationMode.wrappedValue.dismiss()
            }
            
        }.onAppear {
            [viewName, viewNameTwo, viewNameThree].forEach { _ = $0 }
        }
        
    }
}

struct AutotrackingTealiumTrackableView: View {
    
    var body: some View {
        TealiumTrackable(viewName: "Hello World SwiftUI Screen") {
            Text("""
                This view was autotracked by using the SwiftUI view TealiumTrackable.

                The dataLayer should contain:
                {screen_title: \"Hello World SwiftUI Screen\"}
                """)
                .multilineTextAlignment(.center)
                .padding(20)
                .foregroundColor(.tealBlue)
        }
    }
}

struct AutotrackingView_Previews: PreviewProvider {
    static var previews: some View {
        AutotrackingView()
    }
}
