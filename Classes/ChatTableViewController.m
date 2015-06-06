/* ChatTableViewController.m
 *
 * Copyright (C) 2012  Belledonne Comunications, Grenoble, France
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or   
 *  (at your option) any later version.                                 
 *                                                                      
 *  This program is distributed in the hope that it will be useful,     
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of      
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the       
 *  GNU General Public License for more details.                
 *                                                                      
 *  You should have received a copy of the GNU General Public License   
 *  along with this program; if not, write to the Free Software         
 *  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */ 

#import "ChatTableViewController.h"
#import "UIChatCell.h"

#import "linphone/linphonecore.h"
#import "mediastreamer2/mscommon.h"

#import "PhoneMainView.h"
#import "UACellBackgroundView.h"
#import "UILinphone.h"
#import "Utils.h"

@implementation ChatTableViewController {
    @private
    MSList* data;
}


#pragma mark - Lifecycle Functions

- (void)dealloc {
    [super dealloc];
}

#pragma mark - ViewController Functions 

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.tableView.accessibilityIdentifier = @"ChatRoom list";
    [self loadData];
}


#pragma mark - 

static int sorted_history_comparison(LinphoneChatRoom *to_insert, LinphoneChatRoom *elem){
    LinphoneChatMessage* last_new_message  = linphone_chat_room_get_user_data(to_insert);
    LinphoneChatMessage* last_elem_message = linphone_chat_room_get_user_data(elem);

    if( last_new_message && last_elem_message ){
        time_t new = linphone_chat_message_get_time(last_new_message);
        time_t old = linphone_chat_message_get_time(last_elem_message);
        if ( new < old ) return 1;
        else if ( new > old) return -1;
    }
    return 0;
}

- (MSList*)sortChatRooms {
    MSList* sorted   = nil;
    MSList* unsorted = linphone_core_get_chat_rooms([LinphoneManager getLc]);
    MSList* iter     = unsorted;

    LinphoneChatRoom *chatRoom = NULL;
    while (iter) {
        // store last message in user data
        MSList*               history = linphone_chat_room_get_history(iter->data, 1);
        LinphoneChatMessage* last_msg = history? history->data : NULL;
        if( last_msg ){
            linphone_chat_room_set_user_data(iter->data, linphone_chat_message_ref(last_msg));
        }
        ms_list_free_with_data(history, (void (*)(void *))linphone_chat_message_unref);

        sorted = ms_list_insert_sorted(sorted,
                                       linphone_chat_room_ref(iter->data),
                                       (MSCompareFunc)sorted_history_comparison);

        iter = iter->next;
    }
    if (chatRoom == NULL) {
        const char* addressSupport = [[FastAddressBook caspianSupportPhoneNumber] UTF8String];
        LinphoneCore *lc = [LinphoneManager getLc];
        chatRoom = linphone_core_create_chat_room(lc, addressSupport);
    }
    sorted = ms_list_prepend(sorted, chatRoom);
    
    return sorted;
}

static void chatTable_free_chatrooms(void *data){
    LinphoneChatMessage* lastMsg = linphone_chat_room_get_user_data(data);
    if( lastMsg ){
        linphone_chat_message_unref(linphone_chat_room_get_user_data(data));
        linphone_chat_room_set_user_data(data, NULL);
    }
    linphone_chat_room_unref(data);
}

- (void)loadData {
    if( data != NULL ){
        ms_list_free_with_data(data, chatTable_free_chatrooms);
    }
    data = [self sortChatRooms];
    [[self tableView] reloadData];
}

#pragma mark - UITableViewDataSource Functions

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return ms_list_size(data);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *kCellId = @"UIChatCell";
    UIChatCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellId];
    if (cell == nil) {
        cell = [[[UIChatCell alloc] initWithIdentifier:kCellId] autorelease];
        cell.rightUtilityButtons = [self isRowWithOneCallCaspianSupport:indexPath.row] ? [self rightButtonsCall] : [self rightButtonsAll];
        //[cell.rightUtilityButtons autorelease];
        cell.delegate = self;
        
        // Background View
        UACellBackgroundView *selectedBackgroundView = [[[UACellBackgroundView alloc] initWithFrame:CGRectZero] autorelease];
        cell.selectedBackgroundView = selectedBackgroundView;
        [selectedBackgroundView setBackgroundColor:LINPHONE_TABLE_CELL_BACKGROUND_COLOR];
    }
    
    [cell setChatRoom:(LinphoneChatRoom*)ms_list_nth_data(data, (int)[indexPath row])];
    
    return cell;
}


#pragma mark - UITableViewDelegate Functions

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    LinphoneChatRoom *chatRoom = (LinphoneChatRoom*)ms_list_nth_data(data, (int)[indexPath row]);
    
    // Go to ChatRoom view
    ChatRoomViewController *controller = DYNAMIC_CAST([[PhoneMainView instance] changeCurrentView:[ChatRoomViewController compositeViewDescription] push:TRUE], ChatRoomViewController);
    if(controller != nil) {
        [controller setChatRoom:chatRoom];
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)aTableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    // Detemine if it's in editing mode
    if (self.editing) {
        return UITableViewCellEditingStyleDelete;
    }
    return UITableViewCellEditingStyleNone;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath  {
    /*
    if(editingStyle == UITableViewCellEditingStyleDelete) {
        [tableView beginUpdates];

        LinphoneChatRoom *chatRoom = (LinphoneChatRoom *)ms_list_nth_data(data, (int)[indexPath row]);
        linphone_chat_room_delete_history(chatRoom);
        linphone_chat_room_unref(chatRoom);

        // will force a call to [self loadData]
        [[NSNotificationCenter defaultCenter] postNotificationName:kLinphoneTextReceived object:self];

        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        [tableView endUpdates];
    }
    */
}

#pragma mark - SWTableViewCellDelegate

- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerRightUtilityButtonWithIndex:(NSInteger)index {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    if (!indexPath) {
        NSString *textLabel = ((UIChatCell *)cell).addressLabel.text;
        [LinphoneLogger logc:LinphoneLoggerLog format:"ChatTableViewController: indexpath not found for cell - %s", [textLabel UTF8String]];
        return;
    }
    switch (index) {
        case 0: {
            // Call button was pressed
            NSString *address = [self phoneNumberForCellAtRow:indexPath.row];
            NSString *displayName = nil;
            ABRecordRef contact = [[[LinphoneManager instance] fastAddressBook] getContact:address];
            if(contact) {
                displayName = [FastAddressBook getContactDisplayName:contact];
            }
            [[LinphoneManager instance] call:address displayName:displayName transfer:FALSE];

            break;
        }
        case 1: {
            // Delete button was pressed
            [LinphoneLogger logc:LinphoneLoggerLog format:"ChatTableViewController: delete object for row %i", indexPath.row];

            [self.tableView beginUpdates];
            
            LinphoneChatRoom *chatRoom = (LinphoneChatRoom*)ms_list_nth_data(data, (int)indexPath.row);
            linphone_chat_room_delete_history(chatRoom);
            linphone_chat_room_unref(chatRoom);

            [[NSNotificationCenter defaultCenter] postNotificationName:kLinphoneTextReceived object:self];
            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];

            [self.tableView endUpdates];
            
            break;
        }
        default:
            break;
    }
}

- (BOOL)swipeableTableViewCellShouldHideUtilityButtonsOnSwipe:(SWTableViewCell *)cell {
    return YES;
}
/*
- (BOOL)swipeableTableViewCell:(SWTableViewCell *)cell canSwipeToState:(SWCellState)state {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    NSString *address = [self phoneNumberForCellAtRow:indexPath.row];
    return ![address isEqualToString:[FastAddressBook caspianSupportPhoneNumber]];
}
*/

#pragma mark - Private

- (NSMutableArray *)rightButtonsCall {
    UIColor *callColor = [UIColor colorWithRed:0.78f green:0.78f blue:0.8f alpha:1.0];
    
    NSMutableArray *rightUtilityButtons = [[NSMutableArray alloc] init];
    [rightUtilityButtons sw_addUtilityButtonWithColor:callColor title:@"Call"];
    
    return [rightUtilityButtons autorelease];
}

- (NSMutableArray *)rightButtonsAll {
    UIColor *deleteColor = [UIColor colorWithRed:1.0f green:0.231f blue:0.188 alpha:1.0f];
    
    NSMutableArray *rightUtilityButtons = [self rightButtonsCall];
    [rightUtilityButtons sw_addUtilityButtonWithColor:deleteColor title:@"Delete"];
    
    return rightUtilityButtons;
}

- (NSString *)phoneNumberForCellAtRow:(NSInteger)row {
    LinphoneChatRoom *chatRoom = (LinphoneChatRoom*)ms_list_nth_data(data, (int)row);
    if (!chatRoom) {
        return nil;
    }
    const LinphoneAddress *linphoneAddress = linphone_chat_room_get_peer_address(chatRoom);
    const char *username = linphone_address_get_username(linphoneAddress);
    NSString *dirtyAddress = [NSString stringWithUTF8String:username];
    NSString *address = [[LinphoneManager instance] removeUnneededPrefixes:dirtyAddress];
    return [[address retain] autorelease];
}

- (NSString *)displayNameForRow:(NSInteger)row {
    LinphoneChatRoom *chatRoom = (LinphoneChatRoom*)ms_list_nth_data(data, (int)row);
    const LinphoneAddress *linphoneAddress = linphone_chat_room_get_peer_address(chatRoom);

    char *tmp = linphone_address_as_string_uri_only(linphoneAddress);
    NSString *normalizedSipAddress = [NSString stringWithUTF8String:tmp];
    ms_free(tmp);
    
    NSString *displayName = nil;
    
    ABRecordRef contact = [[[LinphoneManager instance] fastAddressBook] getContact:normalizedSipAddress];
    if(contact != nil) {
        displayName = [FastAddressBook getContactDisplayName:contact];
    }
    if(displayName == nil) {
        displayName = [NSString stringWithUTF8String:linphone_address_get_username(linphoneAddress)];
    }
    return displayName;
}

- (BOOL)isRowWithOneCallCaspianSupport:(NSUInteger)row {
    //NSString *displayName = [self displayNameForRow:row];
    NSString *address = [self phoneNumberForCellAtRow:row];
    
    return [address isEqualToString:[FastAddressBook caspianSupportPhoneNumber]];// && [displayName isEqualToString:[ContactsTableViewController caspianDisplayName]];
}

@end
