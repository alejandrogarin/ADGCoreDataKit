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

public enum CoreDataKitError: ErrorType {
    case CannotFindObjectModel(name: String, bundle: NSBundle)
    case CannotCreateManagedModelObject(path: String)
    case ManagedObjectIdNotFound
    case CannotCastManagedObject
}

public protocol CoreDataManagerDelegate: class {
    func coreDataManagerPersistentStoreDidImportUbiquitousContentChangesNotification(notification: NSNotification)
    func coreDataManagerPersistentStoreCoordinatorStoresDidChangeWithTransitionType(transition: NSPersistentStoreUbiquitousTransitionType)
    func coreDataManagerPersistentStoreCoordinatorStoresWillChangeWithTransitionType(transition: NSPersistentStoreUbiquitousTransitionType)
}

public class CoreDataManager: NSObject {

    private var persistentStoreCoordinator : NSPersistentStoreCoordinator?
    
    public weak var delegate : CoreDataManagerDelegate?
    
    let modelName : String
    let icloud : Bool
    let appGroup: String?
    let bundle: NSBundle
    let sqlFileName: String?
    let useInMemoryStore: Bool
    var objectModel : NSManagedObjectModel?
    
    public init(usingModelName modelName: String, sqlFileName: String? = nil, inBundle bundle: NSBundle? = nil, securityApplicationGroup appGroup: String? = nil, enableCloud: Bool = false, useInMemoryStore: Bool = false) {
        self.modelName = modelName
        self.appGroup = appGroup
        self.icloud = enableCloud
        self.sqlFileName = sqlFileName
        self.useInMemoryStore = useInMemoryStore
        if let bundle = bundle {
            self.bundle = bundle
        } else {
            self.bundle = NSBundle.mainBundle()
        }
        super.init()
    }
        
    public func setupCoreDataStack() throws {
        if self.useInMemoryStore {
            self.persistentStoreCoordinator = try self.createInMemoryPersistentStoreCoordinator()
        } else {
            self.persistentStoreCoordinator = try self.createPersistentStoreCoordinator()
        }
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(persistentStoreCoordinatorStoresDidChangeNotification), name: NSPersistentStoreCoordinatorStoresDidChangeNotification, object: self.persistentStoreCoordinator)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:
            #selector(persistentStoreCoordinatorStoresWillChangeNotification), name: NSPersistentStoreCoordinatorStoresWillChangeNotification, object: self.persistentStoreCoordinator)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(persistentStoreDidImportUbiquitousContentChangesNotification), name: NSPersistentStoreDidImportUbiquitousContentChangesNotification, object: self.persistentStoreCoordinator)
    }
    
    public func shutdownCoreDataStack() throws {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NSPersistentStoreCoordinatorStoresDidChangeNotification, object: self.persistentStoreCoordinator)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NSPersistentStoreCoordinatorStoresWillChangeNotification, object: self.persistentStoreCoordinator)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NSPersistentStoreDidImportUbiquitousContentChangesNotification, object: self.persistentStoreCoordinator)
        if let store = self.persistentStoreCoordinator?.persistentStores.first {
            try self.persistentStoreCoordinator?.removePersistentStore(store)
        }
    }
    
    public func makeContext(associateWithMainQueue associateWithMainQueue: Bool) -> CoreDataContext {
        if associateWithMainQueue {
            return CoreDataContext(usingPersistentStoreCoordinator: self.persistentStoreCoordinator!, concurrencyType: .MainQueueConcurrencyType)
        } else {
            return CoreDataContext(usingPersistentStoreCoordinator: self.persistentStoreCoordinator!, concurrencyType: .PrivateQueueConcurrencyType)
        }
    }
    
    func persistentStoreCoordinatorStoresDidChangeNotification(notification: NSNotification) {
        if let userInfo = notification.userInfo, type = userInfo[NSPersistentStoreUbiquitousTransitionTypeKey] as? UInt, enumType = self.convertNSPersistentStoreUbiquitousTransitionTypeKeyValueToEnum(type) {
            self.delegate?.coreDataManagerPersistentStoreCoordinatorStoresDidChangeWithTransitionType(enumType)
        }
    }
    
    func persistentStoreCoordinatorStoresWillChangeNotification(notification: NSNotification) {
        if let userInfo = notification.userInfo, type = userInfo[NSPersistentStoreUbiquitousTransitionTypeKey] as? UInt, enumType = self.convertNSPersistentStoreUbiquitousTransitionTypeKeyValueToEnum(type) {
            self.delegate?.coreDataManagerPersistentStoreCoordinatorStoresWillChangeWithTransitionType(enumType)
        }
    }
    
    func persistentStoreDidImportUbiquitousContentChangesNotification(notification: NSNotification) {
        self.delegate?.coreDataManagerPersistentStoreDidImportUbiquitousContentChangesNotification(notification)
    }
    
    private func convertNSPersistentStoreUbiquitousTransitionTypeKeyValueToEnum(type: UInt) -> NSPersistentStoreUbiquitousTransitionType? {
        if type == NSPersistentStoreUbiquitousTransitionType.AccountAdded.rawValue {
            return NSPersistentStoreUbiquitousTransitionType.AccountAdded
        } else if type == NSPersistentStoreUbiquitousTransitionType.AccountRemoved.rawValue {
            return NSPersistentStoreUbiquitousTransitionType.AccountRemoved
        } else if type == NSPersistentStoreUbiquitousTransitionType.ContentRemoved.rawValue {
            return NSPersistentStoreUbiquitousTransitionType.ContentRemoved
        } else if type == NSPersistentStoreUbiquitousTransitionType.InitialImportCompleted.rawValue {
            return NSPersistentStoreUbiquitousTransitionType.InitialImportCompleted
        } else {
            return nil
        }
    }
    
    private func applicationDocumentDirectory() -> NSURL? {
        let fileManager = NSFileManager.defaultManager()
        if let actualAppGroup = self.appGroup {
            return fileManager.containerURLForSecurityApplicationGroupIdentifier(actualAppGroup)
        }
        let urlsForDir = fileManager.URLsForDirectory(NSSearchPathDirectory.DocumentDirectory, inDomains: NSSearchPathDomainMask.UserDomainMask)
        return urlsForDir.first
    }
    
    private func createManagedObjectModel() throws -> NSManagedObjectModel {
        if (self.objectModel != nil) {
            return self.objectModel!
        }
        
        guard let modelURL = self.bundle.URLForResource(self.modelName, withExtension: "momd") else {
            throw CoreDataKitError.CannotFindObjectModel(name: self.modelName, bundle: self.bundle)
        }

        guard let managedObjectModel = NSManagedObjectModel(contentsOfURL: modelURL) else {
            throw CoreDataKitError.CannotCreateManagedModelObject(path: modelURL.absoluteString)
        }
        
        return managedObjectModel
    }

    private func createInMemoryPersistentStoreCoordinator() throws -> NSPersistentStoreCoordinator {
        self.objectModel = try createManagedObjectModel()
        let storeCoordinator = NSPersistentStoreCoordinator(managedObjectModel: objectModel!)
        try storeCoordinator.addPersistentStoreWithType(NSInMemoryStoreType, configuration: nil, URL: nil, options: nil)
        return storeCoordinator
    }
    
    private func createPersistentStoreCoordinator() throws -> NSPersistentStoreCoordinator {
        var storeOptions: [NSObject : AnyObject]? = nil
        if (self.icloud) {
            storeOptions = [NSPersistentStoreUbiquitousContentNameKey:"container_\(self.modelName)", NSMigratePersistentStoresAutomaticallyOption:true, NSInferMappingModelAutomaticallyOption:true]
        } else {
            //TODO: allow setting this in a property
            storeOptions = [NSMigratePersistentStoresAutomaticallyOption:true, NSInferMappingModelAutomaticallyOption:true]
        }

        var storeFile = self.modelName + ".sqlite"
        if let sqlFileName = self.sqlFileName {
            storeFile = sqlFileName + ".sqlite"
        }
        let documentDirectory: NSURL? = applicationDocumentDirectory()
        let storeURL: NSURL? = documentDirectory?.URLByAppendingPathComponent(storeFile)

        self.objectModel = try createManagedObjectModel()
        
        let storeCoordinator = NSPersistentStoreCoordinator(managedObjectModel: objectModel!)
        try storeCoordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: storeURL, options: storeOptions)
        return storeCoordinator
    }
}
