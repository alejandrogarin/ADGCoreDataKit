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
    
    public weak var delegate : CoreDataContextDelegate?
    
    public var hasChanges: Bool {
        return self.objectContext.hasChanges
    }
    
    internal init(usingPersistentStoreCoordinator storeCoordinator : NSPersistentStoreCoordinator, concurrencyType type : NSManagedObjectContextConcurrencyType) {
        persistentCoordinator = storeCoordinator
        objectContext = NSManagedObjectContext(concurrencyType: type)
        objectContext.persistentStoreCoordinator = storeCoordinator
        super.init()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(objectsDidChangeNotification), name: NSManagedObjectContextObjectsDidChangeNotification, object: objectContext)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(objectContextDidSaveNotification), name: NSManagedObjectContextDidSaveNotification, object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NSManagedObjectContextObjectsDidChangeNotification, object: objectContext)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NSManagedObjectContextDidSaveNotification, object: nil)
    }
    
    public func objectContextDidSaveNotification(notification: NSNotification) {
        self.delegate?.coreDataContextObjectsDidChangeNotification(notification)
    }
    
    public func objectsDidChangeNotification(notification: NSNotification) {
        self.delegate?.coreDataContextObjectsDidChangeNotification(notification)
    }
    
    public func fetch(byManagedObjectId objectId: NSManagedObjectID) throws -> NSManagedObject {
        return try objectContext.existingObjectWithID(objectId)
    }
    
    public func find(entityName entityName : String, predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor]? = nil, page: Int? = nil, pageSize: Int? = nil) throws -> [AnyObject] {
        let request = self.createFetchRequest(forEntityName: entityName, predicate: predicate, sortDescriptors: sortDescriptors, page: page, pageSize: pageSize)
        return try objectContext.executeFetchRequest(request)
    }
        
    public func count(rowsForEntityName entityName: String, predicate: NSPredicate?) throws -> Int {
        let request = self.createFetchRequest(forEntityName: entityName, predicate: predicate)
        var error: NSError?
        let count = objectContext.countForFetchRequest(request, error: &error)
        //TODO: change this error throwing in the next swift update. The countForFetchRequest API should throws
        if let error = error {
            throw error
        }
        return count
    }
        
    public func insert(withEntityName entityName : String) -> NSManagedObject {
        return NSEntityDescription.insertNewObjectForEntityForName(entityName, inManagedObjectContext: self.objectContext)
    }
    
    public func delete(byId objectId: String) throws {
        let managedObjectId = try self.managedObjectIdFromStringObjectId(objectId)
        try self.delete(managedObject: self.fetch(byManagedObjectId: managedObjectId))
    }
    
    public func delete(managedObject managedObject: NSManagedObject) -> Void {
        objectContext.deleteObject(managedObject)
    }
    
    public func save() throws {
        try objectContext.save()
    }
    
    public func rollback() {
        objectContext.rollback()
    }
    
    public func reset() {
        objectContext.reset()
    }
    
    public func performBlock(block: () -> Void) {
        objectContext.performBlock(block)
    }
    
    public func managedObjectIdFromStringObjectId(objectId: String) throws -> NSManagedObjectID {
        guard let url = NSURL(string: objectId), managedObjectId = self.objectContext.persistentStoreCoordinator?.managedObjectIDForURIRepresentation(url) else {
            throw CoreDataKitError.ManagedObjectIdNotFound
        }
        return managedObjectId;
    }
    
    private func createFetchRequest(forEntityName entityName : String, predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor]? = nil, page: Int? = nil, pageSize: Int? = nil) -> NSFetchRequest {
        let request = NSFetchRequest()
        request.sortDescriptors = sortDescriptors
        request.predicate = predicate
        request.entity = NSEntityDescription.entityForName(entityName, inManagedObjectContext: self.objectContext)
        if let page = page, pageSize = pageSize {
            request.fetchLimit = pageSize;
            request.fetchOffset = page * pageSize
        }
        return request
    }
}
