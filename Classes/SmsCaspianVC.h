//
//  smsCaspianVC.h
//  linphone
//
//  Created by  on 3/12/15.
//
//

#import <UIKit/UIKit.h>

#import "UIToggleButton.h"

#import "UICompositeViewController.h"


@interface SmsCaspianVC : UIViewController <UITextFieldDelegate,UICompositeViewDelegate> {
    NSArray *_getSMSHistoryPhoneNumbers;  // Fetch phone numbers from history SQL Lite 3
    NSString *phoneNumberSelectCell;  // Added on 15 March 2015 for passing variable from smsCaspainVC to smsCaspianConversationVC
        UIWindow *window;
        UINavigationController *navController;
    

}

@property (nonatomic,retain) NSArray *getSMSHistoryPhoneNumbers; // Fetch phone numbers from history SQL Lite 3
@property (nonatomic, retain) NSString *phoneNumberSelectCell;  // Added on 15 March 2015 for passing variable from smsCaspainVC to smsCaspianConversationVC

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, retain) UINavigationController *navController;



@end
