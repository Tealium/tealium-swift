//
//  DeviceNamesLookup.swift
//  tealium-swift
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//
// Note: Swift Package Manager currently has no support for resource files, so this was converted from JSON to avoid having to bundle a JSON file in the swift package.

import Foundation

// swiftlint:disable file_length
// swiftlint:disable type_body_length
struct DeviceNamesLookup {
    static let data: [String: Any] = [
        "iPhone4,1": [
            "model_name": "iPhone 4S",
            "model_variant": ""
        ],
        "iPhone5,1": [
            "model_name": "iPhone 5",
            "model_variant": "model A1428, AT&T/Canada"
        ],
        "iPhone5,2": [
            "model_name": "iPhone 5",
            "model_variant": "A1429, except AT&T/Canada)"
        ],
        "iPhone5,3": [
            "model_name": "iPhone 5c",
            "model_variant": "(model A1456, A1532 | GSM)"
        ],
        "iPhone5,4": [
            "model_name": "iPhone 5c",
            "model_variant": "(model A1507, A1516, A1526 (China), A1529 | Global)"
        ],
        "iPhone6,1": [
            "model_name": "iPhone 5s",
            "model_variant": "(model A1433, A1533 | GSM)"
        ],
        "iPhone6,2": [
            "model_name": "iPhone 5s",
            "model_variant": "(model A1457, A1518, A1528 (China), A1530 | Global)"
        ],
        "iPhone7,1": [
            "model_name": "iPhone 6 Plus",
            "model_variant": ""
        ],
        "iPhone7,2": [
            "model_name": "iPhone 6",
            "model_variant": ""
        ],
        "iPhone8,1": [
            "model_name": "iPhone 6S",
            "model_variant": ""
        ],
        "iPhone8,2": [
            "model_name": "iPhone 6S Plus",
            "model_variant": ""
        ],
        "iPhone8,4": [
            "model_name": "iPhone SE",
            "model_variant": "CDMA"
        ],
        "iPhone9,1": [
            "model_name": "iPhone 7",
            "model_variant": "CDMA"
        ],
        "iPhone9,2": [
            "model_name": "iPhone 7 Plus",
            "model_variant": "CDMA"
        ],
        "iPhone9,3": [
            "model_name": "iPhone 7",
            "model_variant": "GSM"
        ],
        "iPhone9,4": [
            "model_name": "iPhone 7 Plus",
            "model_variant": "GSM"
        ],
        "iPhone10,1": [
            "model_name": "iPhone 8",
            "model_variant": ""
        ],
        "iPhone10,2": [
            "model_name": "iPhone 8 Plus",
            "model_variant": ""
        ],
        "iPhone10,3": [
            "model_name": "iPhone X",
            "model_variant": ""
        ],
        "iPhone10,4": [
            "model_name": "iPhone 8",
            "model_variant": "GSM"
        ],
        "iPhone10,5": [
            "model_name": "iPhone 8 Plus",
            "model_variant": "GSM"
        ],
        "iPhone10,6": [
            "model_name": "iPhone X",
            "model_variant": "GSM"
        ],
        "iPhone11,2": [
            "model_name": "iPhone XS",
            "model_variant": ""
        ],
        "iPhone11,4": [
            "model_name": "iPhone XS Max",
            "model_variant": ""
        ],
        "iPhone11,6": [
            "model_name": "iPhone XS Max China",
            "model_variant": ""
        ],
        "iPhone11,8": [
            "model_name": "iPhone XR",
            "model_variant": ""
        ],
        "iPhone12,1": [
            "model_name": "iPhone 11",
            "model_variant": ""
        ],
        "iPhone12,3": [
            "model_name": "iPhone 11 Pro",
            "model_variant": ""
        ],
        "iPhone12,5": [
            "model_name": "iPhone 11 Pro Max",
            "model_variant": ""
        ],
        "iPhone12,8": [
            "model_name": "iPhone SE 2nd Generation",
            "model_variant": ""
        ],
        "iPod5,1": [
            "model_name": "iPod Touch 5th Generation",
            "model_variant": ""
        ],
        "iPod7,1": [
            "model_name": "iPod Touch 6th Generation",
            "model_variant": ""
        ],
        "iPod9,1": [
            "model_name": "iPod Touch 7th Generation",
            "model_variant": ""
        ],
        "iPad2,1": [
            "model_name": "iPad 2",
            "model_variant": "Wifi (model A1432)"
        ],
        "iPad2,2": [
            "model_name": "iPad 2",
            "model_variant": "GSM (model A1396)"
        ],
        "iPad2,3": [
            "model_name": "iPad 2",
            "model_variant": "3G (model A1397)"
        ],
        "iPad2,4": [
            "model_name": "iPad 2",
            "model_variant": "Wifi (model A1395)"
        ],
        "iPad2,5": [
            "model_name": "iPad Mini",
            "model_variant": "Wifi (model A1432)"
        ],
        "iPad2,6": [
            "model_name": "iPad Mini",
            "model_variant": "Wifi + Cellular (model  A1454)"
        ],
        "iPad2,7": [
            "model_name": "iPad Mini",
            "model_variant": "Wifi + Cellular (model  A1455)"
        ],
        "iPad3,1": [
            "model_name": "iPad 3",
            "model_variant": "Wifi (model A1416)"
        ],
        "iPad3,2": [
            "model_name": "iPad 3",
            "model_variant": "Wifi + Cellular (model  A1403)"
        ],
        "iPad3,3": [
            "model_name": "iPad 3",
            "model_variant": "Wifi + Cellular (model  A1430)"
        ],
        "iPad3,4": [
            "model_name": "iPad 4",
            "model_variant": "Wifi (model A1458)"
        ],
        "iPad3,5": [
            "model_name": "iPad 4",
            "model_variant": "Wifi + Cellular (model  A1459)"
        ],
        "iPad3,6": [
            "model_name": "iPad 4",
            "model_variant": "Wifi + Cellular (model  A1460)"
        ],
        "iPad4,1": [
            "model_name": "iPad Air",
            "model_variant": "Wifi (model A1474)"
        ],
        "iPad4,2": [
            "model_name": "iPad Air",
            "model_variant": "Wifi + Cellular (model A1475)"
        ],
        "iPad4,3": [
            "model_name": "iPad Air",
            "model_variant": "Wifi + Cellular (model A1476)"
        ],
        "iPad4,4": [
            "model_name": "iPad Mini 2",
            "model_variant": "Wifi (model A1489)"
        ],
        "iPad4,5": [
            "model_name": "iPad Mini 2",
            "model_variant": "Wifi + Cellular (model A1490)"
        ],
        "iPad4,6": [
            "model_name": "iPad Mini 2",
            "model_variant": "Wifi + Cellular (model A1491)"
        ],
        "iPad4,7": [
            "model_name": "iPad Mini 3",
            "model_variant": "Wifi (model A1599)"
        ],
        "iPad4,8": [
            "model_name": "iPad Mini 3",
            "model_variant": "Wifi + Cellular (model A1600)"
        ],
        "iPad4,9": [
            "model_name": "iPad Mini 3",
            "model_variant": "Wifi + Cellular (model A1601)"
        ],
        "iPad5,1": [
            "model_name": "iPad Mini 4",
            "model_variant": "Wifi (model A1538)"
        ],
        "iPad5,2": [
            "model_name": "iPad Mini 4",
            "model_variant": "Wifi + Cellular (model A1550)"
        ],
        "iPad5,3": [
            "model_name": "iPad Air 2",
            "model_variant": "Wifi (model A1566)"
        ],
        "iPad5,4": [
            "model_name": "iPad Air 2",
            "model_variant": "Wifi + Cellular (model A1567)"
        ],
        "iPad6,3": [
            "model_name": "iPad Pro 12.9\"",
            "model_variant": "Wifi (model A1673)"
        ],
        "iPad6,4": [
            "model_name": "iPad Pro 12.9\"",
            "model_variant": "Wifi + Cellular (model A1674, A1675)"
        ],
        "iPad6,7": [
            "model_name": "iPad Pro 9.7\"",
            "model_variant": "Wifi (model A1584)"
        ],
        "iPad6,8": [
            "model_name": "iPad Pro 9.7\"",
            "model_variant": "Wifi + Cellular (model A1652)"
        ],
        "iPad6,11": [
            "model_name": "iPad 5th Gen 9.7\"",
            "model_variant": "WiFi (model A1822)"
        ],
        "iPad6,12": [
            "model_name": "iPad 5th Gen 9.7\"",
            "model_variant": "Wifi + Cellular (model A1823)"
        ],
        "iPad7,1": [
            "model_name": "iPad Pro 12.9\" 2nd Gen",
            "model_variant": "WiFi (model A1670)"
        ],
        "iPad7,2": [
            "model_name": "iPad Pro 12.9\" 2nd Gen",
            "model_variant": "WiFi + Cellular (model A1671)"
        ],
        "iPad7,3": [
            "model_name": "iPad Pro 10.5\"",
            "model_variant": "WiFi (model A1701)"
        ],
        "iPad7,4": [
            "model_name": "iPad Pro 10.5\"",
            "model_variant": "WiFi + Cellular (model A1709)"
        ],
        "iPad7,5": [
            "model_name": "iPad 6th Gen 9.7\"",
            "model_variant": "WiFi (model A1893)"
        ],
        "iPad7,6": [
            "model_name": "iPad 6th Gen",
            "model_variant": "WiFi + Cellular (model A1954)"
        ],
        "iPad7,11": [
            "model_name": "iPad 7th Gen 10.2\"",
            "model_variant": "WiFi (model A2197)"
        ],
        "iPad7,12": [
            "model_name": "iPad 7th Gen 10.2\"",
            "model_variant": "WiFi + Cellular (models A2200, A2198)"
        ],
        "iPad8,1": [
            "model_name": "iPad Pro 3rd Gen 11\"",
            "model_variant": "WiFi"
        ],
        "iPad8,2": [
            "model_name": "iPad Pro 3rd Gen 11\"",
            "model_variant": "WiFi 1TB"
        ],
        "iPad8,3": [
            "model_name": "iPad Pro 3rd Gen 11\"",
            "model_variant": "WiFi + Cellular"
        ],
        "iPad8,4": [
            "model_name": "iPad Pro 3rd Gen 11\"",
            "model_variant": "WiFi + Cellular 1TB"
        ],
        "iPad8,5": [
            "model_name": "iPad Pro 3rd Gen 12.9\"",
            "model_variant": "WiFi"
        ],
        "iPad8,6": [
            "model_name": "iPad Pro 3rd Gen 12.9\"",
            "model_variant": "WiFi 1TB"
        ],
        "iPad8,7": [
            "model_name": "iPad Pro 3rd Gen 12.9\"",
            "model_variant": "WiFi + Cellular"
        ],
        "iPad8,8": [
            "model_name": "iPad Pro 3rd Gen 12.9\"",
            "model_variant": "WiFi + Cellular 1TB"
        ],
        "iPad11,1": [
            "model_name": "iPad Mini 5th Gen",
            "model_variant": "WiFi"
        ],
        "iPad11,2": [
            "model_name": "iPad Mini 5th Gen",
            "model_variant": "WiFi + Cellular"
        ],
        "iPad11,3": [
            "model_name": "iPad Air 3rd Gen",
            "model_variant": "WiFi"
        ],
        "iPad11,4": [
            "model_name": "iPad Air 3rd Gen",
            "model_variant": "WiFi + Cellular"
        ],
        "AppleTV2,1": [
            "model_name": "Apple TV 2nd Generation",
            "model_variant": ""
        ],
        "AppleTV3,1": [
            "model_name": "Apple TV 3rd Generation",
            "model_variant": ""
        ],
        "AppleTV3,2": [
            "model_name": "Apple TV 3rd Generation",
            "model_variant": ""
        ],
        "AppleTV5,3": [
            "model_name": "Apple TV 4th Generation",
            "model_variant": ""
        ],
        "AppleTV6,2": [
            "model_name": "Apple TV 4K",
            "model_variant": ""
        ],
        "Watch1,1": [
            "model_name": "Apple Watch 1st Generation",
            "model_variant": "38mm"
        ],
        "Watch1,2": [
            "model_name": "Apple Watch 1st Generation",
            "model_variant": "42mm"
        ],
        "Watch2,3": [
            "model_name": "Apple Watch Series 2",
            "model_variant": "38mm"
        ],
        "Watch2,4": [
            "model_name": "Apple Watch Series 2",
            "model_variant": "42mm"
        ],
        "Watch2,6": [
            "model_name": "Apple Watch Series 1",
            "model_variant": "38mm"
        ],
        "Watch2,7": [
            "model_name": "Apple Watch Series 1",
            "model_variant": "42mm"
        ],
        "Watch3,1": [
            "model_name": "Apple Watch Series 3",
            "model_variant": "38mm Cellular"
        ],
        "Watch3,2": [
            "model_name": "Apple Watch Series 3",
            "model_variant": "42mm Cellular"
        ],
        "Watch3,3": [
            "model_name": "Apple Watch Series 3",
            "model_variant": "38mm"
        ],
        "Watch3,4": [
            "model_name": "Apple Watch Series 3",
            "model_variant": "42mm"
        ],
        "Watch4,1": [
            "model_name": "Apple Watch Series 4",
            "model_variant": "40mm"
        ],
        "Watch4,2": [
            "model_name": "Apple Watch Series 4",
            "model_variant": "44mm"
        ],
        "Watch4,3": [
            "model_name": "Apple Watch Series 4",
            "model_variant": "40mm Cellular"
        ],
        "Watch4,4": [
            "model_name": "Apple Watch Series 4",
            "model_variant": "44mm Cellular"
        ],
        "Watch5,1": [
            "model_name": "Apple Watch Series 5",
            "model_variant": "40mm"
        ],
        "Watch5,2": [
            "model_name": "Apple Watch Series 5",
            "model_variant": "44mm"
        ],
        "Watch5,3": [
            "model_name": "Apple Watch Series 5",
            "model_variant": "40mm Cellular"
        ],
        "Watch5,4": [
            "model_name": "Apple Watch Series 5",
            "model_variant": "44mm Cellular"
        ],
        "i386": [
            "model_name": "Simulator",
            "model_variant": "32-bit"
        ],
        "x86_64": [
            "model_name": "Simulator",
            "model_variant": "64-bit"
        ]
    ]

}
// swiftlint:enable type_body_length
// swiftlint:enable file_length
