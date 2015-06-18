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

public struct CoreDataKitConstants {
    static let CORE_DATA_OBJECT_ID = "_core_data_object_id"
}

//TODO: improve names
public enum CoreDataKitError: ErrorType {
    case NoStore
    case CannotCreateObject
    case ObjectNotFound
    case InvalidCast
}

public protocol CoreDataManagerDelegate: class {
    func coreDataManagerPersistentStoreDidImportUbiquitousContentChangesNotification(notification: NSNotification)
    func coreDataManagerPersistentStoreCoordinatorStoresDidChangeWithTransitionType(transition: NSPersistentStoreUbiquitousTransitionType)
    func coreDataManagerPersistentStoreCoordinatorStoresWillChangeWithTransitionType(transition: NSPersistentStoreUbiquitousTransitionType)
}

public class CoreDataManager: NSObject {

    private var storeCoordinator : NSPersistentStoreCoordinator?
    
    let modelName : String
    let icloud : Bool
    let appGroup: String?
    let bundle: NSBundle?

    var objectModel : NSManagedObjectModel?
    
    public weak var delegate : CoreDataManagerDelegate?

    public var persistentStoreCoordinator : NSPersistentStoreCoordinator {
        return self.storeCoordinator!
    }
    
    public init(usingModelName modelName: String, inBundle bundle: NSBundle?, securityApplicationGroup appGroup : String?, enableCloud : Bool) throws {
        self.modelName = modelName;
        self.appGroup = appGroup;
        self.icloud = enableCloud;
        self.bundle = bundle;
        super.init();
        
        self.storeCoordinator = try self.createPersistentStoreCoordinator()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "persistentStoreCoordinatorStoresDidChangeNotification:", name: NSPersistentStoreCoordinatorStoresDidChangeNotification, object: self.storeCoordinator)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "persistentStoreCoordinatorStoresWillChangeNotification:", name: NSPersistentStoreCoordinatorStoresWillChangeNotification, object: self.storeCoordinator)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "persistentStoreDidImportUbiquitousContentChangesNotification:", name: NSPersistentStoreDidImportUbiquitousContentChangesNotification, object: self.storeCoordinator)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NSPersistentStoreCoordinatorStoresDidChangeNotification, object: self.storeCoordinator)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NSPersistentStoreCoordinatorStoresWillChangeNotification, object: self.storeCoordinator)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NSPersistentStoreDidImportUbiquitousContentChangesNotification, object: self.storeCoordinator)
    }
    
    public convenience init(usingModelName modelName: String, securityApplicationGroup appGroup : String?, enableCloud : Bool) throws {
        try self.init(usingModelName: modelName, inBundle: nil, securityApplicationGroup:appGroup, enableCloud:enableCloud);
    }
    
    public convenience init(usingModelName modelName: String) throws {
        try self.init(usingModelName: modelName, securityApplicationGroup:nil, enableCloud:false);
    }
    
    public convenience init(usingModelName modelName: String, enableCloud : Bool) throws {
        try self.init(usingModelName: modelName, securityApplicationGroup:nil, enableCloud:enableCloud);
    }
    
    private func createCoreDataError(code code: Int, failureReason: String) -> NSError {
        let dict:[String:String] = [NSLocalizedFailureReasonErrorKey:failureReason]
        return  NSError(domain: "CORE_DATA_MANAGER", code: code, userInfo: dict)
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
    
    func persistentStoreCoordinatorStoresDidChangeNotification(notification: NSNotification) {
        NSLog("%@:%@", String(self), __FUNCTION__)
        if let userInfo = notification.userInfo, type = userInfo[NSPersistentStoreUbiquitousTransitionTypeKey] as? UInt, enumType = self.convertNSPersistentStoreUbiquitousTransitionTypeKeyValueToEnum(type) {
            self.delegate?.coreDataManagerPersistentStoreCoordinatorStoresDidChangeWithTransitionType(enumType)
        }
    }
    
    func persistentStoreCoordinatorStoresWillChangeNotification(notification: NSNotification) {
        NSLog("%@:%@", String(self), __FUNCTION__)
        if let userInfo = notification.userInfo, type = userInfo[NSPersistentStoreUbiquitousTransitionTypeKey] as? UInt, enumType = self.convertNSPersistentStoreUbiquitousTransitionTypeKeyValueToEnum(type) {
            self.delegate?.coreDataManagerPersistentStoreCoordinatorStoresWillChangeWithTransitionType(enumType)
        }
    }
    
    func persistentStoreDidImportUbiquitousContentChangesNotification(notification: NSNotification) {
        NSLog("%@:%@", String(self), __FUNCTION__)
        self.delegate?.coreDataManagerPersistentStoreDidImportUbiquitousContentChangesNotification(notification)
    }
    
    private func applicationDocumentDirectory() -> NSURL? {
        let fileManager = NSFileManager.defaultManager();
        if let actualAppGroup = self.appGroup {
            return fileManager.containerURLForSecurityApplicationGroupIdentifier(actualAppGroup);
        }
        let urlsForDir = fileManager.URLsForDirectory(NSSearchPathDirectory.DocumentDirectory, inDomains: NSSearchPathDomainMask.UserDomainMask);
        return urlsForDir.first
    }
    
    private func createManagedObjectModel() throws -> NSManagedObjectModel {
        var error: NSError! = NSError(domain: "Migrator", code: 0, userInfo: nil)
        
        if (self.objectModel != nil) {
            if let value = self.objectModel {
                return value
            }
            throw error;
        }
        
        var maybeURL: NSURL? = nil
        if let bundle = self.bundle {
            maybeURL = bundle.URLForResource(self.modelName, withExtension: "momd");
        } else {
            maybeURL = NSBundle.mainBundle().URLForResource(self.modelName, withExtension: "momd");
        }
        
        if let url = maybeURL {
            if let value = NSManagedObjectModel(contentsOfURL: url) {
                return value
            }
            throw error;
        } else {
            if (true) {
                error = createCoreDataError(code: 100, failureReason: "Could not find the path for your data model: \(self.modelName)");
            }
            throw error;
        }
    }
    
    private func createPersistentStoreCoordinator() throws -> NSPersistentStoreCoordinator {

        var storeOptions: [NSObject : AnyObject]? = nil
        if (self.icloud) {
            NSLog("%@:%@ - creating an iCloud enabled persistent store", String(self), __FUNCTION__)
            storeOptions = [NSPersistentStoreUbiquitousContentNameKey:"container_\(self.modelName)", NSMigratePersistentStoresAutomaticallyOption:true, NSInferMappingModelAutomaticallyOption:true];
        } else {
            storeOptions = [NSMigratePersistentStoresAutomaticallyOption:true, NSInferMappingModelAutomaticallyOption:true];
        }
        let storeFile: String = self.modelName + ".sqlite";
        let documentDirectory: NSURL? = applicationDocumentDirectory();
        let storeURL: NSURL? = documentDirectory?.URLByAppendingPathComponent(storeFile);
        
        if (storeURL == nil) {
            throw CoreDataKitError.NoStore
        }
        
        objectModel = try createManagedObjectModel()
        
        let storeCoordinator = NSPersistentStoreCoordinator(managedObjectModel: objectModel!);
        try storeCoordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: storeURL, options: storeOptions)
        return storeCoordinator
    }
}
