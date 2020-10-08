import Foundation

struct LifecycleStubsExpected: Codable {
    let lifecycle_dayofweek_local: Int?
    let lifecycle_dayssincelastwake: Int?
    let lifecycle_dayssincelaunch: Int?
    let lifecycle_firstlaunchdate: String?
    let lifecycle_firstlaunchdate_MMDDYYYY: String?
    let lifecycle_hourofday_local: Int?
    let lifecycle_isfirstlaunch: String?
    let lifecycle_isfirstwakemonth: String?
    let lifecycle_isfirstwaketoday: String?
    let lifecycle_lastlaunchdate: String?
    let lifecycle_lastwakedate: String?
    let lifecycle_launchcount: Int?
    let lifecycle_priorsecondsawake: Int?
    let lifecycle_sleepcount: Int?
    let lifecycle_totalcrashcount: Int?
    let lifecycle_totallaunchcount: Int?
    let lifecycle_totalsecondsawake: Int?
    let lifecycle_totalsleepcount: Int?
    let lifecycle_totalwakecount: Int?
    let lifecycle_type: String?
    let lifecycle_wakecount: Int?

    enum CodingKeys: String, CodingKey {

        case lifecycle_dayofweek_local = "lifecycle_dayofweek_local"
        case lifecycle_dayssincelastwake = "lifecycle_dayssincelastwake"
        case lifecycle_dayssincelaunch = "lifecycle_dayssincelaunch"
        case lifecycle_firstlaunchdate = "lifecycle_firstlaunchdate"
        case lifecycle_firstlaunchdate_MMDDYYYY = "lifecycle_firstlaunchdate_MMDDYYYY"
        case lifecycle_hourofday_local = "lifecycle_hourofday_local"
        case lifecycle_isfirstlaunch = "lifecycle_isfirstlaunch"
        case lifecycle_isfirstwakemonth = "lifecycle_isfirstwakemonth"
        case lifecycle_isfirstwaketoday = "lifecycle_isfirstwaketoday"
        case lifecycle_lastlaunchdate = "lifecycle_lastlaunchdate"
        case lifecycle_lastwakedate = "lifecycle_lastwakedate"
        case lifecycle_launchcount = "lifecycle_launchcount"
        case lifecycle_priorsecondsawake = "lifecycle_priorsecondsawake"
        case lifecycle_sleepcount = "lifecycle_sleepcount"
        case lifecycle_totalcrashcount = "lifecycle_totalcrashcount"
        case lifecycle_totallaunchcount = "lifecycle_totallaunchcount"
        case lifecycle_totalsecondsawake = "lifecycle_totalsecondsawake"
        case lifecycle_totalsleepcount = "lifecycle_totalsleepcount"
        case lifecycle_totalwakecount = "lifecycle_totalwakecount"
        case lifecycle_type = "lifecycle_type"
        case lifecycle_wakecount = "lifecycle_wakecount"
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        lifecycle_dayofweek_local = try values.decodeIfPresent(Int.self, forKey: .lifecycle_dayofweek_local)
        lifecycle_dayssincelastwake = try values.decodeIfPresent(Int.self, forKey: .lifecycle_dayssincelastwake)
        lifecycle_dayssincelaunch = try values.decodeIfPresent(Int.self, forKey: .lifecycle_dayssincelaunch)
        lifecycle_firstlaunchdate = try values.decodeIfPresent(String.self, forKey: .lifecycle_firstlaunchdate)
        lifecycle_firstlaunchdate_MMDDYYYY = try values.decodeIfPresent(String.self, forKey: .lifecycle_firstlaunchdate_MMDDYYYY)
        lifecycle_hourofday_local = try values.decodeIfPresent(Int.self, forKey: .lifecycle_hourofday_local)
        lifecycle_isfirstlaunch = try values.decodeIfPresent(String.self, forKey: .lifecycle_isfirstlaunch)
        lifecycle_isfirstwakemonth = try values.decodeIfPresent(String.self, forKey: .lifecycle_isfirstwakemonth)
        lifecycle_isfirstwaketoday = try values.decodeIfPresent(String.self, forKey: .lifecycle_isfirstwaketoday)
        lifecycle_lastlaunchdate = try values.decodeIfPresent(String.self, forKey: .lifecycle_lastlaunchdate)
        lifecycle_lastwakedate = try values.decodeIfPresent(String.self, forKey: .lifecycle_lastwakedate)
        lifecycle_launchcount = try values.decodeIfPresent(Int.self, forKey: .lifecycle_launchcount)
        lifecycle_priorsecondsawake = try values.decodeIfPresent(Int.self, forKey: .lifecycle_priorsecondsawake)
        lifecycle_sleepcount = try values.decodeIfPresent(Int.self, forKey: .lifecycle_sleepcount)
        lifecycle_totalcrashcount = try values.decodeIfPresent(Int.self, forKey: .lifecycle_totalcrashcount)
        lifecycle_totallaunchcount = try values.decodeIfPresent(Int.self, forKey: .lifecycle_totallaunchcount)
        lifecycle_totalsecondsawake = try values.decodeIfPresent(Int.self, forKey: .lifecycle_totalsecondsawake)
        lifecycle_totalsleepcount = try values.decodeIfPresent(Int.self, forKey: .lifecycle_totalsleepcount)
        lifecycle_totalwakecount = try values.decodeIfPresent(Int.self, forKey: .lifecycle_totalwakecount)
        lifecycle_type = try values.decodeIfPresent(String.self, forKey: .lifecycle_type)
        lifecycle_wakecount = try values.decodeIfPresent(Int.self, forKey: .lifecycle_wakecount)
    }

}
