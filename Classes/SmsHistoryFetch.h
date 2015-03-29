//
//  smsHistoryFetch.h
//  linphone
//
//  Created by  on 3/14/15.
//
//

#import <Foundation/Foundation.h>
#import "SmsHistory.h"
#import <sqlite3.h>

@interface SmsHistoryFetch : NSObject   {
    sqlite3 *_database;
}

+(SmsHistoryFetch *)database;
-(NSArray *)getSMSHistory:(NSString *)phonenumber;        // Modified on 17 March to pass phone number
-(NSArray *)getSMSHistoryPhoneNumbers;
-(NSArray *)insertSMSHistory:(NSString *)username :(NSString *)phoneNumber :(NSString *)message;

@end
