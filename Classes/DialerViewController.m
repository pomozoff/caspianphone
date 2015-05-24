/* DialerViewController.h
 *
 * Copyright (C) 2009  Belledonne Comunications, Grenoble, France
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */

#import <AVFoundation/AVAudioSession.h>
#import <AudioToolbox/AudioToolbox.h>

#import "DialerViewController.h"
#import "IncallViewController.h"
#import "DTAlertView.h"
#import "LinphoneManager.h"
#import "PhoneMainView.h"
#import "Utils.h"
#import "SMSActivationViewController.h"
#import "SMSTableViewController.h"

#include "linphone/linphonecore.h"

static NSString *caspianSMSStatus = @"uk.co.onecallcaspian.phone.smsStatus";

@interface DialerViewController()

@property (nonatomic, retain) UIView *dummyView;

@end

@implementation DialerViewController

@synthesize transferMode;

@synthesize addressField;
@synthesize addContactButton;
@synthesize backButton;
@synthesize addCallButton;
@synthesize transferButton;
@synthesize callButton;
@synthesize eraseButton;

@synthesize oneButton;
@synthesize twoButton;
@synthesize threeButton;
@synthesize fourButton;
@synthesize fiveButton;
@synthesize sixButton;
@synthesize sevenButton;
@synthesize eightButton;
@synthesize nineButton;
@synthesize starButton;
@synthesize zeroButton;
@synthesize sharpButton;

@synthesize backgroundView;
@synthesize videoPreview;
@synthesize videoCameraSwitch;

#pragma mark - Properties

- (UIView *)dummyView {
    if (!_dummyView) {
        _dummyView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    }
    return _dummyView;
}

#pragma mark - Lifecycle Functions

- (id)init {
    self = [super initWithNibName:@"DialerViewController" bundle:[NSBundle mainBundle]];
    if(self) {
        self->transferMode = FALSE;
    }
    return self;
}

- (void)dealloc {
	[addressField release];
    [addContactButton release];
    [backButton release];
    [eraseButton release];
	[callButton release];
    [addCallButton release];
    [transferButton release];

	[oneButton release];
	[twoButton release];
	[threeButton release];
	[fourButton release];
	[fiveButton release];
	[sixButton release];
	[sevenButton release];
	[eightButton release];
	[nineButton release];
	[starButton release];
	[zeroButton release];
	[sharpButton release];

    [videoPreview release];
    [videoCameraSwitch release];
    
    [_dummyView release];

    // Remove all observers
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
	[super dealloc];
}


#pragma mark - UICompositeViewDelegate Functions

static UICompositeViewDescription *compositeDescription = nil;

+ (UICompositeViewDescription *)compositeViewDescription {
    if(compositeDescription == nil) {
        compositeDescription = [[UICompositeViewDescription alloc] init:@"Dialer"
                                                                content:@"DialerViewController"
                                                               stateBar:@"UIStateBar"
                                                        stateBarEnabled:true
                                                                 tabBar:@"UIMainBar"
                                                          tabBarEnabled:true
                                                             fullscreen:false
                                                          landscapeMode:[LinphoneManager runningOnIpad]
                                                           portraitMode:true];
        compositeDescription.darkBackground = true;
    }
    return compositeDescription;
}


#pragma mark - ViewController Functions

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    // Set observer
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(callUpdateEvent:)
                                                 name:kLinphoneCallUpdate
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(coreUpdateEvent:)
                                                 name:kLinphoneCoreUpdate
                                               object:nil];

    // technically not needed, but older versions of linphone had this button
    // disabled by default. In this case, updating by pushing a new version with
    // xcode would result in the callbutton being disabled all the time.
    // We force it enabled anyway now.
    [callButton setEnabled:TRUE];

    // Update on show
    LinphoneManager *mgr    = [LinphoneManager instance];
    LinphoneCore* lc        = [LinphoneManager getLc];
    LinphoneCall* call      = linphone_core_get_current_call(lc);
    LinphoneCallState state = (call != NULL)?linphone_call_get_state(call): 0;
    [self callUpdate:call state:state];

    if([LinphoneManager runningOnIpad]) {
        BOOL videoEnabled = linphone_core_video_enabled(lc);
        BOOL previewPref  = [mgr lpConfigBoolForKey:@"preview_preference"];

		if( videoEnabled && previewPref ) {
            linphone_core_set_native_preview_window_id(lc, (unsigned long)videoPreview);

			if( !linphone_core_video_preview_enabled(lc)){
				linphone_core_enable_video_preview(lc, TRUE);
			}
			
            [backgroundView setHidden:FALSE];
            [videoCameraSwitch setHidden:FALSE];
        } else {
            linphone_core_set_native_preview_window_id(lc, (unsigned long)NULL);
            linphone_core_enable_video_preview(lc, FALSE);
            [backgroundView setHidden:TRUE];
            [videoCameraSwitch setHidden:TRUE];
        }
    }

    [addressField setText:@""];

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_6_0 // attributed string only available since iOS6
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7) {
        // fix placeholder bar color in iOS7
        UIColor *color = [UIColor grayColor];
        NSAttributedString* placeHolderString = [[NSAttributedString alloc]
                                                 initWithString:NSLocalizedString(@"Enter an address", @"Enter an address")
                                                 attributes:@{NSForegroundColorAttributeName: color}];
        addressField.attributedPlaceholder = placeHolderString;
        [placeHolderString release];
    }
#endif

}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    // Remove observer
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kLinphoneCallUpdate
                                                  object:nil];

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kLinphoneCoreUpdate
                                                  object:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];

	[zeroButton    setDigit:'0'];
	[oneButton     setDigit:'1'];
	[twoButton     setDigit:'2'];
	[threeButton   setDigit:'3'];
	[fourButton    setDigit:'4'];
	[fiveButton    setDigit:'5'];
	[sixButton     setDigit:'6'];
	[sevenButton   setDigit:'7'];
	[eightButton   setDigit:'8'];
	[nineButton    setDigit:'9'];
	[starButton    setDigit:'*'];
	[sharpButton   setDigit:'#'];

    [addressField setAdjustsFontSizeToFitWidth:TRUE]; // Not put it in IB: issue with placeholder size

    if([LinphoneManager runningOnIpad]) {
        if ([LinphoneManager instance].frontCamId != nil) {
            // only show camera switch button if we have more than 1 camera
            [videoCameraSwitch setHidden:FALSE];
        }
    }
    
    addressField.inputView = self.dummyView;
}

- (void)viewDidUnload {
    [super viewDidUnload];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    CGRect frame = [videoPreview frame];
    switch (toInterfaceOrientation) {
        case UIInterfaceOrientationPortrait:
            [videoPreview setTransform: CGAffineTransformMakeRotation(0)];
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            [videoPreview setTransform: CGAffineTransformMakeRotation(M_PI)];
            break;
        case UIInterfaceOrientationLandscapeLeft:
            [videoPreview setTransform: CGAffineTransformMakeRotation(M_PI / 2)];
            break;
        case UIInterfaceOrientationLandscapeRight:
            [videoPreview setTransform: CGAffineTransformMakeRotation(-M_PI / 2)];
            break;
        default:
            break;
    }
    [videoPreview setFrame:frame];
}


#pragma mark - Event Functions

- (void)callUpdateEvent:(NSNotification*)notif {
    LinphoneCall *call = [[notif.userInfo objectForKey: @"call"] pointerValue];
    LinphoneCallState state = [[notif.userInfo objectForKey: @"state"] intValue];
    [self callUpdate:call state:state];
}

- (void)coreUpdateEvent:(NSNotification*)notif {
    if([LinphoneManager runningOnIpad]) {
        LinphoneCore* lc = [LinphoneManager getLc];
        if(linphone_core_video_enabled(lc) && linphone_core_video_preview_enabled(lc)) {
            linphone_core_set_native_preview_window_id(lc, (unsigned long)videoPreview);
            [backgroundView setHidden:FALSE];
            [videoCameraSwitch setHidden:FALSE];
        } else {
            linphone_core_set_native_preview_window_id(lc, (unsigned long)NULL);
            [backgroundView setHidden:TRUE];
            [videoCameraSwitch setHidden:TRUE];
        }
    }
}

#pragma mark - Debug Functions
-(void)presentMailViewWithTitle:(NSString*)subject forRecipients:(NSArray*)recipients attachLogs:(BOOL)attachLogs {
	if( [MFMailComposeViewController canSendMail] ){
		MFMailComposeViewController* controller = [[MFMailComposeViewController alloc] init];
		if( controller ){
			controller.mailComposeDelegate = self;
			[controller setSubject:subject];
			[controller setToRecipients:recipients];

			if( attachLogs ){
				char * filepath = linphone_core_compress_log_collection([LinphoneManager getLc]);
				if (filepath == NULL) {
					Linphone_err(@"Cannot sent logs: file is NULL");
					return;
				}
				NSString *appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
				NSString *filename = [appName stringByAppendingString:@".gz"];
				NSString *mimeType = @"text/plain";

				if ([filename hasSuffix:@".gz"]) {
					mimeType = @"application/gzip";
					filename = [appName stringByAppendingString:@".gz"];
				} else {
					Linphone_err(@"Unknown extension type: %@, cancelling email", filename);
					return;
				}
				[controller setMessageBody:NSLocalizedString(@"Application logs", nil) isHTML:NO];
				[controller addAttachmentData:[NSData dataWithContentsOfFile:[NSString stringWithUTF8String:filepath]] mimeType:mimeType fileName:filename];

				ms_free(filepath);

			}
			self.modalPresentationStyle = UIModalPresentationPageSheet;
			[self.view.window.rootViewController presentViewController:controller animated:TRUE completion:^{}];
			[controller release];
		}

	} else {
		UIAlertView* alert = [[UIAlertView alloc] initWithTitle:subject
														message:NSLocalizedString(@"Error: no mail account configured", nil)
													   delegate:nil
											  cancelButtonTitle:NSLocalizedString(@"OK", nil)
											  otherButtonTitles: nil];
		[alert show];
		[alert release];
	}
}


- (BOOL)displayDebugPopup:(NSString*)address {
	LinphoneManager* mgr = [LinphoneManager instance];
	NSString* debugAddress = [mgr lpConfigStringForKey:@"debug_popup_magic" withDefault:@""];
	if( ![debugAddress isEqualToString:@""] && [address isEqualToString:debugAddress]){


		DTAlertView* alertView = [[DTAlertView alloc] initWithTitle:NSLocalizedString(@"Debug", nil)
															message:NSLocalizedString(@"Choose an action", nil)];

		[alertView addCancelButtonWithTitle:NSLocalizedString(@"Cancel", nil) block:nil];

		[alertView addButtonWithTitle:NSLocalizedString(@"Send logs", nil) block:^{
			NSString* appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
			NSString* logsAddress = [mgr lpConfigStringForKey:@"debug_popup_email" withDefault:@"linphone-ios@linphone.org"];
			[self presentMailViewWithTitle:appName forRecipients:@[logsAddress] attachLogs:true];
		}];

		BOOL debugEnabled   = [[LinphoneManager instance] lpConfigBoolForKey:@"debugenable_preference"];
		NSString* actionLog = (debugEnabled ? NSLocalizedString(@"Disable logs", nil) : NSLocalizedString(@"Enable logs", nil));
		[alertView addButtonWithTitle:actionLog block:^{
			// enable / disable
			BOOL enableDebug = ![mgr lpConfigBoolForKey:@"debugenable_preference"];
			[mgr lpConfigSetBool:enableDebug forKey:@"debugenable_preference"];
			[mgr setLogsEnabled:enableDebug];
		}];

		[alertView show];
		[alertView release];
		return true;
	}
	return false;
}


#pragma mark -

- (void)callUpdate:(LinphoneCall*)call state:(LinphoneCallState)state {
    LinphoneCore *lc = [LinphoneManager getLc];
    if(linphone_core_get_calls_nb(lc) > 0) {
        if(transferMode) {
            [addCallButton setHidden:true];
            [transferButton setHidden:false];
        } else {
            [addCallButton setHidden:false];
            [transferButton setHidden:true];
        }
        [callButton setHidden:true];
        [backButton setHidden:false];
        [addContactButton setHidden:true];
    } else {
        [addCallButton setHidden:true];
        [callButton setHidden:false];
        [backButton setHidden:true];
        [addContactButton setHidden:false];
        [transferButton setHidden:true];
    }
}

- (void)setAddress:(NSString*) address {
    [addressField setText:address];
}

- (void)setTransferMode:(BOOL)atransferMode {
    transferMode = atransferMode;
    LinphoneCall* call = linphone_core_get_current_call([LinphoneManager getLc]);
    LinphoneCallState state = (call != NULL)?linphone_call_get_state(call): 0;
    [self callUpdate:call state:state];
}

- (void)call:(NSString*)address {
    NSString *displayName = nil;
    ABRecordRef contact = [[[LinphoneManager instance] fastAddressBook] getContact:address];
    if(contact) {
        displayName = [FastAddressBook getContactDisplayName:contact];
    }
    [self call:address displayName:displayName];
}

- (void)call:(NSString*)address displayName:(NSString *)displayName {
    [[LinphoneManager instance] call:address displayName:displayName transfer:transferMode];
}


#pragma mark - UITextFieldDelegate Functions

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    //[textField performSelector:@selector() withObject:nil afterDelay:0];
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == addressField) {
        [addressField resignFirstResponder];
    }
    return YES;
}

#pragma mark - MFComposeMailDelegate

-(void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
	[controller dismissViewControllerAnimated:TRUE completion:^{}];
	[self.navigationController setNavigationBarHidden:TRUE animated:FALSE];
}


#pragma mark - Action Functions

- (IBAction)onAddContactClick: (id) event {
    [ContactSelection setSelectionMode:ContactSelectionModeEdit];
    [ContactSelection setAddAddress:[addressField text]];
    [ContactSelection setSipFilter:nil];
    [ContactSelection setNameOrEmailFilter:nil];
    [ContactSelection enableEmailFilter:FALSE];
    /*
    ContactsViewController *controller = DYNAMIC_CAST([[PhoneMainView instance] changeCurrentView:[ContactsViewController compositeViewDescription] push:TRUE], ContactsViewController);
    if(controller != nil) {

    }
    */
    ContactDetailsViewController *controller = DYNAMIC_CAST([[PhoneMainView instance] changeCurrentView:[ContactDetailsViewController compositeViewDescription] push:TRUE], ContactDetailsViewController);
    if(controller != nil) {
        if (addressField.text.length == 0) {
            [controller newContact];
        } else {
            [controller newContact:addressField.text];
        }
    }
}

- (IBAction)onBackClick: (id) event {
    [[PhoneMainView instance] changeCurrentView:[InCallViewController compositeViewDescription]];
}

- (IBAction)onAddressChange: (id)sender {
	if( [self displayDebugPopup:self.addressField.text] ){
		self.addressField.text = @"";
	}
    if([[addressField text] length] > 0) {
        [addContactButton setEnabled:TRUE];
        [eraseButton setEnabled:TRUE];
        [addCallButton setEnabled:TRUE];
        [transferButton setEnabled:TRUE];
    } else {
        [addContactButton setEnabled:FALSE];
        [eraseButton setEnabled:FALSE];
        [addCallButton setEnabled:FALSE];
        [transferButton setEnabled:FALSE];
    }
}

- (IBAction)onChatTap:(id)sender {
    ChatViewController *controller = DYNAMIC_CAST([[PhoneMainView instance] changeCurrentView:[ChatViewController compositeViewDescription]
                                                                                         push:TRUE], ChatViewController);
    if (addressField.text.length != 0) {
        controller.addressField.text = addressField.text;
        [controller onAddClick:nil];
    }
}

- (IBAction)onSMSTap:(id)sender {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:caspianSMSStatus]) {
        SMSTableViewController *smsViewController = DYNAMIC_CAST([[PhoneMainView instance] changeCurrentView:[SMSTableViewController compositeViewDescription] push:TRUE], SMSTableViewController);
        
        if (addressField.text.length != 0) {
            smsViewController.phoneNumber = addressField.text;
        }
    }
    else {
        DYNAMIC_CAST([[PhoneMainView instance] changeCurrentView:[SMSActivationViewController compositeViewDescription] push:TRUE], SMSActivationViewController);
    }
}

@end
