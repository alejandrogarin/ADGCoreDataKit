#import <XCTest/XCTest.h>
//#import "ADGCoreDataKit-swift.h"
#import "ADGCoreDataKitTests-swift.h"

@interface BaseObjTestCase : XCTestCase
@property (strong, nonatomic) CoreDataManager *coreDataManager;
@property (strong, nonatomic) CoreDataManagedObjectDAO *playlistDAO;
@end

@implementation BaseObjTestCase

- (void)setUp {
    [super setUp];
    self.coreDataManager = [[CoreDataManager alloc] initUsingModelName:@"TestModel" sqlFileName:nil inBundle:[NSBundle bundleForClass:[self class]] securityApplicationGroup:nil useInMemoryStore:YES];
    
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
    Playlist *playlist = (Playlist *)[self.playlistDAO create];
    playlist.name = @"playlist";
    BOOL result = [self.playlistDAO commitAndReturnError:&error];
    XCTAssertTrue(result);
    XCTAssertNil(error);
}

- (void)testFind {
    NSError *error = nil;
    Playlist *playlist = (Playlist *)[self.playlistDAO create];
    playlist.name = @"playlist";
    [self.playlistDAO commitAndReturnError:&error];
    NSArray *result = [self.playlistDAO findAndReturnError:&error];
    XCTAssertEqual(result.count, 1);
}

@end
