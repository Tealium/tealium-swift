import Foundation

struct LifecycleStubsEvents: Codable {
    let app_version: String?
    let event_number: Int?
    let expected_data: LifecycleStubsExpected?
    let timestamp: String?
    let timestamp_unix: String?
    let timezone: String?

    enum CodingKeys: String, CodingKey {

        case app_version = "app_version"
        case event_number = "event_number"
        case expected_data = "expected_data"
        case timestamp = "timestamp"
        case timestamp_unix = "timestamp_unix"
        case timezone = "timezone"
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        app_version = try values.decodeIfPresent(String.self, forKey: .app_version)
        event_number = try values.decodeIfPresent(Int.self, forKey: .event_number)
        expected_data = try values.decodeIfPresent(LifecycleStubsExpected.self, forKey: .expected_data)
        timestamp = try values.decodeIfPresent(String.self, forKey: .timestamp)
        timestamp_unix = try values.decodeIfPresent(String.self, forKey: .timestamp_unix)
        timezone = try values.decodeIfPresent(String.self, forKey: .timezone)
    }

}
