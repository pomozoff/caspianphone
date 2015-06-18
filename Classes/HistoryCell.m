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

- (IBAction)didTapChatButton:(id)sender
{
    [self.delegate didTapChatButton:self];
}

- (IBAction)didTapSMSButton:(id)sender
{
    [self.delegate didTapSMSButton:self];
}

- (IBAction)didTapCallButton:(id)sender
{
    [self.delegate didTapCallButton:self];
}

- (IBAction)didTapAddButton:(id)sender
{
    [self.delegate didTapAddButton:self];
}

- (IBAction)didTapLogoButton:(id)sender
{
    [self.delegate didTapLogoButton:self];
}

+ (NSString *)reuseIdentifier
{
    return @"HistoryCellIdentifier";
}

@end
