//
//  SMSMessageCell.h
//  linphone
//
//  Created by Art on 5/21/15.
//
//

#import <UIKit/UIKit.h>

@interface SMSMessageCell : UITableViewCell

@property (nonatomic, strong) UILabel *messageLabel;
@property (nonatomic, strong) UILabel *timestampLabel;
@property (nonatomic, strong) UIImageView *statusImageView;

+ (CGFloat)cellHeightWithMessage:(NSString *)message;

@end
