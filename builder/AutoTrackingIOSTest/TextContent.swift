//
//  TextContent.swift
//  AutoTracking Test
//
//  Created by Enrico Zannini on 13/09/21.
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import SwiftUI


class TrackViewModel: ObservableObject {
    @Published var text = ""
    init() {
        TealiumHelper.shared.onWillTrack.subscribe { dict in
            if dict["tealium_event_type"] as! String == "view" && dict["autotracked"] as! String == "true" {
                DispatchQueue.main.async {
                    self.text += dict["tealium_event"] as! String + "\n"
                }
            }
        }
    }
}

struct TextContent: View {
    
    @ObservedObject var model: TrackViewModel
    
    var body: some View {
        Group {
            Spacer()
            Text("AutoTracked Views:").bold()
            Text(model.text)
                .font(Font.system(size: 10))
        }
    }
}
