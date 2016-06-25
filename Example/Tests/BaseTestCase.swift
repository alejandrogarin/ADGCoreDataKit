//
//  BaseTestCase.swift
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

import XCTest
import ADGCoreDataKit
import CoreData

enum CoreDataKitKeys: String {
    case ObjectId = "_core_data_object_id"
}

class BaseTestCase: XCTestCase {
    
    var audioDAO: CoreDataGenericDAO<Audio>!
    var playlistDAO: CoreDataGenericDAO<Playlist>!
    var coreDataManager: CoreDataManager!
    var coreDataContext: CoreDataContext!
    
    override func setUp() {
        super.setUp()
        
        do {
            self.coreDataManager = CoreDataManager(usingModelName: "TestModel", inBundle:Bundle(for: BaseTestCase.self), useInMemoryStore: true)
            try self.coreDataManager.setupCoreDataStack()
            self.coreDataContext = self.coreDataManager.makeContext(associateWithMainQueue: true)
            
            self.audioDAO = CoreDataGenericDAO<Audio>(usingContext: self.coreDataContext, forEntityName: "Audio")
            self.playlistDAO = CoreDataGenericDAO<Playlist>(usingContext: self.coreDataContext, forEntityName: "Playlist")
        } catch let error as NSError {
            XCTFail("\(error)")
        }
    }
    
    override func tearDown() {
        super.tearDown()
        do {
            try self.coreDataManager.shutdownCoreDataStack()
        } catch let error as NSError {
            XCTFail("\(error)")
        }
    }
    
    func tryTest(_ f: @noescape() throws -> Void) {
        do {
            try f()
        } catch let error as NSError {
            XCTFail("\(error)")            
        }
    }
    
    func testTruncate() {
        tryTest {
            let _ = try self.insertPlaylist("test");
            let count: Int = (try self.playlistDAO.find()).count;
            XCTAssertEqual(count, 1);
            try self.playlistDAO.truncate()
            let countAfterTruncate: Int = (try self.playlistDAO.find()).count;
            XCTAssertEqual(countAfterTruncate, 0);
        }
    }
    
    func insertPlaylist(_ name: String?) throws -> Playlist {
        return try self.insertPlaylist(name, order: nil)
    }
    
    func insertPlaylist(_ name: String?, order: Int?) throws -> Playlist {
        var map: [String: AnyObject?] = ["name": name]
        map["order"] = order
        map["lastplayed"] = nil
        let playlist: Playlist = try self.playlistDAO.insert(withMap: map)
        XCTAssertNotNil(playlist)
        return playlist;
    }
    
    func insertAudio(_ title: String, playlist: Playlist?) throws -> Audio {
        var map: [String: AnyObject] = ["title": title]
        if let playlist = playlist {
            map["playlist"] = playlist
        }
        let audio: Audio = try self.audioDAO.insert(withMap: map)
        XCTAssertNotNil(audio)
        return audio;
    }
    
    func stringObjectId(fromMO mo: NSManagedObject) -> String {
        let objectId : NSManagedObjectID = mo.objectID
        let url = objectId.uriRepresentation()
        let absURL = url.absoluteString
        return absURL!;
    }
    
    func managedObjectsToDictionary(_ managedObjects: [NSManagedObject], keys:[String]) -> [[String:Any]] {
        var result:[[String:Any]] = []
        for object in managedObjects {
            var dtoMap: [String: Any] = [:]
            for key in keys {
                if let value:AnyObject = object.value(forKey: key) {
                    dtoMap[key] = value
                }
            }
            dtoMap[CoreDataKitKeys.ObjectId.rawValue] = self.stringObjectId(fromMO: object)
            result.append(dtoMap)
        }
        return result
    }
    
    func managedObjectToDictionary(_ managedObject: NSManagedObject, keys:[String]) -> [String:Any] {
        if let result = self.managedObjectsToDictionary([managedObject], keys: keys).first {
            return result
        } else {
            return [:]
        }
    }
    
    func managedObjectsToDictionary(_ managedObjects: [NSManagedObject]) -> [[String:Any]] {
        var result:[[String:Any]] = []
        for object in managedObjects {
            var dtoMap: [String: Any] = [:]
            let valuesForKey = object.committedValues(forKeys: nil)
            for key in valuesForKey.keys {
                if let value:AnyObject = object.value(forKey: key) {
                    dtoMap[key] = value
                }
            }
            dtoMap[CoreDataKitKeys.ObjectId.rawValue] = self.stringObjectId(fromMO: object)
            result.append(dtoMap)
        }
        return result
    }
    
    func managedObjectToDictionary(_ managedObject: NSManagedObject) -> [String:Any] {
        if let result = self.managedObjectsToDictionary([managedObject]).first {
            return result
        } else {
            return [:]
        }
    }

}
