import Foundation

public enum SQLOperator: String {
    case equalTo = "="
    case lessOrEqualTo = "<="
    case lessThan = "<"
    case like = "LIKE"
    case moreOrEqualTo = ">="
    case moreThan = ">"
    case not = "<>"
}

public indirect enum SQLWhere {
    case and(SQLWhere, SQLWhere)
    case `in`(CodingKey, [SQLParameter])
    case not(SQLWhere)
    case null(CodingKey)
    case or(SQLWhere, SQLWhere)
    case `is`(CodingKey, SQLOperator, SQLParameter)

    public func and(_ other: SQLWhere) -> SQLWhere { return .and(self, other) }
    public func or(_ other: SQLWhere) -> SQLWhere { return .or(self, other) }

    func clause() -> String {
        switch self {
        case .and(let a, let b):
            return "\(a.clause()) AND \(b.clause())"
        case .in(let key, let params):
            return "\(id(key)) IN (\(params.map { _ in "?" }))"
        case .not(let a):
            return "NOT \(a.clause())"
        case .null(let key):
            return "\(id(key)) IS NULL"
        case .or(let a, let b):
            return "\(a.clause()) OR \(b.clause())"
        case .is(let key, let op, _):
            return "\(id(key)) \(op.rawValue) ?"
        }
    }

    func params() -> [SQLParameter] {
        switch self {
        case .and(let a, let b):
            return a.params() + b.params()
        case .in(_, let params):
            return params
        case .not(let a):
            return a.params()
        case .null(_):
            return []
        case .or(let a, let b):
            return a.params() + b.params()
        case .is(_, _, let param):
            return [ param ]
        }
    }
}
