//
//  Common.swift
//  ADGCoreDataKit
//
//  Created by Alejandro Diego Garin on 7/23/15.
//  Copyright © 2015 CocoaPods. All rights reserved.
//

import XCTest
import ADGCoreDataKit
import CoreData

class Common: XCTestCase {
    
    var coreDataManager: CoreDataManager!
    var dataService: CoreDataService!
    
    override func setUp() {
        super.setUp()
        
        do {
            self.coreDataManager = try CoreDataManager(usingModelName: "TestModel", inBundle:NSBundle(forClass: Common.self),  securityApplicationGroup: nil, enableCloud: false)
            self.dataService = CoreDataService(usingCoreDataManager: self.coreDataManager, concurrencyType: NSManagedObjectContextConcurrencyType.MainQueueConcurrencyType);
            try self.dataService.truncate("Playlist")
            try self.dataService.truncate("Audio")
        } catch let error as NSError {
            XCTFail("\(error)")
        }
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testTruncate() {
        
        do {
            try self.insertPlaylist("test");
            let count: Int = (try self.dataService.findObjectsByEntity("Playlist") as [NSManagedObject]).count;
            XCTAssertEqual(count, 1);
            try self.dataService.truncate("Playlist");
            let countAfterTruncate: Int = (try self.dataService.findObjectsByEntity("Playlist") as [NSManagedObject]).count;
            XCTAssertEqual(countAfterTruncate, 0);
        } catch  {
            XCTFail()
        }
    }
    
    func insertPlaylist(name: String) throws -> Playlist {
        return try self.insertPlaylist(name, order: nil)
    }
    
    func insertPlaylist(name: String, order: Int?) throws -> Playlist {
        var map: [String: AnyObject] = ["name": name]
        if let order = order {
            map["order"] = order
        }
        let playlist: Playlist = try self.dataService.insert(map: map)
        XCTAssertNotNil(playlist)
        return playlist;
    }
    
    func insertAudio(title: String, playlist: Playlist?) throws -> Audio {
        var map: [String: AnyObject] = ["title": title]
        if let playlist = playlist {
            map["playlist"] = playlist
        }
        let audio: Audio = try self.dataService.insert(map: map)
        XCTAssertNotNil(audio)
        return audio;
    }

}
