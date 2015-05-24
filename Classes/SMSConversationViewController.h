//
//  SMSConversationViewController.h
//  linphone
//
//  Created by Art on 5/21/15.
//
//

#import <UIKit/UIKit.h>
#import "UICompositeViewController.h"
@class Conversation;

@interface SMSConversationViewController : UIViewController <UICompositeViewDelegate>

@property (nonatomic, strong) Conversation *conversation;

@end
