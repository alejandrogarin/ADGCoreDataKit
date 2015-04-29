//
//  RowTests.swift
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

import UIKit
import XCTest
import CoreData

class RowTests: BaseTestCase {
    
    var coreDataContext: CoreDataContext!

    override func setUp() {
        super.setUp()
        self.coreDataContext = CoreDataContext(usingPersistentStoreCoordinator: self.coreDataManager.persistentStoreCoordinator, concurrencyType: NSManagedObjectContextConcurrencyType.MainQueueConcurrencyType)
    }
    
    private func insertGenericoMO(name: String, order: Int?) -> NSManagedObject? {
        var map: [String: AnyObject] = ["name": name]
        if let order = order {
            map["order"] = order
        }
        var error: NSError? = nil
        let maybeMO: NSManagedObject? = self.dataAccess.insert(entityName: "Playlist", map: map, error: &error)
        XCTAssertNil(error, "\(error)")
        XCTAssertNotNil(maybeMO)
        return maybeMO
    }
    
    func testInsertGenericMO() {
        
        let maybeMO: NSManagedObject? = self.insertGenericoMO("play1", order: 0);
        if let mo = maybeMO {
            let dto: [String: Any] = self.dataAccess.managedObjectToDictionary(mo)
            XCTAssertNotNil(dto["name"] as? String)
        } else {
            XCTFail("Couldn't insert managed object correctly");
        }
    }
    
    func testUpdateGenericMO() {
        let maybeMO: NSManagedObject? = self.insertGenericoMO("play1", order: 0);
        if let mo = maybeMO {
            let result: Bool = self.dataAccess.update(managedObject: mo, map: ["order": 1], error: nil)
            XCTAssertTrue(result)
            let maybeUpdatedMO:NSManagedObject? = self.dataAccess.findObjectByManagedObjectId(moId: mo.objectID)
            if let updatedMO = maybeUpdatedMO {
                let dto: [String: Any] = self.dataAccess.managedObjectToDictionary(mo)
                XCTAssertNotNil(dto["order"] as? Int)
                XCTAssertEqual(dto["order"] as! Int, 1)
            } else {
                XCTFail("Couldn't update managed object correctly");
            }
        } else {
            XCTFail("Couldn't insert managed object correctly");
        }
    }
    
    func testFindAllGenericManagedObject() {
        
        let maybeMO: NSManagedObject? = self.insertGenericoMO("play1", order: 0);
        
        let list: [NSManagedObject] = self.dataAccess.findObjectsByEntity("Playlist")
        XCTAssertEqual(1, list.count)
        let object: NSManagedObject? = list.first
        if let object = object {
            let dto: [String:Any] = self.dataAccess.managedObjectToDictionary(object)
            XCTAssertEqual(dto["name"] as! String, "play1")
        }
    }
    
    func testFindAll() {
        for (var i:Int = 0; i < 100; i++) {
            self.insertPlaylist("play \(i)", order: i)
        }
        let array: [NSManagedObject] = self.coreDataContext.findObjectsByEntity("Playlist", sortKey: nil, predicate: nil, page: nil, pageSize: nil, error: nil)
        XCTAssertEqual(array.count, 100)
    }
    
    func testFindWithPredicate() {
        for (var i:Int = 0; i < 100; i++) {
            self.insertPlaylist("play \(i)", order: i)
        }
        let predicate = NSPredicate(format: "name CONTAINS %@", "play 2")
        let array: [NSManagedObject] = self.coreDataContext.findObjectsByEntity("Playlist", sortKey: nil, predicate: predicate, page: nil, pageSize: nil, error: nil)
        XCTAssertEqual(array.count, 11)
    }
    
    func testFindWithPaggingAndOrder() {
        for (var i:Int = 0; i < 100; i++) {
            self.insertPlaylist("play \(i)", order: i)
        }
        let arrayPage0: [NSManagedObject] = self.coreDataContext.findObjectsByEntity("Playlist", sortKey: "order", predicate: nil, page: 0, pageSize: 10, error: nil)
        let arrayPage1: [NSManagedObject] = self.coreDataContext.findObjectsByEntity("Playlist", sortKey: "order", predicate: nil, page: 1, pageSize: 10, error: nil)
        let arrayPage9: [NSManagedObject] = self.coreDataContext.findObjectsByEntity("Playlist", sortKey: "order", predicate: nil, page: 9, pageSize: 10, error: nil)
        let arrayPage10: [NSManagedObject] = self.coreDataContext.findObjectsByEntity("Playlist", sortKey: "order", predicate: nil, page: 10, pageSize: 10, error: nil)
        XCTAssertEqual(arrayPage0.count, 10)
        XCTAssertEqual(arrayPage1.count, 10)
        XCTAssertEqual(arrayPage9.count, 10)
        XCTAssertEqual(arrayPage10.count, 0)
        var object1: NSManagedObject = arrayPage0.first!
        var object10: NSManagedObject = arrayPage0.last!
        XCTAssertEqual(object1.valueForKey("name") as! String, "play 0")
        XCTAssertEqual(object10.valueForKey("name") as! String, "play 9")
        object1 = arrayPage1.first!
        object10 = arrayPage1.last!
        XCTAssertEqual(object1.valueForKey("name") as! String, "play 10")
        XCTAssertEqual(object10.valueForKey("name") as! String, "play 19")
        object1 = arrayPage9.first!
        object10 = arrayPage9.last!
        XCTAssertEqual(object1.valueForKey("name") as! String, "play 90")
        XCTAssertEqual(object10.valueForKey("name") as! String, "play 99")
    }
}
