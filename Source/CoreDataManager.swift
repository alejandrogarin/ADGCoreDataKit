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

public protocol CoreDataManagerDelegate {
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
    
    public var delegate : CoreDataManagerDelegate?

    public var persistentStoreCoordinator : NSPersistentStoreCoordinator {
        return self.storeCoordinator!
    }
    
    public init?(usingModelName modelName: String, inBundle bundle: NSBundle?, securityApplicationGroup appGroup : String?, enableCloud : Bool, error: NSErrorPointer) {
        self.modelName = modelName;
        self.appGroup = appGroup;
        self.icloud = enableCloud;
        self.bundle = bundle;
        super.init();
        
        self.storeCoordinator = self.createPersistentStoreCoordinator(error);
        if (self.storeCoordinator == nil) {
            return nil;
        }
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "persistentStoreCoordinatorStoresDidChangeNotification:", name: NSPersistentStoreCoordinatorStoresDidChangeNotification, object: self.storeCoordinator)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "persistentStoreCoordinatorStoresWillChangeNotification:", name: NSPersistentStoreCoordinatorStoresWillChangeNotification, object: self.storeCoordinator)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "persistentStoreDidImportUbiquitousContentChangesNotification:", name: NSPersistentStoreDidImportUbiquitousContentChangesNotification, object: self.storeCoordinator)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NSPersistentStoreCoordinatorStoresDidChangeNotification, object: self.storeCoordinator)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NSPersistentStoreCoordinatorStoresWillChangeNotification, object: self.storeCoordinator)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NSPersistentStoreDidImportUbiquitousContentChangesNotification, object: self.storeCoordinator)
    }
    
    public convenience init?(usingModelName modelName: String, securityApplicationGroup appGroup : String?, enableCloud : Bool, error: NSErrorPointer) {
        self.init(usingModelName: modelName, inBundle: nil, securityApplicationGroup:appGroup, enableCloud:enableCloud, error: error);
    }
    
    public convenience init?(usingModelName modelName: String, error: NSErrorPointer) {
        self.init(usingModelName: modelName, securityApplicationGroup:nil, enableCloud:false, error: error);
    }
    
    public convenience init?(usingModelName modelName: String, enableCloud : Bool, error: NSErrorPointer) {
        self.init(usingModelName: modelName, securityApplicationGroup:nil, enableCloud:enableCloud, error: error);
    }
    
    private func createCoreDataError(#code: Int, failureReason: String) -> NSError {
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
        NSLog("%@:%@", toString(self), __FUNCTION__)
        if let userInfo = notification.userInfo, type = userInfo[NSPersistentStoreUbiquitousTransitionTypeKey] as? UInt, enumType = self.convertNSPersistentStoreUbiquitousTransitionTypeKeyValueToEnum(type) {
            self.delegate?.coreDataManagerPersistentStoreCoordinatorStoresDidChangeWithTransitionType(enumType)
        }
    }
    
    func persistentStoreCoordinatorStoresWillChangeNotification(notification: NSNotification) {
        NSLog("%@:%@", toString(self), __FUNCTION__)
        if let userInfo = notification.userInfo, type = userInfo[NSPersistentStoreUbiquitousTransitionTypeKey] as? UInt, enumType = self.convertNSPersistentStoreUbiquitousTransitionTypeKeyValueToEnum(type) {
            self.delegate?.coreDataManagerPersistentStoreCoordinatorStoresWillChangeWithTransitionType(enumType)
        }
    }
    
    func persistentStoreDidImportUbiquitousContentChangesNotification(notification: NSNotification) {
        NSLog("%@:%@", toString(self), __FUNCTION__)
        self.delegate?.coreDataManagerPersistentStoreDidImportUbiquitousContentChangesNotification(notification)
    }
    
    private func applicationDocumentDirectory() -> NSURL? {
        var fileManager = NSFileManager.defaultManager();
        if let actualAppGroup = self.appGroup {
            return fileManager.containerURLForSecurityApplicationGroupIdentifier(actualAppGroup);
        }
        let urlsForDir = fileManager.URLsForDirectory(NSSearchPathDirectory.DocumentDirectory, inDomains: NSSearchPathDomainMask.UserDomainMask);
        return urlsForDir.first as? NSURL;
    }
    
    private func createManagedObjectModel(error : NSErrorPointer) -> NSManagedObjectModel? {
        
        if (self.objectModel != nil) {
            return self.objectModel;
        }
        
        var maybeURL: NSURL? = nil
        if let bundle = self.bundle {
            maybeURL = bundle.URLForResource(self.modelName, withExtension: "momd");
        } else {
            maybeURL = NSBundle.mainBundle().URLForResource(self.modelName, withExtension: "momd");
        }
        
        if let url = maybeURL {
            return NSManagedObjectModel(contentsOfURL: url);
        } else {
            if (error != nil) {
                error.memory = createCoreDataError(code: 100, failureReason: "Could not find the path for your data model: \(self.modelName)");
            }
            return nil;
        }
    }
    
    private func createPersistentStoreCoordinator(error : NSErrorPointer) -> NSPersistentStoreCoordinator? {

        var storeOptions: [NSObject : AnyObject]? = nil
        if (self.icloud) {
            NSLog("%@:%@ - creating an iCloud enabled persistent store", toString(self), __FUNCTION__)
            storeOptions = [NSPersistentStoreUbiquitousContentNameKey:"container_\(self.modelName)", NSMigratePersistentStoresAutomaticallyOption:true, NSInferMappingModelAutomaticallyOption:true];
        } else {
            storeOptions = [NSMigratePersistentStoresAutomaticallyOption:true, NSInferMappingModelAutomaticallyOption:true];
        }
        let storeFile: String = self.modelName + ".sqlite";
        let documentDirectory: NSURL? = applicationDocumentDirectory();
        let storeURL: NSURL? = documentDirectory?.URLByAppendingPathComponent(storeFile);
        
        if (storeURL == nil) {
            if (error != nil) {
                error.memory = createCoreDataError(code: 101, failureReason: "Cannot create an SQL store with a nil URL.");
            }
            return nil;
        }
        
        objectModel = createManagedObjectModel(error);
        if (objectModel == nil) {
            return nil;
        }
        
        let storeCoordinator = NSPersistentStoreCoordinator(managedObjectModel: objectModel!);
        
        var coordinatorError: NSError? = nil
        let store = storeCoordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: storeURL, options: storeOptions, error: &coordinatorError);
        if (store != nil) {
            return storeCoordinator;
        } else {
            if (error != nil) {
                error.memory = coordinatorError;
            }
            return nil;
        }
    }
}
