//
//  linphone_Tests.m
//  linphone Tests
//
//  Created by Anton Pomozov on 17.09.14.
//
//

#import <XCTest/XCTest.h>

#import "LinphoneManager.h"

@interface cleanUsername_Tests : XCTestCase

@property (nonatomic, copy, readonly) NSString *cleanPhoneNumber;

@end

@implementation cleanUsername_Tests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    _cleanPhoneNumber = @"71234567890";
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testSinglePlus
{
    NSString *result = [[LinphoneManager instance] cleanPhoneNumber:[@"+" stringByAppendingString:self.cleanPhoneNumber]];
    XCTAssertEqualObjects(result, self.cleanPhoneNumber, @"");
}

- (void)testTwoPluses
{
    NSString *result = [[LinphoneManager instance] cleanPhoneNumber:[@"++" stringByAppendingString:self.cleanPhoneNumber]];
    XCTAssertEqualObjects(result, self.cleanPhoneNumber, @"");
}

- (void)testManyPluses
{
    NSString *result = [[LinphoneManager instance] cleanPhoneNumber:[@"+++++" stringByAppendingString:self.cleanPhoneNumber]];
    XCTAssertEqualObjects(result, self.cleanPhoneNumber, @"");
}

- (void)testTwoZeros
{
    NSString *result = [[LinphoneManager instance] cleanPhoneNumber:[@"00" stringByAppendingString:self.cleanPhoneNumber]];
    XCTAssertEqualObjects(result, self.cleanPhoneNumber, @"");
}

- (void)testFourZeros
{
    NSString *result = [[LinphoneManager instance] cleanPhoneNumber:[@"0000" stringByAppendingString:self.cleanPhoneNumber]];
    XCTAssertEqualObjects(result, self.cleanPhoneNumber, @"");
}

- (void)testSingleZero
{
    NSString *result = [[LinphoneManager instance] cleanPhoneNumber:[@"0" stringByAppendingString:self.cleanPhoneNumber]];
    XCTAssertEqualObjects(result, self.cleanPhoneNumber, @"");
}

- (void)testThreeZeros
{
    NSString *result = [[LinphoneManager instance] cleanPhoneNumber:[@"000" stringByAppendingString:self.cleanPhoneNumber]];
    XCTAssertEqualObjects(result, self.cleanPhoneNumber, @"");
}

- (void)testSinglePlusAndTwoZeros
{
    NSString *result = [[LinphoneManager instance] cleanPhoneNumber:[@"+00" stringByAppendingString:self.cleanPhoneNumber]];
    XCTAssertEqualObjects(result, self.cleanPhoneNumber, @"");
}

- (void)testTwoZerosAndSinglePlus
{
    NSString *result = [[LinphoneManager instance] cleanPhoneNumber:[@"00+" stringByAppendingString:self.cleanPhoneNumber]];
    XCTAssertEqualObjects(result, self.cleanPhoneNumber, @"");
}

- (void)testTwoPlusesAndTwoZeros
{
    NSString *result = [[LinphoneManager instance] cleanPhoneNumber:[@"++00" stringByAppendingString:self.cleanPhoneNumber]];
    XCTAssertEqualObjects(result, self.cleanPhoneNumber, @"");
}

- (void)testTwoZerosAndTwoPluses
{
    NSString *result = [[LinphoneManager instance] cleanPhoneNumber:[@"00++" stringByAppendingString:self.cleanPhoneNumber]];
    XCTAssertEqualObjects(result, self.cleanPhoneNumber, @"");
}

- (void)testComplicatedCase
{
    NSString *result = [[LinphoneManager instance] cleanPhoneNumber:[@"+0+0" stringByAppendingString:self.cleanPhoneNumber]];
    XCTAssertEqualObjects(result, self.cleanPhoneNumber, @"");
}

- (void)testMoreComplicatedCase
{
    NSString *result = [[LinphoneManager instance] cleanPhoneNumber:[@"000+0+00+++0000+0++++" stringByAppendingString:self.cleanPhoneNumber]];
    XCTAssertEqualObjects(result, self.cleanPhoneNumber, @"");
}

@end
