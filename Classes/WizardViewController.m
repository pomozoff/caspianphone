/* WizardViewController.m
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

#import "WizardViewController.h"
#import "LinphoneManager.h"
#import "PhoneMainView.h"

#import <XMLRPCConnection.h>
#import <XMLRPCConnectionManager.h>
#import <XMLRPCResponse.h>
#import <XMLRPCRequest.h>

#import "DTAlertView.h"
#import "COCAlertView.h"

typedef enum _ViewElement {
    ViewElement_Username            = 100,
    ViewElement_Password            = 101,
    ViewElement_Password2           = 102,
    ViewElement_Email               = 103,
    ViewElement_Domain              = 104,
    ViewElement_Label               = 200,
    ViewElement_Error               = 201,
    ViewElement_Username_Error      = 404
} ViewElement;

static NSString *caspianCountryName = @"uk.co.onecallcaspian.phone.countryName";
static NSString *caspianCountryCode = @"uk.co.onecallcaspian.phone.countryCode";
static NSString *caspianPhoneNumber = @"uk.co.onecallcaspian.phone.phoneNumber";
static NSString *caspianPasswordKey = @"uk.co.onecallcaspian.phone.password";
static NSString *caspianDomain      = @"uk.co.onecallcaspian.phone.domain";
static NSString *caspianActivationCodeKey = @"uk.co.onecallcaspian.phone.activationCode";

static NSString *caspianSelectCountry    = @"Select Country";
static NSString *caspianEnterPhoneNumber = @"Enter Phone Number";
static NSString *caspianEnterName        = @"Enter First and Last Names";
static NSString *caspianContinue         = @"Press continue";

static NSString *caspianCountryListUrl           = @"https://onecallcaspian.co.uk/mobile/country2";
static NSString *caspianCheckAccountExistUrl     = @"https://onecallcaspian.co.uk/mobile/accountexist?phone_number=%@";
static NSString *caspianCheckCardExistUrl        = @"https://onecallcaspian.co.uk/mobile/cardexist?phone_number=%@";
static NSString *caspianRemoveAccountUrl         = @"https://onecallcaspian.co.uk/mobile/remove?card_id=%@&phone_number=%@";
static NSString *caspianCreateAccountUrl         = @"https://onecallcaspian.co.uk/mobile/create?phone_code=%@&phone_number=%@&firstname=%@&lastname=%@&activation_way=%@";
static NSString *caspianConfirmActivationCodeUrl = @"https://onecallcaspian.co.uk/mobile/confirm?code=%@";
static NSString *caspianForgotPasswordUrl        = @"https://onecallcaspian.co.uk/mobile/forgotPassword?phone_code=%@&phone_number=%@";
static NSString *caspianCountryFlagUrl           = @"https://onecallcaspian.co.uk/images/flags/Countries/%@";

static NSString *caspianCountriesListTopKey    = @"Countries";
static NSString *caspianCountryObjectFieldCode = @"Code";
static NSString *caspianCountryObjectFieldName = @"Name";
static NSString *caspianCountryObjectFieldCall = @"Call";
static NSString *caspianCountryObjectFieldSms  = @"Sms";
static NSString *caspianCountryObjectFieldFlag = @"Image";
static NSString *caspianCountryDefaultName     = @"United Kingdom";

extern NSInteger caspianErrorCode;
extern NSString *caspianErrorDomain;

@interface WizardViewController ()

@property (nonatomic, retain) UIView *dummyView;

@property (nonatomic, retain) NSArray *countryAndCode;
@property (nonatomic, copy) NSString *selectedCountryCode;
@property (nonatomic, copy) NSString *activationCode;
@property (nonatomic, copy) NSString *phoneNumber;
@property (nonatomic, copy) NSString *password;
@property (nonatomic, copy) NSString *caspianCardId;
@property (nonatomic, retain) NSOperationQueue *serialCountryListPullQueue;
@property (nonatomic, retain) NSOperationQueue *internetQueue;

@property (nonatomic, assign) NSInteger currentCountryRow;

@property (nonatomic, assign) BOOL isAvableActivateBySMS;
@property (nonatomic, assign) BOOL isAvableActivated;

@end

@implementation WizardViewController

@synthesize contentView;

@synthesize welcomeView;
@synthesize countrySignUpView;
@synthesize phoneNumberSignUpView;
@synthesize signUpView;
@synthesize passwordReceivedView;
@synthesize connectAccountView;
@synthesize forgotPasswordView;
@synthesize askPhoneNumberView;
@synthesize signInView;
@synthesize activateAccountView;
@synthesize provisionedAccountView;
@synthesize waitView;
@synthesize logInView;
@synthesize welcomeView2;
@synthesize countryLoginView;
@synthesize getActivationByCodeView;

@synthesize cancelButton;
@synthesize backButton;
@synthesize startButton;
@synthesize createAccountButton;
@synthesize connectAccountButton;
@synthesize externalAccountButton;
@synthesize remoteProvisioningButton;

@synthesize provisionedDomain, provisionedPassword, provisionedUsername;
@synthesize choiceViewLogoImageView;
@synthesize viewTapGestureRecognizer;
@synthesize rememberMeRegisterSwitch;

@synthesize isAvableActivateBySMS;
@synthesize isAvableActivated;

@synthesize activationCode = _activationCode;


#pragma mark - Properties

- (NSOperationQueue *)serialCountryListPullQueue {
    if (!_serialCountryListPullQueue) {
        _serialCountryListPullQueue = [[NSOperationQueue alloc] init];
        _serialCountryListPullQueue.name = @"Serial Country List Pull Queue";
        _serialCountryListPullQueue.maxConcurrentOperationCount = 1;
    }
    return _serialCountryListPullQueue;
}
- (NSOperationQueue *)internetQueue {
    if (!_internetQueue) {
        _internetQueue = [[NSOperationQueue alloc] init];
        _internetQueue.name = @"Internet Queue";
    }
    return _internetQueue;
}

- (void)setCurrentCountryRow:(NSInteger)currentCountryRow {
    _currentCountryRow = currentCountryRow;
    
    [self.countryPickerView reloadAllComponents];
    [self.countryPickerView selectRow:currentCountryRow inComponent:0 animated:YES];
    
    [self didSelectCountryAtRow:currentCountryRow];
}

- (void)setActivationCode:(NSString *)activationCode {
    if (![_activationCode isEqualToString:activationCode]) {
        [_activationCode release];
        _activationCode = [activationCode copy];
        
        NSLog(@"Activation code is: %@", activationCode);
        
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        [userDefaults setValue:activationCode forKey:caspianActivationCodeKey];
        [userDefaults synchronize];
    }
}
- (NSString *)activationCode {
    if (!_activationCode) {
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        _activationCode = [userDefaults objectForKey:caspianActivationCodeKey];
    }
    return _activationCode;
}

- (UIView *)dummyView {
    if (!_dummyView) {
        _dummyView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    }
    return _dummyView;
}


#pragma mark - Lifecycle Functions

- (id)init {
    self = [super initWithNibName:@"WizardViewController" bundle:[NSBundle mainBundle]];
    if (self != nil) {
        [[NSBundle mainBundle] loadNibNamed:@"WizardViews"
                                      owner:self
                                    options:nil];
        [[NSBundle mainBundle] loadNibNamed:@"WizardViews_2"
                                      owner:self
                                    options:nil];
        self->historyViews = [[NSMutableArray alloc] init];
        self->currentView = nil;
        self->viewTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onViewTap:)];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [contentView release];
    
    [welcomeView release];
    [signUpView release];
    [passwordReceivedView release];
    [connectAccountView release];
    [forgotPasswordView release];
    [askPhoneNumberView release];
    [signInView release];
    [activateAccountView release];
    
    [waitView release];
    
    [cancelButton release];
    [backButton release];
    [startButton release];
    [createAccountButton release];
    [connectAccountButton release];
    [externalAccountButton release];

    [choiceViewLogoImageView release];
    
    [historyViews release];
    
    [viewTapGestureRecognizer release];
    
    [remoteProvisioningButton release];
    [provisionedAccountView release];
    [provisionedUsername release];
    [provisionedPassword release];
    [provisionedDomain release];

    [rememberMeRegisterSwitch release];
    [_countryPickerView release];
    [_countryPickerDoneToolbar release];
    [_phoneNumberSignUpField release];
    [_countryAndCode release];
    [_serialCountryListPullQueue release];
    [_internetQueue release];
    
    [_selectedCountryCode release];
    [_activationCode release];
    [_password release];
    [_caspianCardId release];
    
    [_firstNameSignUpField release];
    [_lastNameSignUpField release];
    [_countryNameSignUpField release];
    [_countryCodeSignUpField release];
    
    [_registrationNextStepSignUpLabel release];
    [_continueSignUpField release];
    [_activateBySignUpSegmented release];
    [_numKeypadDoneToolbar release];
    [_activationCodeActivateField release];
    [_phoneNumberRegisterField release];
    [_passwordRegisterField release];
    [_passwordFinishField release];
    [_domainRegisterField release];
    [_phoneNumberNextToolbar release];
    
    [_countryCodeForgotPasswordField release];
    [_countryNameForgotPasswordField release];
    [_phoneNumberForgotPasswordField release];
    
    [_dummyView release];
    
    [_confirmView release];
    [_phoneNumberConfirmView release];
    [_smsTextConfirmView release];
    [_callTextConfirmView release];
    [_smsImageConfirmView release];
    [_callImageConfirmView release];
    [_phoneNumberAskPhoneNumberField release];
    
    [_transportChooser release];

    [_phoneNumberFoundView release];
    [_phoneNumberExistsView release];
    
    [_phoneNumberFoundPhoneNumberField release];
    [_phoneNumberExistsPhoneNumberField release];
    
    [_countryFlagSignUpImage release];
    [_flagLoadingSignUpActivityIndicator release];
    [_countryFlagForgotPasswordImage release];
    [_flagLoadingForgotPasswordActivityIndicator release];
    [welcomeView2 release];
    [logInView release];
    [_phoneNumberNextSignInToolbar release];
    [_numKeypadDoneSignInToolbar release];
    [_dismissKeyboardButton release];
    [countryLoginView release];
    [_countryPickerLoginNextToolbar release];
    [_dismissKeyboardButtonCountryLoginView release];
    [countrySignUpView release];
    [phoneNumberSignUpView release];
    [getActivationByCodeView release];
    [_doneNumKeyboardForgetPasswordToolbar release];
    [super dealloc];
}


#pragma mark - UICompositeViewDelegate Functions

static UICompositeViewDescription *compositeDescription = nil;

+ (UICompositeViewDescription *)compositeViewDescription {
    if(compositeDescription == nil) {
        compositeDescription = [[UICompositeViewDescription alloc] init:@"Wizard" 
                                                                content:@"WizardViewController" 
                                                               stateBar:nil 
                                                        stateBarEnabled:false 
                                                                 tabBar:nil 
                                                          tabBarEnabled:false 
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


#pragma mark - ViewController Functions

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(registrationUpdateEvent:)
                                                 name:kLinphoneRegistrationUpdate
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(configuringUpdate:)
                                                 name:kLinphoneConfiguringStateUpdate
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];

    [self checkNextStep];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kLinphoneRegistrationUpdate
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kLinphoneConfiguringStateUpdate
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [viewTapGestureRecognizer setCancelsTouchesInView:FALSE];
    [viewTapGestureRecognizer setDelegate:self];
    //[contentView addGestureRecognizer:viewTapGestureRecognizer];
    
    if([LinphoneManager runningOnIpad]) {
        [LinphoneUtils adjustFontSize:welcomeView mult:2.22f];
        [LinphoneUtils adjustFontSize:signUpView mult:2.22f];
        [LinphoneUtils adjustFontSize:passwordReceivedView mult:2.22f];
        [LinphoneUtils adjustFontSize:connectAccountView mult:2.22f];
        [LinphoneUtils adjustFontSize:forgotPasswordView mult:2.22f];
        [LinphoneUtils adjustFontSize:askPhoneNumberView mult:2.22f];
        [LinphoneUtils adjustFontSize:signInView mult:2.22f];
        [LinphoneUtils adjustFontSize:activateAccountView mult:2.22f];
        [LinphoneUtils adjustFontSize:provisionedAccountView mult:2.22f];
    }
    
    self.countryNameLoginViewField.inputView = self.countryPickerView;
    self.countryNameLoginViewField.inputAccessoryView = self.countryPickerLoginNextToolbar;
    
    self.countryNameSignUpField.inputView = self.countryPickerView;
    self.countryNameSignUpField.inputAccessoryView = self.countryPickerDoneToolbar;
    self.phoneNumberSignUpField.inputAccessoryView = self.phoneNumberNextToolbar;
    self.phoneNumberConfirmView.inputView = self.dummyView;
    
    self.countryNameForgotPasswordField.inputView = self.countryPickerView;
    self.countryNameForgotPasswordField.inputAccessoryView = self.countryPickerDoneToolbar;
    
    self.phoneNumberRegisterField.inputAccessoryView = self.phoneNumberNextSignInToolbar;
    //self.passwordRegisterField.inputAccessoryView = self.numKeypadDoneSignInToolbar;
    self.activationCodeActivateField.inputAccessoryView = self.numKeypadDoneToolbar;
    self.passwordFinishField.inputView = self.dummyView;
    self.phoneNumberForgotPasswordField.inputAccessoryView = self.doneNumKeyboardForgetPasswordToolbar;
    
    self.phoneNumberAskPhoneNumberField.inputView = self.dummyView;
    self.phoneNumberFoundPhoneNumberField.inputView = self.dummyView;
    self.phoneNumberExistsPhoneNumberField.inputView = self.dummyView;

    self.phoneNumberAskPhoneNumberField.editable = NO;
    self.phoneNumberFoundPhoneNumberField.editable = NO;
    self.phoneNumberExistsPhoneNumberField.editable = NO;
    
    self.confirmView.layer.cornerRadius = 5.0f;
    self.confirmView.layer.masksToBounds = YES;
}


#pragma mark -

+ (void)cleanTextField:(UIView*)view {
    if([view isKindOfClass:[UITextField class]]) {
        [(UITextField*)view setText:@""];
    } else {
        for(UIView *subview in view.subviews) {
            [WizardViewController cleanTextField:subview];
        }
    }
}

- (void)fillDefaultValues {

    /*
    LinphoneCore* lc = [LinphoneManager getLc];
    [self resetTextFields];

    LinphoneProxyConfig* current_conf = NULL;
    linphone_core_get_default_proxy([LinphoneManager getLc], &current_conf);
    if( current_conf != NULL ){
        const char* proxy_addr = linphone_proxy_config_get_identity(current_conf);
        if( proxy_addr ){
            LinphoneAddress *addr = linphone_address_new( proxy_addr );
            if( addr ){
                const LinphoneAuthInfo *auth = linphone_core_find_auth_info(lc, NULL, linphone_address_get_username(addr), linphone_proxy_config_get_domain(current_conf));
                linphone_address_destroy(addr);
                if( auth ){
                    [LinphoneLogger log:LinphoneLoggerLog format:@"A proxy config was set up with the remote provisioning, skip wizard"];
                    [self onCancelClick:nil];
                }
            }
        }
    }

    LinphoneProxyConfig* default_conf = linphone_core_create_proxy_config([LinphoneManager getLc]);
    const char* identity = linphone_proxy_config_get_identity(default_conf);
    if( identity ){
        LinphoneAddress* default_addr = linphone_address_new(identity);
        if( default_addr ){
            const char* domain = linphone_address_get_domain(default_addr);
            const char* username = linphone_address_get_username(default_addr);
            if( domain && strlen(domain) > 0){
                //UITextField* domainfield = [WizardViewController findTextField:ViewElement_Domain view:externalAccountView];
                [provisionedDomain setText:[NSString stringWithUTF8String:domain]];
            }

            if( username && strlen(username) > 0 && username[0] != '?' ){
                //UITextField* userField = [WizardViewController findTextField:ViewElement_Username view:externalAccountView];
                [provisionedUsername setText:[NSString stringWithUTF8String:username]];
            }
        }
    }

    [self changeView:provisionedAccountView back:FALSE animation:TRUE];

    linphone_proxy_config_destroy(default_conf);
    */
}

- (void)resetTextFields {
    [WizardViewController cleanTextField:welcomeView];
    [WizardViewController cleanTextField:signUpView];
    [WizardViewController cleanTextField:passwordReceivedView];
    [WizardViewController cleanTextField:connectAccountView];
    [WizardViewController cleanTextField:forgotPasswordView];
    [WizardViewController cleanTextField:askPhoneNumberView];
    [WizardViewController cleanTextField:signInView];
    [WizardViewController cleanTextField:activateAccountView];
    [WizardViewController cleanTextField:provisionedAccountView];
}

- (void)reset {
    [self clearProxyConfig];
    [[LinphoneManager instance] lpConfigSetBool:FALSE forKey:@"pushnotification_preference"];
    
    LinphoneCore *lc = [LinphoneManager getLc];
    LCSipTransports transportValue = {5060, 5060, -1, -1};

    if (linphone_core_set_sip_transports(lc, &transportValue)) {
        [LinphoneLogger logc:LinphoneLoggerError format:"cannot set transport"];
    }
    
    [[LinphoneManager instance] lpConfigSetString:@"" forKey:@"sharing_server_preference"];
    [[LinphoneManager instance] lpConfigSetBool:YES   forKey:@"ice_preference"];
    [[LinphoneManager instance] lpConfigSetString:@"" forKey:@"stun_preference"];

    linphone_core_set_stun_server(lc, NULL);
    linphone_core_set_firewall_policy(lc, LinphonePolicyNoFirewall);

    waitView.hidden = YES;
    
    [self loadWizardConfig:@"wizard_external_sip_caspian.rc"];
    [self changeView:signInView back:NO animation:YES];
}

+ (UIView*)findView:(ViewElement)tag view:(UIView*)view {
    for(UIView *child in [view subviews]) {
        if([child tag] == tag){
            return (UITextField*)child;
        } else {
            UIView *o = [WizardViewController findView:tag view:child];
            if(o)
                return o;
        }
    }
    return nil;
}

+ (UITextField*)findTextField:(ViewElement)tag view:(UIView*)view {
    UIView *aview = [WizardViewController findView:tag view:view];
    if([aview isKindOfClass:[UITextField class]])
        return (UITextField*)aview;
    return nil;
}

+ (UILabel*)findLabel:(ViewElement)tag view:(UIView*)view {
    UIView *aview = [WizardViewController findView:tag view:view];
    if([aview isKindOfClass:[UILabel class]])
        return (UILabel*)aview;
    return nil;
}

- (void)clearHistory {
    [historyViews removeAllObjects];
}

- (void)savePhoneNumber:(NSString *)phoneNumber andPassword:(NSString *)password andDomain:(NSString *)domain {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    [userDefaults setObject:phoneNumber forKey:caspianPhoneNumber];
    [userDefaults setObject:password    forKey:caspianPasswordKey];
    [userDefaults setObject:domain      forKey:caspianDomain];
    
    [userDefaults synchronize];
}

- (void)fillCredentials {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    NSString *countryCode = [userDefaults objectForKey:caspianCountryCode];
    NSString *phoneNumber = [userDefaults objectForKey:caspianPhoneNumber];
    NSString *password    = [userDefaults objectForKey:caspianPasswordKey];
    //NSString *domain      = [userDefaults objectForKey:caspianDomain];
    
    self.phoneNumberRegisterField.text = phoneNumber;
    self.passwordRegisterField.text = password;
    //self.domainRegisterField.text = domain.length != 0 ? domain : [[LinphoneManager instance] caspianDomainIp];
    self.domainRegisterField.text = [[LinphoneManager instance] caspianDomainIp];
    
    if (!phoneNumber || [phoneNumber isEqualToString:@""]) {
        self.phoneNumberRegisterField.text = countryCode;
        [self.phoneNumberRegisterField becomeFirstResponder];
    } else if (!password || [password isEqualToString:@""]) {
        [self.passwordRegisterField becomeFirstResponder];
    }
}

- (NSDictionary *)countryByPhoneNumber:(NSString *)phoneNUmber {
    NSDictionary *country = nil;
    NSString *countryCode = @"";
    for (NSDictionary *currentCountry in self.countryAndCode) {
        NSString *code = currentCountry[caspianCountryObjectFieldCode];
        if ([phoneNUmber hasPrefix:code] && code.length > countryCode.length) {
            countryCode = code;
            country = currentCountry;
        }
    }
    return country;
}

- (void)changeView:(UIView *)view back:(BOOL)back animation:(BOOL)animation {

    /*
    static BOOL placement_done = NO; // indicates if the button placement has been done in the wizard choice view

    // Change toolbar buttons following view
    if (view == welcomeView) {
        [startButton setHidden:false];
        [backButton setHidden:true];
    } else {
        [startButton setHidden:true];
        [backButton setHidden:false];
    }
    
    if (view == validateAccountView) {
        [backButton setEnabled:FALSE];
    } else if (view == choiceView) {
        if ([[LinphoneManager instance] lpConfigBoolForKey:@"hide_wizard_welcome_view_preference"] == true) {
            [backButton setEnabled:FALSE];
        } else {
            [backButton setEnabled:TRUE];
        }
    } else {
        [backButton setEnabled:TRUE];
    }

    if (view == choiceView) {
        // layout is this:
        // [ Logo         ]
        // [ Create Btn   ]
        // [ Connect Btn  ]
        // [ External Btn ]
        // [ Remote Prov  ]

        BOOL show_logo   =  [[LinphoneManager instance] lpConfigBoolForKey:@"show_wizard_logo_in_choice_view_preference"];
        BOOL show_extern = ![[LinphoneManager instance] lpConfigBoolForKey:@"hide_wizard_custom_account"];
        BOOL show_new    = ![[LinphoneManager instance] lpConfigBoolForKey:@"hide_wizard_create_account"];

        if( !placement_done ) {
            // visibility
            choiceViewLogoImageView.hidden = !show_logo;
            externalAccountButton.hidden   = !show_extern;
            createAccountButton.hidden     = !show_new;

            // placement
            if (show_logo && show_new && !show_extern) {
                // lower both remaining buttons
                [createAccountButton  setCenter:[connectAccountButton  center]];
                [connectAccountButton setCenter:[externalAccountButton center]];

            } else if (!show_logo && !show_new && show_extern ) {
                // move up the extern button
                [externalAccountButton setCenter:[createAccountButton center]];
            }
            placement_done = YES;
        }
        if (!show_extern && !show_logo) {
            // no option to create or specify a custom account: go to connect view directly
            view = connectAccountView;
        }
    }
    */
    
    [[LinphoneManager instance] lpConfigSetBool:(view != signInView || back) forKey:@"animations_preference"];
    if (view == signInView) {
        if (!back) {
            //[self fillCredentials];
        }
    } else if (view == countryLoginView) {
        if (!back) {
            waitView.hidden = NO;
            [self pullCountriesWithCompletion:^{
               waitView.hidden = YES;
            [self.countryNameLoginViewField becomeFirstResponder];
            }];
        }
    } else if (view == logInView) {
        if (!back) {
            [self fillCredentials];
        }
    } else if (view == countrySignUpView) {
        [self cleanUpSignUpView];

        waitView.hidden = NO;
        [self pullCountriesWithCompletion:^{
            waitView.hidden = YES;
            [self.countryNameSignUpField becomeFirstResponder];
        }];
    } else if (view == phoneNumberSignUpView) {
            if (!back) {
                self.phoneNumberSignUpField.text = self.selectedCountryCode;
                [self.phoneNumberSignUpField becomeFirstResponder];
            }
    } else if (view == signUpView) {
        if (!back) {
            [self.firstNameSignUpField becomeFirstResponder];
        }
    } else if (view == activateAccountView) {
        self.activationCodeActivateField.text = @"";
        [self.activationCodeActivateField becomeFirstResponder];
    } else if (view == passwordReceivedView) {
        self.passwordFinishField.text = self.password;
    } else if (view == askPhoneNumberView) {
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSString *phoneNumber = [userDefaults objectForKey:caspianPhoneNumber];
        
        waitView.hidden = NO;
        [self pullCountriesWithCompletion:^{
            waitView.hidden = YES;
            self.phoneNumberAskPhoneNumberField.text = phoneNumber;
        }];
    } else if (view == forgotPasswordView) {
        waitView.hidden = NO;
        [self pullCountriesWithCompletion:^{
            waitView.hidden = YES;
            [self.countryNameForgotPasswordField becomeFirstResponder];
            self.phoneNumberForgotPasswordField.text = self.selectedCountryCode;
        }];
    }
    
    // Animation
    if (animation && [[LinphoneManager instance] lpConfigBoolForKey:@"animations_preference"] == YES) {
      CATransition* trans = [CATransition animation];
      [trans setType:kCATransitionPush];
      [trans setDuration:0.35];
      [trans setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
      if (back) {
          [trans setSubtype:kCATransitionFromLeft];
      } else {
          [trans setSubtype:kCATransitionFromRight];
      }
      [contentView.layer addAnimation:trans forKey:@"Transition"];
    }
    
    // Stack current view
    if (currentView != nil) {
        if (!back) {
            [historyViews addObject:currentView];
        }
        [currentView removeFromSuperview];
    }
    
    // Set current view
    currentView = view;
    [contentView insertSubview:view atIndex:0];
    view.frame = contentView.bounds;
    contentView.contentSize = view.bounds.size;
}

- (void)clearProxyConfig {
	linphone_core_clear_proxy_config([LinphoneManager getLc]);
	linphone_core_clear_all_auth_info([LinphoneManager getLc]);
}

- (void)setDefaultSettings:(LinphoneProxyConfig*)proxyCfg {
    LinphoneManager* lm = [LinphoneManager instance];

	[lm configurePushTokenForProxyConfig:proxyCfg];

}

- (BOOL)addProxyConfig:(NSString*)username password:(NSString*)password domain:(NSString*)domain withTransport:(NSString*)transport {
    LinphoneCore* lc = [LinphoneManager getLc];
	LinphoneProxyConfig* proxyCfg = linphone_core_create_proxy_config(lc);
	//NSString* server_address = domain;

    NSString *uriSuffix = [NSString stringWithFormat:@"%@:5060;transport=tcp", domain];
    linphone_proxy_config_set_server_addr(proxyCfg, [uriSuffix cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    char normalizedUserName[256];
    linphone_proxy_config_normalize_number(proxyCfg, [username cStringUsingEncoding:[NSString defaultCStringEncoding]], normalizedUserName, sizeof(normalizedUserName));

    const char* identity = linphone_proxy_config_get_identity(proxyCfg);
    if( !identity || !*identity ) identity = "sip:user@example.com";

    LinphoneAddress* linphoneAddress = linphone_address_new(identity);
    linphone_address_set_username(linphoneAddress, normalizedUserName);

    if( domain && [domain length] != 0) {
        /*
		if( transport != nil ){
			server_address = [NSString stringWithFormat:@"%@;transport=%@", server_address, [transport lowercaseString]];
		}
        */
        // when the domain is specified (for external login), take it as the server address
        /*
         This line of code cuts off specefied transport type in uri from xml config
         for example here is setting from xml config:
         sip:194.72.111.163:5060;transport=tcp
         this line changes uri to:
         sip:194.72.111.163
        */
        //linphone_proxy_config_set_server_addr(proxyCfg, [server_address UTF8String]);
        linphone_address_set_domain(linphoneAddress, [domain UTF8String]);
    }

    char* extractedAddres = linphone_address_as_string_uri_only(linphoneAddress);

	LinphoneAddress* parsedAddress = linphone_address_new(extractedAddres);
	ms_free(extractedAddres);

    if( parsedAddress == NULL || !linphone_address_is_sip(parsedAddress) ){
		if( parsedAddress ) linphone_address_destroy(parsedAddress);
		UIAlertView* errorView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Check error(s)",nil)
															message:NSLocalizedString(@"Please enter a valid username", nil)
														   delegate:nil
												  cancelButtonTitle:NSLocalizedString(@"Continue",nil)
												  otherButtonTitles:nil,nil];
		[errorView show];
		[errorView release];
		return FALSE;
	}

	char *c_parsedAddress = linphone_address_as_string_uri_only(parsedAddress);

	linphone_proxy_config_set_identity(proxyCfg, c_parsedAddress);

	linphone_address_destroy(parsedAddress);
	ms_free(c_parsedAddress);

    LinphoneAuthInfo* info = linphone_auth_info_new([username UTF8String]
													, NULL, [password UTF8String]
													, NULL
													, NULL
													,linphone_proxy_config_get_domain(proxyCfg));

    [self setDefaultSettings:proxyCfg];

    [self clearProxyConfig];

    linphone_proxy_config_enable_register(proxyCfg, true);
	linphone_core_add_auth_info(lc, info);
    linphone_core_add_proxy_config(lc, proxyCfg);
	linphone_core_set_default_proxy_config(lc, proxyCfg);
	return TRUE;
}

- (void)addProvisionedProxy:(NSString*)username withPassword:(NSString*)password withDomain:(NSString*)domain {
    [self clearProxyConfig];

	LinphoneProxyConfig* proxyCfg = linphone_core_create_proxy_config([LinphoneManager getLc]);

    const char *addr= linphone_proxy_config_get_domain(proxyCfg);
    char normalizedUsername[256];
    LinphoneAddress* linphoneAddress = linphone_address_new(addr);

    linphone_proxy_config_normalize_number(proxyCfg,
                                           [username cStringUsingEncoding:[NSString defaultCStringEncoding]],
                                           normalizedUsername,
                                           sizeof(normalizedUsername));

    linphone_address_set_username(linphoneAddress, normalizedUsername);
    linphone_address_set_domain(linphoneAddress, [domain UTF8String]);

    const char* identity = linphone_address_as_string_uri_only(linphoneAddress);
	linphone_proxy_config_set_identity(proxyCfg, identity);

    LinphoneAuthInfo* info = linphone_auth_info_new([username UTF8String], NULL, [password UTF8String], NULL, NULL, [domain UTF8String]);

    linphone_proxy_config_enable_register(proxyCfg, true);
	linphone_core_add_auth_info([LinphoneManager getLc], info);
    linphone_core_add_proxy_config([LinphoneManager getLc], proxyCfg);
	linphone_core_set_default_proxy_config([LinphoneManager getLc], proxyCfg);
}

- (NSString*)identityFromUsername:(NSString*)username {
    char normalizedUserName[256];
    LinphoneAddress* linphoneAddress = linphone_address_new("sip:user@domain.com");
    linphone_proxy_config_normalize_number(NULL, [username cStringUsingEncoding:[NSString defaultCStringEncoding]], normalizedUserName, sizeof(normalizedUserName));
    linphone_address_set_username(linphoneAddress, normalizedUserName);
    linphone_address_set_domain(linphoneAddress, [[[LinphoneManager instance] lpConfigStringForKey:@"domain" forSection:@"wizard"] UTF8String]);
    NSString* uri = [NSString stringWithUTF8String:linphone_address_as_string_uri_only(linphoneAddress)];
    NSString* scheme = [NSString stringWithUTF8String:linphone_address_get_scheme(linphoneAddress)];
    return [uri substringFromIndex:[scheme length] + 1];
}


#pragma mark - Linphone XMLRPC

- (void)checkUserExist:(NSString*)username {
    [LinphoneLogger log:LinphoneLoggerLog format:@"XMLRPC check_account %@", username];
    
    NSURL *URL = [NSURL URLWithString:[[LinphoneManager instance] lpConfigStringForKey:@"service_url" forSection:@"wizard"]];
    XMLRPCRequest *request = [[XMLRPCRequest alloc] initWithURL: URL];
    [request setMethod: @"check_account" withParameters:[NSArray arrayWithObjects:username, nil]];
    
    XMLRPCConnectionManager *manager = [XMLRPCConnectionManager sharedManager];
    [manager spawnConnectionWithXMLRPCRequest: request delegate: self];
    
    [request release];
    [waitView setHidden:false];
}

- (void)createAccount:(NSString*)identity password:(NSString*)password email:(NSString*)email {
    NSString *useragent = [LinphoneManager getUserAgent];
    [LinphoneLogger log:LinphoneLoggerLog format:@"XMLRPC create_account_with_useragent %@ %@ %@ %@", identity, password, email, useragent];
    
    NSURL *URL = [NSURL URLWithString: [[LinphoneManager instance] lpConfigStringForKey:@"service_url" forSection:@"wizard"]];
    XMLRPCRequest *request = [[XMLRPCRequest alloc] initWithURL: URL];
    [request setMethod: @"create_account_with_useragent" withParameters:[NSArray arrayWithObjects:identity, password, email, useragent, nil]];
    
    XMLRPCConnectionManager *manager = [XMLRPCConnectionManager sharedManager];
    [manager spawnConnectionWithXMLRPCRequest: request delegate: self];
    
    [request release];
    [waitView setHidden:false];
}

- (void)checkAccountValidation:(NSString*)identity {
    [LinphoneLogger log:LinphoneLoggerLog format:@"XMLRPC check_account_validated %@", identity];
    
    NSURL *URL = [NSURL URLWithString: [[LinphoneManager instance] lpConfigStringForKey:@"service_url" forSection:@"wizard"]];
    XMLRPCRequest *request = [[XMLRPCRequest alloc] initWithURL: URL];
    [request setMethod: @"check_account_validated" withParameters:[NSArray arrayWithObjects:identity, nil]];
    
    XMLRPCConnectionManager *manager = [XMLRPCConnectionManager sharedManager];
    [manager spawnConnectionWithXMLRPCRequest: request delegate: self];
    
    [request release];
    [waitView setHidden:false];
}


#pragma mark -

- (void)registrationUpdate:(LinphoneRegistrationState)state message:(NSString*)message{
    switch (state) {
        case LinphoneRegistrationOk: {
            BOOL isRememberCredentials = self.rememberMeRegisterSwitch.isOn;
            NSString *phoneNumber = isRememberCredentials ? self.phoneNumberRegisterField.text : @"";
            NSString *password    = isRememberCredentials ? self.passwordRegisterField.text : @"";
            NSString *domain      = isRememberCredentials ? self.domainRegisterField.text : @"";
            
            [self savePhoneNumber:phoneNumber andPassword:password andDomain:domain];
            [[LinphoneManager instance] resetSettingsToDefault:[LinphoneManager getLc]];

            [waitView setHidden:true];
            [[PhoneMainView instance] changeCurrentView:[DialerViewController compositeViewDescription]];
            break;
        }
        case LinphoneRegistrationNone:
        case LinphoneRegistrationCleared:  {
            [waitView setHidden:true];
            if (LinphoneGlobalShutdown) {
                [self resign];
            }
            break;
        }
        case LinphoneRegistrationFailed: {
            [waitView setHidden:true];
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Registration failure", nil)
                                                            message:message
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
            [alert release];
            break;
        }
        case LinphoneRegistrationProgress: {
            [waitView setHidden:false];
            break;
        }
        default:
            break;
    }
}

- (void)loadWizardConfig:(NSString*)rcFilename {
    NSString* fullPath = [@"file://" stringByAppendingString:[LinphoneManager bundleFile:rcFilename]];
    linphone_core_set_provisioning_uri([LinphoneManager getLc], [fullPath cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    [[LinphoneManager instance] lpConfigSetInt:1 forKey:@"transient_provisioning" forSection:@"misc"];
    [[LinphoneManager instance] resetLinphoneCore];
}


#pragma mark - UITextFieldDelegate Functions

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.passwordRegisterField) {
        [self loginInMethod];
    } else
    if (textField == self.firstNameSignUpField) {
        [self.lastNameSignUpField becomeFirstResponder];
    } else if (textField == self.lastNameSignUpField) {
        [self changeView:getActivationByCodeView back:NO animation:YES];
    } else {
        [textField resignFirstResponder];
    }
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    activeTextField = textField;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [self checkNextStep];
}
    
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (textField == self.countryNameSignUpField || textField == self.passwordFinishField) {
        return NO;
    }
    
    // only validate the username when creating a new account
    if( (textField.tag == ViewElement_Username) && (currentView == passwordReceivedView) ){
        NSRegularExpression *regex = [NSRegularExpression
                                      regularExpressionWithPattern:@"^[a-z0-9-_\\.]*$"
                                      options:NSRegularExpressionCaseInsensitive
                                      error:nil];
        NSArray* matches = [regex matchesInString:string options:0 range:NSMakeRange(0, [string length])];
        if ([matches count] == 0) {
            UILabel* error = [WizardViewController findLabel:ViewElement_Username_Error view:contentView];

            // show error with fade animation
            [error setText:[NSString stringWithFormat:NSLocalizedString(@"Illegal character in username: %@", nil), string]];
            error.alpha = 0;
            error.hidden = NO;
            [UIView animateWithDuration:0.3 animations:^{
                error.alpha = 1;
            }];

            // hide again in 2s
            [NSTimer scheduledTimerWithTimeInterval:2.0f target:self selector:@selector(hideError:) userInfo:nil repeats:NO];


            return NO;
        }
    }
    return YES;
}

- (void)hideError:(NSTimer*)timer {
    UILabel* error_label =[WizardViewController findLabel:ViewElement_Username_Error view:contentView];
    if( error_label ) {
        [UIView animateWithDuration:0.3
                         animations:^{
                             error_label.alpha = 0;
                         }
                         completion: ^(BOOL finished) {
                             error_label.hidden = YES;
                         }
         ];
    }
}

- (void)loginInMethod {
    NSString *phone    = self.phoneNumberRegisterField.text;
    NSString *password = self.passwordRegisterField.text;
    NSString *domain   = self.domainRegisterField.text;
    
    NSMutableString *errors = [NSMutableString string];
    if ([phone length] == 0) {
        [errors appendString:[NSString stringWithFormat:NSLocalizedString(@"Please enter a username.\n", nil)]];
    }
    
    if ([errors length]) {
        UIAlertView* errorView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Check error(s)",nil)
                                                            message:[errors substringWithRange:NSMakeRange(0, [errors length] - 1)]
                                                           delegate:nil
                                                  cancelButtonTitle:NSLocalizedString(@"Continue",nil)
                                                  otherButtonTitles:nil,nil];
        [errorView show];
        [errorView release];
    } else {
        [self checkIsSameUserSigningIn:phone];
        [self.waitView setHidden:false];
        [self addProxyConfig:[[LinphoneManager instance] removeUnneededPrefixes:phone] password:password domain:domain withTransport:@"tcp"];
    }
}


#pragma mark - Action Functions

- (IBAction)onStartClick:(id)sender {
    [self changeView:countrySignUpView back:FALSE animation:TRUE];
}

- (IBAction)onBackClick:(id)sender {
    if ([historyViews count] > 0) {
        UIView * view = [[[historyViews lastObject] retain] autorelease];
        [historyViews removeLastObject];
        [self changeView:view back:TRUE animation:TRUE];
    }
}

- (IBAction)onCancelClick:(id)sender {
    [[PhoneMainView instance] changeCurrentView:[DialerViewController compositeViewDescription]];
}

- (IBAction)onCreateAccountClick:(id)sender {
    nextView = passwordReceivedView;
    [self loadWizardConfig:@"wizard_linphone_create.rc"];
}

- (IBAction)onConnectLinphoneAccountClick:(id)sender {
    nextView = connectAccountView;
    [self loadWizardConfig:@"wizard_linphone_existing.rc"];
}

- (IBAction)onExternalAccountClick:(id)sender {
    nextView = forgotPasswordView;
    [self loadWizardConfig:@"wizard_external_sip.rc"];
}

- (IBAction)onCheckValidationClick:(id)sender {
    NSString *username = [WizardViewController findTextField:ViewElement_Username view:contentView].text;
    NSString *identity = [self identityFromUsername:username];
    [self checkAccountValidation:identity];
}

- (IBAction)onRemoteProvisioningClick:(id)sender {
    UIAlertView* remoteInput = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Enter provisioning URL", @"")
                                                          message:@""
                                                         delegate:self
                                                cancelButtonTitle:NSLocalizedString(@"Cancel", @"")
                                                otherButtonTitles:NSLocalizedString(@"Fetch", @""), nil];
    remoteInput.alertViewStyle = UIAlertViewStylePlainTextInput;

    UITextField* prov_url = [remoteInput textFieldAtIndex:0];
    prov_url.keyboardType = UIKeyboardTypeURL;
    prov_url.text = [[LinphoneManager instance] lpConfigStringForKey:@"config-uri" forSection:@"misc"];
    prov_url.placeholder  = @"URL";

    [remoteInput show];
    [remoteInput release];
}

- (void)verificationSignInWithUsername:(NSString*)username password:(NSString*)password domain:(NSString*)domain withTransport:(NSString*)transport {
	NSMutableString *errors = [NSMutableString string];
	if ([username length] == 0) {
		[errors appendString:[NSString stringWithFormat:NSLocalizedString(@"Please enter a valid username.\n", nil)]];
	}

	if (domain != nil && [domain length] == 0) {
		[errors appendString:[NSString stringWithFormat:NSLocalizedString(@"Please enter a valid domain.\n", nil)]];
	}

	if([errors length]) {
		UIAlertView* errorView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Check error(s)",nil)
															message:[errors substringWithRange:NSMakeRange(0, [errors length] - 1)]
														   delegate:nil
												  cancelButtonTitle:NSLocalizedString(@"Continue",nil)
												  otherButtonTitles:nil,nil];
		[errorView show];
		[errorView release];
	} else {
		[waitView setHidden:false];
		if ([LinphoneManager instance].connectivity == none) {
			DTAlertView *alert = [[DTAlertView alloc] initWithTitle:NSLocalizedString(@"No connectivity", nil)
															message:NSLocalizedString(@"You can either skip verification or connect to the Internet first.", nil)];
			[alert addCancelButtonWithTitle:NSLocalizedString(@"Stay here", nil) block:^{
				[waitView setHidden:true];
			}];
			[alert addButtonWithTitle:NSLocalizedString(@"Continue", nil) block:^{
				[waitView setHidden:true];
				[self addProxyConfig:username password:password domain:domain withTransport:transport];
				[[PhoneMainView instance] changeCurrentView:[DialerViewController compositeViewDescription]];
			}];
			[alert show];
		} else {
			BOOL success = [self addProxyConfig:username password:password domain:domain withTransport:transport];
			if( !success ){
				waitView.hidden = true;
			}
		}
	}
}

- (IBAction)onSignInExternalClick:(id)sender {
    [self loginInMethod];
}

- (IBAction)onSignInClick:(id)sender {
	// domain and server will be configured from the default proxy values
    [self verificationSignInWithUsername:self.phoneNumberRegisterField.text password:self.passwordRegisterField.text domain:nil withTransport:nil];
}

- (IBAction)onSignUpClick:(id)sender {
    [self changeView:countrySignUpView back:FALSE animation:TRUE];
}

- (IBAction)onRegisterClick:(id)sender {
    UITextField* username_tf = [WizardViewController findTextField:ViewElement_Username  view:contentView];
    NSString *username = username_tf.text;
    NSString *password = [WizardViewController findTextField:ViewElement_Password  view:contentView].text;
    NSString *password2 = [WizardViewController findTextField:ViewElement_Password2  view:contentView].text;
    NSString *email = [WizardViewController findTextField:ViewElement_Email view:contentView].text;
    NSMutableString *errors = [NSMutableString string];

    NSInteger username_length = [[LinphoneManager instance] lpConfigIntForKey:@"username_length" forSection:@"wizard"];
    NSInteger password_length = [[LinphoneManager instance] lpConfigIntForKey:@"password_length" forSection:@"wizard"];
    
    if ([username length] < username_length) {
        [errors appendString:[NSString stringWithFormat:NSLocalizedString(@"The username is too short (minimum %d characters).\n", nil), username_length]];
    }
    
    if ([password length] < password_length) {
        [errors appendString:[NSString stringWithFormat:NSLocalizedString(@"The password is too short (minimum %d characters).\n", nil), password_length]];
    }
    
    if (![password2 isEqualToString:password]) {
        [errors appendString:NSLocalizedString(@"The passwords are different.\n", nil)];
    }
    
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", @".+@.+\\.[A-Za-z]{2}[A-Za-z]*"];
    if(![emailTest evaluateWithObject:email]) {
        [errors appendString:NSLocalizedString(@"The email is invalid.\n", nil)];
    }

    if([errors length]) {
        UIAlertView* errorView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Check error(s)",nil)
                                                        message:[errors substringWithRange:NSMakeRange(0, [errors length] - 1)]
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"Continue",nil)
                                              otherButtonTitles:nil,nil];
        [errorView show];
        [errorView release];

    } else {
        username = [username lowercaseString];
        [username_tf setText:username];
        NSString *identity = [self identityFromUsername:username];
        [self checkUserExist:identity];
    }
}

- (IBAction)onProvisionedLoginClick:(id)sender {
    NSString *username = provisionedUsername.text;
    NSString *password = provisionedPassword.text;

    NSMutableString *errors = [NSMutableString string];
    if ([username length] == 0) {

        [errors appendString:[NSString stringWithFormat:NSLocalizedString(@"Please enter a valid username.\n", nil)]];
    }

    if([errors length]) {
        UIAlertView* errorView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Check error(s)",nil)
                                                            message:[errors substringWithRange:NSMakeRange(0, [errors length] - 1)]
                                                           delegate:nil
                                                  cancelButtonTitle:NSLocalizedString(@"Continue",nil)
                                                  otherButtonTitles:nil,nil];
        [errorView show];
        [errorView release];
    } else {
        [self.waitView setHidden:false];
        [self addProvisionedProxy:username withPassword:password withDomain:provisionedDomain.text];
    }
}

- (IBAction)onViewTap:(id)sender {
    [LinphoneUtils findAndResignFirstResponder:currentView];
}

- (IBAction)onBackButtonClicked:(id)sender {
    WizardViewController *controller = DYNAMIC_CAST([[PhoneMainView instance] changeCurrentView:[WizardViewController compositeViewDescription]], WizardViewController);
    
    if(controller != nil) {
        [controller reset];
    }
}

- (IBAction)onCountryPickerNextTap:(id)sender {
    self.currentCountryRow = [self.countryPickerView selectedRowInComponent:0];
    [self.phoneNumberSignUpField becomeFirstResponder];
    [self.phoneNumberForgotPasswordField becomeFirstResponder];
}

- (IBAction)onPhoneNumberRegisterNextTap:(id)sender {
    [self.firstNameSignUpField becomeFirstResponder];
}

- (IBAction)onPhoneNumberSignInNextTap:(id)sender {
    [self.passwordRegisterField becomeFirstResponder];
}

- (IBAction)onDoneNumKeypad:(id)sender {
    [self.view endEditing:YES];
}

- (IBAction)onSmsContinueCreatingAccountTap:(id)sender {
    [self onContinueCreatingAccountTap:YES];
}

- (IBAction)onCallContinueCreatingAccountTap:(id)sender {
    [self onContinueCreatingAccountTap:NO];
}


- (IBAction)onCancelConfirmTap:(UIButton *)sender {
    [self animateConfirmViewHide:YES];
}

- (IBAction)onOkConfirmTap:(UIButton *)sender {
    NSString *cleanPhoneNumberSignUpField = self.phoneNumberSignUpField.text;
    NSString *countryCode = self.countryCodeSignUpField.text;
    [self animateConfirmViewHide:YES];
    cleanPhoneNumberSignUpField = [cleanPhoneNumberSignUpField substringFromIndex:countryCode.length-1];
    [self checkAndCreateAccountForPhoneNumber:cleanPhoneNumberSignUpField
                                  countryCode:self.countryCodeSignUpField.text
                                    firstName:self.firstNameSignUpField.text
                                     lastName:self.lastNameSignUpField.text
                                activateBySms:isAvableActivateBySMS]; //self.activateBySignUpSegmented.selectedSegmentIndex == 0]
}

- (IBAction)onContinueActivatingTap:(id)sender {
    [self activateAccountWithCode:self.activationCodeActivateField.text];
}

- (IBAction)onContinuePasswordTap:(id)sender {
    self.phoneNumberRegisterField.text = self.phoneNumber;
    self.passwordRegisterField.text = self.password;
    
    [self changeView:signInView back:YES animation:YES];
}

- (IBAction)onForgotPasswordTap:(id)sender {
    [self changeView:askPhoneNumberView back:NO animation:YES];
}

- (IBAction)onSubmitForgotPasswordTap:(id)sender {
    [self submitRecoveryPasswordAction];
}

- (IBAction)onNoAskPasswordTap:(UIButton *)sender {
    [self changeView:forgotPasswordView back:NO animation:YES];
}

- (IBAction)onYesAskPasswordTap:(UIButton *)sender {
    NSDictionary *country = [self countryByPhoneNumber:self.phoneNumberAskPhoneNumberField.text];
    NSString *countryCode = country[caspianCountryObjectFieldCode];
    if (countryCode) {
        NSString *phoneNumber = [self.phoneNumberAskPhoneNumberField.text substringFromIndex:countryCode.length];
        [self recoverPasswordForPhoneNumber:phoneNumber andCountryCode:countryCode];
    } else {
        [self alertErrorMessageEmptyCountry];
    }
}

- (IBAction)onSmsMePassword:(UIButton *)sender {
    [self recoverPasswordForPhoneNumber:self.phoneNumberSignUpField.text
                         andCountryCode:self.countryCodeSignUpField.text];
}

- (IBAction)onRemovePhoneFromCard:(UIButton *)sender {
    [self removePhoneNumberFromCard:self.phoneNumberExistsPhoneNumberField.text];
}

- (IBAction)onCountryListPullCancel:(UIButton *)sender {
    [self.serialCountryListPullQueue cancelAllOperations];
    [self onBackButtonClicked:sender];
}

- (IBAction)onLogInClick:(id)sender {
    [self changeView:countryLoginView back:FALSE animation:TRUE];
}

- (IBAction)onNextLogInClick:(id)sender {
    [self saveSelectedCountry];
    [self changeView:logInView back:NO animation:YES];
}

- (IBAction)onNextCountrySignUpClick:(id)sender {
        //[self saveSelectedCountry];
    if (currentView == self.forgotPasswordView) {
        [self.phoneNumberForgotPasswordField becomeFirstResponder];
    } else {
    [self changeView:phoneNumberSignUpView back:NO animation:YES];
    }
}

- (IBAction)onNextPhoneNumberSignUpClick:(id)sender {
        //[self saveSelectedCountry];
    [self changeView:signUpView back:NO animation:YES];
}

- (IBAction)onContinueSingUpView:(id)sender {
        //[self saveSelectedCountry];
    [self changeView:getActivationByCodeView back:NO animation:YES];
}

- (IBAction)onDismissKeyboardButton:(id)sender {
    if ([self.countryNameLoginViewField isFirstResponder]) {
        [self.countryNameLoginViewField resignFirstResponder];
    } else if ([self.phoneNumberRegisterField isFirstResponder]) {
        [self.phoneNumberRegisterField resignFirstResponder];
    } else if ([self.passwordRegisterField isFirstResponder]) {
        [self.passwordRegisterField resignFirstResponder];
    } else if ([self.countryNameSignUpField isFirstResponder]) {
        [self.countryNameSignUpField resignFirstResponder];
    } else if ([self.countryNameForgotPasswordField isFirstResponder]) {
        [self.countryNameForgotPasswordField resignFirstResponder];
    } else if ([self.phoneNumberForgotPasswordField isFirstResponder]) {
        [self.phoneNumberForgotPasswordField resignFirstResponder];
    } else if ([self.countryNameSignUpField isFirstResponder]) {
        [self.countryNameSignUpField resignFirstResponder];
    } else if ([self.phoneNumberSignUpField isFirstResponder]) {
        [self.phoneNumberSignUpField resignFirstResponder];
    } else if ([self.firstNameSignUpField isFirstResponder]) {
        [self.firstNameSignUpField resignFirstResponder];
    } else if ([self.lastNameSignUpField isFirstResponder]) {
        [self.lastNameSignUpField resignFirstResponder];
    } else if ([self.activationCodeActivateField isFirstResponder]) {
        [self.activationCodeActivateField resignFirstResponder];
    }


}


#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([alertView isKindOfClass:[COCAlertView class]]) {
        COCAlertView *ownAlertView = (COCAlertView *)alertView;
        if (ownAlertView.completion) {
            ownAlertView.completion();
        }
    }
}

- (void)configuringUpdate:(NSNotification *)notif {
    LinphoneConfiguringState status = (LinphoneConfiguringState)[[notif.userInfo valueForKey:@"state"] integerValue];

    [waitView setHidden:true];

    switch (status) {
        case LinphoneConfiguringSuccessful:
            if( nextView == nil ){
            [self fillDefaultValues];
            } else {
                [self changeView:nextView back:false animation:TRUE];
                nextView = nil;
            }
            break;
        case LinphoneConfiguringFailed:
        {
            NSString* error_message = [notif.userInfo valueForKey:@"message"];
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Provisioning Load error", nil)
                                                            message:error_message
                                                           delegate:nil
                                                  cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                  otherButtonTitles: nil];
            [alert show];
            [alert release];
            break;
        }

        case LinphoneConfiguringSkipped:
        default:
            break;
    }
}


#pragma mark - Event Functions

- (void)registrationUpdateEvent:(NSNotification*)notif {
    NSString* message = [notif.userInfo objectForKey:@"message"];
    [self registrationUpdate:[[notif.userInfo objectForKey: @"state"] intValue] message:message];
}


#pragma mark - Keyboard Event Functions

- (void)keyboardWillHide:(NSNotification *)notif {
    //CGRect beginFrame = [[[notif userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    //CGRect endFrame = [[[notif userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    UIViewAnimationCurve curve = [[[notif userInfo] objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue];
    NSTimeInterval duration = [[[notif userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    [UIView beginAnimations:@"resize" context:nil];
    [UIView setAnimationDuration:duration];
    [UIView setAnimationCurve:curve];
    [UIView setAnimationBeginsFromCurrentState:TRUE];
    
    // Move view
    UIEdgeInsets inset = {0, 0, 0, 0};
    [contentView setContentInset:inset];
    [contentView setScrollIndicatorInsets:inset];
    [contentView setShowsVerticalScrollIndicator:FALSE];
    
    [UIView commitAnimations];
}

- (void)keyboardWillShow:(NSNotification *)notif {
    //CGRect beginFrame = [[[notif userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    CGRect endFrame = [[[notif userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    UIViewAnimationCurve curve = [[[notif userInfo] objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue];
    NSTimeInterval duration = [[[notif userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    [UIView beginAnimations:@"resize" context:nil];
    [UIView setAnimationDuration:duration];
    [UIView setAnimationCurve:curve];
    [UIView setAnimationBeginsFromCurrentState:TRUE];
    
    if(([[UIDevice currentDevice].systemVersion floatValue] < 8) &&
       UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
        int width = endFrame.size.height;
        endFrame.size.height = endFrame.size.width;
        endFrame.size.width = width;
    }
    
    // Change inset
    {
        UIEdgeInsets inset = {0,0,0,0};
        CGRect frame = [contentView frame];
        CGRect rect = [PhoneMainView instance].view.bounds;
        CGPoint pos = {frame.size.width, frame.size.height};
        CGPoint gPos = [contentView convertPoint:pos toView:[UIApplication sharedApplication].keyWindow.rootViewController.view]; // Bypass IOS bug on landscape mode
        inset.bottom = -(rect.size.height - gPos.y - endFrame.size.height);
        if(inset.bottom < 0) inset.bottom = 0;
        
        [contentView setContentInset:inset];
        [contentView setScrollIndicatorInsets:inset];
        CGRect fieldFrame = activeTextField.frame;
        fieldFrame.origin.y += fieldFrame.size.height;
        [contentView scrollRectToVisible:fieldFrame animated:TRUE];
        [contentView setShowsVerticalScrollIndicator:TRUE];
    }
    [UIView commitAnimations];
}


#pragma mark - XMLRPCConnectionDelegate Functions

- (void)request:(XMLRPCRequest *)request didReceiveResponse:(XMLRPCResponse *)response {
    [LinphoneLogger log:LinphoneLoggerLog format:@"XMLRPC %@: %@", [request method], [response body]];
    [waitView setHidden:true];
    if ([response isFault]) {
        NSString *errorString = [NSString stringWithFormat:NSLocalizedString(@"Communication issue (%@)", nil), [response faultString]];
        UIAlertView* errorView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Communication issue",nil)
                                                            message:errorString
                                                           delegate:nil
                                                  cancelButtonTitle:NSLocalizedString(@"Continue",nil)
                                                  otherButtonTitles:nil,nil];
        [errorView show];
        [errorView release];
    } else if([response object] != nil) { //Don't handle if not object: HTTP/Communication Error
        if([[request method] isEqualToString:@"check_account"]) {
            if([response object] == [NSNumber numberWithInt:1]) {
                UIAlertView* errorView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Check issue",nil)
                                                                message:NSLocalizedString(@"Username already exists", nil)
                                                               delegate:nil
                                                      cancelButtonTitle:NSLocalizedString(@"Continue",nil)
                                                      otherButtonTitles:nil,nil];
                [errorView show];
                [errorView release];
            } else {
                NSString *username = [WizardViewController findTextField:ViewElement_Username view:contentView].text;
                NSString *password = [WizardViewController findTextField:ViewElement_Password view:contentView].text;
                NSString *email = [WizardViewController findTextField:ViewElement_Email view:contentView].text;
                NSString* identity = [self identityFromUsername:username];
                [self createAccount:identity password:password email:email];
            }
        } else if([[request method] isEqualToString:@"create_account_with_useragent"]) {
            if([response object] == [NSNumber numberWithInt:0]) {
                NSString *username = [WizardViewController findTextField:ViewElement_Username view:contentView].text;
                NSString *password = [WizardViewController findTextField:ViewElement_Password view:contentView].text;
                [self changeView:activateAccountView back:FALSE animation:TRUE];
                [WizardViewController findTextField:ViewElement_Username view:contentView].text = username;
                [WizardViewController findTextField:ViewElement_Password view:contentView].text = password;
            } else {
                UIAlertView* errorView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Account creation issue",nil)
                                                                    message:NSLocalizedString(@"Can't create the account. Please try again.", nil)
                                                                   delegate:nil
                                                          cancelButtonTitle:NSLocalizedString(@"Continue",nil)
                                                          otherButtonTitles:nil,nil];
                [errorView show];
                [errorView release];
            }
        } else if([[request method] isEqualToString:@"check_account_validated"]) {
             if([response object] == [NSNumber numberWithInt:1]) {
                 NSString *username = [WizardViewController findTextField:ViewElement_Username view:contentView].text;
                 NSString *password = [WizardViewController findTextField:ViewElement_Password view:contentView].text;
                [self addProxyConfig:username password:password domain:nil withTransport:nil];
             } else {
                 UIAlertView* errorView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Account validation issue",nil)
                                                                     message:NSLocalizedString(@"Your account is not validate yet.", nil)
                                                                    delegate:nil
                                                           cancelButtonTitle:NSLocalizedString(@"Continue",nil)
                                                           otherButtonTitles:nil,nil];
                 [errorView show];
                 [errorView release];
             }
        }
    }
}

- (void)request:(XMLRPCRequest *)request didFailWithError:(NSError *)error {
    NSString *errorString = [NSString stringWithFormat:NSLocalizedString(@"Communication issue (%@)", nil), [error localizedDescription]];
    UIAlertView* errorView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Communication issue", nil)
                                                    message:errorString
                                                   delegate:nil
                                          cancelButtonTitle:NSLocalizedString(@"Continue", nil)
                                          otherButtonTitles:nil,nil];
    [errorView show];
    [errorView release];
    [waitView setHidden:true];
}

- (BOOL)request:(XMLRPCRequest *)request canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace {
    return FALSE;
}

- (void)request:(XMLRPCRequest *)request didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    
}

- (void)request:(XMLRPCRequest *)request didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    
}


#pragma mark - TPMultiLayoutViewController Functions

- (NSDictionary*)attributesForView:(UIView*)view {
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    [attributes setObject:[NSValue valueWithCGRect:view.frame] forKey:@"frame"];
    [attributes setObject:[NSValue valueWithCGRect:view.bounds] forKey:@"bounds"];
    if([view isKindOfClass:[UIButton class]]) {
        UIButton *button = (UIButton *)view;
        [LinphoneUtils buttonMultiViewAddAttributes:attributes button:button];
    }
    [attributes setObject:[NSNumber numberWithInteger:view.autoresizingMask] forKey:@"autoresizingMask"];
    return attributes;
}

- (void)applyAttributes:(NSDictionary*)attributes toView:(UIView*)view {
    view.frame = [[attributes objectForKey:@"frame"] CGRectValue];
    view.bounds = [[attributes objectForKey:@"bounds"] CGRectValue];
    if([view isKindOfClass:[UIButton class]]) {
        UIButton *button = (UIButton *)view;
        [LinphoneUtils buttonMultiViewApplyAttributes:attributes button:button];
    }
    view.autoresizingMask = [[attributes objectForKey:@"autoresizingMask"] integerValue];
}


#pragma mark - UIGestureRecognizerDelegate Functions

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if ([touch.view isKindOfClass:[UIButton class]]) {
		/* we resign any keyboard that's displayed when a button is touched */
        if([LinphoneUtils findAndResignFirstResponder:currentView]) {
            return NO;
        }
    }
    return YES;
}


#pragma mark - Picker view data source

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return self.countryAndCode.count;
}
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    NSDictionary *country = [self countryAtIndex:row];
    return country[caspianCountryObjectFieldName];
}


#pragma mark - Picker view delegate

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    [self didSelectCountryAtRow:row];
}


#pragma mark - Private

- (void)alertErrorMessageEmptyCountry {
    [self alertErrorMessage:NSLocalizedString(@"Can't determine a country code, please enter correct phone number or press NO and select a country from list", nil)
                  withTitle:NSLocalizedString(@"Wrong phone number", nil)
             withCompletion:nil];
}

- (void)alertErrorMessage:(NSString *)message withTitle:(NSString *)title withCompletion:(void(^)(void))completion {
    COCAlertView *alert = [[COCAlertView alloc] initWithTitle:title
                                                      message:message
                                                     delegate:self
                                            cancelButtonTitle:@"OK"
                                            otherButtonTitles:nil];
    alert.completion = completion;
    [alert show];
    [alert release];
}

- (void)pullCountriesWithCompletion:(void(^)(void))completion {
    if (self.serialCountryListPullQueue.operationCount == 0) {
        __block WizardViewController *weakSelf = self;
        [self.serialCountryListPullQueue addOperationWithBlock:^{
            [[LinphoneManager instance] dataFromUrlString:caspianCountryListUrl completionBlock:^(NSDictionary *countries) {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    completion();
                    [weakSelf fillCountryAndCodeArray:countries];
                }];
            } errorBlock:^(NSError *error) {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    NSString *path = [[NSBundle mainBundle] pathForResource:@"countries_list" ofType:@"json"];
                    NSString *jsonString = [[NSString alloc] initWithContentsOfFile:path encoding:NSUTF8StringEncoding error:NULL];

                    NSError *jsonError = nil;
                    NSDictionary *countries = [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding]
                                                                              options:NSJSONReadingMutableContainers
                                                                                error:&jsonError];
                    [jsonString release];
                    if (!jsonError) {
                        completion();
                        [weakSelf fillCountryAndCodeArray:countries];
                    } else {
                        weakSelf.countryAndCode = nil;
                        [weakSelf alertErrorMessage:error.localizedDescription withTitle:NSLocalizedString(@"Error retrieving country list", nil) withCompletion:nil];
                    }
                }];
            }];
        }];
    }
}

- (BOOL)isStatusSuccess:(NSDictionary *)jsonAnswer {
    NSString *status = jsonAnswer[@"status"];
    if (status) {
        return [status isEqualToString:@"success"];
    } else {
        status = jsonAnswer[@"success"];
        return [status boolValue];
    }
}

- (BOOL)checkCountryCode:(NSString *)code {
    if (code.length == 0) {
        [self alertErrorMessage:NSLocalizedString(@"Please select country first", nil)
                      withTitle:NSLocalizedString(@"Undefined country", nil)
                 withCompletion:nil];
    }
    return code.length > 0;
}

- (void)switchToActivationByCall {
        //self.activateBySignUpSegmented.selectedSegmentIndex = 1;
    isAvableActivateBySMS = NO;
}

- (void)checkIsSameUserSigningIn:(NSString *)phoneNumber {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    NSString *lastPhoneNumber = [userDefaults objectForKey:caspianPhoneNumber];
    if (![phoneNumber isEqualToString:lastPhoneNumber]) {
        [[LinphoneManager instance] cleanCallHistory];
    }
}

- (void)fillCountryAndCodeArray:(NSDictionary *)countries {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *country = [userDefaults objectForKey:caspianCountryName];
    
    self.countryAndCode = countries[caspianCountriesListTopKey];
    if (currentView == countryLoginView && country != NULL) {
        self.currentCountryRow = [self indexOfCountryWithName:country];
    } else {
    self.currentCountryRow = [self indexOfCountryWithName:caspianCountryDefaultName];
    }
}

- (void)saveSelectedCountry {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *countryCode = [userDefaults objectForKey:caspianCountryCode];
    
    if (![self.selectedCountryCode isEqualToString:countryCode]) {
        [userDefaults setObject:self.selectedCountryCode forKey:caspianCountryCode];
        [userDefaults setObject:self.countryNameLoginViewField.text forKey:caspianCountryName];

        [userDefaults setObject:@"" forKey:caspianPhoneNumber];
        [userDefaults setObject:@"" forKey:caspianPasswordKey];
    }
    
    [userDefaults synchronize];
}


#pragma mark - Sign Up

- (void)animateConfirmViewHide:(BOOL)hide {
    CGRect rootViewRect = self.view.frame;
    CGRect confirmViewRect = self.confirmView.frame;
    CGFloat confirmViewY = 80.0f;
    if (hide) {
        [UIView animateWithDuration:0.5f delay:0.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.confirmView.frame = CGRectMake(confirmViewRect.origin.x, rootViewRect.size.height, confirmViewRect.size.width, confirmViewRect.size.height);
        } completion:^(BOOL finished) {
            self.confirmView.hidden = hide;
        }];
    } else {
        self.confirmView.frame = CGRectMake(confirmViewRect.origin.x, rootViewRect.size.height, confirmViewRect.size.width, confirmViewRect.size.height);
        self.confirmView.hidden = hide;
        [UIView animateWithDuration:0.5f delay:0.0 options:UIViewAnimationOptionCurveEaseIn animations:^{
            self.confirmView.frame = CGRectMake(confirmViewRect.origin.x, confirmViewY, confirmViewRect.size.width, confirmViewRect.size.height);
        } completion:^(BOOL finished) {
        }];
    }
}

- (void)cleanUpSignUpView {
    self.phoneNumberSignUpField.text = @"";
    self.firstNameSignUpField.text = @"";
    self.lastNameSignUpField.text = @"";
}

- (NSInteger)indexOfCountryWithName:(NSString *)countryName {
    for (NSDictionary *country in self.countryAndCode) {
        if ([[country valueForKey:caspianCountryObjectFieldName] isEqualToString:countryName]) {
            return [self.countryAndCode indexOfObject:country];
        }
    }
    return 0;
}

- (void)didSelectCountryAtRow:(NSInteger)row {
    NSDictionary *country = [self countryAtIndex:row];

    [self updateFlagForCountry:country];
    
    self.selectedCountryCode = country[caspianCountryObjectFieldCode];
    NSString *fullCountryCode = [@"+" stringByAppendingString:self.selectedCountryCode != nil ? self.selectedCountryCode : @""];
    
    self.countryCodeSignUpField.text = self.selectedCountryCode.length > 0 ? fullCountryCode : @"";
    self.countryNameSignUpField.text = country[caspianCountryObjectFieldName];
    
    self.countryNameLoginViewField.text = self.countryNameSignUpField.text;
    
    self.countryCodeForgotPasswordField.text = self.countryCodeSignUpField.text;
    self.countryNameForgotPasswordField.text = self.countryNameSignUpField.text;
    self.phoneNumberForgotPasswordField.text = self.selectedCountryCode;
    
    [self checkNextStep];
    [self activationAvailableForCountry:country];
}

- (void)updateFlagForCountry:(NSDictionary *)country {
    if (currentView == self.countrySignUpView) {
        [self updateCountryFlag:country[caspianCountryObjectFieldFlag] activityIndicator:self.flagLoadingSignUpActivityIndicator flagImageView:self.countryFlagSignUpImage];
    } else if (currentView == self.forgotPasswordView) {
        [self updateCountryFlag:country[caspianCountryObjectFieldFlag] activityIndicator:self.flagLoadingForgotPasswordActivityIndicator flagImageView:self.countryFlagForgotPasswordImage];
    }
}

- (NSDictionary *)countryAtIndex:(NSInteger)index {
    return [self.countryAndCode objectAtIndex:index];
}

- (void)checkNextStep {
    BOOL isPhoneNumberValid = NO;
    if (self.countryCodeSignUpField.text.length > 0) {
        if (self.phoneNumberSignUpField.text.length > 0) {
            isPhoneNumberValid = YES;
            if (self.firstNameSignUpField.text.length > 0 && self.lastNameSignUpField.text.length > 0) {
                self.registrationNextStepSignUpLabel.text = NSLocalizedString(caspianContinue, nil);
            } else {
                self.registrationNextStepSignUpLabel.text = NSLocalizedString(caspianEnterName, nil);
            }
        } else {
            self.registrationNextStepSignUpLabel.text = NSLocalizedString(caspianEnterPhoneNumber, nil);
        }
    } else {
        self.registrationNextStepSignUpLabel.text = caspianSelectCountry;
    }
    self.continueSignUpField.enabled = isPhoneNumberValid;
}

- (void)activationAvailableForCountry:(NSDictionary *)country {
    BOOL isSmsAvailable = [country[caspianCountryObjectFieldSms] boolValue];
    BOOL isCallAvailable = [country[caspianCountryObjectFieldCall] boolValue];

        //[self.activateBySignUpSegmented setEnabled:isSmsAvailable forSegmentAtIndex:0];
        //[self.activateBySignUpSegmented setEnabled:isCallAvailable forSegmentAtIndex:1];
    
    if (isSmsAvailable) {
            //[self.activateBySignUpSegmented setSelectedSegmentIndex:0];
        isAvableActivateBySMS = YES;
    } else if (isCallAvailable) {
            //[self.activateBySignUpSegmented setSelectedSegmentIndex:1];
        isAvableActivateBySMS = NO;
    } else {
            //[self.activateBySignUpSegmented setSelectedSegmentIndex:UISegmentedControlNoSegment];
        isAvableActivated = NO;
    }
    
    self.continueSignUpField.enabled = self.continueSignUpField.enabled && (isCallAvailable || isSmsAvailable);
}

- (NSString *)correctPhoneNumber:(NSString *)phoneNumber andCountryCode:(NSString *)countryCode {
    NSString *fullPhoneNumber = nil;
    NSString *cleanPhoneNumber = nil;
    cleanPhoneNumber = [phoneNumber substringFromIndex:countryCode.length-1];
    if ([self checkCountryCode:countryCode]) {
        NSString *cleanedPhoneNumber = [[LinphoneManager instance] removeUnneededPrefixes:cleanPhoneNumber];
        fullPhoneNumber = [countryCode stringByAppendingString:cleanedPhoneNumber];
    }
    return fullPhoneNumber;
}

- (void)checkAndCreateAccountForPhoneNumber:(NSString *)phoneNumber
                                countryCode:(NSString *)countryCode
                                  firstName:(NSString *)firstName
                                   lastName:(NSString *)lastName
                              activateBySms:(BOOL)activateBySms {
    if ([self checkCountryCode:countryCode]) {
        waitView.hidden = NO;
        NSString *cleanedPhoneNumber = [[LinphoneManager instance] removeUnneededPrefixes:phoneNumber];
        NSString *cleanedCountryCode = [[LinphoneManager instance] removeUnneededPrefixes:countryCode];
        NSString *fullPhoneNumber = [cleanedCountryCode stringByAppendingString:cleanedPhoneNumber];
        [self checkPhoneNumberRegistered:fullPhoneNumber completion:^{
            [self checkPhoneNumberExists:fullPhoneNumber completion:^{
                NSString *createAccountUrl = [NSString stringWithFormat:caspianCreateAccountUrl
                                              , [[LinphoneManager instance] removeUnneededPrefixes:countryCode]
                                              , cleanedPhoneNumber
                                              , firstName
                                              , lastName
                                              , activateBySms ? @"sms" : @"call"
                                              ];
                [self createCaspianAccountByUrl:createAccountUrl activateType:activateBySms];
            }];
        }];
    }
}

- (void)checkPhoneNumberRegistered:(NSString *)phoneNumber completion:(void(^)(void))completion {
    __block WizardViewController *weakSelf = self;
    
    [self.internetQueue addOperationWithBlock:^{
        NSString *errorTitle = NSLocalizedString(@"Checking phone number failed", nil);
        NSString *checkAccountExistUrl = [NSString stringWithFormat:caspianCheckAccountExistUrl, phoneNumber];
        [[LinphoneManager instance] dataFromUrlString:checkAccountExistUrl completionBlock:^(NSDictionary *jsonAnswer) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                waitView.hidden = YES;
                if ([weakSelf isStatusSuccess:jsonAnswer]) {
                    // Account exists, it needs to be recovered
                    self.phoneNumberFoundPhoneNumberField.text = phoneNumber;
                    [weakSelf changeView:self.phoneNumberFoundView back:NO animation:YES];
                } else {
                    NSString *errorMessage = NSLocalizedString(@"Try to create account again", nil);
                    [weakSelf alertErrorMessage:errorMessage withTitle:errorTitle withCompletion:nil];
                }
            }];
        } errorBlock:^(NSError *error) {
            NSString *errorMessage = error.userInfo[NSLocalizedDescriptionKey];
            if (error.code == caspianErrorCode && [error.domain isEqualToString:caspianErrorDomain] && [errorMessage isEqualToString:@"System can not find user"]) {
                // Account was not found, creating a new one
                completion();
            } else {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    waitView.hidden = YES;
                    [weakSelf alertErrorMessage:errorMessage withTitle:errorTitle withCompletion:nil];
                }];
            }
        }];
    }];
}

- (void)checkPhoneNumberExists:(NSString *)phoneNumber completion:(void(^)(void))completion {
    __block WizardViewController *weakSelf = self;
    
    [self.internetQueue addOperationWithBlock:^{
        NSString *errorTitle = NSLocalizedString(@"Checking phone number failed", nil);
        NSString *checkCardExistUrl = [NSString stringWithFormat:caspianCheckCardExistUrl, phoneNumber];
        [[LinphoneManager instance] dataFromUrlString:checkCardExistUrl completionBlock:^(NSDictionary *jsonAnswer) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                waitView.hidden = YES;
                if ([weakSelf isStatusSuccess:jsonAnswer]) {
                    // Card exists, it needs to remove phone number
                    self.phoneNumberExistsPhoneNumberField.text = phoneNumber;
                    self.caspianCardId = jsonAnswer[@"card_id"];
                    [weakSelf changeView:self.phoneNumberExistsView back:NO animation:YES];
                } else {
                    NSString *errorMessage = NSLocalizedString(@"Try to create account again", nil);
                    [weakSelf alertErrorMessage:errorMessage withTitle:errorTitle withCompletion:nil];
                }
            }];
        } errorBlock:^(NSError *error) {
            NSString *errorMessage = error.userInfo[NSLocalizedDescriptionKey];
            if (error.code == caspianErrorCode && [error.domain isEqualToString:caspianErrorDomain] && [errorMessage isEqualToString:@"System can not find card"]) {
                // Card was not found, creating a new one
                completion();
            } else {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    waitView.hidden = YES;
                    [weakSelf alertErrorMessage:errorMessage withTitle:errorTitle withCompletion:nil];
                }];
            }
        }];
    }];
}

- (void)createCaspianAccountByUrl:(NSString *)createAccountUrl activateType:(BOOL)activateBySms {
    __block WizardViewController *weakSelf = self;

    [self.internetQueue addOperationWithBlock:^{
        [[LinphoneManager instance] dataFromUrlString:createAccountUrl completionBlock:^(NSDictionary *jsonAnswer) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                waitView.hidden = YES;
                if ([weakSelf isStatusSuccess:jsonAnswer]) {
                    NSString *activationCode = jsonAnswer[@"activation_code"];
                    weakSelf.activationCode = [NSString stringWithFormat:@"%@", activationCode];
                    [weakSelf changeView:activateAccountView back:NO animation:YES];
                } else {
                    [weakSelf alertErrorMessage:NSLocalizedString(@"Fail", nil)
                                      withTitle:NSLocalizedString(@"Error creating account", nil)
                                 withCompletion:nil];
                }
            }];
        } errorBlock:^(NSError *error) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                waitView.hidden = YES;
                
                NSString *errorTitle = @"";
                NSString *errorMessage = @"";
                
                if (activateBySms && error.code == caspianErrorCode) {
                    errorTitle = NSLocalizedString(@"Activation by sms failed", nil);
                    errorMessage = NSLocalizedString(@"Try to activate your account by call", nil);
                    [weakSelf switchToActivationByCall];
                } else {
                    errorTitle = NSLocalizedString(@"Error creating account", nil);
                    errorMessage = error.localizedDescription;
                }
                [weakSelf alertErrorMessage:errorMessage withTitle:errorTitle withCompletion:nil];
            }];
        }];
    }];
}

- (void)removePhoneNumberFromCard:(NSString *)phoneNumber {
    waitView.hidden = NO;
    __block WizardViewController *weakSelf = self;
    
    [self.internetQueue addOperationWithBlock:^{
        NSString *errorTitle = NSLocalizedString(@"Removing phone number failed", nil);
        NSString *removeAccountUrl = [NSString stringWithFormat:caspianRemoveAccountUrl, self.caspianCardId, phoneNumber];
        [[LinphoneManager instance] dataFromUrlString:removeAccountUrl completionBlock:^(NSDictionary *jsonAnswer) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                waitView.hidden = YES;
                if ([weakSelf isStatusSuccess:jsonAnswer]) {
                    // Account successfully removed
                    [weakSelf checkAndCreateAccountForPhoneNumber:self.phoneNumberSignUpField.text
                                                      countryCode:self.countryCodeSignUpField.text
                                                        firstName:self.firstNameSignUpField.text
                                                         lastName:self.lastNameSignUpField.text
                                                    activateBySms:isAvableActivateBySMS]; //self.activateBySignUpSegmented.selectedSegmentIndex == 0
                } else {
                    NSString *errorMessage = NSLocalizedString(@"Try to create account again", nil);
                    [weakSelf alertErrorMessage:errorMessage withTitle:errorTitle withCompletion:nil];
                }
            }];
        } errorBlock:^(NSError *error) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                waitView.hidden = YES;
                
                NSString *errorMessage = error.userInfo[NSLocalizedDescriptionKey];
                [weakSelf alertErrorMessage:errorMessage withTitle:errorTitle withCompletion:nil];
            }];
        }];
    }];
}

- (void)updateCountryFlag:(NSString *)flagFileName activityIndicator:(UIActivityIndicatorView *)activityIndicator flagImageView:(UIImageView *)flagImageView {
    flagImageView.image = [UIImage imageNamed:@"flag_placeholder.png"];

    activityIndicator.hidden = NO;
    [activityIndicator startAnimating];
    [self.internetQueue addOperationWithBlock:^{
        NSString *removeAccountUrl = [NSString stringWithFormat:caspianCountryFlagUrl, flagFileName];
        [[LinphoneManager instance] dataFromUrlString:removeAccountUrl completionBlock:^(UIImage *flagImage) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                activityIndicator.hidden = YES;
                [activityIndicator stopAnimating];
                flagImageView.image = flagImage;
            }];
        } errorBlock:^(NSError *error) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                activityIndicator.hidden = YES;
                [activityIndicator stopAnimating];
            }];
        }];
    }];
}

- (void) onContinueCreatingAccountTap:(BOOL)isSmsActivationSelected {
    NSString *phoneNumber = [self correctPhoneNumber:self.phoneNumberSignUpField.text andCountryCode:self.countryCodeSignUpField.text];
    if (phoneNumber) {
        self.phoneNumberConfirmView.text = phoneNumber;
        
        /* BOOL isSmsActivationSelected = self.activateBySignUpSegmented.selectedSegmentIndex == 0;
         */
            // BOOL isSmsActivationSelected = YES;
        
        self.smsImageConfirmView.hidden = !isSmsActivationSelected;
        self.callImageConfirmView.hidden = isSmsActivationSelected;
        
        self.smsTextConfirmView.hidden = !isSmsActivationSelected;
        self.callTextConfirmView.hidden = isSmsActivationSelected;
        
        [self animateConfirmViewHide:NO];
    }
}


#pragma mark - Activation

- (void)activateAccountWithCode:(NSString *)userInputActivationCode {
    if (userInputActivationCode.length == 0) {
        [self alertErrorMessage:NSLocalizedString(@"Please enter activation code first", nil)
                      withTitle:NSLocalizedString(@"No activation code", nil)
                 withCompletion:nil];
    } else if (userInputActivationCode.length <= 2) {
        [self alertErrorMessage:NSLocalizedString(@"Please enter more than two characters", nil)
                      withTitle:NSLocalizedString(@"Too short activation code", nil)
                 withCompletion:nil];
    } else if ([userInputActivationCode isEqualToString:self.activationCode]) {
        waitView.hidden = NO;
        __block WizardViewController *weakSelf = self;
        [self.internetQueue addOperationWithBlock:^{
            NSString *confirmCodeUrl = [NSString stringWithFormat:caspianConfirmActivationCodeUrl, userInputActivationCode];
            [[LinphoneManager instance] dataFromUrlString:confirmCodeUrl completionBlock:^(NSDictionary *jsonAnswer) {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    waitView.hidden = YES;
                    
                    if ([weakSelf isStatusSuccess:jsonAnswer]) {
                        NSString *phoneNumber = jsonAnswer[@"phone_number"];
                        NSString *password = jsonAnswer[@"password"];

                        weakSelf.phoneNumber = [NSString stringWithFormat:@"%@", phoneNumber];
                        weakSelf.password = [NSString stringWithFormat:@"%@", password];

                        weakSelf.phoneNumberRegisterField.text = phoneNumber;
                        weakSelf.passwordRegisterField.text = password;

                        [weakSelf changeView:signInView back:YES animation:YES];
                    } else {
                        [weakSelf alertErrorMessage:NSLocalizedString(@"Fail", nil)
                                          withTitle:NSLocalizedString(@"Error activating account", nil)
                                     withCompletion:nil];
                    }
                }];
            } errorBlock:^(NSError *error) {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    waitView.hidden = YES;
                    [weakSelf alertErrorMessage:error.localizedDescription
                                      withTitle:NSLocalizedString(@"Error activating account", nil)
                                 withCompletion:nil];
                }];
            }];
        }];
    } else {
        [self alertErrorMessage:NSLocalizedString(@"Please enter correct activation code", nil)
                      withTitle:NSLocalizedString(@"Wrong activation code", nil)
                 withCompletion:nil];
    }
}


#pragma mark - Forgot Password

- (void) submitRecoveryPasswordAction {
    [self recoverPasswordForPhoneNumber:self.phoneNumberForgotPasswordField.text
                         andCountryCode:self.countryCodeForgotPasswordField.text];
}

- (void)recoverPasswordForPhoneNumber:(NSString *)phoneNumber andCountryCode:(NSString *)countryCode {
    if ([self checkCountryCode:countryCode]) {
        waitView.hidden = NO;
        __block WizardViewController *weakSelf = self;
        [self.internetQueue addOperationWithBlock:^{
            NSString *cleanedPhoneNumber = [[LinphoneManager instance] removeUnneededPrefixes:phoneNumber];
            NSString *forgotPasswordUrl = [NSString stringWithFormat:caspianForgotPasswordUrl
                                           , [[LinphoneManager instance] removeUnneededPrefixes:countryCode]
                                           , cleanedPhoneNumber
                                           ];
            [[LinphoneManager instance] dataFromUrlString:forgotPasswordUrl completionBlock:^(NSDictionary *jsonAnswer) {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    waitView.hidden = YES;
                    
                    if ([weakSelf isStatusSuccess:jsonAnswer]) {
                        [weakSelf alertErrorMessage:NSLocalizedString(@"Password has been sent to your phone number by sms", nil)
                                          withTitle:NSLocalizedString(@"Successful", nil)
                                     withCompletion:nil];
                        weakSelf.password = @"";
                        [weakSelf changeView:signInView back:YES animation:YES];
                    } else {
                        [weakSelf alertErrorMessage:NSLocalizedString(@"Phone number not found", nil)
                                          withTitle:NSLocalizedString(@"Error recovering password", nil)
                                     withCompletion:nil];
                    }
                }];
            } errorBlock:^(NSError *error) {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    waitView.hidden = YES;
                    [weakSelf alertErrorMessage:error.localizedDescription
                                      withTitle:NSLocalizedString(@"Error recovering password", nil)
                                 withCompletion:nil];
                }];
            }];
        }];
    }
}


#pragma mark - Resign

- (void)resign {
    NSString *phone    = self.phoneNumberRegisterField.text;
    NSString *password = self.passwordRegisterField.text;
    NSString *domain   = self.domainRegisterField.text;
    
    [self checkIsSameUserSigningIn:phone];
    [self.waitView setHidden:false];
    [self addProxyConfig:[[LinphoneManager instance] removeUnneededPrefixes:phone] password:password domain:domain withTransport:@"tcp"];
}

@end
