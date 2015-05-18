//
//  ProgressHUD.h
//  linphone
//
//  Created by Art on 5/18/15.
//
//

#import <Foundation/Foundation.h>

@interface ProgressHUD : NSObject

+ (void)showLoadingInView:(UIView *)view;
+ (void)hideLoadingInView:(UIView *)view;
+ (void)showAlertWithTitle:(NSString *)title
                   message:(NSString *)message;

@end
