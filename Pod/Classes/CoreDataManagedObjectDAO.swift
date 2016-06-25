//
//  CoreDataManagedObjectDAO.swift
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

public class CoreDataManagedObjectDAO: CoreDataBaseDAO {
    
    public func insert(withMap map: [String : AnyObject]) throws -> NSManagedObject {
        let managedObject = self.coreDataContext.insert(withEntityName: entityName)
        for key in map.keys {
            if let value = map[key] {
                managedObject.setValue(value, forKey: key)
            }
        }
        try self.saveIfAutocommit()
        return managedObject
    }
    
    private func managedObjectArray(fromGenericArray list: [AnyObject]) -> [NSManagedObject] {
        var newArray : [NSManagedObject] = []
        for anyObject in list {
            if let anyObject = anyObject as? NSManagedObject {
                newArray.append(anyObject)
            }
        }
        return newArray
    }
    
    public func find() throws -> [NSManagedObject] {
        let list: [AnyObject] = try self.coreDataContext.find(entityName: entityName, predicate: nil, sortDescriptors: nil, page: nil, pageSize: nil)
        return self.managedObjectArray(fromGenericArray: list)
    }
    
    public func find(withPredicate predicate: Predicate?, sortDescriptors: [SortDescriptor]?) throws -> [NSManagedObject] {
        let list: [AnyObject] = try self.coreDataContext.find(entityName: entityName, predicate: predicate, sortDescriptors: sortDescriptors, page: nil, pageSize: nil)
        return self.managedObjectArray(fromGenericArray: list)
    }
}
