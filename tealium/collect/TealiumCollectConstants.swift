//
//  TealiumCollectConstants.swift
//  SegueCatalog
//
//  Created by Jason Koo on 11/16/16.
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

enum TealiumCollectKey {
    static let moduleName = "collect"
    static let encodedURLString = "encoded_url"
    static let overrideCollectUrl = "tealium_override_collect_url"
    static let payload = "payload"
    static let responseHeader = "response_headers"
    static let dispatchService = "dispatch_service"
}

enum TealiumCollectError : Error {
    case unknownResponseType
    case xErrorDetected
    case non200Response
    case unknownIssueWithSend
}
