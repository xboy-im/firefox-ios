/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import XCGLogger
import Shared

private let log = Logger.syncLogger

// A protocol for information about a particular table. This is used as a type to be stored by TableTable.
protocol TableInfo {
    var name: NSString { get }
    var version: Int { get }
}

// A wrapper class for table info coming from the TableTable. This should ever only be used internally.
class TableInfoWrapper: TableInfo {
    let name: NSString
    let version: Int
    init(name: String, version: Int) {
        self.name = name as NSString
        self.version = version
    }
}

/**
 * Something that knows how to construct part of a database.
 */
protocol SectionCreator: TableInfo {
    func create(_ db: SQLiteDBConnection) -> Bool
}

protocol SectionUpdater: TableInfo {
    func updateTable(_ db: SQLiteDBConnection, from: Int) -> Bool
}

/*
 * This should really be called "Section" or something like that.
 */
protocol Table: SectionCreator, SectionUpdater {
    func exists(_ db: SQLiteDBConnection) -> Bool
    func drop(_ db: SQLiteDBConnection) -> Bool
}

/**
 * A table in our database. Note this doesn't have to be a real table. It might be backed by a join
 * or something else interesting.
 */
protocol BaseTable: Table {
    associatedtype DataType
    func insert(_ db: SQLiteDBConnection, item: DataType?, err: inout NSError?) -> Int?
    func update(_ db: SQLiteDBConnection, item: DataType?, err: inout NSError?) -> Int
    func delete(_ db: SQLiteDBConnection, item: DataType?, err: inout NSError?) -> Int
    func query(_ db: SQLiteDBConnection, options: QueryOptions?) -> Cursor<DataType>
}


public enum QuerySort {
    case none, lastVisit, frecency
}

open class QueryOptions {
    // A filter string to apploy to the query
    open var filter: Any? = nil

    // Allows for customizing how the filter is applied (i.e. only urls or urls and titles?)
    open var filterType: FilterType = .none

    // The way to sort the query
    open var sort: QuerySort = .none

    public init(filter: Any? = nil, filterType: FilterType = .none, sort: QuerySort = .none) {
        self.filter = filter
        self.filterType = filterType
        self.sort = sort
    }
}


public enum FilterType {
    case exactUrl
    case url
    case guid
    case id
    case none
}

let DBCouldNotOpenErrorCode = 200

enum TableResult {
    case exists             // The table already existed.
    case created            // The table was correctly created.
    case updated            // The table was updated to a new version.
    case failed             // Table creation failed.
}


class GenericTable<T>: BaseTable {
    typealias DataType = T

    // Implementors need override these methods
    var name: NSString { return "" }
    var version: Int { return 0 }
    var rows: String { return "" }
    var factory: ((SDRow) -> DataType)? {
        return nil
    }

    // These methods take an inout object to avoid some runtime crashes that seem to be due
    // to using generics. Yay Swift!
    func getInsertAndArgs(_ item: inout DataType) -> (sql: String, args: Args)? {
        return nil
    }

    func getUpdateAndArgs(_ item: inout DataType) -> (sql: String, args: Args)? {
        return nil
    }

    func getDeleteAndArgs(_ item: inout DataType?) -> (sql: String, args: Args)? {
        return nil
    }

    func getQueryAndArgs(_ options: QueryOptions?) -> (sql: String, args: Args)? {
        return nil
    }

    func create(_ db: SQLiteDBConnection) -> Bool {
        if let err = db.executeChange("CREATE TABLE IF NOT EXISTS \(name) (\(rows))") {
            log.error("Error creating \(self.name) - \(err)")
            return false
        }
        return true
    }

    func updateTable(_ db: SQLiteDBConnection, from: Int) -> Bool {
        let to = self.version
        log.debug("Update table \(self.name) from \(from) to \(to)")
        return false
    }

    func exists(_ db: SQLiteDBConnection) -> Bool {
        let res = db.executeQuery("SELECT name FROM sqlite_master WHERE type = 'table' AND name=?", factory: StringFactory, withArgs: [name])
        return res.count > 0
    }

    func drop(_ db: SQLiteDBConnection) -> Bool {
        let sqlStr = "DROP TABLE IF EXISTS \(name)"
        let args =  Args()
        let err = db.executeChange(sqlStr, withArgs: args)
        if err != nil {
            log.error("Error dropping \(self.name): \(err)")
        }
        return err == nil
    }

    /**
     * Returns nil or the last inserted row ID.
     * err will be nil if there was no error (e.g., INSERT OR IGNORE).
     */
    func insert(_ db: SQLiteDBConnection, item: DataType?, err: inout NSError?) -> Int? {
        if var site = item {
            if let (query, args) = getInsertAndArgs(&site) {
                let previous = db.lastInsertedRowID
                if let error = db.executeChange(query, withArgs: args) {
                    err = error
                    return nil
                }

                let now = db.lastInsertedRowID
                if previous == now {
                    log.debug("INSERT did not change last inserted row ID.")
                    return nil
                }
                return now
            }
        }

        err = NSError(domain: "mozilla.org", code: 0, userInfo: [
            NSLocalizedDescriptionKey: "Tried to save something that isn't a site"
        ])
        return -1
    }

    func update(_ db: SQLiteDBConnection, item: DataType?, err: inout NSError?) -> Int {
        if var item = item {
            if let (query, args) = getUpdateAndArgs(&item) {
                if let error = db.executeChange(query, withArgs: args) {
                    log.error(error.description)
                    err = error
                    return 0
                }

                return db.numberOfRowsModified
            }
        }

        err = NSError(domain: "mozilla.org", code: 0, userInfo: [
            NSLocalizedDescriptionKey: "Tried to save something that isn't a site"
            ])
        return 0
    }

    func delete(_ db: SQLiteDBConnection, item: DataType?, err: inout NSError?) -> Int {
        if var item: DataType? = item {
            if let (query, args) = getDeleteAndArgs(&item) {
                if let error = db.executeChange(query, withArgs: args) {
                    print(error.description)
                    err = error
                    return 0
                }

                return db.numberOfRowsModified
            }
        }
        return 0
    }

    func query(_ db: SQLiteDBConnection, options: QueryOptions?) -> Cursor<DataType> {
        if let (query, args) = getQueryAndArgs(options) {
            if let factory = self.factory {
                let c =  db.executeQuery(query, factory: factory, withArgs: args)
                return c
            }
        }
        return Cursor(status: CursorStatus.failure, msg: "Invalid query: \(options?.filter)")
    }
}
