//
//  SMSMessageCell.m
//  linphone
//
//  Created by Art on 5/21/15.
//
//

#import "SMSMessageCell.h"

@interface SMSMessageCell ()

@property (nonatomic, strong) UIView *bubbleView;
@property (nonatomic, strong) UIImageView *bubbleImageView;

@end

@implementation SMSMessageCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectedBackgroundView = [UIView new];
        self.backgroundColor = [UIColor clearColor];
        
        _bubbleView = [[UIView alloc] initWithFrame:CGRectZero];
        _bubbleView.backgroundColor = [UIColor colorWithRed:198.0/255.0 green:209.0/255.0 blue:215.0/255.0 alpha:1];
        _bubbleView.layer.cornerRadius = 10.0;
        _bubbleView.layer.borderWidth = 1;
        _bubbleView.layer.borderColor = [UIColor colorWithRed:161.0/255.0 green:174.0/255.0 blue:187.0/255.0 alpha:1].CGColor;
        [self.contentView addSubview:_bubbleView];
        
        _messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 280, 1000)];
        _messageLabel.textColor = [UIColor darkTextColor];
        _messageLabel.font = [UIFont systemFontOfSize:14.0];
        _messageLabel.numberOfLines = 0;
        [self.contentView addSubview:_messageLabel];
        
        _timestampLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 250, 15)];
        _timestampLabel.textColor = [UIColor grayColor];
        _timestampLabel.font = [UIFont systemFontOfSize:10.0];
        _timestampLabel.numberOfLines = 1;
        [self.contentView addSubview:_timestampLabel];
        
        _statusImageView = [[UIImageView alloc] init];
        [self.contentView addSubview:_statusImageView];
        
        _bubbleImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"chat_bubble_outgoing_triangle"]];
        [self.contentView addSubview:_bubbleImageView];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    [self.messageLabel sizeToFit];
    CGFloat width = (self.messageLabel.frame.size.width < 125) ? 125 : self.messageLabel.frame.size.width;
    self.messageLabel.frame = CGRectMake(self.contentView.frame.size.width - width - 20, 20, width, self.messageLabel.frame.size.height);
    
    [self.timestampLabel sizeToFit];
    self.timestampLabel.frame = CGRectMake(self.contentView.frame.size.width - self.timestampLabel.frame.size.width - 33, self.messageLabel.frame.size.height + 25, self.timestampLabel.frame.size.width, self.timestampLabel.frame.size.height);
    
    self.statusImageView.frame = CGRectMake(self.contentView.frame.size.width - 30, self.timestampLabel.frame.origin.y, 10, 10);
    
    width = (self.messageLabel.frame.size.width + 20 < 145) ? 145 : self.messageLabel.frame.size.width + 20;
    self.bubbleView.frame = CGRectMake(self.contentView.frame.size.width - width - 10, 10, width, self.messageLabel.frame.size.height + 35);
    
    self.bubbleImageView.frame = CGRectMake(CGRectGetMaxX(self.bubbleView.frame) - 35, CGRectGetMaxY(self.bubbleView.frame) - 1, 16, 11);
}

+ (CGFloat)cellHeightWithMessage:(NSString *)message
{
    CGFloat height = 65;
    height += [message sizeWithFont:[UIFont systemFontOfSize:14.0] constrainedToSize:CGSizeMake(280, 1000)].height;
    return height;
}

+ (NSString *)reuseIdentifier
{
    return @"SMSMessageCellIdentifier";
}

@end
