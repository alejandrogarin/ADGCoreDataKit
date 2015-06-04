//
//  DataAccessBase.swift
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

struct CoreDataAccessConstants {
    static let CORE_DATA_OBJECT_ID = "_core_data_object_id"
}

public protocol CoreDataAccess {
    
    var coreDataContextDelegate: CoreDataContextDelegate? {get set}

    func insert<T>(#entityName: String, map: [String: AnyObject], error: NSErrorPointer) ->T?
    func insert<T>(#map: [String: AnyObject], error: NSErrorPointer) ->T?
    func update<T>(#objectId: String, map: [String:AnyObject?], error: NSErrorPointer) -> T?
    func update(managedObject mo: NSManagedObject, map: [String:AnyObject?], error: NSErrorPointer) -> Bool
    
    func findObjectById<T>(#objectId: String) ->T?
    func findObjectByManagedObjectId<T>(#moId: NSManagedObjectID) ->T?
    func findObjectByEntity<T>(#key: String, andValue value: String) -> T?
    func findObjectByEntity<T>(entityName: String, withKey key: String, andValue value: String) -> T?

    func findObjectsByEntity<T>() -> [T]
    func findObjectsByEntity<T>(#predicate: NSPredicate) -> [T];    
    func findObjectsByEntity<T>(#sortKey: String) -> [T];
    func findObjectsByEntity<T>(#sortKey: String, page: Int, pageSize: Int) -> [T];
    func findObjectsByEntity<T>(#sortKey: String, predicate: NSPredicate) -> [T]
    func findObjectsByEntity<T>(#sortKey: String, predicate: NSPredicate, page: Int, pageSize: Int) -> [T]

    func findObjectsByEntity<T>(entityName: String) -> [T]
    func findObjectsByEntity<T>(entityName: String, predicate: NSPredicate) -> [T];
    func findObjectsByEntity<T>(entityName: String, withSortKey sortKey: String) -> [T]
    func findObjectsByEntity<T>(entityName: String, withSortKey sortKey: String, page: Int, pageSize: Int) -> [T]
    func findObjectsByEntity<T>(entityName: String, withSortKey sortKey: String, predicate: NSPredicate) -> [T]
    
    func truncate(entityName: String) -> Bool
    func delete(#objectId: String) -> Bool
    func delete(#object: NSManagedObject) -> Bool
    func stringObjectId(fromMO mo : NSManagedObject) -> String?
    func managedObjectsToDictionary(managedObjects: [NSManagedObject], keys:[String]) -> [[String:Any]]
    func managedObjectsToDictionary(managedObjects: [NSManagedObject]) -> [[String:Any]]
    func managedObjectToDictionary(managedObject: NSManagedObject, keys:[String]) -> [String:Any]
    func managedObjectToDictionary(managedObject: NSManagedObject) -> [String:Any]    
}
