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

public protocol QueryParameterProvider: AnyObject {
    func provideParameters(completion: @escaping ([URLQueryItem]) -> Void)
}

class TagManagementUrlBuilder {
    let modules: [TealiumModule]?
    let baseURL: URL?
    init(modules: [TealiumModule]?, baseURL: URL?) {
        self.modules = modules
        self.baseURL = baseURL
    }

    func createUrl(completion: @escaping (URL?) -> Void) {
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
        group.notify(queue: TealiumQueues.backgroundSerialQueue) {
            completion(baseURL.appendingQueryItems(params))
        }
    }
}
#endif
