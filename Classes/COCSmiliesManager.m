//
//  COCSmiliesManager.m
//  linphone
//
//  Created by Антон on 10.02.15.
//
//

#import "COCSmiliesManager.h"
#import "COCTextAttachment.h"

#import "LinphoneManager.h"

@interface COCSmiliesManager ()

@property (nonatomic, retain) NSDictionary *smiliesCollection;

@end

@implementation COCSmiliesManager

static COCSmiliesManager *_sharedInstance = nil;
static dispatch_once_t once_token = 0;

#pragma mark - Public

+ (instancetype)sharedInstance {
    dispatch_once(&once_token, ^{
        if (_sharedInstance == nil) {
            _sharedInstance = [[COCSmiliesManager alloc] init];
        }
    });
    return _sharedInstance;
}

- (NSAttributedString *)attributedStringForText:(NSString *)nstext {
    NSAttributedString *attr_text = [[NSAttributedString alloc]
                                     initWithString:nstext
                                     attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:17.0],
                                                  NSForegroundColorAttributeName:[UIColor darkGrayColor]}];
    
    BOOL useImagesForSmilies = [[LinphoneManager instance] lpConfigBoolForKey:@"use_images_for_smilies_preference"];
    if (useImagesForSmilies) {
        NSArray *allSmileies = [self.smiliesCollection allKeys];
        NSArray *OrderedByLength = [allSmileies sortedArrayUsingComparator:^(NSString *str1, NSString *str2) {
            if (str1.length > str2.length) {
                return NSOrderedAscending;
            } else {
                return NSOrderedDescending;
            }
            return NSOrderedSame;
        }];
        for (NSString *smile in OrderedByLength) {
            NSUInteger index = 0;
            while (true) {
                NSRange findInRange = NSMakeRange(index, nstext.length - index);
                NSRange foundRange = [nstext rangeOfString:smile options:NSLiteralSearch range:findInRange];
                if (foundRange.location == NSNotFound) {
                    break;
                }
                
                COCTextAttachment *textAttachment = [[COCTextAttachment alloc] init];
                textAttachment.image = self.smiliesCollection[smile];
                NSAttributedString *attrStringWithImage = [NSAttributedString attributedStringWithAttachment:textAttachment];
                
                NSMutableAttributedString *attributedString = [attr_text mutableCopy];
                [attributedString replaceCharactersInRange:foundRange withAttributedString:attrStringWithImage];
                
                [attr_text release];
                attr_text = attributedString;
                
                index = foundRange.location;
                nstext = [attributedString string];
            }
        }
    }
    return [attr_text autorelease];
}

#pragma mark - Lifecycle

- (instancetype)init {
    if (self = [super init]) {
        self.smiliesCollection = [self smilesOfSize:@"64"];
    }
    return self;
}
- (void)dealloc {
    self.smiliesCollection = nil;

    [_sharedInstance release];
    
    [super dealloc];
}

#pragma mark - Private

- (void)addImage:(UIImage *)image toCollection:(NSMutableDictionary *)collection forSmilies:(NSArray *)arrayOfSmilies {
    for (NSString *smile in arrayOfSmilies) {
        collection[smile] = image;
    }
}
- (NSDictionary *)smilesOfSize:(NSString *)size {
    NSMutableDictionary *smiliesMutableCollectionSmall = [[NSMutableDictionary alloc] init];

    [self addImage:[UIImage imageNamed:[NSString stringWithFormat:@"smilie_%@_angel.png", size]]     toCollection:smiliesMutableCollectionSmall forSmilies:@[@":angel:", @"O:)", @"O:-)"]];
    [self addImage:[UIImage imageNamed:[NSString stringWithFormat:@"smilie_%@_angry.png", size]]     toCollection:smiliesMutableCollectionSmall forSmilies:@[@":angry:", @":(", @":-(", @":-[", @":["]];
    [self addImage:[UIImage imageNamed:[NSString stringWithFormat:@"smilie_%@_ashamed.png", size]]   toCollection:smiliesMutableCollectionSmall forSmilies:@[@":ashamed:", @":/ ", @":-/", @":-|", @":|"]];
    [self addImage:[UIImage imageNamed:[NSString stringWithFormat:@"smilie_%@_balloons.png", size]]  toCollection:smiliesMutableCollectionSmall forSmilies:@[@":balloons:", @"O~"]];
    [self addImage:[UIImage imageNamed:[NSString stringWithFormat:@"smilie_%@_blush.png", size]]     toCollection:smiliesMutableCollectionSmall forSmilies:@[@":blush:", @":$)"]];
    [self addImage:[UIImage imageNamed:[NSString stringWithFormat:@"smilie_%@_burger.png", size]]    toCollection:smiliesMutableCollectionSmall forSmilies:@[@":burger:", @"(||)"]];
    [self addImage:[UIImage imageNamed:[NSString stringWithFormat:@"smilie_%@_cake.png", size]]      toCollection:smiliesMutableCollectionSmall forSmilies:@[@":cake:", @"<|"]];
    [self addImage:[UIImage imageNamed:[NSString stringWithFormat:@"smilie_%@_coffee.png", size]]    toCollection:smiliesMutableCollectionSmall forSmilies:@[@":coffee:"]];
    [self addImage:[UIImage imageNamed:[NSString stringWithFormat:@"smilie_%@_flower.png", size]]    toCollection:smiliesMutableCollectionSmall forSmilies:@[@":flower:", @"@}-;-"]];
    [self addImage:[UIImage imageNamed:[NSString stringWithFormat:@"smilie_%@_football.png", size]]  toCollection:smiliesMutableCollectionSmall forSmilies:@[@":football:", @"¤"]];
    [self addImage:[UIImage imageNamed:[NSString stringWithFormat:@"smilie_%@_glasses.png", size]]   toCollection:smiliesMutableCollectionSmall forSmilies:@[@":glasses:", @"(..)"]];
    [self addImage:[UIImage imageNamed:[NSString stringWithFormat:@"smilie_%@_goofy.png", size]]     toCollection:smiliesMutableCollectionSmall forSmilies:@[@":goofy:", @":o)"]];
    [self addImage:[UIImage imageNamed:[NSString stringWithFormat:@"smilie_%@_grin.png", size]]      toCollection:smiliesMutableCollectionSmall forSmilies:@[@":grin:", @":D", @":-D", @"XD", @"X-D"]];
    [self addImage:[UIImage imageNamed:[NSString stringWithFormat:@"smilie_%@_happy.png", size]]     toCollection:smiliesMutableCollectionSmall forSmilies:@[@":happy:", @":)", @":-)"]];
    [self addImage:[UIImage imageNamed:[NSString stringWithFormat:@"smilie_%@_heart.png", size]]     toCollection:smiliesMutableCollectionSmall forSmilies:@[@":heart:", @"<3"]];
    [self addImage:[UIImage imageNamed:[NSString stringWithFormat:@"smilie_%@_icetea.png", size]]    toCollection:smiliesMutableCollectionSmall forSmilies:@[@":drink:"]];
    [self addImage:[UIImage imageNamed:[NSString stringWithFormat:@"smilie_%@_kiss.png", size]]      toCollection:smiliesMutableCollectionSmall forSmilies:@[@":kiss:", @":*", @":-*"]];
    [self addImage:[UIImage imageNamed:[NSString stringWithFormat:@"smilie_%@_kisses.png", size]]    toCollection:smiliesMutableCollectionSmall forSmilies:@[@":kisses:"]];
    [self addImage:[UIImage imageNamed:[NSString stringWithFormat:@"smilie_%@_penguin.png", size]]   toCollection:smiliesMutableCollectionSmall forSmilies:@[@":penguin:", @"^o|"]];
    [self addImage:[UIImage imageNamed:[NSString stringWithFormat:@"smilie_%@_present.png", size]]   toCollection:smiliesMutableCollectionSmall forSmilies:@[@":present:"]];
    [self addImage:[UIImage imageNamed:[NSString stringWithFormat:@"smilie_%@_sleepy.png", size]]    toCollection:smiliesMutableCollectionSmall forSmilies:@[@":sleepy:", @":O"]];
    [self addImage:[UIImage imageNamed:[NSString stringWithFormat:@"smilie_%@_stopclock.png", size]] toCollection:smiliesMutableCollectionSmall forSmilies:@[@":stopclock:"]];
    [self addImage:[UIImage imageNamed:[NSString stringWithFormat:@"smilie_%@_sun.png", size]]       toCollection:smiliesMutableCollectionSmall forSmilies:@[@":sun:"]];
    [self addImage:[UIImage imageNamed:[NSString stringWithFormat:@"smilie_%@_surprised.png", size]] toCollection:smiliesMutableCollectionSmall forSmilies:@[@":surprised:", @"O_o"]];
    [self addImage:[UIImage imageNamed:[NSString stringWithFormat:@"smilie_%@_whistling.png", size]] toCollection:smiliesMutableCollectionSmall forSmilies:@[@":whistling:"]];
    
    return [smiliesMutableCollectionSmall autorelease];
}

@end
