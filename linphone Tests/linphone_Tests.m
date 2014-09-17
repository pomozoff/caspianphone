//
//  linphone_Tests.m
//  linphone Tests
//
//  Created by Anton Pomozov on 17.09.14.
//
//

#import <XCTest/XCTest.h>

#import "WizardViewController.h"

@interface WizardViewController (Test)

- (NSString *)cleanUsername:(NSString *)username;

@end

@interface linphone_Tests : XCTestCase

@property (nonatomic, strong) WizardViewController *wizardViewController;
@property (nonatomic, strong, readonly) NSString *cleanPhoneNumber;

@end

@implementation linphone_Tests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    self.wizardViewController = [[WizardViewController alloc] init];
    _cleanPhoneNumber = @"71234567890";
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testSinglePlus
{
    NSString *result = [self.wizardViewController cleanUsername:[@"+" stringByAppendingString:self.cleanPhoneNumber]];
    XCTAssertEqualObjects(result, self.cleanPhoneNumber, @"");
}

- (void)testTwoPluses
{
    NSString *result = [self.wizardViewController cleanUsername:[@"++" stringByAppendingString:self.cleanPhoneNumber]];
    XCTAssertEqualObjects(result, self.cleanPhoneNumber, @"");
}

- (void)testManyPluses
{
    NSString *result = [self.wizardViewController cleanUsername:[@"+++++" stringByAppendingString:self.cleanPhoneNumber]];
    XCTAssertEqualObjects(result, self.cleanPhoneNumber, @"");
}

- (void)testTwoZeros
{
    NSString *result = [self.wizardViewController cleanUsername:[@"00" stringByAppendingString:self.cleanPhoneNumber]];
    XCTAssertEqualObjects(result, self.cleanPhoneNumber, @"");
}

- (void)testFourZeros
{
    NSString *result = [self.wizardViewController cleanUsername:[@"0000" stringByAppendingString:self.cleanPhoneNumber]];
    XCTAssertEqualObjects(result, self.cleanPhoneNumber, @"");
}

- (void)testSingleZero
{
    NSString *result = [self.wizardViewController cleanUsername:[@"0" stringByAppendingString:self.cleanPhoneNumber]];
    XCTAssertNotEqualObjects(result, self.cleanPhoneNumber, @"");
}

- (void)testThreeZeros
{
    NSString *result = [self.wizardViewController cleanUsername:[@"000" stringByAppendingString:self.cleanPhoneNumber]];
    XCTAssertNotEqualObjects(result, self.cleanPhoneNumber, @"");
}

- (void)testSinglePlusAndTwoZeros
{
    NSString *result = [self.wizardViewController cleanUsername:[@"+00" stringByAppendingString:self.cleanPhoneNumber]];
    XCTAssertEqualObjects(result, self.cleanPhoneNumber, @"");
}

- (void)testTwoZerosAndSinglePlus
{
    NSString *result = [self.wizardViewController cleanUsername:[@"00+" stringByAppendingString:self.cleanPhoneNumber]];
    XCTAssertEqualObjects(result, self.cleanPhoneNumber, @"");
}

- (void)testTwoPlusesAndTwoZeros
{
    NSString *result = [self.wizardViewController cleanUsername:[@"++00" stringByAppendingString:self.cleanPhoneNumber]];
    XCTAssertEqualObjects(result, self.cleanPhoneNumber, @"");
}

- (void)testTwoZerosAndTwoPluses
{
    NSString *result = [self.wizardViewController cleanUsername:[@"00++" stringByAppendingString:self.cleanPhoneNumber]];
    XCTAssertEqualObjects(result, self.cleanPhoneNumber, @"");
}

@end
