//
//  COCTextAttachment.m
//  linphone
//
//  Created by Антон on 05.02.15.
//
//

#import "COCTextAttachment.h"

@implementation COCTextAttachment

- (id)initWithData:(NSData *)contentData ofType:(NSString *)uti {
    self = [super initWithData:contentData ofType:uti];
    if (self) {
        if (self.image == nil) {
            self.image = [UIImage imageWithData:contentData];
        } else {
            NSLog(@"COCTextAttachment - self.image is NOT nil");
        }
    }
    return self;
}
- (CGRect)attachmentBoundsForTextContainer:(NSTextContainer *)textContainer proposedLineFragment:(CGRect)lineFrag glyphPosition:(CGPoint)position characterIndex:(NSUInteger)charIndex {
    return [self scaleImageSizeToWidth:lineFrag.size.width];
}

- (CGRect)scaleImageSizeToWidth:(float)width {
    float scalingFactor = 0.5;
    CGSize imageSize = [self.image size];
    CGRect rect = CGRectMake(0, -3, imageSize.width * scalingFactor, imageSize.height * scalingFactor);
    return rect;
}

@end
