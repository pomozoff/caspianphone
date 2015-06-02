//
//  SMSMessageCell.m
//  linphone
//
//  Created by Art on 5/21/15.
//
//

#import "SMSMessageCell.h"
#import "CoreDataManager.h"

@interface SMSMessageCell ()

@property (nonatomic, strong) UIView *bubbleView;
@property (nonatomic, strong) UIImageView *bubbleImageView;
@property (nonatomic, strong) UILabel *resendLabel;

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
        
        _resendLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 250, 15)];
        _resendLabel.text = @"Resend";
        _resendLabel.textColor = [UIColor redColor];
        _resendLabel.font = [UIFont systemFontOfSize:10.0];
        _resendLabel.alpha = 0;
        _resendLabel.numberOfLines = 1;
        _resendLabel.userInteractionEnabled = YES;
        [self.contentView addSubview:_resendLabel];
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(resendTapped)];
        [_resendLabel addGestureRecognizer:tap];
        
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
    
    [self.resendLabel sizeToFit];
    self.resendLabel.frame = CGRectMake(self.contentView.frame.size.width - self.resendLabel.frame.size.width - 33, self.messageLabel.frame.size.height + 25, self.resendLabel.frame.size.width, self.resendLabel.frame.size.height);
    
    self.statusImageView.frame = CGRectMake(self.contentView.frame.size.width - 30, self.timestampLabel.frame.origin.y, 10, 10);
    
    width = (self.messageLabel.frame.size.width + 20 < 145) ? 145 : self.messageLabel.frame.size.width + 20;
    self.bubbleView.frame = CGRectMake(self.contentView.frame.size.width - width - 10, 10, width, self.messageLabel.frame.size.height + 35);
    
    self.bubbleImageView.frame = CGRectMake(CGRectGetMaxX(self.bubbleView.frame) - 35, CGRectGetMaxY(self.bubbleView.frame) - 1, 16, 11);
}

- (void)setStatus:(NSInteger)status
{
    _status = status;
    
    if (status == MessageStatusSending) {
        self.statusImageView.image = [UIImage imageNamed:@"chat_message_inprogress"];
        self.timestampLabel.alpha = 1;
        self.resendLabel.alpha = 0;
    }
    else if (status == MessageStatusSent) {
        self.statusImageView.image = [UIImage imageNamed:@"chat_message_delivered"];
        self.timestampLabel.alpha = 1;
        self.resendLabel.alpha = 0;
    }
    else if (status == MessageStatusFailed) {
        self.statusImageView.image = [UIImage imageNamed:@"chat_message_not_delivered"];
        self.timestampLabel.alpha = 0;
        self.resendLabel.alpha = 1;
    }
}

- (void)resendTapped
{
    [self.delegate resendTapped:self];
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
