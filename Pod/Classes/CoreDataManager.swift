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

public enum CoreDataKitError: ErrorProtocol {
    case cannotFindObjectModel(name: String, bundle: Bundle)
    case cannotCreateManagedModelObject(path: String)
    case managedObjectIdNotFound
}

public protocol CoreDataManagerDelegate: class {
    func coreDataManagerPersistentStoreDidImportUbiquitousContentChangesNotification(_ notification: Notification)
    func coreDataManagerPersistentStoreCoordinatorStoresDidChangeWithTransitionType(_ transition: NSPersistentStoreUbiquitousTransitionType)
    func coreDataManagerPersistentStoreCoordinatorStoresWillChangeWithTransitionType(_ transition: NSPersistentStoreUbiquitousTransitionType)
}

public class CoreDataManager: NSObject {

    private var persistentStoreCoordinator : NSPersistentStoreCoordinator?
    
    public weak var delegate : CoreDataManagerDelegate?
    
    let modelName : String
    let icloud : Bool
    let appGroup: String?
    let bundle: Bundle
    let sqlFileName: String?
    let useInMemoryStore: Bool
    var objectModel : NSManagedObjectModel?
    
    public init(usingModelName modelName: String, sqlFileName: String? = nil, inBundle bundle: Bundle? = nil, securityApplicationGroup appGroup: String? = nil, enableCloud: Bool = false, useInMemoryStore: Bool = false) {
        self.modelName = modelName
        self.appGroup = appGroup
        self.icloud = enableCloud
        self.sqlFileName = sqlFileName
        self.useInMemoryStore = useInMemoryStore
        if let bundle = bundle {
            self.bundle = bundle
        } else {
            self.bundle = Bundle.main()
        }
        super.init()
    }
        
    public func setupCoreDataStack() throws {
        if self.useInMemoryStore {
            self.persistentStoreCoordinator = try self.createInMemoryPersistentStoreCoordinator()
        } else {
            self.persistentStoreCoordinator = try self.createPersistentStoreCoordinator()
        }
        NotificationCenter.default().addObserver(self, selector: #selector(persistentStoreCoordinatorStoresDidChangeNotification), name: NSNotification.Name.NSPersistentStoreCoordinatorStoresDidChange, object: self.persistentStoreCoordinator)
        NotificationCenter.default().addObserver(self, selector:
            #selector(persistentStoreCoordinatorStoresWillChangeNotification), name: NSNotification.Name.NSPersistentStoreCoordinatorStoresWillChange, object: self.persistentStoreCoordinator)
        NotificationCenter.default().addObserver(self, selector: #selector(persistentStoreDidImportUbiquitousContentChangesNotification), name: NSNotification.Name.NSPersistentStoreDidImportUbiquitousContentChanges, object: self.persistentStoreCoordinator)
    }
    
    public func shutdownCoreDataStack() throws {
        NotificationCenter.default().removeObserver(self, name: NSNotification.Name.NSPersistentStoreCoordinatorStoresDidChange, object: self.persistentStoreCoordinator)
        NotificationCenter.default().removeObserver(self, name: NSNotification.Name.NSPersistentStoreCoordinatorStoresWillChange, object: self.persistentStoreCoordinator)
        NotificationCenter.default().removeObserver(self, name: NSNotification.Name.NSPersistentStoreDidImportUbiquitousContentChanges, object: self.persistentStoreCoordinator)
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
    
    func persistentStoreCoordinatorStoresDidChangeNotification(_ notification: Notification) {
        if let userInfo = (notification as NSNotification).userInfo, type = userInfo[NSPersistentStoreUbiquitousTransitionTypeKey] as? UInt, enumType = self.convertNSPersistentStoreUbiquitousTransitionTypeKeyValueToEnum(type) {
            self.delegate?.coreDataManagerPersistentStoreCoordinatorStoresDidChangeWithTransitionType(enumType)
        }
    }
    
    func persistentStoreCoordinatorStoresWillChangeNotification(_ notification: Notification) {
        if let userInfo = (notification as NSNotification).userInfo, type = userInfo[NSPersistentStoreUbiquitousTransitionTypeKey] as? UInt, enumType = self.convertNSPersistentStoreUbiquitousTransitionTypeKeyValueToEnum(type) {
            self.delegate?.coreDataManagerPersistentStoreCoordinatorStoresWillChangeWithTransitionType(enumType)
        }
    }
    
    func persistentStoreDidImportUbiquitousContentChangesNotification(_ notification: Notification) {
        self.delegate?.coreDataManagerPersistentStoreDidImportUbiquitousContentChangesNotification(notification)
    }
    
    private func convertNSPersistentStoreUbiquitousTransitionTypeKeyValueToEnum(_ type: UInt) -> NSPersistentStoreUbiquitousTransitionType? {
        if type == NSPersistentStoreUbiquitousTransitionType.accountAdded.rawValue {
            return NSPersistentStoreUbiquitousTransitionType.accountAdded
        } else if type == NSPersistentStoreUbiquitousTransitionType.accountRemoved.rawValue {
            return NSPersistentStoreUbiquitousTransitionType.accountRemoved
        } else if type == NSPersistentStoreUbiquitousTransitionType.contentRemoved.rawValue {
            return NSPersistentStoreUbiquitousTransitionType.contentRemoved
        } else if type == NSPersistentStoreUbiquitousTransitionType.initialImportCompleted.rawValue {
            return NSPersistentStoreUbiquitousTransitionType.initialImportCompleted
        } else {
            return nil
        }
    }
    
    private func applicationDocumentDirectory() -> URL? {
        let fileManager = FileManager.default()
        if let actualAppGroup = self.appGroup {
            return fileManager.containerURLForSecurityApplicationGroupIdentifier(actualAppGroup)
        }
        let urlsForDir = fileManager.urlsForDirectory(FileManager.SearchPathDirectory.documentDirectory, inDomains: FileManager.SearchPathDomainMask.userDomainMask)
        return urlsForDir.first
    }
    
    private func createManagedObjectModel() throws -> NSManagedObjectModel {
        if (self.objectModel != nil) {
            return self.objectModel!
        }
        
        guard let modelURL = self.bundle.urlForResource(self.modelName, withExtension: "momd") else {
            throw CoreDataKitError.cannotFindObjectModel(name: self.modelName, bundle: self.bundle)
        }

        guard let managedObjectModel = NSManagedObjectModel(contentsOf: modelURL) else {
            throw CoreDataKitError.cannotCreateManagedModelObject(path: modelURL.absoluteString!)
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
        let documentDirectory: URL? = applicationDocumentDirectory()
        let storeURL: URL? = try! documentDirectory?.appendingPathComponent(storeFile)

        self.objectModel = try createManagedObjectModel()
        
        let storeCoordinator = NSPersistentStoreCoordinator(managedObjectModel: objectModel!)
        try storeCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: storeOptions)
        return storeCoordinator
    }
}
