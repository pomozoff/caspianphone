//
//  Conversation.h
//  linphone
//
//  Created by Art on 5/18/15.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Message;

@interface Conversation : NSManagedObject

@property (nonatomic, retain) NSString * recepient;
@property (nonatomic, retain) NSString * lastMessage;
@property (nonatomic, retain) NSDate * timestamp;
@property (nonatomic, retain) NSData * image;
@property (nonatomic, retain) NSSet *messages;
@end

@interface Conversation (CoreDataGeneratedAccessors)

- (void)addMessagesObject:(Message *)value;
- (void)removeMessagesObject:(Message *)value;
- (void)addMessages:(NSSet *)values;
- (void)removeMessages:(NSSet *)values;

@end
