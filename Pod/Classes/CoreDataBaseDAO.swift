//
//  CoreDataBaseDAO.swift
//  ADGCoreDataKit
//
//  Created by Alejandro Diego Garin

// The MIT License (MIT)
//
// Copyright (c) 2015 Alejandro Garin @alejandrogarin
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Foundation
import CoreData

public class CoreDataBaseDAO: NSObject {
    
    internal let coreDataContext: CoreDataContext
    
    /*!
     * @brief if this flag is true every core data operation will be saved to the store. If you are not autocommitting you should
     * call commit() after adding/updating/removing data
     */
    public var autocommit = true
    
    internal var entityName: String
    
    public init(usingContext context: CoreDataContext, forEntityName entityName: String) {
        self.coreDataContext = context
        self.entityName = entityName
    }
    
    public func count(withPredicate predicate: Predicate? = nil) throws -> Int {
        return try self.coreDataContext.count(rowsForEntityName: entityName, predicate: predicate)
    }
    
    public func commit() throws {
        try coreDataContext.save()
    }
    
    public func delete(byId objectId: String) throws {
        try self.coreDataContext.delete(byId: objectId)
        try self.saveIfAutocommit()
    }
    
    public func delete(managedObject: NSManagedObject) throws {
        self.coreDataContext.delete(managedObject: managedObject)
        try self.saveIfAutocommit()
    }
    
    public func fetchManagedObject(byId objectId: String) throws -> NSManagedObject {
        let managedObjectId = try self.coreDataContext.managedObjectIdFromStringObjectId(objectId)
        return try self.fetchManagedObject(byManagedObjectId: managedObjectId)
    }
    
    public func fetchManagedObject(byManagedObjectId moId: NSManagedObjectID) throws -> NSManagedObject {
        return try self.coreDataContext.fetch(byManagedObjectId: moId)
    }
    
    public func performBlock(_ block: () -> Void) {
        coreDataContext.performBlock(block)
    }
    
    public func rollback() {
        coreDataContext.rollback()
    }
    
    public func reset() {
        coreDataContext.reset()
    }
    
    public func truncate() throws {
        let objects: [AnyObject] = try self.coreDataContext.find(entityName: entityName)
        for mo in objects {
            if let mo = mo as? NSManagedObject {
                self.coreDataContext.delete(managedObject: mo)
            }
        }
        try self.saveIfAutocommit()
    }
    
    public func update(managedObject mo: NSManagedObject, map: [String:AnyObject?]) throws {
        for key in map.keys {
            let maybeValue: AnyObject? = map[key]!
            mo.setValue(maybeValue, forKey: key)
        }
        try self.saveIfAutocommit()
    }
    
    //MARK: - Internal API
    
    internal func saveIfAutocommit() throws {
        if autocommit {
            try coreDataContext.save()
        }
    }
}
