import Foundation

struct LifecycleStubs: Codable {
    let events: [LifecycleStubsEvents]?

    enum CodingKeys: String, CodingKey {
        case events = "events"
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        events = try values.decodeIfPresent([LifecycleStubsEvents].self, forKey: .events)
    }

}
