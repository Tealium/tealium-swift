//
// Copyright (c) 2018 Tealium, Inc. All rights reserved.
//

import Foundation

extension Date {

    func daysFrom(earlierDate: Date) -> Int {
        // NOTE: This is not entirely accurate as it does not adjust for Daylight Savings -
        //  and is off by one day after about 172
        //  days have elapsed
        let components = Calendar.autoupdatingCurrent.dateComponents([.second], from: earlierDate, to: self)
        let days = components.second! / (60 * 60 * 24)
        return Int(days) - 1
    }

}

extension String {
    func toDate(with format: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(identifier: "America/Los_Angeles")
        dateFormatter.locale = Locale(identifier: "en_US")
        dateFormatter.calendar = Calendar(identifier: .gregorian)
        dateFormatter.dateFormat = format
        let date = dateFormatter.date(from: self)
        return date
    }
}
