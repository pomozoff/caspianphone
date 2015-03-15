//
//  COCAlertView.h
//  linphone
//
//  Created by Антон on 15.03.15.
//
//

#import <UIKit/UIKit.h>

typedef void(^AlertCompletionBlock)(void);

@interface COCAlertView : UIAlertView

@property (nonatomic, strong) AlertCompletionBlock completion;

@end
