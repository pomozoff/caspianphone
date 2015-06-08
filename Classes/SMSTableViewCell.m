//
//  SMSTableViewCell.m
//  linphone
//
//  Created by Art on 5/19/15.
//
//

#import "SMSTableViewCell.h"

@implementation SMSTableViewCell

- (void)awakeFromNib {
    UIView *selectionColor = [[UIView alloc] init];
    selectionColor.backgroundColor = [UIColor colorWithRed:(102/255.0) green:(167/255.0) blue:(200/255.0) alpha:1];
    self.selectedBackgroundView = selectionColor;
    self.profileImageView.layer.cornerRadius = self.profileImageView.frame.size.width / 2;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

+ (NSString *)reuseIdentifier
{
    return @"SMSTableViewCellIdentifier";
}

@end
