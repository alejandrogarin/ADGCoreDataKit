//
//  ModelTests.swift
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
import ADGCoreDataKit

class ModelTests: BaseTestCase {
        
    override func setUp() {
        super.setUp()
    }
    
    func testInsertPlaylist() {
        tryTest {
            let playlist: Playlist = try self.insertPlaylist("play1")
            if let name = playlist.name, let order = playlist.order {
                XCTAssertEqual(name, "play1")
                XCTAssertEqual(order, 0)
                try self.playlistDAO.delete(managedObject: playlist)
                XCTAssert(true)
            } else {
                XCTFail("Couldn't insert playlist correctly");
            }
        }
    }
    
    func testInsert_WithNull() {
        tryTest {
            let playlist: Playlist = try self.insertPlaylist(nil)
            let name = playlist.name, order = playlist.order
            XCTAssertNil(name)
            XCTAssertEqual(order, 0)
            try self.playlistDAO.delete(managedObject: playlist)
            XCTAssert(true)
        }
    }
    
    func testUpdatePlaylist() {
        tryTest {
            let playlist: Playlist = try self.insertPlaylist("play1")
            playlist.name = "updated"
            try self.playlistDAO.commit()
            let array: [Playlist] = try self.playlistDAO.find()
            XCTAssertEqual(array.count, 1)
            let updatedPlaylist:Playlist! = array.first
            XCTAssertEqual(updatedPlaylist.name!, "updated")
        }
    }
    
    func testUpdatePlaylist_WithNullInProperty() {
        tryTest {
            let playlist: Playlist = try self.insertPlaylist("play1")
            playlist.name = nil
            try self.playlistDAO.commit()
            let array: [Playlist] = try self.playlistDAO.find()
            XCTAssertEqual(array.count, 1)
            let updatedPlaylist:Playlist! = array.first
            XCTAssertNil(updatedPlaylist.name)
        }
    }
    
    func testInsertAudio() {
        tryTest {
            let audio: Audio = try self.insertAudio("audio1", playlist: self.insertPlaylist("p1"))
            if let title = audio.title, let audioPlaylist = audio.playlist {
                XCTAssertEqual(title, "audio1")
                XCTAssertNotNil(audioPlaylist)
            } else {
                XCTFail("Couldn't insert audio correctly");
            }
        }
    }
    
    func testInsertAudioWithoutPlaylist() {
        tryTest {
            let audio: Audio = try self.insertAudio("audio1", playlist: nil)
            if let title = audio.title {
                XCTAssertEqual(title, "audio1")
                XCTAssertNil(audio.playlist)
            } else {
                XCTFail("Couldn't insert audio correctly");
            }
        }
    }
    
    func testFetch_UsingStringObjectId() {
        tryTest {
            let playlist: Playlist = try self.insertPlaylist("play1")
            let objectId = self.stringObjectId(fromMO: playlist)
            let retrieved: Playlist = try self.playlistDAO.fetch(byId: objectId)
            if let name = retrieved.name {
                XCTAssertEqual(name, "play1")
            } else {
                XCTFail("Playlist object is invalid");
            }
        }
    }
    
    func testFetch_UsingManagedObjectId() {
        tryTest {
            let playlist: Playlist = try self.insertPlaylist("play1")
            let retrived: Playlist = try self.playlistDAO.fetch(byManagedObjectId: playlist.objectID)
            if let name = retrived.name {
                XCTAssertEqual(name, "play1")
            } else {
                XCTFail("Playlist object is invalid");
            }
        }
    }
    
    func testFind() {
        tryTest {
            for i in 0..<100 {
                let _ = try self.insertPlaylist("play \(i)")
            }
            let result:[Playlist] = try self.playlistDAO.find()
            XCTAssertEqual(result.count, 100)
        }
    }
    
    func testCount() {
        tryTest {
            for i in 0..<100 {
                let _ = try self.insertPlaylist("play \(i)")
            }
            XCTAssertEqual(try self.playlistDAO.count(), 100)
        }
    }
    
    func testCount_WithPredicate() {
        tryTest {
            for i in 0..<100 {
                let _ = try self.insertPlaylist("play \(i)")
            }
            let predicate = NSPredicate(format: "name == %@", "play 1")
            XCTAssertEqual(try self.playlistDAO.count(withPredicate: predicate), 1)
        }
    }
    
    func testDelete_UsingManagedObject() {
        tryTest { 
            let playlist = try self.insertPlaylist("playlist")
            XCTAssertEqual(try self.playlistDAO.find().count, 1)
            try self.playlistDAO.delete(managedObject: playlist)
            XCTAssertEqual(try self.playlistDAO.find().count, 0)
        }
    }
    
    func testDelete_UsingStringObjectId() {
        tryTest {
            let playlist = try self.insertPlaylist("playlist")
            XCTAssertEqual(try self.playlistDAO.find().count, 1)
            let objectId = self.stringObjectId(fromMO: playlist)
            try self.playlistDAO.delete(byId: objectId)
            XCTAssertEqual(try self.playlistDAO.find().count, 0)
        }
    }
    
    func testOperationWithManualCommit() {
        tryTest { 
            self.playlistDAO.autocommit = false
            let _ = self.playlistDAO.create()
            self.playlistDAO.rollback()
            XCTAssertEqual(try self.playlistDAO.count(), 0)
        }
    }
    
    func testFind_Transformed() {
        tryTest {
            
            struct PlaylistDAO {
                var name: String
            }
            
            let _ = try self.insertPlaylist("playlist1")
            let _ = try self.insertPlaylist("playlist2")
            let result = try self.playlistDAO.findTransformed(transformationHandler: { (entity: Playlist) -> PlaylistDAO in
                return PlaylistDAO(name: entity.name!)
            })
            
            XCTAssertEqual(result[0].name, "playlist1")
            XCTAssertEqual(result[1].name, "playlist2")
        }
    }
    
    func testFindAllPlaylists() {
        tryTest {
            for i in 0 ..< 100 {
                let _ = try self.insertPlaylist("play \(i)", order: i)
            }
            let array: [AnyObject] = try self.coreDataContext.find(entityName: "Playlist")
            XCTAssertEqual(array.count, 100)
        }
    }
    
    func testFindPlaylistWithPredicate() {
        tryTest {
            for i in 0 ..< 100 {
                let _ = try self.insertPlaylist("play \(i)", order: i)
            }
            let predicate = NSPredicate(format: "name CONTAINS %@", "play 2")
            let array: [AnyObject] = try self.coreDataContext.find(entityName: "Playlist", predicate: predicate)
            XCTAssertEqual(array.count, 11)
        }
    }
    
    func testFindPlaylistWithPaggingAndOrder() {
        tryTest {
            for i in 0 ..< 100 {
                let _ = try self.insertPlaylist("play \(i)", order: i)
            }
            
            let descriptor = [NSSortDescriptor(key: "order", ascending: true)]
            
            let arrayPage0: [AnyObject] = try self.coreDataContext.find(entityName: "Playlist", predicate: nil, sortDescriptors: descriptor, page: 0, pageSize: 10)
            let arrayPage1: [AnyObject] = try self.coreDataContext.find(entityName: "Playlist", predicate: nil, sortDescriptors: descriptor, page: 1, pageSize: 10)
            let arrayPage9: [AnyObject] = try self.coreDataContext.find(entityName: "Playlist", predicate: nil, sortDescriptors: descriptor, page: 9, pageSize: 10)
            let arrayPage10: [AnyObject] = try self.coreDataContext.find(entityName: "Playlist", predicate: nil, sortDescriptors: descriptor, page: 10, pageSize: 10)
            XCTAssertEqual(arrayPage0.count, 10)
            XCTAssertEqual(arrayPage1.count, 10)
            XCTAssertEqual(arrayPage9.count, 10)
            XCTAssertEqual(arrayPage10.count, 0)
            var object1: NSManagedObject = arrayPage0.first! as! NSManagedObject
            var object10: NSManagedObject = arrayPage0.last! as! NSManagedObject
            XCTAssertEqual((object1.value(forKey: "name") as? String)!, "play 0")
            XCTAssertEqual((object10.value(forKey: "name") as? String)!, "play 9")
            object1 = arrayPage1.first! as! NSManagedObject
            object10 = arrayPage1.last! as! NSManagedObject
            XCTAssertEqual((object1.value(forKey: "name") as? String)!, "play 10")
            XCTAssertEqual((object10.value(forKey: "name") as? String)!, "play 19")
            object1 = arrayPage9.first! as! NSManagedObject
            object10 = arrayPage9.last! as! NSManagedObject
            XCTAssertEqual((object1.value(forKey: "name") as? String)!, "play 90")
            XCTAssertEqual((object10.value(forKey: "name") as? String)!, "play 99")
        }
    }    
    
}
