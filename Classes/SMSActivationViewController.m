//
//  SMSActivationViewController.m
//  linphone
//
//  Created by Art on 5/16/15.
//
//

#import "SMSActivationViewController.h"
#import "SMSTableViewController.h"
#import "LinphoneManager.h"
#import "PhoneMainView.h"
#import "ProgressHUD.h"

static NSString *caspianPhoneNumber = @"uk.co.onecallcaspian.phone.phoneNumber";
static NSString *caspianPasswordKey = @"uk.co.onecallcaspian.phone.password";
static NSString *caspianRandomCode = @"uk.co.onecallcaspian.phone.randomCode";
static NSString *caspianSMSStatus = @"uk.co.onecallcaspian.phone.smsStatus";
static NSString *smsActivationAPI = @"https://onecallcaspian.co.uk/mobile/sms?phone_number=%@&password=%@&from=onecall&text=Your verification code is %@&receiver=%@";

@interface SMSActivationViewController ()

@property (nonatomic, strong) IBOutlet UILabel *messageLabel;
@property (nonatomic, strong) IBOutlet UITextField *codeTextField;
@property (nonatomic, strong) IBOutlet UIButton *firstButton;
@property (nonatomic, strong) IBOutlet UIButton *secondButton;
@property (nonatomic, strong) IBOutlet UIButton *skipButton;

@end

@implementation SMSActivationViewController

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch * touch = [touches anyObject];
    if(touch.phase == UITouchPhaseBegan) {
        [self.view endEditing:YES];
    }
}

#pragma mark - Button Click Methods

- (IBAction)firstButtonTapped:(id)sender
{
    if ([self.firstButton.titleLabel.text isEqualToString:@"Yes"]) {
        self.messageLabel.text = @"Activation in progress. You should receive an SMS with the activation code. Input the code here and click Activate.";
        [self requestActivationCode];
    }
    else if ([self.firstButton.titleLabel.text isEqualToString:@"Activate"]) {
        if (self.codeTextField.text.length <= 0) {
            [ProgressHUD showAlertWithTitle:@"Error" message:@"Please input the activation code."];
        }
        else {
            if ([self.codeTextField.text isEqualToString:[[NSUserDefaults standardUserDefaults] objectForKey:caspianRandomCode]]) {
                [ProgressHUD showAlertWithTitle:@"SMS Activation" message:@"SMS Activation successful!"];
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:caspianSMSStatus];
                [[NSUserDefaults standardUserDefaults] synchronize];
                
                DYNAMIC_CAST([[PhoneMainView instance] changeCurrentView:[SMSTableViewController compositeViewDescription] push:TRUE], SMSTableViewController);
            }
            else {
                [ProgressHUD showAlertWithTitle:@"Error" message:@"Incorrect activation code."];
            }
        }
    }
}

- (IBAction)secondButtonTapped:(id)sender
{
    if ([self.secondButton.titleLabel.text isEqualToString:@"No"]) {
        [[PhoneMainView instance] popCurrentView];
    }
    else if ([self.secondButton.titleLabel.text isEqualToString:@"Cancel"]) {
        self.messageLabel.text = @"This is the first time you are sending an SMS. Do you want to activate SMS sending on you account now?";
        [self.firstButton setTitle:@"Yes" forState:UIControlStateNormal];
        [self.secondButton setTitle:@"No" forState:UIControlStateNormal];
        
        [UIView animateWithDuration:0.3 animations:^{
            self.codeTextField.alpha = 0;
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.5 animations:^{
                CGRect firstButtonFrame = self.firstButton.frame;
                firstButtonFrame.origin.y = firstButtonFrame.origin.y - 45;
                self.firstButton.frame = firstButtonFrame;
                CGRect secondButtonFrame = self.secondButton.frame;
                secondButtonFrame.origin.y = secondButtonFrame.origin.y - 45;
                self.secondButton.frame = secondButtonFrame;
                self.skipButton.alpha = 1;
            }];
        }];
    }
}

- (IBAction)skipButtonTapped:(id)sender
{
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:caspianSMSStatus];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    DYNAMIC_CAST([[PhoneMainView instance] changeCurrentView:[SMSTableViewController compositeViewDescription] push:TRUE], SMSTableViewController);
}

#pragma mark - Other Methods

- (void)requestActivationCode
{
    [[NSUserDefaults standardUserDefaults] setObject:[self generateRandomString] forKey:caspianRandomCode];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    NSString *phoneNumber = [[NSUserDefaults standardUserDefaults] objectForKey:caspianPhoneNumber];
    NSString *password = [[NSUserDefaults standardUserDefaults] objectForKey:caspianPasswordKey];
    NSString *randomCode = [[NSUserDefaults standardUserDefaults] objectForKey:caspianRandomCode];
    
    [ProgressHUD showLoadingInView:self.view];
    
    NSString *urlString = [NSString stringWithFormat:smsActivationAPI, phoneNumber, password, randomCode, phoneNumber];
    [[LinphoneManager instance] dataFromUrlString:urlString method:@"GET" completionBlock:^{
        [ProgressHUD hideLoadingInView:self.view];
        [ProgressHUD showAlertWithTitle:@"SMS Activation" message:@"Activation code sent!"];
        
        [self.firstButton setTitle:@"Activate" forState:UIControlStateNormal];
        [self.secondButton setTitle:@"Cancel" forState:UIControlStateNormal];
        
        [UIView animateWithDuration:0.5 animations:^{
            CGRect firstButtonFrame = self.firstButton.frame;
            firstButtonFrame.origin.y = firstButtonFrame.origin.y + 45;
            self.firstButton.frame = firstButtonFrame;
            CGRect secondButtonFrame = self.secondButton.frame;
            secondButtonFrame.origin.y = secondButtonFrame.origin.y + 45;
            self.secondButton.frame = secondButtonFrame;
            self.skipButton.alpha = 0;
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.5 animations:^{
                self.codeTextField.alpha = 1.0;
            }];
        }];
    } errorBlock:^{
        [ProgressHUD hideLoadingInView:self.view];
        [ProgressHUD showAlertWithTitle:@"SMS Activation" message:@"Failed to send activation code. Please try again."];
    }];
}

- (NSString *)generateRandomString {
    static NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    NSMutableString *randomString = [NSMutableString stringWithCapacity: 4];
    for (int i = 0; i < 6; i++) {
        [randomString appendFormat: @"%C", [letters characterAtIndex: arc4random() % [letters length]]];
    }
    return randomString;
}

#pragma mark - UICompositeViewDelegate Functions

static UICompositeViewDescription *compositeDescription = nil;

+ (UICompositeViewDescription *)compositeViewDescription {
    if(compositeDescription == nil) {
        compositeDescription = [[UICompositeViewDescription alloc] init:@"Activate SMS"
                                                                content:@"SMSActivationViewController"
                                                               stateBar:nil
                                                        stateBarEnabled:false
                                                                 tabBar:@"UIMainBar"
                                                          tabBarEnabled:true
                                                             fullscreen:false
                                                          landscapeMode:[LinphoneManager runningOnIpad]
                                                           portraitMode:true];
        compositeDescription.darkBackground = NO;
        compositeDescription.statusBarMargin = 0.0f;
        compositeDescription.statusBarColor = [UIColor colorWithWhite:0.935f alpha:0.0f];
        compositeDescription.statusBarStyle = UIStatusBarStyleLightContent;
    }
    return compositeDescription;
}

@end
