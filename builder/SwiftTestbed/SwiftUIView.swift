//
//  SwiftUIView.swift
//  SwiftTestbed
//
//  Created by Craig Rouse on 29/10/2019.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import SwiftUI
import UIKit

struct SwiftUIView: View {
    @State var text: String = "Enter Trace ID"
    
    var body: some View {
        VStack(alignment: .center) {
                    Text("Swift Demo App")
                    Spacer()
                    Button(action: {
                        print("Track View")
                        TealiumHelper.shared.trackView(title: "iOS View", data: nil)
                    },
                       label: {
                        Text("Track View")
                    }).padding(.bottom)
                    
                    Button(action: {
                         print("Track Event")
                        TealiumHelper.shared.track(title: "iOS Event", data: nil)
                    },
                    label: {
                         Text("Track Event")
                    }).padding(.bottom)
            
                    TextField("Trace ID", text: $text) {
                        TealiumHelper.shared.joinTrace(self.text)
                    }.multilineTextAlignment(.center)
                    .border(Color.black)
                        .frame(width: 150.0, height: nil, alignment: .center)
                    .padding(.bottom)
            
                    Button(action: {
                        TealiumHelper.shared.leaveTrace()
                        self.text = "Enter Trace ID"
                    },
                    label: {
                         Text("Leave Trace")
                    }).padding(.bottom)
                
                    Spacer()
                    Spacer()
                    Spacer()
        }
    }
}

struct SwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        SwiftUIView()
    }
}
