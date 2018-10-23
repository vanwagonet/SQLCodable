import Foundation

public enum SQLOrder {
    case atoz(CodingKey)
    case ztoa(CodingKey)

    func clause() -> String {
        switch self {
        case .atoz(let key): return "\(id(key)) ASC"
        case .ztoa(let key): return "\(id(key)) DESC"
        }
    }
}
