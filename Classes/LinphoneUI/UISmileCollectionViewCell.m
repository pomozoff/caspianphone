//
//  UISmileCollectionViewCell.m
//  linphone
//
//  Created by Антон on 18.02.15.
//
//

#import "UISmileCollectionViewCell.h"

@implementation UISmileCollectionViewCell

#pragma mark Lifecycle

- (void)dealloc {
    [_smileImage release];
    [super dealloc];
}

@end
