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
@property (nonatomic, retain) NSArray *smiliesList;

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
                
                NSString *previousChar = [self previousCharForRange:foundRange inString:nstext];
                if (![self isCharWhitespace:previousChar]) {
                    break;
                }
                NSString *nextChar = [self nextCharForRange:foundRange insString:nstext];
                if (![self isCharWhitespace:nextChar]) {
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

- (NSInteger)smiliesCount {
    return self.smiliesList.count;
}
- (NSString *)smileCodeWithIndex:(NSInteger)index {
    return self.smiliesList[index];
}
- (UIImage *)smileWithIndex:(NSInteger)index {
    return self.smiliesCollection[[self smileCodeWithIndex:index]];
}

#pragma mark - Properties

- (void)setSmiliesCollection:(NSDictionary *)smiliesCollection {
    if (_smiliesCollection != smiliesCollection) {
        [smiliesCollection retain];
        [_smiliesCollection release];
        _smiliesCollection = smiliesCollection;
        self.smiliesList = [self smiliesListFromCollection:smiliesCollection];
    }
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
    self.smiliesList = nil;

    [_sharedInstance release];
    
    [super dealloc];
}

#pragma mark - Private

- (NSArray *)smiliesListFromCollection:(NSDictionary *)smiliesCollection {
    NSMutableArray *smiliesMutableList = [[NSMutableArray alloc] init];
    
    for (NSString *smile in smiliesCollection) {
        if (smile.length > 2
            && [[smile substringWithRange:NSMakeRange(0, 1)] isEqualToString:@":"]
            && [[smile substringWithRange:NSMakeRange(smile.length - 1, 1)] isEqualToString:@":"]
            ) {
            [smiliesMutableList addObject:smile];
        }
    }
    return [smiliesMutableList autorelease];
}
- (void)addImage:(UIImage *)image toCollection:(NSMutableDictionary *)collection forSmilies:(NSArray *)arrayOfSmilies {
    for (NSString *smile in arrayOfSmilies) {
        collection[smile] = image;
    }
}
- (NSDictionary *)smilesOfSize:(NSString *)size {
    NSMutableDictionary *smiliesMutableCollection = [[NSMutableDictionary alloc] init];

    [self addImage:[UIImage imageNamed:[NSString stringWithFormat:@"smilie_%@_angel.png", size]]     toCollection:smiliesMutableCollection forSmilies:@[@":angel:", @"O:)", @"O:-)"]];
    [self addImage:[UIImage imageNamed:[NSString stringWithFormat:@"smilie_%@_angry.png", size]]     toCollection:smiliesMutableCollection forSmilies:@[@":angry:", @":(", @":-(", @":-[", @":["]];
    [self addImage:[UIImage imageNamed:[NSString stringWithFormat:@"smilie_%@_ashamed.png", size]]   toCollection:smiliesMutableCollection forSmilies:@[@":ashamed:", @":/ ", @":-/", @":-|", @":|"]];
    [self addImage:[UIImage imageNamed:[NSString stringWithFormat:@"smilie_%@_balloons.png", size]]  toCollection:smiliesMutableCollection forSmilies:@[@":balloons:", @"O~"]];
    [self addImage:[UIImage imageNamed:[NSString stringWithFormat:@"smilie_%@_blush.png", size]]     toCollection:smiliesMutableCollection forSmilies:@[@":blush:", @":$)"]];
    [self addImage:[UIImage imageNamed:[NSString stringWithFormat:@"smilie_%@_burger.png", size]]    toCollection:smiliesMutableCollection forSmilies:@[@":burger:", @"(||)"]];
    [self addImage:[UIImage imageNamed:[NSString stringWithFormat:@"smilie_%@_cake.png", size]]      toCollection:smiliesMutableCollection forSmilies:@[@":cake:", @"<|"]];
    [self addImage:[UIImage imageNamed:[NSString stringWithFormat:@"smilie_%@_coffee.png", size]]    toCollection:smiliesMutableCollection forSmilies:@[@":coffee:"]];
    [self addImage:[UIImage imageNamed:[NSString stringWithFormat:@"smilie_%@_flower.png", size]]    toCollection:smiliesMutableCollection forSmilies:@[@":flower:", @"@}-;-"]];
    [self addImage:[UIImage imageNamed:[NSString stringWithFormat:@"smilie_%@_football.png", size]]  toCollection:smiliesMutableCollection forSmilies:@[@":football:", @"¤"]];
    [self addImage:[UIImage imageNamed:[NSString stringWithFormat:@"smilie_%@_glasses.png", size]]   toCollection:smiliesMutableCollection forSmilies:@[@":glasses:", @"(..)"]];
    [self addImage:[UIImage imageNamed:[NSString stringWithFormat:@"smilie_%@_goofy.png", size]]     toCollection:smiliesMutableCollection forSmilies:@[@":goofy:", @":o)"]];
    [self addImage:[UIImage imageNamed:[NSString stringWithFormat:@"smilie_%@_grin.png", size]]      toCollection:smiliesMutableCollection forSmilies:@[@":grin:", @":D", @":-D", @"XD", @"X-D"]];
    [self addImage:[UIImage imageNamed:[NSString stringWithFormat:@"smilie_%@_happy.png", size]]     toCollection:smiliesMutableCollection forSmilies:@[@":happy:", @":)", @":-)"]];
    [self addImage:[UIImage imageNamed:[NSString stringWithFormat:@"smilie_%@_heart.png", size]]     toCollection:smiliesMutableCollection forSmilies:@[@":heart:", @"<3"]];
    [self addImage:[UIImage imageNamed:[NSString stringWithFormat:@"smilie_%@_icetea.png", size]]    toCollection:smiliesMutableCollection forSmilies:@[@":drink:"]];
    [self addImage:[UIImage imageNamed:[NSString stringWithFormat:@"smilie_%@_kiss.png", size]]      toCollection:smiliesMutableCollection forSmilies:@[@":kiss:", @":*", @":-*"]];
    [self addImage:[UIImage imageNamed:[NSString stringWithFormat:@"smilie_%@_kisses.png", size]]    toCollection:smiliesMutableCollection forSmilies:@[@":kisses:"]];
    [self addImage:[UIImage imageNamed:[NSString stringWithFormat:@"smilie_%@_penguin.png", size]]   toCollection:smiliesMutableCollection forSmilies:@[@":penguin:", @"^o|"]];
    [self addImage:[UIImage imageNamed:[NSString stringWithFormat:@"smilie_%@_present.png", size]]   toCollection:smiliesMutableCollection forSmilies:@[@":present:"]];
    [self addImage:[UIImage imageNamed:[NSString stringWithFormat:@"smilie_%@_sleepy.png", size]]    toCollection:smiliesMutableCollection forSmilies:@[@":sleepy:", @":O"]];
    [self addImage:[UIImage imageNamed:[NSString stringWithFormat:@"smilie_%@_stopclock.png", size]] toCollection:smiliesMutableCollection forSmilies:@[@":stopclock:"]];
    [self addImage:[UIImage imageNamed:[NSString stringWithFormat:@"smilie_%@_sun.png", size]]       toCollection:smiliesMutableCollection forSmilies:@[@":sun:"]];
    [self addImage:[UIImage imageNamed:[NSString stringWithFormat:@"smilie_%@_surprised.png", size]] toCollection:smiliesMutableCollection forSmilies:@[@":surprised:", @"O_o"]];
    [self addImage:[UIImage imageNamed:[NSString stringWithFormat:@"smilie_%@_whistling.png", size]] toCollection:smiliesMutableCollection forSmilies:@[@":whistling:"]];
    
    return [smiliesMutableCollection autorelease];
}
- (NSString *)previousCharForRange:(NSRange)range inString:(NSString *)string {
    if (range.location == 0) {
        return nil;
    }
    return [string substringWithRange:NSMakeRange(range.location - 1, 1)];
}
- (NSString *)nextCharForRange:(NSRange)range insString:(NSString *)string {
    if (range.location + range.length >= string.length) {
        return nil;
    }
    return [string substringWithRange:NSMakeRange(range.location + range.length, 1)];
}
- (BOOL)isCharWhitespace:(NSString *)charStr {
    if (charStr) {
        NSArray *wordsArray = [charStr componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSString *noSpaceString = [wordsArray componentsJoinedByString:@""];
        return noSpaceString.length > 0 ? NO : YES;
    }
    return YES;
}

@end
