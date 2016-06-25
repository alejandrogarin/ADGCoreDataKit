//
//  CoreDataGenericDAO.swift
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

public class CoreDataGenericDAO<T: NSManagedObject>: CoreDataBaseDAO {
    
    public override init(usingContext context: CoreDataContext, forEntityName entityName: String) {
        super.init(usingContext: context, forEntityName: entityName)
    }
    
    public func fetch(byId objectId: String) throws -> T {
        return try self.fetchManagedObject(byId: objectId) as! T
    }
    
    public func fetch(byManagedObjectId objectId: NSManagedObjectID) throws -> T {
        return try self.fetchManagedObject(byManagedObjectId: objectId) as! T
    }
    
    public func find(withPredicate predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor]? = nil, page: Int? = nil, pageSize: Int? = nil) throws -> [T] {
        let list: [AnyObject] = try self.coreDataContext.find(entityName: entityName, predicate: predicate, sortDescriptors: sortDescriptors, page: page, pageSize: pageSize)
        var newArray: [T] = []
        for anyObject in list {
            if let anyObject = anyObject as? T {
                newArray.append(anyObject)
            }
        }
        return newArray
    }
    
    public func findTransformed<DTO>(withPredicate predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor]? = nil, page: Int? = nil, pageSize: Int? = nil, transformationHandler:(entity: T) -> DTO) throws -> [DTO] {
        let list: [AnyObject] = try self.coreDataContext.find(entityName: entityName, predicate: predicate, sortDescriptors: sortDescriptors, page: page, pageSize: pageSize)
        var newArray: [DTO] = []
        for anyObject in list {
            if let anyObject = anyObject as? T {
                let transformedObject = transformationHandler(entity: anyObject)
                newArray.append(transformedObject)
            }
        }
        return newArray
    }
    
    public func insert(withMap map: [String:AnyObject?]) throws -> T {
        let managedObject = self.coreDataContext.insert(withEntityName: entityName)
        for key in map.keys {
            if let value = map[key] {
                managedObject.setValue(value, forKey: key)
            }
        }
        try self.saveIfAutocommit()
        return managedObject as! T
    }
    
    public func update(byId objectId: String, map: [String:AnyObject?]) throws -> T {
        let managedObject = try self.fetchManagedObject(byId: objectId)
        for key in map.keys {
            let maybeValue: AnyObject? = map[key]!
            managedObject.setValue(maybeValue, forKey: key)
        }
        try self.saveIfAutocommit()
        return managedObject as! T
    }
}