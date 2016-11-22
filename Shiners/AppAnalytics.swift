//
//  AppAnalytics.swift
//  Shiners
//
//  Created by Yury Dorofeev on 11/21/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import Foundation
import FBSDKCoreKit

class AppAnalytics{
    class func logEvent(event: Event) {
        ThreadHelper.runOnBackgroundThread { 
            FBSDKAppEvents.logEvent(event.rawValue)
        }
        print("Logging event: \(event.rawValue)")
    }
    
    enum Event: String {
        case Main_NearbyPostsTab_Display, Main_MessagesTab_Display, Main_CreatePost_Display, Main_MyPostsTab_Display, Main_SettingsLoggedInTab_Display, Main_SettingsLoggedOutTab_Display
        case SettingsLoggedOutScreen_Register_Click, SettingsLoggedOutScreen_Login_Click
        case RegisterScreen_BtnCancel_Click, RegisterScreen_BtnRegister_Click
        case LoginScreen_BtnCancel_Click, LoginScreen_BtnLogin_Click, LoginScreen_BtnResetPassword_Click
        case ResetPasswordScreen_BtnBack_Click, ResetPasswordScreen_ResetPassword
        case NearbyPostsScreen_BtnNewPost_Click, NearbyPostsScreen_ListTabActive, NearbyPostsScreen_MapTabActive, NearbyPostsScreen_BtnSearch_Click, NearbyPostsScreen_List_PostSelected, NearbyPostsScreen_Map_PostSelected, NearbyPostsScreen_Search_Cancel, NearbyPostsScreen_List_GetMore
        case MessagesScreen_BtnEdit_Click, MessagesScreen_DialogSelected, MessagesScreen_BtnDelete_Clicked, MessagesScreen_SlideDelete_Clicked
        case MyPostsScreen_BtnNewPost_Click, MyPostsScreen_BtnEdit_Click, MyPostsScreen_PostSelected, MyPostsScreen_BtnDelete_Clicked, MyPostsScreen_SlideDelete_Clicked, MyPostsScreen_SlideHide_Clicked
        case SettingsLoggedInScreen_BtnEdit_Click, SettingsLoggedInScreen_ContactUs, SettingsLoggedInScreen_AboutUs, SettingsLoggedInScreen_Logout, SettingsLoggedInScreen_DoLogout, SettingsLoggedInScreen_CancelLogout, SettingsLoggedInScreen_Notify_Change
        case ProfileScreen_Call, ProfileScreen_Message, ProfileScreen_Msg_Send, ProfileScreen_Msg_Cancel
        case ContactUsScreen_BtnCancel_Click, ContactUsScreen_BtnSend_Click
        case EditProfileScreen_BtnCancel_Click, EditProfileScreen_BtnSave_Click, EditProfileScreen_ChangePhoto_Click
        case NewPostWizard_TitleStep_BtnCancel_Click, NewPostWizard_BtnNext_Click
        case NewPostWizard_Loc_BtnBack_Click, NewPostWizard_Loc_Dynamic_On, NewPostWizard_Loc_Dynamic_Off, NewPostWizard_Loc_Static_On, NewPostWizard_Loc_Static_Off, NewPostWizard_Loc_SearchFieldActive, NewPostWizard_Loc_Search_Cancel_Click, NewPostWizard_Loc_Search_ResSelected, NewPostWizard_Loc_BtnNext_Click
        case NewPostWizard_WhenStep_BtnBack_Click, NewPostWizard_WhenStep_Preset_Click, NewPostWizard_WhenStep_Spinner_Modified, NewPostWizard_WhenStep_BtnNext_Click
        case NewPostWizard_PhotoStep_BtnBack_Click, NewPostWizard_PhotoStep_BtnCreate_Click, NewPostWizard_PhotoStep_AddPhoto_Click, NewPostWizard_PhotoStep_Photo_Remove, NewPostWizard_PhotoStep_Photo_Retry, NewPostWizard_PhotoStep_Photo_LowerQual
        case PostDetailsScreen_BtnCall_Clicked, PostDetailsScreen_BtnMessage_Clicked, PostDetailsScreen_BtnShare_Clicked, PostDetailsScreen_FullScreenPhoto, PostDetailsScreen_FullScreenMap, PostDetailsScreen_UserProfile, PostDetailsScreen_Msg_BtnSend_Clicked, PostDetailsScreen_Msg_BtnCancel_Clicked
    }
}