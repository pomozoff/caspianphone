//
//  smsHistory.h
//  linphone
//
//  Created by  on 3/14/15.
//
//

#import <Foundation/Foundation.h>

@interface SmsHistory : NSObject    {
    
    int _sno;
    NSString *_username;
    NSString *_phoneNumber;
    NSString *_message;
}

@property (nonatomic, assign)int sno;
@property (nonatomic, copy) NSString *username;
@property (nonatomic, copy) NSString *phoneNumber;
@property (nonatomic, copy) NSString *message;

-(id) initWithUniqueId:(int)sno username:(NSString *)username phoneNumber:(NSString *)phoneNumber message:(NSString *)message;

-(id) initWithUniqueId:(NSString *)phoneNumber;

-(id) initWithUniqueId:(NSString *)username phoneNumber:(NSString *)phoneNumber message:(NSString *)message;

@end
