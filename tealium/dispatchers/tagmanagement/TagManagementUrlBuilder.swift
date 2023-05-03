//
//  TagManagementUrlBuilder.swift
//  TealiumTagManagement
//
//  Created by Enrico Zannini on 02/08/22.
//  Copyright © 2022 Tealium, Inc. All rights reserved.
//
#if os(iOS)
import Foundation
#if tagmanagement
import TealiumCore
#endif

class TagManagementUrlBuilder {
    let modules: [TealiumModule]?
    let baseURL: URL?
    init(modules: [TealiumModule]?, baseURL: URL?) {
        self.modules = modules
        self.baseURL = baseURL
    }

    func createUrl(timeout: TimeInterval = 5.0, completion: @escaping (URL?) -> Void) {
        guard let providers = modules?.compactMap({ $0 as? QueryParameterProvider }),
                !providers.isEmpty,
              let baseURL = self.baseURL else {
            completion(baseURL)
            return
        }
        var params = [URLQueryItem]()
        let group = DispatchGroup()
        for provider in providers {
            group.enter()
            provider.provideParameters { result in
                TealiumQueues.backgroundSerialQueue.async {
                    params.append(contentsOf: result)
                    group.leave()
                }
            }
        }
        group.tealiumNotify(queue: TealiumQueues.backgroundSerialQueue, timeout: timeout) {
            completion(baseURL.appendingQueryItems(params))
        }
    }
}
#endif
