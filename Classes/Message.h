//
//  Message.h
//  linphone
//
//  Created by Art on 5/18/15.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Conversation;

@interface Message : NSManagedObject

@property (nonatomic, retain) NSDate * timestamp;
@property (nonatomic, retain) NSString * content;
@property (nonatomic, retain) Conversation *conversation;

@end
