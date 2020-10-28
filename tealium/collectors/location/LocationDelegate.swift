//
//  LocationDelegate.swift
//  tealium-swift
//
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

#if os(iOS)
import Foundation

protocol LocationDelegate: class {
    func didEnterGeofence(_ data: [String: Any])
    func didExitGeofence(_ data: [String: Any])
}
#endif
