//
//  CoreDataDAO.swift
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

public class CoreDataDAO<T: NSManagedObject> {
    
    private let coreDataContext: CoreDataContext
    
    /*!
    * @brief if this flag is true every core data operation will be saved to the store. If you are not autocommitting you should
    * call commit() after adding/updating/removing data
    */
    public var autocommit = true
    
    public var entityName:String {
        return self.guessEntityName()
    }
    
    public init(usingContext context: CoreDataContext) {
        self.coreDataContext = context
    }
    
    public func insert(map map: [String : AnyObject]) throws -> T {
        return try self.insert(entityName: entityName, map: map)
    }
    
    public func insert(entityName entityName: String, map: [String: AnyObject?]) throws -> T {
        let managedObject = self.coreDataContext.insertObjectForEntity(entityName)
        for key in map.keys {
            if let value = map[key] {
                managedObject.setValue(value, forKey: key)
            } else {
                managedObject.setValue(nil, forKey: key)
            }
        }
        try self.saveIfAutocommit()
        guard let managedEntity = managedObject as? T else {
            throw CoreDataKitError.CannotCastManagedObject
        }
        return managedEntity
    }
    
    public func update(objectId objectId: String, map: [String:AnyObject?]) throws -> T {
        let managedObject: T = try self.findObjectById(objectId: objectId)
        for key in map.keys {
            let maybeValue: AnyObject? = map[key]!
            (managedObject as NSManagedObject).setValue(maybeValue, forKey: key)
        }
        try self.saveIfAutocommit()
        return managedObject
    }
    
    public func update(managedObject mo: NSManagedObject, map: [String:AnyObject?]) throws {
        for key in map.keys {
            let maybeValue: AnyObject? = map[key]!
            mo.setValue(maybeValue, forKey: key)
        }
        try self.saveIfAutocommit()
    }

    private func findObjectsByEntity(entityName : String, sortKey: String?, ascending: Bool?, predicate: NSPredicate?, page: Int?, pageSize: Int?) throws -> [T] {
        let list: [AnyObject] = try self.coreDataContext.findObjectsByEntity(entityName, sortKey: sortKey, ascending: ascending, predicate: predicate, page: page, pageSize: pageSize)
        var newArray : [T] = []
        for anyObject in list {
            if let anyObject = anyObject as? T {
                newArray.append(anyObject)
            }
        }
        return newArray
    }
    
    public func countObjectsByEntity(entityName: String, predicate: NSPredicate?) throws -> Int {
        return try self.coreDataContext.countObjectsByEntity(entityName, predicate: predicate)
    }
    
    public func findObjectsByEntity(entityName: String) throws -> [T] {
        return try self.findObjectsByEntity(entityName, sortKey: nil, ascending: nil, predicate: nil, page: nil, pageSize: nil)
    }
    
    public func findObjectsByEntity(entityName: String, predicate: NSPredicate) throws -> [T] {
        return try self.findObjectsByEntity(entityName, sortKey: nil, ascending: nil, predicate: predicate, page: nil, pageSize: nil)
    }
    
    public func findObjectsByEntity(entityName: String, withSortKey sortKey: String) throws -> [T] {
        return try self.findObjectsByEntity(entityName, sortKey: sortKey, ascending: true, predicate: nil, page: nil, pageSize: nil)
    }
    
    public func findObjectsByEntity(entityName: String, withSortKey sortKey: String, predicate: NSPredicate) throws -> [T] {
        return try self.findObjectsByEntity(entityName, sortKey: sortKey, ascending: true, predicate: predicate, page: nil, pageSize: nil)
    }
    
    public func findObjectsByEntity(entityName: String, withSortKey sortKey: String, ascending: Bool, predicate: NSPredicate) throws -> [T] {
        return try self.findObjectsByEntity(entityName, sortKey: sortKey, ascending: ascending, predicate: predicate, page: nil, pageSize: nil)
    }
    
    public func findObjectsByEntity(entityName: String, withSortKey sortKey: String, ascending: Bool, predicate: NSPredicate, page: Int, pageSize: Int) throws -> [T] {
        return try self.findObjectsByEntity(entityName, sortKey: sortKey, ascending: ascending, predicate: predicate, page: page, pageSize: pageSize)
    }
    
    public func findObjectsByEntity(entityName: String, withSortKey sortKey: String, page: Int, pageSize: Int) throws -> [T] {
        return try self.findObjectsByEntity(entityName, sortKey: sortKey, ascending: true, predicate: nil, page: page, pageSize: pageSize)
    }
    
    public func findObjectsByEntity() throws -> [T] {
        return try self.findObjectsByEntity(self.entityName)
    }
    
    public func findObjectsByEntity(sortKey sortKey: String) throws -> [T] {
        return try self.findObjectsByEntity(self.entityName, withSortKey: sortKey)
    }
    
    public func findObjectsByEntity(predicate predicate: NSPredicate) throws -> [T] {
        return try self.findObjectsByEntity(self.entityName, predicate: predicate)
    }
    
    public func findObjectsByEntity(sortKey sortKey: String, predicate: NSPredicate) throws -> [T] {
        return try self.findObjectsByEntity(self.entityName, withSortKey: sortKey, predicate: predicate)
    }
    
    public func findObjectsByEntity(sortKey sortKey: String, page: Int, pageSize: Int) throws -> [T] {
        return try self.findObjectsByEntity(self.entityName, sortKey: sortKey, ascending: true, predicate: nil, page: page, pageSize: pageSize)
    }
    
    public func findObjectsByEntity(sortKey sortKey: String, predicate: NSPredicate, page: Int, pageSize: Int) throws -> [T] {
        return try self.findObjectsByEntity(self.entityName, sortKey: sortKey, ascending: true, predicate: predicate, page: page, pageSize: pageSize)
    }
    
    public func findObjectByManagedObjectId(moId moId: NSManagedObjectID) throws ->T {
        guard let object = try self.coreDataContext.findObjectById(moId) as? T else {
            throw CoreDataKitError.CannotCastManagedObject
        }
        return object
    }
    
    public func findObjectById(objectId objectId: String) throws -> T {
        let managedObjectId = try self.coreDataContext.managedObjectIdFromStringObjectId(objectId)
        return try self.findObjectByManagedObjectId(moId: managedObjectId)
    }
    
    public func delete(objectId objectId: String) throws {
        try self.coreDataContext.deleteObject(byObjectId: objectId)
        try self.saveIfAutocommit()
    }
    
    public func delete(object object: NSManagedObject) throws {
        self.coreDataContext.deleteObject(object)
        try self.saveIfAutocommit()
    }
    
    public func truncate(entityName: String) throws {
        let objects: [NSManagedObject] = try self.findObjectsByEntity(entityName)
        for mo in objects {
            self.coreDataContext.deleteObject(mo)
        }
        try self.saveIfAutocommit()
    }
    
    public func findObjectByEntity(entityName: String, withKey key: String, andValue value: String) throws -> T? {
        let expressionKey = NSExpression(forKeyPath: key)
        let expressionValue = NSExpression(forConstantValue: value)
        let predicate = NSComparisonPredicate(leftExpression: expressionKey, rightExpression: expressionValue, modifier: .DirectPredicateModifier, type: .EqualToPredicateOperatorType, options: .CaseInsensitivePredicateOption)
        
        let result: [T] = try self.findObjectsByEntity(entityName, sortKey: nil, ascending: nil, predicate: predicate, page: nil, pageSize: nil)
        
        return result.first
    }
    
    public func findObjectByEntity(key key: String, andValue value: String) throws -> T? {
        return try self.findObjectByEntity(self.entityName, withKey: key, andValue: value);
    }
    
    public class func stringObjectId(fromMO mo: NSManagedObject) -> String {
        let objectId : NSManagedObjectID = mo.objectID
        let url = objectId.URIRepresentation()
        let absURL = url.absoluteString
        return absURL;
    }
    
    public func performBlock(block: () -> Void) {
        coreDataContext.performBlock(block)
    }
    
    public func commit() throws {
        try coreDataContext.saveContext()
    }
    
    public func rollback() {
        coreDataContext.rollbackContext()
    }
    
    public func reset() {
        coreDataContext.reset()
    }
    
    private func saveIfAutocommit() throws {
        if autocommit {
            try coreDataContext.saveContext()
        }
    }
    
    private func guessEntityName() -> String {
        let components = String(T.self).componentsSeparatedByString(".")
        if (components.count == 1) {
            return components[0]
        } else if components.count >= 2 {
            return components[1]
        } else {
            return ""
        }
    }
}