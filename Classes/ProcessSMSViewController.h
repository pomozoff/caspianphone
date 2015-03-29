//
//  ProcessSMSViewController.h
//  linphone
//
//  Created by  on 3/5/15.
//
//

#import <UIKit/UIKit.h>

@interface ProcessSMSViewController : UIViewController

@property (nonatomic, retain) IBOutlet UITextField* addressField;
@property (nonatomic, retain) UIView *dummyView; // added by  on 5 March 2015
@property (retain, nonatomic) IBOutlet UITextField *textActivateSMS;
@end
