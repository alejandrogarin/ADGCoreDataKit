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

import UIKit
import XCTest
import CoreData

class BaseTestCase: XCTestCase {

    var coreDataManager: CoreDataManager!
    var dataService: CoreDataService!
    
    override func setUp() {
        super.setUp()
        
        do {
            self.coreDataManager = try CoreDataManager(usingModelName: "TestModel", inBundle:NSBundle(forClass: BaseTestCase.self),  securityApplicationGroup: nil, enableCloud: false)
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
    
    func testTruncate() throws {
        try self.insertPlaylist("test");
        let count: Int = (try self.dataService.findObjectsByEntity("Playlist") as [NSManagedObject]).count;
        XCTAssertEqual(count, 1);
        try self.dataService.truncate("Playlist");
        let countAfterTruncate: Int = (try self.dataService.findObjectsByEntity("Playlist") as [NSManagedObject]).count;
        XCTAssertEqual(countAfterTruncate, 0);
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
