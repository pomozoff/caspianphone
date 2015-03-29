//
//  smsHistory.m
//  linphone
//
//  Created by  on 3/14/15.
//
//

#import "SmsHistory.h"
#import "SmsHistoryFetch.h"

@implementation SmsHistory

@synthesize sno = _sno;
@synthesize username = _username;
@synthesize phoneNumber = _phoneNumber;
@synthesize  message = _message;

-(id) initWithUniqueId:(int)sno username:(NSString *)username phoneNumber:(NSString *)phoneNumber message:(NSString *)message   {
    self = [super init];
    if (self)    {
        self.sno = sno;
        self.username = username;
        self.phoneNumber = phoneNumber;
        self.message = message;
    }
    return self;
}

-(id) initWithUniqueId:(NSString *)phoneNumber  {
    self = [super init];
    if (self)    {
        self.phoneNumber = phoneNumber;
    }
    return self;
}

-(id) initWithUniqueId:(NSString *)username phoneNumber:(NSString *)phoneNumber message:(NSString *)message   {
    self = [super init];
    if (self)    {
        self.username = username;
        self.phoneNumber = phoneNumber;
        self.message = message;
    }
    return self;
    
}
-(void) dealloc {

    self.username = nil;
    self.phoneNumber = nil;
    self.message = nil;
    [super dealloc];
}

@end
