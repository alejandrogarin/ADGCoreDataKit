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

class ModelTests: BaseTestCase {
    
//MARK: - Tests
    
    func testInsertPlaylist() {
        let playlist: Playlist = self.insertPlaylist("play1")
        if let name = playlist.name, order = playlist.order {
            XCTAssertEqual(name, "play1")
            XCTAssertEqual(order, 0)
            let result = self.dataAccess.delete(object: playlist)
            XCTAssertTrue(result)
        } else {
            XCTFail("Couldn't insert playlist correctly");
        }
    }

    func testUpdatePlaylist() {
        let playlist: Playlist = self.insertPlaylist("play1")
        let result = self.dataAccess.update(managedObject: playlist, map: ["name": "updated"], error: nil)
        let array: [Playlist] = self.dataAccess.findObjectsByEntity()
        XCTAssertEqual(array.count, 1)
        let updatedPlaylist:Playlist! = array.first
        XCTAssertEqual(updatedPlaylist.name!, "updated")
    }
    
    func testInsertAudio() {
        let audio: Audio = self.insertAudio("audio1", playlist: self.insertPlaylist("p1"))
        if let title = audio.title, audioPlaylist = audio.playlist {
            XCTAssertEqual(title, "audio1")
            XCTAssertNotNil(audioPlaylist)
        } else {
            XCTFail("Couldn't insert audio correctly");
        }
    }
    
    func testInsertAudioWithoutPlaylist() {
        let audio: Audio = self.insertAudio("audio1", playlist: nil)
        if let title = audio.title {
            XCTAssertEqual(title, "audio1")
            XCTAssertNil(audio.playlist)
        } else {
            XCTFail("Couldn't insert audio correctly");
        }
    }
    
    func testGetPlaylistUsingObjectIdString() {
        let playlist: Playlist = self.insertPlaylist("play1")
        let objectId = self.dataAccess.stringObjectId(fromMO: playlist)
        if let objectId = objectId {
            let retrived: Playlist? = self.dataAccess.findObjectById(objectId: objectId)
            if let retrieved = retrived, name = retrieved.name {
                XCTAssertEqual(name, "play1")
            } else {
                XCTFail("Playlist object is invalid");
            }
        } else {
            XCTFail("Playlist object id not found");
        }
    }
    
    func testGetPlaylistUsingManagedObjectId() {
        let playlist: Playlist = self.insertPlaylist("play1")
        let retrived: Playlist? = self.dataAccess.findObjectByManagedObjectId(moId: playlist.objectID)
        if let retrieved = retrived, name = retrieved.name {
            XCTAssertEqual(name, "play1")
        } else {
            XCTFail("Playlist object is invalid");
        }
    }
    
    func testFindAllPlaylists() {
        for (var i = 0; i < 100; i++) {
            self.insertPlaylist("play \(i)")
        }
        let result:[Playlist] = self.dataAccess.findObjectsByEntity()
        XCTAssertEqual(result.count, 100)
    }
}
