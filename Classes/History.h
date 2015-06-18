//
//  History.h
//  linphone
//
//  Created by Art on 6/17/15.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface History : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * number;
@property (nonatomic, retain) NSDate * timestamp;

@end
