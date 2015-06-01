//
//  SMSMessageCell.h
//  linphone
//
//  Created by Art on 5/21/15.
//
//

#import <UIKit/UIKit.h>
@class SMSMessageCell;

@protocol SMSMessageCellDelegate <NSObject>

- (void)resendTapped:(SMSMessageCell *)cell;

@end

@interface SMSMessageCell : UITableViewCell

@property (nonatomic, weak) id <SMSMessageCellDelegate> delegate;
@property (nonatomic, strong) UILabel *messageLabel;
@property (nonatomic, strong) UILabel *timestampLabel;
@property (nonatomic, strong) UIImageView *statusImageView;
@property (nonatomic) NSInteger status;

+ (CGFloat)cellHeightWithMessage:(NSString *)message;

@end
