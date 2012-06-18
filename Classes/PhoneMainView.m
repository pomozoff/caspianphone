/* PhoneMainView.m
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
 *  GNU General Public License for more details.                
 *                                                                      
 *  You should have received a copy of the GNU General Public License   
 *  along with this program; if not, write to the Free Software         
 *  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */   

#import "PhoneMainView.h"
#import "DialerViewController.h"
#import "HistoryViewController.h"
#import "ContactsViewController.h"
#import "InCallViewController.h"

@implementation ViewsDescription

-(id) copy {
    ViewsDescription *copy = [ViewsDescription alloc];
    copy->content = self->content;
    copy->tabBar = self->tabBar;
    copy->tabBarEnabled = self->tabBarEnabled;
    copy->statusEnabled = self->statusEnabled;
    copy->fullscreen = self->fullscreen;
    return copy;
}
@end

@implementation PhoneMainView

@synthesize stateBarView;
@synthesize contentView;
@synthesize tabBarView;

@synthesize stateBarController;

@synthesize callTabBarController;
@synthesize mainTabBarController;
@synthesize incomingCallTabBarController;

- (void)changeView: (NSNotification*) notif {   
    NSNumber *viewId = [notif.userInfo objectForKey: @"view"];
    NSNumber *tabBar = [notif.userInfo objectForKey: @"tabBar"];
    NSNumber *fullscreen = [notif.userInfo objectForKey: @"fullscreen"];
    
    if(viewId != nil) {
        PhoneView view = [viewId intValue];
        currentViewDescription = [[viewDescriptions objectForKey:[NSNumber numberWithInt: view]] copy];
    }
    
    ViewsDescription *description = currentViewDescription;
    if(description == nil) {
        return;
    }
    
    UIView *innerView = description->content.view;
    
    // Change view
    if(viewId != nil) {
        for (UIView *view in contentView.subviews) {
            [view removeFromSuperview];
        }
        for (UIView *view in tabBarView.subviews) {
            [view removeFromSuperview];
        }
        
        [contentView addSubview: innerView];
        [tabBarView addSubview: description->tabBar.view];
    }
    
    if(tabBar != nil) {
        description->tabBarEnabled = [tabBar boolValue];
    }
    
    if(fullscreen != nil) {
        description->fullscreen = [fullscreen boolValue];
    }
    
    CGRect contentFrame = contentView.frame;
    
    // Resize StateBar
    CGRect stateBarFrame = stateBarView.frame;
    if(description->fullscreen)
        stateBarFrame.origin.y = -20;
    else
        stateBarFrame.origin.y = 0;
    
    if(description->statusEnabled) {
        stateBarView.hidden = false;
        [stateBarView setFrame: stateBarFrame];
        contentFrame.origin.y = stateBarFrame.size.height + stateBarFrame.origin.y;
    } else {
        stateBarView.hidden = true;
        contentFrame.origin.y = stateBarFrame.origin.y;
    }
    
    // Resize TabBar
    CGRect tabFrame = tabBarView.frame;
    if(description->tabBar != nil && description->tabBarEnabled) {
        tabBarView.hidden = false;
        tabFrame.origin.y += tabFrame.size.height;
        tabFrame.origin.x += tabFrame.size.width;
        tabFrame.size.height = description->tabBar.view.frame.size.height;
        tabFrame.size.width = description->tabBar.view.frame.size.width;
        tabFrame.origin.y -= tabFrame.size.height;
        tabFrame.origin.x -= tabFrame.size.width;
        [tabBarView setFrame: tabFrame];
        contentFrame.size.height = tabFrame.origin.y - contentFrame.origin.y;
        for (UIView *view in description->tabBar.view.subviews) {
            if(view.tag == -1) {
                contentFrame.size.height += view.frame.origin.y;
                break;
            }
        }
    } else {
        tabBarView.hidden = true;
        contentFrame.size.height = tabFrame.origin.y + tabFrame.size.height;
        if(description->fullscreen)
            contentFrame.size.height += 20;
    }
    
    // Resize innerView
    [contentView setFrame: contentFrame];
    CGRect innerContentFrame = innerView.frame;
    innerContentFrame.size = contentFrame.size;
    [innerView setFrame: innerContentFrame];
    
    // Call abstractCall
    NSDictionary *dict = [notif.userInfo objectForKey: @"args"];
    if(dict != nil)
        [LinphoneManager abstractCall:description->content dict:dict];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    UIView *dumb;
    
    // Init view descriptions
    viewDescriptions = [[NSMutableDictionary alloc] init];
    
    // Load Bars
    dumb = mainTabBarController.view;
    
    // Status Bar
    [stateBarView addSubview: stateBarController.view];
    
    //
    // Main View
    //
    DialerViewController* myDialerViewController = [[DialerViewController alloc]  
                                                  initWithNibName:@"DialerViewController" 
                                                  bundle:[NSBundle mainBundle]];
    //[myPhoneViewController loadView];
    ViewsDescription *dialerDescription = [ViewsDescription alloc];
    dialerDescription->content = myDialerViewController;
    dialerDescription->tabBar = mainTabBarController;
    dialerDescription->statusEnabled = true;
    dialerDescription->fullscreen = false;
    dialerDescription->tabBarEnabled = true;
    [viewDescriptions setObject:dialerDescription forKey:[NSNumber numberWithInt: PhoneView_Dialer]];
    
    
    //
    // Contacts View
    //
    ContactsViewController* myContactsController = [[ContactsViewController alloc]
                                                initWithNibName:@"ContactsViewController" 
                                                bundle:[NSBundle mainBundle]];
    //[myContactsController loadView];
    ViewsDescription *contactsDescription = [ViewsDescription alloc];
    contactsDescription->content = myContactsController;
    contactsDescription->tabBar = mainTabBarController;
    contactsDescription->statusEnabled = false;
    contactsDescription->fullscreen = false;
    contactsDescription->tabBarEnabled = true;
    [viewDescriptions setObject:contactsDescription forKey:[NSNumber numberWithInt: PhoneView_Contacts]];
    
    
    //
    // Call History View
    //
    HistoryViewController* myHistoryController = [[HistoryViewController alloc]
                                              initWithNibName:@"HistoryViewController" 
                                              bundle:[NSBundle mainBundle]];
    //[myHistoryController loadView];
    ViewsDescription *historyDescription = [ViewsDescription alloc];
    historyDescription->content = myHistoryController;
    historyDescription->tabBar = mainTabBarController;
    historyDescription->statusEnabled = false;
    historyDescription->fullscreen = false;
    historyDescription->tabBarEnabled = true;
    [viewDescriptions setObject:historyDescription forKey:[NSNumber numberWithInt: PhoneView_History]];
    
    
    //
    // InCall View
    //
    InCallViewController* myInCallController = [[InCallViewController alloc]
                                                initWithNibName:@"InCallViewController" 
                                                bundle:[NSBundle mainBundle]];
    //[myHistoryController loadView];
    ViewsDescription *inCallDescription = [ViewsDescription alloc];
    inCallDescription->content = myInCallController;
    inCallDescription->tabBar = callTabBarController;
    inCallDescription->statusEnabled = true;
    inCallDescription->fullscreen = false;
    inCallDescription->tabBarEnabled = true;
    [viewDescriptions setObject:inCallDescription forKey:[NSNumber numberWithInt: PhoneView_InCall]];
    
    
    // Set observers
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(changeView:) 
                                                 name:@"LinphoneMainViewChange" 
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(callUpdate:) 
                                                 name:@"LinphoneCallUpdate" 
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(batteryLevelChanged:) 
                                                 name:UIDeviceBatteryLevelDidChangeNotification 
                                               object:nil];
}
     
- (void)viewDidUnload {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)callUpdate: (NSNotification*) notif {  
    LinphoneCallWrapper *callWrapper = [notif.userInfo objectForKey: @"call"];
    LinphoneCall *call = callWrapper->call;
    LinphoneCallState state = [[notif.userInfo objectForKey: @"state"] intValue];
    NSString *message = [notif.userInfo objectForKey: @"message"];
    
    bool canHideInCallView = (linphone_core_get_calls([LinphoneManager getLc]) == NULL);
    
	switch (state) {					
		case LinphoneCallIncomingReceived: 
        {
			[self displayIncomingCall:call];
			break;
        }
		case LinphoneCallOutgoingInit: 
        case LinphoneCallPausedByRemote:
		case LinphoneCallConnected:
        case LinphoneCallUpdated:
        {
            if ([[LinphoneManager instance] currentView] != PhoneView_InCall) {
                [[LinphoneManager instance] changeView:PhoneView_InCall];
            }
            break;
        }
        case LinphoneCallUpdatedByRemote:
        {
            const LinphoneCallParams* current = linphone_call_get_current_params(call);
            const LinphoneCallParams* remote = linphone_call_get_remote_params(call);
            
            /* remote wants to add video */
            if (!linphone_call_params_video_enabled(current) && 
                linphone_call_params_video_enabled(remote) && 
                !linphone_core_get_video_policy([LinphoneManager getLc])->automatically_accept) {
                linphone_core_defer_call_update([LinphoneManager getLc], call);
                //TODO
                //[self displayAskToEnableVideoCall:call forUser:lUserName withDisplayName:lDisplayName];
            } else if (linphone_call_params_video_enabled(current) && !linphone_call_params_video_enabled(remote)) {
                if ([[LinphoneManager instance] currentView] != PhoneView_InCall) {
                    [[LinphoneManager instance] changeView:PhoneView_InCall];
                }
            }
            break;
        }
		case LinphoneCallError:
        {
            [self displayCallError:call message: message];
        }
		case LinphoneCallEnd: 
        {
            [self dismissIncomingCall];
            if (canHideInCallView) {
                if ([[LinphoneManager instance] currentView] != PhoneView_Dialer) {
                    // Go to dialer view
                    NSDictionary *dict = [[NSDictionary alloc] initWithObjectsAndKeys:
                                           [[NSArray alloc] initWithObjects: @"", nil]
                                          , @"setAddress:",
                                          nil];
                    [[LinphoneManager instance] changeView:PhoneView_Dialer dict:dict];
                }
            } else {
                if ([[LinphoneManager instance] currentView] != PhoneView_InCall) {
                    [[LinphoneManager instance] changeView:PhoneView_InCall];
                }
			}
			break;
        }
		case LinphoneCallStreamsRunning:
        {
            if ([[LinphoneManager instance] currentView] != PhoneView_InCall) {
                [[LinphoneManager instance] changeView:PhoneView_InCall];
            }
			break;
        }
        default:
            break;
	}
    
}

- (void)displayCallError:(LinphoneCall*) call message:(NSString*) message {
    const char* lUserNameChars=linphone_address_get_username(linphone_call_get_remote_address(call));
    NSString* lUserName = lUserNameChars?[[[NSString alloc] initWithUTF8String:lUserNameChars] autorelease]:NSLocalizedString(@"Unknown",nil);
    NSString* lMessage;
    NSString* lTitle;
    
    //get default proxy
    LinphoneProxyConfig* proxyCfg;	
    linphone_core_get_default_proxy([LinphoneManager getLc],&proxyCfg);
    if (proxyCfg == nil) {
        lMessage = NSLocalizedString(@"Please make sure your device is connected to the internet and double check your SIP account configuration in the settings.", nil);
    } else {
        lMessage = [NSString stringWithFormat : NSLocalizedString(@"Cannot call %@", nil), lUserName];
    }
    
    if (linphone_call_get_reason(call) == LinphoneReasonNotFound) {
        lMessage = [NSString stringWithFormat : NSLocalizedString(@"'%@' not registered to Service", nil), lUserName];
    } else {
        if (message != nil) {
            lMessage = [NSString stringWithFormat : NSLocalizedString(@"%@\nReason was: %@", nil), lMessage, message];
        }
    }
    lTitle = NSLocalizedString(@"Call failed",nil);
    UIAlertView* error = [[UIAlertView alloc] initWithTitle:lTitle
                                                    message:lMessage 
                                                   delegate:nil 
                                          cancelButtonTitle:NSLocalizedString(@"Dismiss",nil) 
                                          otherButtonTitles:nil];
    [error show];
    [error release];
}

- (void)dismissIncomingCall {
	//cancel local notification, just in case
	if ([[UIDevice currentDevice] respondsToSelector:@selector(isMultitaskingSupported)]  
		&& [UIApplication sharedApplication].applicationState ==  UIApplicationStateBackground ) {
		// cancel local notif if needed
		[[UIApplication sharedApplication] cancelAllLocalNotifications];
	} else {
		if (incomingCallActionSheet) {
			[incomingCallActionSheet dismissWithClickedButtonIndex:1 animated:true];
			incomingCallActionSheet = nil;
		}
	}
    
    //TODO
    /*
     if ([[NSUserDefaults standardUserDefaults] boolForKey:@"firstlogindone_preference" ] == true) {
     //first login case, dismmis first login view																		 
     [self dismissModalViewControllerAnimated:true];
     }; */
}


- (void)displayIncomingCall:(LinphoneCall*) call{
    const char* userNameChars=linphone_address_get_username(linphone_call_get_remote_address(call));
    NSString* userName = userNameChars?[[[NSString alloc] initWithUTF8String:userNameChars] autorelease]:NSLocalizedString(@"Unknown",nil);
    const char* displayNameChars =  linphone_address_get_display_name(linphone_call_get_remote_address(call));        
	NSString* displayName = [displayNameChars?[[NSString alloc] initWithUTF8String:displayNameChars]:@"" autorelease];
    
	//TODO
    //[mMainScreenWithVideoPreview showPreview:NO]; 
	if ([[UIDevice currentDevice] respondsToSelector:@selector(isMultitaskingSupported)] 
		&& [UIApplication sharedApplication].applicationState !=  UIApplicationStateActive) {
		// Create a new notification
		UILocalNotification* notif = [[[UILocalNotification alloc] init] autorelease];
		if (notif)
		{
			notif.repeatInterval = 0;
			notif.alertBody =[NSString  stringWithFormat:NSLocalizedString(@" %@ is calling you",nil),[displayName length]>0?displayName:userName];
			notif.alertAction = @"Answer";
			notif.soundName = @"oldphone-mono-30s.caf";
            NSData *callData = [NSData dataWithBytes:&call length:sizeof(call)];
			notif.userInfo = [NSDictionary dictionaryWithObject:callData forKey:@"call"];
			
			[[UIApplication sharedApplication]  presentLocalNotificationNow:notif];
		}
	} else 	{
        CallDelegate* cd = [[CallDelegate alloc] init];
        cd.eventType = CD_NEW_CALL;
        cd.delegate = self;
        cd.call = call;
        
		incomingCallActionSheet = [[UIActionSheet alloc] initWithTitle:[NSString  stringWithFormat:NSLocalizedString(@" %@ is calling you",nil),[displayName length]>0?displayName:userName]
															   delegate:cd 
													  cancelButtonTitle:nil 
												 destructiveButtonTitle:NSLocalizedString(@"Answer",nil) 
													  otherButtonTitles:NSLocalizedString(@"Decline",nil),nil];
        
		incomingCallActionSheet.actionSheetStyle = UIActionSheetStyleDefault;
        //TODO
        /*if ([LinphoneManager runningOnIpad]) {
            if (self.modalViewController != nil)
                [incomingCallActionSheet showInView:[self.modalViewController view]];
            else
                [incomingCallActionSheet showInView:self.parentViewController.view];
        } else */{
            [incomingCallActionSheet showInView: self.view];
        }
		[incomingCallActionSheet release];
	}
}

- (void)batteryLevelChanged: (NSNotification*) notif {
    LinphoneCall* call = linphone_core_get_current_call([LinphoneManager getLc]);
    if (!call || !linphone_call_params_video_enabled(linphone_call_get_current_params(call)))
        return;
    LinphoneCallAppData* appData = (LinphoneCallAppData*) linphone_call_get_user_pointer(call);
    if ([UIDevice currentDevice].batteryState == UIDeviceBatteryStateUnplugged) {
        float level = [UIDevice currentDevice].batteryLevel;
        ms_message("Video call is running. Battery level: %.2f", level);
        if (level < 0.1 && !appData->batteryWarningShown) {
            // notify user
            CallDelegate* cd = [[CallDelegate alloc] init];
            cd.eventType = CD_STOP_VIDEO_ON_LOW_BATTERY;
            cd.delegate = self;
            cd.call = call;
            
            if (batteryActionSheet != nil) {
                [batteryActionSheet dismissWithClickedButtonIndex:batteryActionSheet.cancelButtonIndex animated:TRUE];
            }
            NSString* title = NSLocalizedString(@"Battery is running low. Stop video ?",nil);
            batteryActionSheet = [[UIActionSheet alloc] initWithTitle:title
                                                             delegate:cd 
                                                    cancelButtonTitle:NSLocalizedString(@"Continue video",nil) 
                                               destructiveButtonTitle:NSLocalizedString(@"Stop video",nil) 
                                                    otherButtonTitles:nil];
            
            batteryActionSheet.actionSheetStyle = UIActionSheetStyleDefault;
            [batteryActionSheet showInView: self.view];
            [batteryActionSheet release];
            appData->batteryWarningShown = TRUE;
        }
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet ofType:(enum CallDelegateType)type 
                                   clickedButtonAtIndex:(NSInteger)buttonIndex 
                                          withUserDatas:(void *)datas {
    
    switch(type) {
        case CD_NEW_CALL: 
        {
            LinphoneCall* call = (LinphoneCall*)datas;
            if (buttonIndex == actionSheet.destructiveButtonIndex) {
                linphone_core_accept_call([LinphoneManager getLc], call);	
            } else {
                linphone_core_terminate_call([LinphoneManager getLc], call);
            }
            incomingCallActionSheet = nil;
            break;
        }
        case CD_STOP_VIDEO_ON_LOW_BATTERY: 
        {
            LinphoneCall* call = (LinphoneCall*)datas;
            LinphoneCallParams* paramsCopy = linphone_call_params_copy(linphone_call_get_current_params(call));
            if ([batteryActionSheet destructiveButtonIndex] == buttonIndex) {
                // stop video
                linphone_call_params_enable_video(paramsCopy, FALSE);
                linphone_core_update_call([LinphoneManager getLc], call, paramsCopy);
            }
            break;
        }
        default:
            break;
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [viewDescriptions release];
    [stateBarView release];
    [stateBarController release];
    [mainTabBarController release];
    
    [super dealloc];
}

@end