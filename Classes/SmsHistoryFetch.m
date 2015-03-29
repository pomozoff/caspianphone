//
//  smsHistoryFetch.m
//  linphone
//
//  Created by  on 3/14/15.
//
//

#import "SmsHistoryFetch.h"
#import "SmsHistory.h"

@implementation SmsHistoryFetch

static SmsHistoryFetch *_database;

+ (SmsHistoryFetch *)database    {
    if (_database == nil)    {
        _database = [[SmsHistoryFetch alloc] init];
    }
    return _database;
}

- (id)init {
    self = [super init];
    if (self) {
        NSString *str_CompleteDataBasePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        str_CompleteDataBasePath = [str_CompleteDataBasePath stringByAppendingString:[NSString stringWithFormat:@"/smshistory.sqlite3"]];
        
        NSString *sqliteDb = [[NSBundle mainBundle] pathForResource:@"smshistory" ofType:@"sqlite3"];
        if(![[NSFileManager defaultManager] fileExistsAtPath: str_CompleteDataBasePath])
            [[NSFileManager defaultManager] copyItemAtPath:sqliteDb toPath:str_CompleteDataBasePath error:nil];
        NSLog(@"%@",[[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory  inDomains:NSUserDomainMask] lastObject]);  //sunil
        if (sqlite3_open([sqliteDb UTF8String], &_database) != SQLITE_OK ){
            NSLog(@"Failed to open the smsHistory database");
        }
    }
    return self;
}

extern NSString *caspianPhoneNumber;
extern NSString *caspianPasswordKey;

-(NSArray *)getSMSHistory:(NSString *)phonenumber   {
    NSString *str_mblNumber = [[NSUserDefaults standardUserDefaults] objectForKey:caspianPhoneNumber];   // Username from the key
    NSMutableArray *returnArray = [[[NSMutableArray alloc] init] autorelease];
    
    NSString *str_CompleteDataBasePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    str_CompleteDataBasePath = [str_CompleteDataBasePath stringByAppendingString:[NSString stringWithFormat:@"/smshistory.sqlite3"]];
    if (sqlite3_open([str_CompleteDataBasePath UTF8String], &_database) == SQLITE_OK) {
        NSString *query = [NSString stringWithFormat:@"SELECT * FROM smshistory WHERE phonenumber=%@ AND username=%@",phonenumber,str_mblNumber];
        sqlite3_stmt *statement;
        if (sqlite3_prepare_v2(_database, [query UTF8String], -1, &statement, nil) == SQLITE_OK )  {
            while (sqlite3_step(statement) ==  SQLITE_ROW) {
                int sno = sqlite3_column_int(statement, 0);
                char *usernameChars = (char *) sqlite3_column_text(statement, 1);
                char *phoneNumberChars = (char *) sqlite3_column_text(statement, 2);
                char *messageChars = (char *) sqlite3_column_text(statement, 3);
                NSString *username = [[NSString alloc] initWithUTF8String:usernameChars];
                NSString *phoneNumber = [[NSString alloc] initWithUTF8String:phoneNumberChars];
                NSString *message = [[NSString alloc] initWithUTF8String:messageChars];
                
                SmsHistory *getSMS = [[SmsHistory alloc] initWithUniqueId:sno username:username phoneNumber:phoneNumber message:message];
                
                [returnArray addObject:getSMS];
                [username release];
                [phoneNumber release];
                [message release];
                [getSMS release];
            }
            sqlite3_finalize(statement);
        } else {
            sqlite3_close(_database);
        }
    }
    return returnArray;
}
-(NSArray *)getSMSHistoryPhoneNumbers   {
    NSMutableArray *returnArray = [[[NSMutableArray alloc] init] autorelease];
    NSString *str_CompleteDataBasePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    str_CompleteDataBasePath = [str_CompleteDataBasePath stringByAppendingString:[NSString stringWithFormat:@"/smshistory.sqlite3"]];
    if (sqlite3_open([str_CompleteDataBasePath UTF8String], &_database) == SQLITE_OK) {
        NSString *query = @"SELECT DISTINCT phonenumber FROM smshistory";
        sqlite3_stmt *statement;
        if (sqlite3_prepare_v2(_database, [query UTF8String], -1, &statement, nil) == SQLITE_OK ) {
            while (sqlite3_step(statement) ==  SQLITE_ROW) {
                char *phoneNumberChars = (char *) sqlite3_column_text(statement, 0);
                NSString *phoneNumber = [[NSString alloc] initWithUTF8String:phoneNumberChars];
                
                SmsHistory *getSMS = [[SmsHistory alloc]  initWithUniqueId:(NSString *)phoneNumber];
                
                [returnArray addObject:getSMS];
                
                [phoneNumber release];
                [getSMS release];
            }
            sqlite3_finalize(statement);
        } else {
            sqlite3_close(_database);
        }
    }
    return returnArray;
}

-(NSArray *)insertSMSHistory:(NSString *)username :(NSString *)phoneNumber :(NSString *)message {
    NSMutableArray *returnArray = [[[NSMutableArray alloc] init] autorelease];
    NSString *str_CompleteDataBasePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    str_CompleteDataBasePath = [str_CompleteDataBasePath stringByAppendingString:[NSString stringWithFormat:@"/smshistory.sqlite3"]];
    if (sqlite3_open([str_CompleteDataBasePath UTF8String], &_database) == SQLITE_OK) {
        NSString *query = [NSString stringWithFormat:@"INSERT INTO smshistory (username, phonenumber, message) VALUES ('%@','%@','%@')",username,phoneNumber,message];
        sqlite3_stmt *statement;
        if (sqlite3_prepare_v2(_database, [query UTF8String], -1, &statement, nil) == SQLITE_OK )  {
            if (SQLITE_DONE != sqlite3_step(statement)) {
                NSLog(@"Error inserting data in sqlite3");
            } else {
                NSLog(@"Inserted");
            }
            sqlite3_finalize(statement);
            sqlite3_close(_database);
        } else {
            sqlite3_close(_database);
        }
    }
    return returnArray;
}

- (void)dealloc {
    sqlite3_close(_database);
    [super dealloc];
}

@end
