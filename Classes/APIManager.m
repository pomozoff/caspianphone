//
//  APIManager.m
//  linphone
//
//  Created by Art on 5/18/15.
//
//

#import "APIManager.h"

static NSString *smsActivationAPI = @"https://onecallcaspian.co.uk/mobile/sms?phone_number=%@&password=%@&from=onecall&text=Your verification code is %@&receiver=%@";
static NSString *smsAPI = @"https://onecallcaspian.co.uk/mobile/sms?phone_number=%@&password=%@&from=%@&text=%@&receiver=%@";

@implementation APIManager

+ (void)sendSMSActivationWithCode:(NSString *)code
                      phoneNumber:(NSString *)phoneNumber
                         password:(NSString *)password
                     successBlock:(void(^)(void))successBlock
                     failureBlock:(void(^)(void))failureBlock
{
    NSString *urlRequestString = [NSString stringWithFormat:smsActivationAPI, phoneNumber, password, code, phoneNumber];
    NSString *urlEncodedString = [urlRequestString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlEncodedString] cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:3000];
    [request setHTTPMethod: @"GET"];
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    
    [NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        if (connectionError == nil) {
            if (successBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    successBlock();
                });
            }
        }
        else {
            if (failureBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    failureBlock();
                });
            }
        }
    }];
}

+ (void)sendSMSWithMessage:(NSString *)message
                 recepient:(NSString *)recepient
               phoneNumber:(NSString *)phoneNumber
                  password:(NSString *)password
              successBlock:(void(^)(void))successBlock
              failureBlock:(void(^)(void))failureBlock
{
    NSString *urlRequestString = [NSString stringWithFormat:smsAPI, phoneNumber, password, phoneNumber, message, recepient];
    NSString *urlEncodedString = [urlRequestString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlEncodedString] cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:3000];
    [request setHTTPMethod: @"GET"];
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    
    [NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        if (connectionError == nil) {
            if (successBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    successBlock();
                });
            }
        }
        else {
            if (failureBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    failureBlock();
                });
            }
        }
    }];
}

@end
