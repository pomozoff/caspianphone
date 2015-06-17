//
//  HistoryCell.m
//  linphone
//
//  Created by Art on 6/16/15.
//
//

#import "HistoryCell.h"

@implementation HistoryCell

- (void)awakeFromNib {
    
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (IBAction)didTapChatButton:(id)sender {
}

- (IBAction)didTapSMSButton:(id)sender {
}

- (IBAction)didTapCallButton:(id)sender {
}

- (IBAction)didTapAddButton:(id)sender {
}

- (IBAction)didTapLogoButton:(id)sender {
}

+ (NSString *)reuseIdentifier
{
    return @"HistoryCellIdentifier";
}

@end
