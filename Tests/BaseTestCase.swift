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
    var dataAccess: CoreDataAccessImpl!
    
    override func setUp() {
        super.setUp()
        
        var error: NSError? = nil
        self.coreDataManager = CoreDataManager(usingModelName: "TestModel", inBundle:NSBundle(forClass: BaseTestCase.self),  securityApplicationGroup: nil, enableCloud: false, error: &error)
        XCTAssertNotNil(self.coreDataManager, "\(error)");
        self.dataAccess = CoreDataAccessImpl(usingCoreDataManager: self.coreDataManager, concurrencyType: NSManagedObjectContextConcurrencyType.MainQueueConcurrencyType);
    }
    
    override func tearDown() {
        super.tearDown()
        
        let playlists:[Playlist] = self.dataAccess.findObjectsByEntity()
        for (var i = 0; i < playlists.count; i++) {
            self.dataAccess.delete(object: playlists[i])
        }
        let audios:[Audio] = self.dataAccess.findObjectsByEntity()
        for (var i = 0; i < audios.count; i++) {
            self.dataAccess.delete(object: audios[i])
        }
    }

    func insertPlaylist(name: String) -> Playlist {
        return self.insertPlaylist(name, order: nil)
    }
    
    func insertPlaylist(name: String, order: Int?) -> Playlist {
        var map: [String: AnyObject] = ["name": name]
        if let order = order {
            map["order"] = order
        }
        var error: NSError? = nil
        let playlist: Playlist? = self.dataAccess.insert(map: map, error: &error)
        XCTAssertNil(error, "\(error)")
        XCTAssertNotNil(playlist)
        return playlist!;
    }
    
    func insertAudio(title: String, playlist: Playlist?) -> Audio {
        var error: NSError? = nil
        var map: [String: AnyObject] = ["title": title]
        if let playlist = playlist {
            map["playlist"] = playlist
        }
        let audio: Audio? = self.dataAccess.insert(map: map, error: &error)
        XCTAssertNil(error, "\(error)")
        XCTAssertNotNil(audio)
        return audio!;
    }
}
