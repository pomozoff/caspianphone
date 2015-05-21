//
//  APIManager.h
//  linphone
//
//  Created by Art on 5/18/15.
//
//

#import <Foundation/Foundation.h>

@interface APIManager : NSObject

+ (void)sendSMSActivationWithCode:(NSString *)code
                      phoneNumber:(NSString *)phoneNumber
                         password:(NSString *)password
                     successBlock:(void(^)(void))successBlock
                     failureBlock:(void(^)(void))failureBlock;

+ (void)sendSMSWithMessage:(NSString *)message
                 recepient:(NSString *)recepient
               phoneNumber:(NSString *)phoneNumber
                  password:(NSString *)password
              successBlock:(void(^)(void))successBlock
              failureBlock:(void(^)(void))failureBlock;

@end
