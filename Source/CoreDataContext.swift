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
    func coreDataContextObjectsDidChangeNotification(_ notification: Notification)
    func coreDataContextObjectContextDidSaveNotification(_ notification: Notification)
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
        
        NotificationCenter.default.addObserver(self, selector: #selector(objectsDidChangeNotification), name: NSNotification.Name.NSManagedObjectContextObjectsDidChange, object: objectContext)
        NotificationCenter.default.addObserver(self, selector: #selector(objectContextDidSaveNotification), name: NSNotification.Name.NSManagedObjectContextDidSave, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.NSManagedObjectContextObjectsDidChange, object: objectContext)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.NSManagedObjectContextDidSave, object: nil)
    }
    
    public func objectContextDidSaveNotification(_ notification: Notification) {
        self.delegate?.coreDataContextObjectsDidChangeNotification(notification)
    }
    
    public func objectsDidChangeNotification(_ notification: Notification) {
        self.delegate?.coreDataContextObjectsDidChangeNotification(notification)
    }
    
    public func fetch(byManagedObjectId objectId: NSManagedObjectID) throws -> NSManagedObject {
        return try objectContext.existingObject(with: objectId)
    }
    
    public func find(entityName: String, predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor]? = nil, page: Int? = nil, pageSize: Int? = nil) throws -> [AnyObject] {
        let request = self.createFetchRequest(forEntityName: entityName, predicate: predicate, sortDescriptors: sortDescriptors, page: page, pageSize: pageSize)
        return try objectContext.fetch(request)
    }
        
    public func count(rowsForEntityName entityName: String, predicate: NSPredicate?) throws -> Int {
        let request = self.createFetchRequest(forEntityName: entityName, predicate: predicate)
        return try objectContext.count(for: request)
    }
        
    public func insert(withEntityName entityName: String) -> NSManagedObject {
        return NSEntityDescription.insertNewObject(forEntityName: entityName, into: self.objectContext)
    }
    
    public func delete(byId objectId: String) throws {
        let managedObjectId = try self.managedObjectIdFromStringObjectId(objectId)
        try self.delete(managedObject: self.fetch(byManagedObjectId: managedObjectId))
    }
    
    public func delete(managedObject: NSManagedObject) -> Void {
        objectContext.delete(managedObject)
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
    
    public func performBlock(_ block: @escaping () -> Void) {
        objectContext.perform(block)
    }
    
    public func managedObjectIdFromStringObjectId(_ objectId: String) throws -> NSManagedObjectID {
        guard let url = URL(string: objectId), let managedObjectId = self.objectContext.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: url) else {
            throw CoreDataKitError.managedObjectIdNotFound
        }
        return managedObjectId;
    }
    
    private func createFetchRequest(forEntityName entityName : String, predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor]? = nil, page: Int? = nil, pageSize: Int? = nil) -> NSFetchRequest<NSManagedObject> {
        let request = NSFetchRequest<NSManagedObject>()
        request.sortDescriptors = sortDescriptors
        request.predicate = predicate
        request.entity = NSEntityDescription.entity(forEntityName: entityName, in: self.objectContext)
        if let page = page, let pageSize = pageSize {
            request.fetchLimit = pageSize;
            request.fetchOffset = page * pageSize
        }
        return request
    }
}
