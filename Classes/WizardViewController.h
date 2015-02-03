/* WizardViewController.h
 *
 * Copyright (C) 2012  Belledonne Comunications, Grenoble, France
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or   
 *  (at your option) any later version.                                 
 *                                                                      
 *  This program is distributed in the hope that it will be useful,     
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of      
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the       
 *  GNU Library General Public License for more details.                
 *                                                                      
 *  You should have received a copy of the GNU General Public License   
 *  along with this program; if not, write to the Free Software         
 *  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */ 

#import <UIKit/UIKit.h>
#import <XMLRPCConnectionDelegate.h>
#import "UICompositeViewController.h"

#import "COCTextField.h"

@interface WizardViewController : TPMultiLayoutViewController
<UITextFieldDelegate,
    UICompositeViewDelegate,
    XMLRPCConnectionDelegate,
    UIGestureRecognizerDelegate,
    UIAlertViewDelegate,
    UIPickerViewDataSource,
    UIPickerViewDelegate>
{
    @private
    UITextField *activeTextField;
    UIView *currentView;
    UIView *nextView;
    NSMutableArray *historyViews;
}

@property (nonatomic, retain) IBOutlet UIScrollView *contentView;

@property (nonatomic, retain) IBOutlet UIView *welcomeView;
@property (nonatomic, retain) IBOutlet UIView *signUpView;
@property (nonatomic, retain) IBOutlet UIView *passwordReceivedView;
@property (nonatomic, retain) IBOutlet UIView *connectAccountView;
@property (nonatomic, retain) IBOutlet UIView *forgotPasswordView;
@property (nonatomic, retain) IBOutlet UIView *signInView;
@property (nonatomic, retain) IBOutlet UIView *activateAccountView;
@property (nonatomic, retain) IBOutlet UIView *provisionedAccountView;
@property (nonatomic, retain) IBOutlet UIView *askPhoneNumberView;

@property (nonatomic, retain) IBOutlet UIView *waitView;

@property (nonatomic, retain) IBOutlet UIButton *cancelButton;
@property (nonatomic, retain) IBOutlet UIButton *backButton;
@property (nonatomic, retain) IBOutlet UIButton *startButton;
@property (nonatomic, retain) IBOutlet UIButton *createAccountButton;
@property (nonatomic, retain) IBOutlet UIButton *connectAccountButton;
@property (nonatomic, retain) IBOutlet UIButton *externalAccountButton;
@property (nonatomic, retain) IBOutlet UIButton *remoteProvisioningButton;

@property (nonatomic, retain) IBOutlet UITextField *provisionedUsername;
@property (nonatomic, retain) IBOutlet UITextField *provisionedPassword;
@property (nonatomic, retain) IBOutlet UITextField *provisionedDomain;

@property (nonatomic, retain) IBOutlet UIImageView *choiceViewLogoImageView;
@property (retain, nonatomic) IBOutlet UISegmentedControl *transportChooser;

@property (nonatomic, retain) IBOutlet UITapGestureRecognizer *viewTapGestureRecognizer;

@property (nonatomic, retain) IBOutlet UISwitch *rememberMeRegisterSwitch;
@property (nonatomic, retain) IBOutlet UITextField *passwordRegisterField;
@property (nonatomic, retain) IBOutlet UITextField *phoneNumberRegisterField;
@property (nonatomic, retain) IBOutlet UITextField *domainRegisterField;
@property (nonatomic, retain) IBOutlet UIToolbar *phoneNumberNextToolbar;

@property (nonatomic, retain) IBOutlet UIPickerView *countryPickerView;
@property (nonatomic, retain) IBOutlet UIToolbar *countryPickerDoneToolbar;
@property (nonatomic, retain) IBOutlet UIToolbar *numKeypadDoneToolbar;

@property (nonatomic, retain) IBOutlet UILabel *registrationNextStepSignUpLabel;
@property (nonatomic, retain) IBOutlet UITextField *countryCodeSignUpField;
@property (nonatomic, retain) IBOutlet COCTextField *countryNameSignUpField;
@property (nonatomic, retain) IBOutlet COCTextField *phoneNumberSignUpField;
@property (nonatomic, retain) IBOutlet COCTextField *firstNameSignUpField;
@property (nonatomic, retain) IBOutlet COCTextField *lastNameSignUpField;
@property (nonatomic, retain) IBOutlet UISegmentedControl *activateBySignUpSegmented;
@property (nonatomic, retain) IBOutlet UIButton *continueSignUpField;

@property (nonatomic, retain) IBOutlet UIView *confirmView;
@property (nonatomic, retain) IBOutlet UIImageView *smsImageConfirmView;
@property (nonatomic, retain) IBOutlet UIImageView *callImageConfirmView;
@property (nonatomic, retain) IBOutlet COCTextField *phoneNumberConfirmView;
@property (nonatomic, retain) IBOutlet UILabel *smsTextConfirmView;
@property (nonatomic, retain) IBOutlet UILabel *callTextConfirmView;

@property (nonatomic, retain) IBOutlet COCTextField *activationCodeActivateField;

@property (nonatomic, retain) IBOutlet COCTextField *passwordFinishField;

@property (nonatomic, retain) IBOutlet UITextField *countryCodeForgotPasswordField;
@property (nonatomic, retain) IBOutlet COCTextField *countryNameForgotPasswordField;
@property (nonatomic, retain) IBOutlet COCTextField *phoneNumberForgotPasswordField;

@property (retain, nonatomic) IBOutlet COCTextField *phoneNumberAskPhoneNumberField;

- (void)reset;
- (void)resetToDefaults;
- (void)fillDefaultValues;

- (IBAction)onStartClick:(id)sender;
- (IBAction)onBackClick:(id)sender;
- (IBAction)onCancelClick:(id)sender;

- (IBAction)onCreateAccountClick:(id)sender;
- (IBAction)onConnectLinphoneAccountClick:(id)sender;
- (IBAction)onExternalAccountClick:(id)sender;
- (IBAction)onCheckValidationClick:(id)sender;
- (IBAction)onRemoteProvisioningClick:(id)sender;

- (IBAction)onSignInClick:(id)sender;
- (IBAction)onSignInExternalClick:(id)sender;
- (IBAction)onRegisterClick:(id)sender;
- (IBAction)onProvisionedLoginClick:(id)sender;

@end
