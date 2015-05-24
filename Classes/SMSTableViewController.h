//
//  SMSTableViewController.h
//  linphone
//
//  Created by Art on 5/18/15.
//
//

#import <UIKit/UIKit.h>
#import "UICompositeViewController.h"

@interface SMSTableViewController : UIViewController <UICompositeViewDelegate>

@property (nonatomic, strong) NSString *phoneNumber;

@end
