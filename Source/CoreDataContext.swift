//
//  CoreDataContext.swift
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

public protocol CoreDataContextDelegate: class {
    func coreDataContextObjectsDidChangeNotification(notification: NSNotification)
    func coreDataContextObjectContextDidSaveNotification(notification: NSNotification)
}

public class CoreDataContext: NSObject {
    
    let objectContext : NSManagedObjectContext
    
    let persistentCoordinator: NSPersistentStoreCoordinator
    
    public var delegate : CoreDataContextDelegate?
    
    public init(usingPersistentStoreCoordinator storeCoordinator : NSPersistentStoreCoordinator, concurrencyType type : NSManagedObjectContextConcurrencyType) {
        persistentCoordinator = storeCoordinator
        objectContext = NSManagedObjectContext(concurrencyType: type)
        objectContext.persistentStoreCoordinator = storeCoordinator
        super.init()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "objectsDidChangeNotification:", name: NSManagedObjectContextObjectsDidChangeNotification, object: objectContext)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "objectContextDidSaveNotification:", name: NSManagedObjectContextDidSaveNotification, object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NSManagedObjectContextObjectsDidChangeNotification, object: objectContext)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NSManagedObjectContextDidSaveNotification, object: nil)
    }
    
    func objectContextDidSaveNotification(notification: NSNotification) {
        self.delegate?.coreDataContextObjectsDidChangeNotification(notification)
    }
    
    func objectsDidChangeNotification(notification: NSNotification) {
        self.delegate?.coreDataContextObjectsDidChangeNotification(notification)
    }
    
    func findObjectById<T>(objectId: NSManagedObjectID) -> T {
        return objectContext.objectWithID(objectId) as! T;
    }

    func findObjectsByEntity<T>(entityName : String, sortKey: String?, predicate: NSPredicate?, var page: Int?, pageSize: Int?, error: NSErrorPointer) -> [T] {
        let all = NSFetchRequest()
        if let sortKey = sortKey {
            all.sortDescriptors = [NSSortDescriptor(key: sortKey, ascending: true)]
        }
        if let predicate = predicate {
            all.predicate = predicate
        }
        all.entity = NSEntityDescription.entityForName(entityName, inManagedObjectContext: self.objectContext)
        if let page = page, pageSize = pageSize {
            all.fetchLimit = pageSize;
            all.fetchOffset = page * pageSize
        }
        let list: [AnyObject]? = objectContext.executeFetchRequest(all, error: error)
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
    
    func insertObjectForEntity<T>(entityName : String) -> T? {
        let anyObject: AnyObject = NSEntityDescription.insertNewObjectForEntityForName(entityName, inManagedObjectContext: self.objectContext)
        return anyObject as? T
    }
    
    func deleteObject(byObjectId objectId: String) -> Bool {
        let url : NSURL? = NSURL(string: objectId)
        if (url != nil) {
            let objectId: NSManagedObjectID? = self.objectContext.persistentStoreCoordinator?.managedObjectIDForURIRepresentation(url!)
            if let actualObjectId = objectId {
                let managedObject: NSManagedObject = self.findObjectById(actualObjectId)
                self.deleteObject(managedObject)
                return true
            }
        }
        return false;
    }
    
    func deleteObject(managedObject : NSManagedObject) -> Void {
        objectContext.deleteObject(managedObject);
    }
    
    func saveContext () -> Bool {
        return objectContext.hasChanges && objectContext.save(nil);
    }
    
    func saveContext (error: NSErrorPointer) -> Bool {
        return objectContext.hasChanges && objectContext.save(error);
    }

}
