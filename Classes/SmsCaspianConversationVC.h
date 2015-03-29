//
//  smsCaspianConversationVC.h
//  linphone
//
//  Created by  on 3/13/15.
//
//
#import "AMBubbleTableViewController.h"   // Bubble view
#import <UIKit/UIKit.h>
#import "UIToggleButton.h"
#import "SmsCaspianVC.h"
#import "UICompositeViewController.h"
// Added on 14 March for Growing text

#import "HPGrowingTextView.h"

#include "linphone/linphonecore.h"
//End
// Modified class from UIViewController to AMBubbleTableViewController
@interface SmsCaspianConversationVC : AMBubbleTableViewController <HPGrowingTextViewDelegate, UITextFieldDelegate,UICompositeViewDelegate> {

    BOOL scrollOnGrowingEnabled;    // Added on 14 March for Growing text
    BOOL composingVisible;  // Added on 14 March for Growing text
    NSString *_seguePhoneNumber;  // Added on 15 March to pass value from first view controller to second view controller
}
@property (retain, nonatomic) IBOutlet UILabel *contactLabel;

@property (retain, nonatomic) IBOutlet UIView *messageView;
// Added on 14 March for Growing text
@property (retain, nonatomic) IBOutlet HPGrowingTextView *messageField;
@property (retain, nonatomic) IBOutlet HPGrowingTextView *messageViewField;
@property (assign, nonatomic) NSString *seguePhoneNumber;   // Added on 15 March to pass value from first view controller to second view controller
// End


@end
