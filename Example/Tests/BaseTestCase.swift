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
    
    var audioDAO: CoreDataDAO<Audio>!
    var playlistDAO: CoreDataDAO<Playlist>!
    var coreDataManager: CoreDataManager!
    var coreDataContext: CoreDataContext!
    
    override func setUp() {
        super.setUp()
        
        do {
            self.coreDataManager = CoreDataManager(usingModelName: "TestModel", inBundle:NSBundle(forClass: BaseTestCase.self))
            try self.coreDataManager.setupCoreDataStack()
            self.coreDataContext = self.coreDataManager.makeContext(associateWithMainQueue: true)
            
            self.audioDAO = CoreDataDAO<Audio>(usingContext: self.coreDataContext)
            self.playlistDAO = CoreDataDAO<Playlist>(usingContext: self.coreDataContext)
            
            try self.playlistDAO.truncate("Playlist")
            try self.audioDAO.truncate("Audio")
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
    
    func testTruncate() {
        do {
            try self.insertPlaylist("test");
            let count: Int = (try self.playlistDAO.findObjectsByEntity("Playlist") as [NSManagedObject]).count;
            XCTAssertEqual(count, 1);
            try self.playlistDAO.truncate("Playlist");
            let countAfterTruncate: Int = (try self.playlistDAO.findObjectsByEntity("Playlist") as [NSManagedObject]).count;
            XCTAssertEqual(countAfterTruncate, 0);
        } catch {
            XCTFail()
        }
    }
    
    func insertPlaylist(name: String) throws -> Playlist {
        return try self.insertPlaylist(name, order: nil)
    }
    
    func insertPlaylist(name: String, order: Int?) throws -> Playlist {
        var map: [String: AnyObject] = ["name": name]
        map["order"] = order
        let playlist: Playlist = try self.playlistDAO.insert(map: map)
        XCTAssertNotNil(playlist)
        return playlist;
    }
    
    func insertAudio(title: String, playlist: Playlist?) throws -> Audio {
        var map: [String: AnyObject] = ["title": title]
        if let playlist = playlist {
            map["playlist"] = playlist
        }
        let audio: Audio = try self.audioDAO.insert(map: map)
        XCTAssertNotNil(audio)
        return audio;
    }
    
    func managedObjectsToDictionary(managedObjects: [NSManagedObject], keys:[String]) -> [[String:Any]] {
        var result:[[String:Any]] = []
        for object in managedObjects {
            var dtoMap: [String: Any] = [:]
            for key in keys {
                if let value:AnyObject = object.valueForKey(key) {
                    dtoMap[key] = value
                }
            }
            dtoMap[CoreDataKitKeys.ObjectId.rawValue] = CoreDataDAO.stringObjectId(fromMO: object)
            result.append(dtoMap)
        }
        return result
    }
    
    func managedObjectToDictionary(managedObject: NSManagedObject, keys:[String]) -> [String:Any] {
        if let result = self.managedObjectsToDictionary([managedObject], keys: keys).first {
            return result
        } else {
            return [:]
        }
    }
    
    func managedObjectsToDictionary(managedObjects: [NSManagedObject]) -> [[String:Any]] {
        var result:[[String:Any]] = []
        for object in managedObjects {
            var dtoMap: [String: Any] = [:]
            let valuesForKey = object.committedValuesForKeys(nil)
            for key in valuesForKey.keys {
                if let value:AnyObject = object.valueForKey(key) {
                    dtoMap[key] = value
                }
            }
            dtoMap[CoreDataKitKeys.ObjectId.rawValue] = CoreDataDAO.stringObjectId(fromMO: object)
            result.append(dtoMap)
        }
        return result
    }
    
    func managedObjectToDictionary(managedObject: NSManagedObject) -> [String:Any] {
        if let result = self.managedObjectsToDictionary([managedObject]).first {
            return result
        } else {
            return [:]
        }
    }

}
