//
//  BaseObjTestCase.m
//  ADGCoreDataKit
//
//  Created by Alejandro Garin on 6/23/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ADGCoreDataKit-swift.h"

@interface BaseObjTestCase : XCTestCase
@property (strong, nonatomic) CoreDataManager *coreDataManager;
@property (strong, nonatomic) CoreDataManagedObjectDAO *playlistDAO;
@end

@implementation BaseObjTestCase

- (void)setUp {
    [super setUp];
    self.coreDataManager = [[CoreDataManager alloc] initUsingModelName:@"TestModel" sqlFileName:nil inBundle:[NSBundle bundleForClass:[self class]] securityApplicationGroup:nil enableCloud:NO useInMemoryStore:YES];
    
    NSError *error = nil;
    BOOL result = [self.coreDataManager setupCoreDataStackAndReturnError:&error];
    if (result) {
        CoreDataContext *context = [self.coreDataManager makeContextWithAssociateWithMainQueue:YES];
        self.playlistDAO = [[CoreDataManagedObjectDAO alloc] initUsingContext:context forEntityName:@"Playlist"];
    } else {
        XCTFail(@"Error: %@", error);
    }
}

- (void)tearDown {
    [self.coreDataManager shutdownCoreDataStackAndReturnError:nil];
    [super tearDown];
}

- (void)testInsert {
    NSError *error = nil;
    NSManagedObject *playlist = [self.playlistDAO insertWithMap:@{@"name": @"playlist"} error:&error];
    XCTAssertNotNil(playlist);
}

- (void)testFind {
    NSError *error = nil;
    [self.playlistDAO insertWithMap:@{@"name": @"playlist"} error:&error];
    NSArray *result = [self.playlistDAO findAndReturnError:&error];
    XCTAssertEqual(result.count, 1);
}

@end
