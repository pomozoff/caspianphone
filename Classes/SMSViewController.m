//
//  SMSViewController.m
//  linphone
//
//  Created by Art on 5/18/15.
//
//

#import "SMSViewController.h"

@interface SMSViewController ()

@end

@implementation SMSViewController

#pragma mark - UICompositeViewDelegate Functions

static UICompositeViewDescription *compositeDescription = nil;

+ (UICompositeViewDescription *)compositeViewDescription {
    if(compositeDescription == nil) {
        compositeDescription = [[UICompositeViewDescription alloc] init:@"Activate SMS"
                                                                content:@"SMSViewController"
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
