//
//  CoreDataManager.swift
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

import CoreData

public enum CoreDataKitError: Error {
    case cannotFindObjectModel(name: String, bundle: Bundle)
    case cannotCreateManagedModelObject(path: String)
    case managedObjectIdNotFound
}

public class CoreDataManager: NSObject {

    private var persistentStoreCoordinator : NSPersistentStoreCoordinator?
    
    let modelName : String
    let appGroup: String?
    let bundle: Bundle
    let sqlFileName: String?
    let useInMemoryStore: Bool
    var objectModel : NSManagedObjectModel?
    
    public init(usingModelName modelName: String, sqlFileName: String? = nil, inBundle bundle: Bundle? = nil, securityApplicationGroup appGroup: String? = nil, useInMemoryStore: Bool = false) {
        self.modelName = modelName
        self.appGroup = appGroup
        self.sqlFileName = sqlFileName
        self.useInMemoryStore = useInMemoryStore
        if let bundle = bundle {
            self.bundle = bundle
        } else {
            self.bundle = Bundle.main
        }
        super.init()
    }
        
    public func setupCoreDataStack() throws {
        if self.useInMemoryStore {
            self.persistentStoreCoordinator = try self.createInMemoryPersistentStoreCoordinator()
        } else {
            self.persistentStoreCoordinator = try self.createPersistentStoreCoordinator()
        }
    }
    
    public func shutdownCoreDataStack() throws {
        if let store = self.persistentStoreCoordinator?.persistentStores.first {
            try self.persistentStoreCoordinator?.remove(store)
        }
    }
    
    public func makeContext(associateWithMainQueue: Bool) -> CoreDataContext {
        if associateWithMainQueue {
            return CoreDataContext(usingPersistentStoreCoordinator: self.persistentStoreCoordinator!, concurrencyType: .mainQueueConcurrencyType)
        } else {
            return CoreDataContext(usingPersistentStoreCoordinator: self.persistentStoreCoordinator!, concurrencyType: .privateQueueConcurrencyType)
        }
    }
    
    private func applicationDocumentDirectory() -> URL? {
        let fileManager = FileManager.default
        if let actualAppGroup = self.appGroup {
            return fileManager.containerURL(forSecurityApplicationGroupIdentifier: actualAppGroup)
        }
        let urlsForDir = fileManager.urls(for: FileManager.SearchPathDirectory.documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask)
            
        return urlsForDir.first
    }
    
    private func createManagedObjectModel() throws -> NSManagedObjectModel {
        if (self.objectModel != nil) {
            return self.objectModel!
        }
        
        guard let modelURL = self.bundle.url(forResource: self.modelName, withExtension: "momd") else {
            throw CoreDataKitError.cannotFindObjectModel(name: self.modelName, bundle: self.bundle)
        }

        guard let managedObjectModel = NSManagedObjectModel(contentsOf: modelURL) else {
            throw CoreDataKitError.cannotCreateManagedModelObject(path: modelURL.absoluteString)
        }
        
        return managedObjectModel
    }

    private func createInMemoryPersistentStoreCoordinator() throws -> NSPersistentStoreCoordinator {
        self.objectModel = try createManagedObjectModel()
        let storeCoordinator = NSPersistentStoreCoordinator(managedObjectModel: objectModel!)
        try storeCoordinator.addPersistentStore(ofType: NSInMemoryStoreType, configurationName: nil, at: nil, options: nil)
        return storeCoordinator
    }
    
    private func createPersistentStoreCoordinator() throws -> NSPersistentStoreCoordinator {
        //TODO: allow setting this in a property
        let storeOptions: [AnyHashable : Any]? = [NSMigratePersistentStoresAutomaticallyOption:true, NSInferMappingModelAutomaticallyOption:true]

        var storeFile = self.modelName + ".sqlite"
        if let sqlFileName = self.sqlFileName {
            storeFile = sqlFileName + ".sqlite"
        }
        
        let documentDirectory: URL? = applicationDocumentDirectory()
        let storeURL: URL? = documentDirectory?.appendingPathComponent(storeFile)

        self.objectModel = try createManagedObjectModel()
        
        let storeCoordinator = NSPersistentStoreCoordinator(managedObjectModel: objectModel!)
        try storeCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: storeOptions)
        return storeCoordinator
    }
}
