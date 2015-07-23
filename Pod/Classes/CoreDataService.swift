//
//  DataAccessBaseImpl.swift
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

public class CoreDataService {
    
    private let coreDataContext: CoreDataContext
    
    public enum Keys: String {
        case CORE_DATA_OBJECT_ID = "_core_data_object_id"
    }
    
    public var coreDataContextDelegate: CoreDataContextDelegate? {
        get {
            return self.coreDataContext.delegate
        }
        set {
            self.coreDataContext.delegate = newValue
        }
    }
    
    public init(usingCoreDataManager coreDataManager: CoreDataManager, concurrencyType type: NSManagedObjectContextConcurrencyType) {
        self.coreDataContext = CoreDataContext(usingPersistentStoreCoordinator: coreDataManager.persistentStoreCoordinator, concurrencyType: type)
    }
    
    private func parseEntityName(var entityName: String) -> String {
        let components = entityName.componentsSeparatedByString(".")
        if components.count >= 2 {
            entityName = components[1]
        } else if components.count >= 3 {
            entityName = components[2]
            entityName.stringByReplacingOccurrencesOfString(">", withString: "")
        }
        return entityName
    }
    
    public func insert<T>(map map: [String : AnyObject]) throws -> T {
        let entityName = self.parseEntityName(String(T.self));
        return try self.insert(entityName: entityName, map: map)
    }
    
    public func insert<T>(entityName entityName: String, map: [String: AnyObject]) throws -> T {
        
        let genericMO = self.coreDataContext.insertObjectForEntity(entityName)
        for key in map.keys {
            genericMO.setValue(map[key], forKey: key)
        }
        try self.coreDataContext.saveContext()
        if let mo = genericMO as? T {
            return mo
        }
        throw CoreDataKitError.CannotCreateObject
    }
    
    public func update<T>(objectId objectId: String, map: [String:AnyObject?]) throws -> T {
        
        let genericMO: T? = try self.findObjectById(objectId: objectId)
        
        if let mo = genericMO as? NSManagedObject {
            for key in map.keys {
                let maybeValue: AnyObject? = map[key]!
                mo.setValue(maybeValue, forKey: key)
            }
            try coreDataContext.saveContext()
            return genericMO!
        }
        throw CoreDataKitError.ObjectNotFound
    }
    
    public func update(managedObject mo: NSManagedObject, map: [String:AnyObject?]) throws {
        for key in map.keys {
            let maybeValue: AnyObject? = map[key]!
            mo.setValue(maybeValue, forKey: key)
        }
        try coreDataContext.saveContext()
    }
    
    private func findObjectsByEntity<T>(entityName : String, sortKey: String?, predicate: NSPredicate?, page: Int?, pageSize: Int?) throws -> [T] {
        
        let list: [AnyObject]? = try self.coreDataContext.findObjectsByEntity(entityName, sortKey: sortKey, predicate: predicate, page: page, pageSize: pageSize)
        if let actualList = list {
            var newArray : [T] = []
            for anyObject in actualList {
                if (anyObject is T) {
                    newArray.append(anyObject as! T)
                }
            }
            return newArray
        } else {
            return []
        }
    }
    
    public func findObjectsByEntity<T>(entityName: String) throws -> [T] {
        return try self.findObjectsByEntity(entityName, sortKey: nil, predicate: nil, page: nil, pageSize: nil)
    }
    
    public func findObjectsByEntity<T>(entityName: String, predicate: NSPredicate) throws -> [T] {
        return try self.findObjectsByEntity(entityName, sortKey: nil, predicate: predicate, page: nil, pageSize: nil)
    }
    
    public func findObjectsByEntity<T>(entityName: String, withSortKey sortKey: String) throws -> [T] {
        return try self.findObjectsByEntity(entityName, sortKey: sortKey, predicate: nil, page: nil, pageSize: nil)
    }
    
    public func findObjectsByEntity<T>(entityName: String, withSortKey sortKey: String, predicate: NSPredicate) throws -> [T] {
        return try self.findObjectsByEntity(entityName, sortKey: sortKey, predicate: predicate, page: nil, pageSize: nil)
    }
    
    public func findObjectsByEntity<T>(entityName: String, withSortKey sortKey: String, page: Int, pageSize: Int) throws -> [T] {
        return try self.findObjectsByEntity(entityName, sortKey: sortKey, predicate: nil, page: page, pageSize: pageSize)
    }

    public func findObjectsByEntity<T>() throws -> [T] {
        let entityName = self.parseEntityName(String(T.self))
        return try self.findObjectsByEntity(entityName)
    }
    
    public func findObjectsByEntity<T>(sortKey sortKey: String) throws -> [T] {
        let entityName = self.parseEntityName(String(T.self))
        return try self.findObjectsByEntity(entityName, withSortKey: sortKey)
    }
    
    public func findObjectsByEntity<T>(predicate predicate: NSPredicate) throws -> [T] {
        let entityName = self.parseEntityName(String(T.self))
        return try self.findObjectsByEntity(entityName, predicate: predicate)
    }
    
    public func findObjectsByEntity<T>(sortKey sortKey: String, predicate: NSPredicate) throws -> [T] {
        let entityName = self.parseEntityName(String(T.self))
        return try self.findObjectsByEntity(entityName, withSortKey: sortKey, predicate: predicate)
    }
    
    public func findObjectsByEntity<T>(sortKey sortKey: String, page: Int, pageSize: Int) throws -> [T] {
        let entityName = self.parseEntityName(String(T.self))
        return try self.findObjectsByEntity(entityName, sortKey: sortKey, predicate: nil, page: page, pageSize: pageSize)
    }
    
    public func findObjectsByEntity<T>(sortKey sortKey: String, predicate: NSPredicate, page: Int, pageSize: Int) throws -> [T] {
        let entityName = self.parseEntityName(String(T.self))
        return try self.findObjectsByEntity(entityName, sortKey: sortKey, predicate: predicate, page: page, pageSize: pageSize)
    }
    
    public func findObjectByManagedObjectId<T>(moId moId: NSManagedObjectID) throws ->T {
        guard let object = try self.coreDataContext.findObjectById(moId) as? T else {
            throw CoreDataKitError.InvalidCast
        }
        return object
    }
    
    public func findObjectById<T>(objectId objectId: String) throws ->T {
        
        guard let url = NSURL(string: objectId) else {
            throw CoreDataKitError.ObjectNotFound
        }
        
        guard let objectId = self.coreDataContext.persistentCoordinator.managedObjectIDForURIRepresentation(url) else {
            throw CoreDataKitError.ObjectNotFound
        }

        return try self.findObjectByManagedObjectId(moId: objectId)
    }
    
    public func delete(objectId objectId: String) throws {
        self.coreDataContext.deleteObject(byObjectId: objectId)
        try self.coreDataContext.saveContext()
    }
    
    public func delete(object object: NSManagedObject) throws {
        self.coreDataContext.deleteObject(object)
        try self.coreDataContext.saveContext()
    }
    
    public func truncate(entityName: String) throws {
        let objects: [NSManagedObject] = try self.findObjectsByEntity(entityName)
        for mo in objects {
            self.coreDataContext.deleteObject(mo)
        }
        try coreDataContext.saveContext()
    }
    
    public func findObjectByEntity<T>(entityName: String, withKey key: String, andValue value: String) throws -> T? {
        let expressionKey = NSExpression(forKeyPath: key)
        let expressionValue = NSExpression(forConstantValue: value)
        let predicate = NSComparisonPredicate(leftExpression: expressionKey, rightExpression: expressionValue, modifier: .DirectPredicateModifier, type: .EqualToPredicateOperatorType, options: .CaseInsensitivePredicateOption)
        
        let result: [T] = try self.findObjectsByEntity(entityName, sortKey: nil, predicate: predicate, page: nil, pageSize: nil)
        
        return result.first
    }
    
    public func findObjectByEntity<T>(key key: String, andValue value: String) throws -> T? {
        let entityName = self.parseEntityName(String(T.self));
        return try self.findObjectByEntity(entityName, withKey: key, andValue: value);
    }
    
    public func stringObjectId(fromMO mo: NSManagedObject) -> String? {
        let objectId : NSManagedObjectID = mo.objectID
        let url = objectId.URIRepresentation()
        let absURL = url.absoluteString
        return absURL;
    }

    public func managedObjectsToDictionary(managedObjects: [NSManagedObject], keys:[String]) -> [[String:Any]] {
        var result:[[String:Any]] = []
        for object in managedObjects {
            var dtoMap: [String: Any] = [:]
            for key in keys {
                if let value:AnyObject = object.valueForKey(key) {
                    dtoMap[key] = value
                }
            }
            dtoMap[Keys.CORE_DATA_OBJECT_ID.rawValue] = self.stringObjectId(fromMO: object)
            result.append(dtoMap)
        }
        return result
    }
    
    public func managedObjectToDictionary(managedObject: NSManagedObject, keys:[String]) -> [String:Any] {
        if let result = self.managedObjectsToDictionary([managedObject], keys: keys).first {
            return result
        } else {
            return [:]
        }
    }
    
    public func managedObjectsToDictionary(managedObjects: [NSManagedObject]) -> [[String:Any]] {
        
        var result:[[String:Any]] = []
        for object in managedObjects {
            var dtoMap: [String: Any] = [:]
            let valuesForKey = object.committedValuesForKeys(nil)
            for key in valuesForKey.keys {
                if let value:AnyObject = object.valueForKey(key) {
                    dtoMap[key] = value
                }
            }
            dtoMap[Keys.CORE_DATA_OBJECT_ID.rawValue] = self.stringObjectId(fromMO: object)
            result.append(dtoMap)
        }
        return result
    }
    
    public func managedObjectToDictionary(managedObject: NSManagedObject) -> [String:Any] {
        if let result = self.managedObjectsToDictionary([managedObject]).first {
            return result
        } else {
            return [:]
        }
    }
}