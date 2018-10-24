import Foundation

enum SQLError: Error {
    // http://www.sqlite.org/c3ref/c_abort.html
    case sqliteError(Int32, String)

    case invalidColumns([String])
    case missingPlaceholder(Any.Type)
    case noPrimaryKey(Any.Type)
    case notRepresentable(String)
}
