//
//  QueryParameterProvider.swift
//  TealiumCore
//
//  Created by Enrico Zannini on 10/08/22.
//  Copyright © 2022 Tealium, Inc. All rights reserved.
//

import Foundation

public protocol QueryParameterProvider: AnyObject {
    func provideParameters(completion: @escaping ([URLQueryItem]) -> Void)
}
