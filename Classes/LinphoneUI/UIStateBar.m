/* UIStateBar.m
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

#import "UIStateBar.h"
#import "LinphoneManager.h"
#import "PhoneMainView.h"

@interface UIStateBar ()

@property (nonatomic, retain) NSOperationQueue *balanceQueue;
@property (nonatomic, retain) NSNumberFormatter *numberFormatter;
@property (nonatomic, readonly) NSString *username;
@property (nonatomic, readonly) NSString *password;
@property (nonatomic, retain) NSURL *balanceUrl;

@end

@implementation UIStateBar

@synthesize registrationStateImage;
@synthesize registrationStateLabel;
@synthesize callQualityImage;
@synthesize callSecurityImage;
@synthesize callSecurityButton;
@synthesize balanceLabel;
@synthesize balanceQueue;
@synthesize numberFormatter;
@synthesize username = _username;
@synthesize password = _password;

static NSTimer *callQualityTimer;
static NSTimer *callSecurityTimer;
static NSTimer *balanceTimer;

static NSString *caspianBalanceUrl = @"http://onecallcaspian.co.uk/mobile/credit?phone_number=%@&password=%@";

const static NSTimeInterval balanceIntervalMax = 10.0;
const static NSTimeInterval balanceInterval = 1.0;

static NSTimeInterval balanceIntervalCurrent = balanceIntervalMax;

#pragma mark - Properties

- (NSOperationQueue *)balanceQueue {
    if (!balanceQueue) {
        balanceQueue = [[NSOperationQueue alloc] init];
        balanceQueue.name = @"Balance queue";
        balanceQueue.maxConcurrentOperationCount = 1;
    }
    return balanceQueue;
}
- (NSNumberFormatter *)numberFormatter {
    if (!numberFormatter) {
        numberFormatter = [[NSNumberFormatter alloc] init];
        numberFormatter.numberStyle = NSNumberFormatterCurrencyStyle;
        numberFormatter.maximumFractionDigits = 2;
        numberFormatter.currencyCode = @"GBP";
    }
    return numberFormatter;
}
- (NSString *)username {
    if (!_username) {
        LinphoneCore *lc = [LinphoneManager getLc];
        LinphoneProxyConfig *cfg = NULL;
        linphone_core_get_default_proxy(lc, &cfg);
        if (cfg) {
            const char *identity = linphone_proxy_config_get_identity(cfg);
            LinphoneAddress *addr = linphone_address_new(identity);
            if (addr) {
                _username = [[NSString stringWithUTF8String:linphone_address_get_username(addr)] retain];
                linphone_address_destroy(addr);
            }
        }
    }
    return _username;
}
- (NSString *)password {
    if (!_password) {
        LinphoneAuthInfo *ai;
        LinphoneCore *lc = [LinphoneManager getLc];
        const MSList *elem = linphone_core_get_auth_info_list(lc);
        if (elem && (ai = (LinphoneAuthInfo *)elem->data)) {
            _password = [[NSString stringWithUTF8String:linphone_auth_info_get_passwd(ai)] retain];
        }
    }
    return _password;
}
- (NSURL *)balanceUrl {
    if (!_balanceUrl) {
        NSString *urlString = [NSString stringWithFormat:caspianBalanceUrl, self.username, self.password];
        _balanceUrl = [[NSURL URLWithString:[urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] retain];
    }
    return _balanceUrl;
}

#pragma mark - Lifecycle Functions

- (id)init {
	self = [super initWithNibName:@"UIStateBar" bundle:[NSBundle mainBundle]];
	if(self != nil) {
		self->callSecurityImage = nil;
		self->callQualityImage = nil;
		self->securitySheet = nil;
	}
	return self;
}

- (void) dealloc {
	if(securitySheet) {
		[securitySheet release];
	}
	[registrationStateImage release];
	[registrationStateLabel release];
	[callQualityImage release];
	[callSecurityImage release];
	[callSecurityButton release];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[callQualityTimer invalidate];
	[callQualityTimer release];
	[_voicemailCount release];
    [balanceLabel release];
    [balanceQueue release];
    [numberFormatter release];
    [_username release];
    [_password release];
    [_balanceUrl release];
	[super dealloc];
}


#pragma mark - ViewController Functions

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

	// Set callQualityTimer
	callQualityTimer = [NSTimer scheduledTimerWithTimeInterval:1
														target:self
													  selector:@selector(callQualityUpdate)
													  userInfo:nil
													   repeats:YES];

	// Set callQualityTimer
	callSecurityTimer = [NSTimer scheduledTimerWithTimeInterval:1
														target:self
													  selector:@selector(callSecurityUpdate)
													  userInfo:nil
													   repeats:YES];


    // Set balanceTimer
    balanceTimer = [NSTimer scheduledTimerWithTimeInterval:balanceInterval
                                                    target:self
                                                  selector:@selector(updateBalance)
                                                  userInfo:nil
                                                   repeats:YES];
	// Set observer
	[[NSNotificationCenter defaultCenter]	addObserver:self
						selector:@selector(registrationUpdate:)
						name:kLinphoneRegistrationUpdate
						object:nil];

	[[NSNotificationCenter defaultCenter]	addObserver:self
						selector:@selector(globalStateUpdate:)
						name:kLinphoneGlobalStateUpdate
						object:nil];

	[[NSNotificationCenter defaultCenter]	addObserver:self
						selector:@selector(notifyReceived:)
						name:kLinphoneNotifyReceived
						object:nil];

	[callQualityImage setHidden: true];
	[callSecurityImage setHidden: true];
	self.voicemailCount.hidden = true;

	// Update to default state
	LinphoneProxyConfig* config = NULL;
	if([LinphoneManager isLcReady])
		linphone_core_get_default_proxy([LinphoneManager getLc], &config);
	[self proxyConfigUpdate: config];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];


	// Remove observer
	[[NSNotificationCenter defaultCenter]	removeObserver:self
						name:kLinphoneRegistrationUpdate
						object:nil];
	[[NSNotificationCenter defaultCenter]	removeObserver:self
						name:kLinphoneGlobalStateUpdate
						object:nil];
	[[NSNotificationCenter defaultCenter]	removeObserver:self
						name:kLinphoneNotifyReceived
						object:nil];
	if(callQualityTimer != nil) {
		[callQualityTimer invalidate];
		callQualityTimer = nil;
	}
	if(callSecurityTimer != nil) {
		[callSecurityTimer invalidate];
		callSecurityTimer = nil;
	}
    if(balanceTimer != nil) {
        [balanceTimer invalidate];
        balanceTimer = nil;
    }
}


#pragma mark - Event Functions

- (void)registrationUpdate: (NSNotification*) notif {
	LinphoneProxyConfig* config = NULL;
	linphone_core_get_default_proxy([LinphoneManager getLc], &config);
	[self proxyConfigUpdate:config];
}

- (void) globalStateUpdate:(NSNotification*) notif {
	if ([LinphoneManager isLcReady]) [self registrationUpdate:notif];
}

- (void) notifyReceived:(NSNotification*) notif {
	const LinphoneContent * content = [[notif.userInfo objectForKey: @"content"] pointerValue];

	if ((content == NULL)
		|| (strcmp("application", content->type) != 0)
		|| (strcmp("simple-message-summary", content->subtype) != 0)
		|| (content->data == NULL)) {
		return;
	}

	const char * body = (const char*) content->data;
	if ((body = strstr(body, "voice-message: ")) == NULL) {
		[LinphoneLogger log:LinphoneLoggerWarning format:@"Received new NOTIFY from voice mail but could not find 'voice-message' in BODY. Ignoring it."];
		return;
	}

	int unreadCount = 0;
	sscanf(body, "voice-message: %d", &unreadCount);

	[LinphoneLogger log:LinphoneLoggerLog format:@"Received new NOTIFY from voice mail: there is/are now %d message(s) unread", unreadCount];

	if (unreadCount > 0) {
		self.voicemailCount.hidden = FALSE;
		self.voicemailCount.text = [NSString stringWithFormat:NSLocalizedString(@"%d unread messages", @"%d"), unreadCount];
	} else {
		self.voicemailCount.hidden = TRUE;
	}
}

#pragma mark -

- (void)proxyConfigUpdate: (LinphoneProxyConfig*) config {
	LinphoneRegistrationState state = LinphoneRegistrationNone;
	NSString* message = nil;
	UIImage* image = nil;
	LinphoneCore* lc = [LinphoneManager getLc];
	LinphoneGlobalState gstate = linphone_core_get_global_state(lc);

	if( gstate == LinphoneGlobalConfiguring ){
		message = NSLocalizedString(@"Fetching remote configuration", nil);
	} else if (config == NULL) {
		state = LinphoneRegistrationNone;
		if(![LinphoneManager isLcReady] || linphone_core_is_network_reachable([LinphoneManager getLc]))
			message = NSLocalizedString(@"No SIP account configured", nil);
		else
			message = NSLocalizedString(@"Network down", nil);
	} else {
		state = linphone_proxy_config_get_state(config);

		switch (state) {
			case LinphoneRegistrationOk:
				message = NSLocalizedString(@"Registered", nil); break;
			case LinphoneRegistrationNone:
			case LinphoneRegistrationCleared:
				message =  NSLocalizedString(@"Not registered", nil); break;
			case LinphoneRegistrationFailed:
				message =  NSLocalizedString(@"Registration failed", nil); break;
			case LinphoneRegistrationProgress:
				message =  NSLocalizedString(@"Registration in progress", nil); break;
			default: break;
		}
	}

	registrationStateLabel.hidden = NO;
	switch(state) {
		case LinphoneRegistrationFailed:
			registrationStateImage.hidden = NO;
			image = [UIImage imageNamed:@"led_error.png"];
			break;
		case LinphoneRegistrationCleared:
		case LinphoneRegistrationNone:
			registrationStateImage.hidden = NO;
			image = [UIImage imageNamed:@"led_disconnected.png"];
			break;
		case LinphoneRegistrationProgress:
			registrationStateImage.hidden = NO;
			image = [UIImage imageNamed:@"led_inprogress.png"];
			break;
		case LinphoneRegistrationOk:
			registrationStateImage.hidden = NO;
			image = [UIImage imageNamed:@"led_connected.png"];
			break;
	}
	[registrationStateLabel setText:message];
	[registrationStateImage setImage:image];
}


#pragma mark -

- (void)callSecurityUpdate {
	BOOL pending = false;
	BOOL security = true;

	if(![LinphoneManager isLcReady]) {
		[callSecurityImage setHidden:true];
		return;
	}
	const MSList *list = linphone_core_get_calls([LinphoneManager getLc]);
	if(list == NULL) {
		if(securitySheet) {
			[securitySheet dismissWithClickedButtonIndex:securitySheet.destructiveButtonIndex animated:TRUE];
		}
		[callSecurityImage setHidden:true];
		return;
	}
	while(list != NULL) {
		LinphoneCall *call = (LinphoneCall*) list->data;
		LinphoneMediaEncryption enc = linphone_call_params_get_media_encryption(linphone_call_get_current_params(call));
		if(enc == LinphoneMediaEncryptionNone)
			security = false;
		else if(enc == LinphoneMediaEncryptionZRTP) {
			if(!linphone_call_get_authentication_token_verified(call)) {
				pending = true;
			}
		}
		list = list->next;
	}

	if(security) {
		if(pending) {
			[callSecurityImage setImage:[UIImage imageNamed:@"security_pending.png"]];
		} else {
			[callSecurityImage setImage:[UIImage imageNamed:@"security_ok.png"]];
		}
	} else {
		[callSecurityImage setImage:[UIImage imageNamed:@"security_ko.png"]];
	}
	[callSecurityImage setHidden: false];
}

- (void)callQualityUpdate {
	UIImage *image = nil;
	if([LinphoneManager isLcReady]) {
		LinphoneCall *call = linphone_core_get_current_call([LinphoneManager getLc]);
		if(call != NULL) {
			//FIXME double check call state before computing, may cause core dump
			float quality = linphone_call_get_average_quality(call);
			if(quality < 1) {
				image = [UIImage imageNamed:@"call_quality_indicator_0.png"];
			} else if (quality < 2) {
				image = [UIImage imageNamed:@"call_quality_indicator_1.png"];
			} else if (quality < 3) {
				image = [UIImage imageNamed:@"call_quality_indicator_2.png"];
			} else {
				image = [UIImage imageNamed:@"call_quality_indicator_3.png"];
			}
		}
	}
	if(image != nil) {
		[callQualityImage setHidden:false];
		[callQualityImage setImage:image];
	} else {
		[callQualityImage setHidden:true];
	}
}

- (void)pullBalanceCompletionBlock:(void(^)(NSString *))block {
    if (self.balanceQueue.operationCount == 0) {
        [self.balanceQueue addOperationWithBlock:^{
            if (self.balanceUrl) {
                NSData *data = [NSData dataWithContentsOfURL:self.balanceUrl];
                if (data) {
                    NSError *error = nil;
                    NSDictionary *jsonAnswer = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
                    if (!error) {
                        BOOL isError = [jsonAnswer[@"error"] boolValue];
                        if (!isError) {
                            NSString *accurateBalance = jsonAnswer[@"balance"];
                            NSDecimalNumber *digitBalance = [NSDecimalNumber decimalNumberWithString:accurateBalance];
                            if (digitBalance != nil) {
                                NSString *balance = [self.numberFormatter stringFromNumber:digitBalance];
                                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                    block(balance);
                                }];
                            }
                        }
                    }
                }
            }
        }];
    }
}

- (void)updateBalance {
    BOOL isOnCall = NO;
    if([LinphoneManager isLcReady]) {
        LinphoneCall *call = linphone_core_get_current_call([LinphoneManager getLc]);
        isOnCall = call != NULL;
    }

    if (!isOnCall) {
        if (balanceIntervalCurrent > balanceIntervalMax) {
            balanceIntervalCurrent = 0.0;
        } else {
            balanceIntervalCurrent++;
            return;
        }
    }
    
    [self pullBalanceCompletionBlock:^(NSString *balance){
        self.balanceLabel.text = balance;
    }];
}

#pragma mark - Action Functions

- (IBAction)doSecurityClick:(id)sender {
	if([LinphoneManager isLcReady] && linphone_core_get_calls_nb([LinphoneManager getLc])) {
		LinphoneCall *call = linphone_core_get_current_call([LinphoneManager getLc]);
		if(call != NULL) {
			LinphoneMediaEncryption enc = linphone_call_params_get_media_encryption(linphone_call_get_current_params(call));
			if(enc == LinphoneMediaEncryptionZRTP) {
				bool valid = linphone_call_get_authentication_token_verified(call);
				NSString *message = nil;
				if(valid) {
					message = NSLocalizedString(@"Remove trust in the peer?",nil);
				} else {
					message = [NSString stringWithFormat:NSLocalizedString(@"Confirm the following SAS with the peer:\n%s",nil),
							   linphone_call_get_authentication_token(call)];
				}
				if( securitySheet == nil ){
					securitySheet = [[DTActionSheet alloc] initWithTitle:message];
					[securitySheet setDelegate:self];
					[securitySheet addButtonWithTitle:NSLocalizedString(@"Ok",nil) block:^(){
						linphone_call_set_authentication_token_verified(call, !valid);
						[securitySheet release];
						securitySheet = nil;
					}];

					[securitySheet addDestructiveButtonWithTitle:NSLocalizedString(@"Cancel",nil) block:^(){
						[securitySheet release];
						securitySheet = nil;
					}];
					[securitySheet showInView:[PhoneMainView instance].view];
				}
			}
		}
	}
}

-(void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex{
	[securitySheet release];
	securitySheet = nil;
}

#pragma mark - TPMultiLayoutViewController Functions

- (NSDictionary*)attributesForView:(UIView*)view {
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];

	[attributes setObject:[NSValue valueWithCGRect:view.frame] forKey:@"frame"];
	[attributes setObject:[NSValue valueWithCGRect:view.bounds] forKey:@"bounds"];
	[attributes setObject:[NSNumber numberWithInteger:view.autoresizingMask] forKey:@"autoresizingMask"];

	return attributes;
}

- (void)applyAttributes:(NSDictionary*)attributes toView:(UIView*)view {
	view.frame = [[attributes objectForKey:@"frame"] CGRectValue];
	view.bounds = [[attributes objectForKey:@"bounds"] CGRectValue];
	view.autoresizingMask = [[attributes objectForKey:@"autoresizingMask"] integerValue];
}

@end
