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

public class CoreDataAccessImpl: CoreDataAccess {
    
    private let coreDataContext: CoreDataContext

    public let CORE_DATA_OBJECT_ID = "_core_data_object_id"
    
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
    
    private func createError(#code: Int, failureReason: String) -> NSError {
        let dict:[String:String] = [NSLocalizedFailureReasonErrorKey:failureReason]
        return  NSError(domain: "CORE_DATA_ACCESS_IMPL", code: code, userInfo: dict)
    }
    
    private func parseEntityName(var entityName: String) -> String {
        let components = entityName.componentsSeparatedByString(".")
        if components.count >= 2 {
            entityName = components[1]
        }
        return entityName
    }
    
    public func insert<T>(#map: [String : AnyObject], error: NSErrorPointer) -> T? {

        let entityName = self.parseEntityName(toString(T.self));
        return self.insert(entityName: entityName, map: map, error: error)
    }
    
    public func insert<T>(#entityName: String, map: [String: AnyObject], error: NSErrorPointer) ->T? {

        let genericMO: T? = self.coreDataContext.insertObjectForEntity(entityName)
        let maybeMO = genericMO as? NSManagedObject
        if let mo = maybeMO {
            for key in map.keys {
                mo.setValue(map[key], forKey: key)
            }
            coreDataContext.saveContext(error)
        }
        return genericMO;
    }
    
    public func update<T>(#objectId: String, map: [String:AnyObject?], error: NSErrorPointer) -> T? {
        
        let genericMO: T? = self.findObjectById(objectId: objectId)
        
        let maybeMO = genericMO as? NSManagedObject
        if let mo = maybeMO {
            for key in map.keys {
                let maybeValue: AnyObject? = map[key]!
                mo.setValue(maybeValue, forKey: key)
            }
            coreDataContext.saveContext(error)
            return genericMO
        } else {
            self.createError(code: 1, failureReason: "Can not update managed object because it was not found")
            return nil
        }
    }
    
    public func update(managedObject mo: NSManagedObject, map: [String:AnyObject?], error: NSErrorPointer) -> Bool {
        for key in map.keys {
            let maybeValue: AnyObject? = map[key]!
            mo.setValue(maybeValue, forKey: key)
        }
        return coreDataContext.saveContext(error)
    }
    
    public func findObjectsByEntity<T>(entityName: String) -> [T] {
        return self.coreDataContext.findObjectsByEntity(entityName, sortKey: nil, predicate: nil, page: nil, pageSize: nil, error: nil)
    }
    
    public func findObjectsByEntity<T>(entityName: String, predicate: NSPredicate) -> [T] {
        return self.coreDataContext.findObjectsByEntity(entityName, sortKey: nil, predicate: predicate, page: nil, pageSize: nil, error: nil)
    }
    
    public func findObjectsByEntity<T>(entityName: String, withSortKey sortKey: String) -> [T] {
        return self.coreDataContext.findObjectsByEntity(entityName, sortKey: sortKey, predicate: nil, page: nil, pageSize: nil, error: nil)
    }
    
    public func findObjectsByEntity<T>(entityName: String, withSortKey sortKey: String, predicate: NSPredicate) -> [T] {
        return self.coreDataContext.findObjectsByEntity(entityName, sortKey: sortKey, predicate: predicate, page: nil, pageSize: nil, error: nil)
    }
    
    public func findObjectsByEntity<T>(entityName: String, withSortKey sortKey: String, page: Int, pageSize: Int) -> [T] {
        return self.coreDataContext.findObjectsByEntity(entityName, sortKey: sortKey, predicate: nil, page: page, pageSize: pageSize, error: nil)
    }

    public func findObjectsByEntity<T>() -> [T] {
        let entityName = self.parseEntityName(toString(T.self))
        return self.findObjectsByEntity(entityName)
    }
    
    public func findObjectsByEntity<T>(#sortKey: String) -> [T] {
        let entityName = self.parseEntityName(toString(T.self))
        return self.findObjectsByEntity(entityName, withSortKey: sortKey)
    }
    
    public func findObjectsByEntity<T>(#predicate: NSPredicate) -> [T] {
        let entityName = self.parseEntityName(toString(T.self))
        return self.findObjectsByEntity(entityName, predicate: predicate)
    }
    
    public func findObjectsByEntity<T>(#sortKey: String, predicate: NSPredicate) -> [T] {
        let entityName = self.parseEntityName(toString(T.self))
        return self.findObjectsByEntity(entityName, withSortKey: sortKey, predicate: predicate)
    }
    
    public func findObjectsByEntity<T>(#sortKey: String, page: Int, pageSize: Int) -> [T] {
        let entityName = self.parseEntityName(toString(T.self))
        return self.coreDataContext.findObjectsByEntity(entityName, sortKey: sortKey, predicate: nil, page: page, pageSize: pageSize, error: nil)
    }
    
    public func findObjectsByEntity<T>(#sortKey: String, predicate: NSPredicate, page: Int, pageSize: Int) -> [T] {
        let entityName = self.parseEntityName(toString(T.self))
        return self.coreDataContext.findObjectsByEntity(entityName, sortKey: sortKey, predicate: predicate, page: page, pageSize: pageSize, error: nil)
    }
    
    public func findObjectByManagedObjectId<T>(#moId: NSManagedObjectID) ->T? {
        let result : T = self.coreDataContext.findObjectById(moId)
        return result
    }
    
    public func findObjectById<T>(#objectId: String) ->T? {
        let maybeURL : NSURL? = NSURL(string: objectId)
        if let url = maybeURL {
            let objectId: NSManagedObjectID? = self.coreDataContext.persistentCoordinator.managedObjectIDForURIRepresentation(url)
            if let actualObjectId = objectId {
                let result : T = self.coreDataContext.findObjectById(actualObjectId)
                return result
            }
        }
        return nil
    }
    
    public func delete(#objectId: String) -> Bool {
        let resultDelete = self.coreDataContext.deleteObject(byObjectId: objectId)
        let resultSave = coreDataContext.saveContext()
        return resultDelete && resultSave
    }
    
    public func delete(#object: NSManagedObject) -> Bool {
        self.coreDataContext.deleteObject(object)
        let resultSave = coreDataContext.saveContext()
        return resultSave
    }
    
    public func truncate(entityName: String) -> Bool {
        let objects: [NSManagedObject] = self.findObjectsByEntity(entityName)
        for mo in objects {
            self.coreDataContext.deleteObject(mo)
        }
        let resultSave = coreDataContext.saveContext()
        return resultSave;
    }
    
    public func findObjectByEntity<T>(entityName: String, withKey key: String, andValue value: String) -> T? {
        let expressionKey = NSExpression(forKeyPath: key)
        let expressionValue = NSExpression(forConstantValue: value)
        let predicate = NSComparisonPredicate(leftExpression: expressionKey, rightExpression: expressionValue, modifier: .DirectPredicateModifier, type: .EqualToPredicateOperatorType, options: .CaseInsensitivePredicateOption)
        
        let result: [T] = self.coreDataContext.findObjectsByEntity(entityName, sortKey: nil, predicate: predicate, page: nil, pageSize: nil, error: nil)
        
        return result.first
    }
    
    public func findObjectByEntity<T>(#key: String, andValue value: String) -> T? {
        let entityName = self.parseEntityName(toString(T.self));
        return self.findObjectByEntity(entityName, withKey: key, andValue: value);
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
            dtoMap[CORE_DATA_OBJECT_ID] = self.stringObjectId(fromMO: object)
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
                if let convertedKey = key as? String, value:AnyObject = object.valueForKey(convertedKey) {
                    dtoMap[convertedKey] = value
                }
            }
            dtoMap[CORE_DATA_OBJECT_ID] = self.stringObjectId(fromMO: object)
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