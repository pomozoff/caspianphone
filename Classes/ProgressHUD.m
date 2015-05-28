//
//  ProgressHUD.m
//  linphone
//
//  Created by Art on 5/18/15.
//
//

#import "ProgressHUD.h"
#import "UILoadingImageView.h"

#define progressTag 12345

@implementation ProgressHUD

+ (void)showLoadingInView:(UIView *)view
{
    UIView *transparentBG = [[UIView alloc] initWithFrame:view.frame];
    transparentBG.tag = progressTag;
    transparentBG.backgroundColor = [UIColor whiteColor];
    transparentBG.alpha = 0.5;
    [view addSubview:transparentBG];
    
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    spinner.tag = progressTag;
    [spinner setColor:[UIColor grayColor]];
    spinner.center = view.center;
    [view addSubview:spinner];
    [spinner startAnimating];
}

+ (void)hideLoadingInView:(UIView *)view
{
    for (UIView *subview in view.subviews) {
        if (subview.tag == progressTag) {
            [subview removeFromSuperview];
        }
    }
}

+ (void)showAlertWithTitle:(NSString *)title
                   message:(NSString *)message
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}

@end
