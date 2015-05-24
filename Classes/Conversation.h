//
//  Conversation.h
//  linphone
//
//  Created by Art on 5/21/15.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Message;

@interface Conversation : NSManagedObject

@property (nonatomic, retain) NSData * image;
@property (nonatomic, retain) NSString * lastMessage;
@property (nonatomic, retain) NSString * recepientName;
@property (nonatomic, retain) NSDate * timestamp;
@property (nonatomic, retain) NSString * recepientNumber;
@property (nonatomic, retain) NSSet *messages;
@end

@interface Conversation (CoreDataGeneratedAccessors)

- (void)addMessagesObject:(Message *)value;
- (void)removeMessagesObject:(Message *)value;
- (void)addMessages:(NSSet *)values;
- (void)removeMessages:(NSSet *)values;

@end
