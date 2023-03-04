/*
*	*	*	*	*	*	*	*	*	*	*	*	*	*	*	*	*	*	*	*	*	*	*	*	*	*	*	*	*	*	*	*	*	*	*	*	*	*	*	*	*
*					BNet Account Switcher																														*
*					Easily switch between accounts without having to input your password everytime																*
*																																								*
*					https://github.com/lemasato/BNet-Account-Switcher/																							*
*																																								*	
*	*	*	*	*	*	*	*	*	*	*	*	*	*	*	*	*	*	*	*	*	*	*	*	*	*	*	*	*	*	*	*	*	*	*	*	*	*	*	*	*
*/

#Warn LocalSameAsGlobal
OnExit("Exit_Func")
#SingleInstance, Force
#Persistent
#NoEnv
SetWorkingDir, %A_ScriptDir%
FileEncoding, UTF-8
#KeyHistory 0
SetWinDelay, 0
DetectHiddenWindows, Off
ListLines, Off

if ( !A_IsCompiled && FileExist(A_ScriptDir "\resources\icon.ico") )
	Menu, Tray, Icon,% A_ScriptDir "\resources\icon.ico"
Menu,Tray,Tip,BNet Account Switcher
Menu,Tray,NoStandard
Menu,Tray,Add,Reload,Reload_Func
Menu,Tray,Add,Close,Exit_Func
Menu,Tray,Icon

GroupAdd, ScriptPID,% "ahk_pid " DllCall("GetCurrentProcessId")

Start_Script()
Return

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#IfWinActive, ahk_group ScriptPID

Esc:: ; Close the script if its the active window
	ExitApp
Return

Space:: ; Close the SplashTextOn() window
	global SPACEBAR_WAIT

	if (SPACEBAR_WAIT) {
		SplashTextOff()
	}
Return

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

Start_Script() {
	global ProgramValues := {}
	global BNetSettings := {}
	global BNetSettingsRegEx := {}

	ProgramValues.Name 					:= "BNet Account Switcher"
	ProgramValues.Version 				:= "1.0"
	ProgramValues.Github_User 			:= "lemasato"
	ProgramValues.GitHub_Repo 			:= "BNet-Account-Switcher"

	ProgramValues.GitHub 				:= "https://github.com/" ProgramValues.Github_User "/" ProgramValues.GitHub_Repo
	ProgramValues.Reddit 				:= "https://www.reddit.com/user/lemasato/submitted/"
	ProgramValues.Paypal 				:= "https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=KUTP3PG7GY756"

	ProgramValues.Local_Folder 			:= A_MyDocuments "\AutoHotkey\" ProgramValues.Name
	ProgramValues.Resources_Folder 		:= ProgramValues.Local_Folder "\resources"
	ProgramValues.Game_Icons_Folder		:= ProgramValues.Resources_Folder "\games_icons"

	ProgramValues.BNet_Config_File 		:=	A_AppData "\Battle.net\Battle.net.config"
	ProgramValues.Ini_File 				:= ProgramValues.Local_Folder "\Preferences.ini"

	ProgramValues.Updater_File 			:= ProgramValues.Local_Folder "/BNet-AC-Updater.exe"
	ProgramValues.Temporary_Name		:= ProgramValues.Local_Folder "/BNet-AC-NewVersion.exe"
	ProgramValues.Updater_Link 			:= "https://raw.githubusercontent.com/" ProgramValues.Github_User "/" ProgramValues.GitHub_Repo "/master/Updater_v2.exe"

	ProgramValues.PID 					:= DllCall("GetCurrentProcessId")

	SetWorkingDir,% ProgramValues.Local_Folder
;	- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

	BNetSettingsRegEx.SavedAccountNames := """" "SavedAccountNames" """" ": " """" "(.*?)" """"
	BNetSettingsRegEx.Path 				:= """" "Path" """" ": " """" "(.*?)" """"
;	- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

;	Directories Creation
	localDirs := ProgramValues.Local_Folder
			. "`n" ProgramValues.Resources_Folder
			. "`n" ProgramValues.Game_Icons_Folder
	Loop, Parse, localDirs,% "`n"
	{
		if (!InStr(FileExist(A_LoopField), "D")) {
			FileCreateDir, % A_LoopField
		}
	}
;	- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

	FileDelete,% ProgramValues.Updater_File
;	Startup
	Tray_Refresh()
	Extract_Assets()
	Create_Local_File()
	UpdateCheck(0, 1)

;	Login GUI
	GUI_BNetLogin()

;	Exiting
	Tray_Refresh()
	; ExitApp
}

;==================================================================================================================
;											BNet Login GUI
;==================================================================================================================

GUI_BNetLogin() {
	static
	global ProgramValues
	global BNetLogin_Values := {} ; Values specific to the GUI
	global BNetLogin_Handles := {} ; Handles of some controls
	global BNetLogin_Tabs := {} ; Handles of tabs
	global BNetLogin_Games := {} ; Handles of game icons
	global BNetLogin_Styles := {}
	global BNetLogin_Submit := {}

	; Some GUI variables
	guiName := "BNetLogin"
	borderSize := 1, borderColor := "0x474747"
	guiWidth := 400, guiHeight := 230
	guiShowWidth := guiWidth+(borderSize*2), guiShowHeight := guiHeight+(borderSize*2)
	
	leftMost := borderSize, upMost := borderSize, rightMost := guiWidth-borderSize, downMost := guiHeight-borderSize

	; Get Local Settings
	bNetLauncherLocal := Get_Local_Config("SETTINGS", "Launcher")
	disableAutoStart := Get_Local_Config("SETTINGS", "Disable_AutoStart")

	; Get BNet Settings
	bNetLauncher := Parse_BNet_Config("Path"), BNetLogin_Values.Launcher := bNetLauncher
	accountsList := Parse_BNet_Config("SavedAccountNames")

	; Button styles
	Style_SystemButton := [ [0, "0xdddfdd", , "Black"] ; normal
						,  [0, "0x8fddfa"] ; hover
						,  [0, "0x44c6f6"] ] ; press

	Style_WhiteButton := [ [0, "White", , "Black"] ; normal
						,  [0, "0xdddfdd"] ; hover
						,  [0, "0x8fddfa"] ; press
						,  [0, "0x8fddfa", , "White"] ] ; default

	Style_GameButton := ; See below for Style. Used in a Loop, cant declare now.

	Style_Tab := [ [0, "0xEEEEEE", "", "Black", 0, , ""] ; normal
				,  [0, "0xdbdbdb", "", "Black", 0] ; hover
				,  [3, "0x44c6f6", "0x098ebe", "Black", 0]  ; press
				,  [3, "0x44c6f6", "0x098ebe", "White", 0 ] ] ; default

	BNetLogin_Styles.Style_SystemButton := Style_SystemButton

	/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	*/

	; Default GUI Settings
	Gui, BNetLogin:Destroy
	Gui, BNetLogin:+AlwaysOnTop -Border -SysMenu -Caption +hwndhGUIBNetLogin +LabelGUI_BNetLogin_
	Gui, BNetLogin:Margin, 0, 0
	Gui, BNetLogin:Default ; Neccessary for LV_ functions
	Gui, BNetLogin:Color, White
	Gui, BNetLogin:Font, S10 cBlack, Segoe UI

	; Creating tab control
	Gui, BNetLogin:Add, Tab2, x0 y0 w0 h0 hwndhTAB_Tab vTAB_Tab,Accounts|Games|Settings
	Gui, BNetLogin:Tab
	; Borders
	Gui, BNetLogin:Add, Progress,% "x0 y0 w" guiShowWidth " h" borderSize " Background" borderColor ; ^
	Gui, BNetLogin:Add, Progress,% "x" guiShowWidth-borderSize " y0 w" borderSize " h" guiShowHeight " Background" borderColor ; >
	Gui, BNetLogin:Add, Progress,% "x0 y" guiShowHeight-borderSize " w" guiShowWidth " h" borderSize " Background" borderColor ; v 
	Gui, BNetLogin:Add, Progress,% "x0 y0 w" borderSize " h" guiShowHeight " Background" borderColor ; <
	; Creating tabs button	
	TAB_WIDTH := (guiWidth/2)-20, TAB_HEIGHT := 30
	TAB_SMALL_WIDTH := (guiWidth-TAB_WIDTH*2), TAB_SMALL_HEIGHT := TAB_HEIGHT

	Gui, BNetLogin:Add, Button,% "x" leftMost " y" upMost " w" TAB_WIDTH " h" TAB_HEIGHT " hwndhBTN_TabAccount gGUI_BNetLogin_OnTabSelect",Accounts
	Gui, BNetLogin:Add, Button,% "x+0 yp wp hp hwndhBTN_TabGames gGUI_BNetLogin_OnTabSelect",Games
	Gui, BNetLogin:Add, Button,% "x+0 yp w" TAB_SMALL_WIDTH " h" TAB_SMALL_HEIGHT " hwndhBTN_TabSettings gGUI_BNetLogin_OnTabSelect",Opts

	BNetLogin_Tabs := {Handle:hTAB_Tab, Accounts:hBTN_TabAccount, Games:hBTN_TabGames, Settings:hBTN_TabSettings}

	ImageButton.Create(hBTN_TabAccount, Style_Tab*)
	ImageButton.Create(hBTN_TabGames, Style_Tab*)
	ImageButton.Create(hBTN_TabSettings, Style_Tab*)

	/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	*/ ; ACCOUNTS TABS
	Gui, BNetLogin:Tab, Accounts
		
	; Accounts List
	Gui, BNetLogin:Add, ListView,% "x" leftMost " yp+" TAB_HEIGHT+10 " w" guiWidth-(5-borderSize) " gGUI_BNetLogin_OnLvSelect -HDR -Multi -E0x200 AltSubmit +LV0x10000 hwndhLV_Accounts R7",Accounts
	LV_SetSelColors(hLV_Accounts, "0x8fddfa") ; Light blue ListView Select

	Sort, accountsList, D,
	Loop, Parse, accountsList,% "," ; Add each account to the ListView
	{
		if (A_LoopField) {
			LV_Add("", A_LoopField) ; Add entries to LV
		}
	}
	LV_ModifyCol(1, guiWidth-(5-borderSize))
	Loop % LV_GetCount()
		accountsInList++
	if (accountsInList > 7) { ; Make col smaller to hide horizontal scroll
		SysGet, VSBW, 2 ; Get vertical scroll size
		LV_ModifyCol(1, guiWidth-(VSBW+7)) ; VSWB+4 = no hor bar. I use 7 to make the highlighting centered
	}


	/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	*/ ; GAMES TAB
	Gui, BNetLogin:Tab, Games
	
	; [ None ]
	Gui, BNetLogin:Add, Button,% "x" leftMost " y" TAB_HEIGHT+10 " w" guiWidth " h30 hwndhBTN_None gGUI_BNetLogin_OnGameSelect",[ Do not run anything ]
	ImageButton.Create(hBTN_None, Style_WhiteButton*)
	BNetLogin_Games.None := hBTN_None

	; Games Icons
	gameIconW := 48, gameIconH := 48
	firstRowY := TAB_HEIGHT+10+30+10
	xpos := 0, ypos := firstRowY
	thisRow := 0
	gameIcons := []

		; Get game IDs
	allGameIDS := Get_Game_ID("all")
	gameNamesList := 
	for gameName, gameID in allGameIDS {
		gameNamesList .= "," gameName
	}
	StringTrimLeft, gameNamesList, gameNamesList, 1
	gameName := gameID :=

		; Loop through the icon files
	gameIconsNum := 0
	Loop, Files,% ProgramValues.Game_Icons_Folder "\*.png"
	{
		SplitPath, A_LoopFileName, , , , fileNameNoExt
		if fileNameNoExt in %gameNamesList%
		{
			gameIconsNum++
			remainingIcons := gameIconsNum
			gameIcons.Push(A_LoopFileFullPath)
		}
	}
	fileNameNoExt :=

		; Calculate the space between each
	spaceBetweenIcons := (guiWidth/gameIconsNum)
	gameIconsPerRow := gameIconsNum
	maxGameIconsPerRow := 5

	While (gameIconsPerRow > maxGameIconsPerRow) { ; So that icons do not overlap
		gameIconsPerRow := (gameIconsPerRow)?(gameIconsPerRow-1):(gameIconsNum-1)
		spaceBetweenIcons := (guiWidth/gameIconsPerRow)
	}
	firstIconX := (guiWidth-(spaceBetweenIcons*(gameIconsPerRow-1)+gameIconW))/2 ; We retrieve the blank space after the lastest icon in the row
																				 ;	then divide this space in two so icons are centered
		; Create the game icon buttons
	Loop % gameIcons.MaxIndex() {
		this_gameIcon := gameIcons[A_Index]

		Style_GameButton := [[0, this_gameIcon, , , , "White"] ; normal
			,[0, this_gameIcon, , , ,"0xdddfdd"] ; hover
			,[0, this_gameIcon, , , ,"0x8fddfa"] ; press
			,[0, this_gameIcon, , , ,"0x8fddfa"]] ; default

		thisRow++
		if (thisRow > gameIconsPerRow) { ; Draw a new row
			thisRow := 1, ypos += 55
			divider := (remainingIcons <= gameIconsPerRow)?(remainingIcons):(gameIconsPerRow) ; Caculate the divider, so we can center the new row
			firstIconX := (guiWidth-(spaceBetweenIcons*(divider-1)+gameIconW))/2 ; Same thing as the firstIconX above
		}
		xpos := (thisRow=1)?(firstIconX)
			   :(xpos+spaceBetweenIcons)
		ypos := (!ypos)?(firstRowY):(ypos)

		Gui, BNetLogin:Add, Button, x%xpos% y%ypos% w%gameIconW% h%gameIconH% hwndhBTN_Games%A_Index% gGUI_BNetLogin_OnGameSelect
		SplitPath, this_gameIcon, , , , fileNameNoExt
		fileNameNoUnderspace := StrReplace(fileNameNoExt, "_", " ")
		AddToolTip(hBTN_Games%A_Index%, fileNameNoUnderspace)
		ImageButton.Create(hBTN_Games%A_Index%, Style_GameButton*)

		BNetLogin_Games[fileNameNoExt] := hBTN_Games%A_Index%

		remainingIcons--
	}

	/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	*/ ; SETTINGS TAB
	Gui, BNetLogin:Tab, Settings

	Gui, BNetLogin:Add, Text,% "x" leftMost+5 " y" TAB_HEIGHT+10,Blizzard App: 
	Gui, BNetLogin:Add, Edit, x+5 yp-2 w265 vEDIT_BNetLauncher hwndhEDIT_BNetLauncher R1,% bNetLauncher
	Gui, BNetLogin:Add, Button, x+5 w35 h25 hwndhBTN_BrowseApp gGUI_BNetLogin_BrowseLauncher, O

	Gui, BNetLogin:Add, Checkbox,% "x" leftMost+5 " y+15 vCB_DisableAutoStart hwndhCB_DisableAutoStart Checked" disableAutoStart " gGUI_BNetLogin_OnCBToggle",Disable automatic start
	Gui, BNetLogin:Add, Text,% "x" leftMost+5 " y" guiHeight-40 " hwndhTEXT_Version",% "v" ProgramValues.Version
	Gui, BNetLogin:Add, Link,% "x" leftMost+5 " y" guiHeight-20 " hwndhLINK_GitHub gGitHub_Link",% "<a href="""">GitHub</a>"
	Gui, BNetLogin:Add, Text,% "x+5 yp hwndhTEXT_Separator1",-
	Gui, BNetLogin:Add, Link,% "x+5 yp hwndhLINK_Reddit gReddit_Link",% "<a href="""">Reddit</a>"
	moveEm := [hLINK_GitHub, hTEXT_Separator1, hLINK_Reddit]
	Loop % moveEm.MaxIndex() {
		coords := Get_Control_Coords("BNetLogin", moveEm[A_Index])
		GuiControl, BNetLogin:Move,% moveEm[A_Index],% "y" guiHeight-(coords.H+borderSize)
	}
	GuiControl, BNetLogin:Move,% hTEXT_Version,% "y" guiHeight-((coords.H*2)+borderSize)
	; Gui, BNetLogin:Add, Button,% "x" leftMost " y" guiHeight-29 " w" rightMost " h30 hwndhBTN_CheckUpdate gGUI_BNetLogin_OnUpdateCheck",Check for updates
	Gui, BNetLogin:Add, Picture,% "x" leftMost " y" guiHeight-50 " hwndhBTN_Donate gPaypal_Link",% ProgramValues.Resources_Folder "\Donate_PayPal.png"
	coords := Get_Control_Coords("BNetLogin", hBTN_Donate)
	GuiControl, BNetLogin:Move,% hBTN_Donate,% "x" guiWidth-(coords.W+borderSize) " y" guiHeight-(coords.H-borderSize)

	AddToolTip(hCB_DisableAutoStart, "Do not run the Blizzard App once an account and game have been chosen.")

	BNetLogin_Handles.EDIT_BNetLauncher := hEDIT_BNetLauncher
	BNetLogin_Handles.CB_DisableAutoStart := hCB_DisableAutoStart
	BNetLogin_Handles.hBTN_BrowseApp := hBTN_BrowseApp
	BNetLogin_Handles.Check_Update := hBTN_CheckUpdate
	BNetLogin_Handles.Check_Update2 := hBTN_CheckUpdate2
	
	ImageButton.Create(hBTN_BrowseApp, Style_SystemButton*)
	ImageButton.Create(hBTN_ManageAccounts, Style_SystemButton*)
	ImageButton.Create(hBTN_WhyGameMissing, Style_SystemButton*)
	ImageButton.Create(hBTN_CheckUpdate, Style_SystemButton*)

	/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	*/ ; ALL TABS
	Gui, BNetLogin:Tab

	Gui, BNetLogin:Add, Button,% "x" leftMost " y" guiHeight-29 " w" guiWidth " h" 30 " hwndhBTN_Login gGUI_BNetLogin_Login",Login
	ImageButton.Create(hBTN_Login, Style_SystemButton*)
	BNetLogin_Handles.BTN_Login := hBTN_Login


	GUI_BNetLogin_OnTabSelect(hBTN_TabAccount)
	; GUI_BNetLogin_OnTabSelect(hBTN_TabGames)
	; GUI_BNetLogin_OnTabSelect(hBTN_TabSettings)
	Gui, BNetLogin:Show, w%guiShowWidth% h%guiShowHeight%,% ProgramValues.Name
	WinWait ahk_id %hGUIBNetLogin%
	; WinWaitClose ahk_id %hGUIBNetLogin%
	Return

	GUI_BNetLogin_OnCBToggle:
		GUI_BNetLogin_SaveSettings()		
	Return

	GUI_BNetLogin_Login:
		GUI_BNetLogin_Login_Func()
	Return
	Return
}

GUI_BNetLogin_Close() {
	Gui, BNetLogin:Destroy
	ExitApp
}

GUI_BNetLogin_OnUpdateCheck(CtrlHwnd) {
	global BNetLogin_Handles, BNetLogin_Styles, ProgramValues

	gitUser := ProgramValues.Github_User
	gitRepo := ProgramValues.GitHub_Repo
	localVer := ProgramValues.Version

	GuiControl, %A_Gui%:,% CtrlHwnd,% "Checking for updates..."
	ImageButton.Create(CtrlHwnd, BNetLogin_Styles.Style_SystemButton*)

	ret := UpdateCheck()
	onlineVer := ret.Version
	onlineDownload := ret.Download

	if onlineVer contains Not,Found,Error
		apiError := true

	if (onlineVer = localVer) && !(apiError) {
		GuiControl, %A_Gui%:,% CtrlHwnd,% "No update available!"
		ImageButton.Create(CtrlHwnd, BNetLogin_Styles.Style_SystemButton*)
		SetTimer, GUI_BNetLogin_OnUpdateCheck_Restore, -5000
	}
	else if (onlineVer != localVer) && (onlineVer) && (!apiError) {
		GuiControl, %A_Gui%:,% CtrlHwnd,% "Update found! v" onlineVer
		ImageButton.Create(CtrlHwnd, BNetLogin_Styles.Style_SystemButton*)
		GoSub, %A_ThisFunc%_Update_Detected
	}
	else {
		GuiControl, %A_Gui%:,% CtrlHwnd,% "An error occured!"
		ImageButton.Create(CtrlHwnd, BNetLogin_Styles.Style_SystemButton*)
	}
	Return

	GUI_BNetLogin_OnUpdateCheck_Update_Detected:
		ShowUpdatePrompt(onlineDownload, onlineVer)
	Return

	GUI_BNetLogin_OnUpdateCheck_Restore:
		GuiControl, %A_Gui%:,% CtrlHwnd,% "Check for updates"
		ImageButton.Create(CtrlHwnd, BNetLogin_Styles.Style_SystemButton*)
	Return
}

GUI_BNetLogin_AddAccount() {
	global ProgramValues, LV_RightClick
	LV_RightClick := false
	
	Gui, BNetLogin:+OwnDialogs
	InputBox, email, Adding an account,Remember to tick the "Keep me logged in" case if you want to log in automatically without inputting your password.`n`nInput the new account's email:, , 400, 180
	if (!ErrorLevel && Is_Email(email)) {
		accNames := Parse_BNet_Config("SavedAccountNames")
		if email in %accNames%
		{
			MsgBox,4096,% ProgramValues.Name,%email% is already in the list!
			GUI_BNetLogin_AddAccount()
			Return
		}
		Set_BNet_Config("SavedAccountNames", accNames "," email)

		GUI_BNetLogin_SaveSettings()
		GUI_BNetLogin()
	}
	else if (!ErrorLevel && !Is_Email(email)) {
		MsgBox,4096,% ProgramValues.Name,%email% is not a valid email address.
		GUI_BNetLogin_AddAccount()
	}
}

GUI_BNetLogin_RemoveAccount() {
	global BNetLogin_Values, ProgramValues, LV_RightClick
	LV_RightClick := false

	user := BNetLogin_Values.User
	if !Is_Email(user) {
		MsgBox,4096,% ProgramValues.Name,%email% is not a valid email address.
		Return
	}


	Gui, BNetLogin:+OwnDialogs
	guiName := "BNetRemoveAcc"

	emails := Parse_BNet_Config("SavedAccountNames")

	Gui, BNetLogin:Hide
	MsgBox, % 4099, Removing an account,% "You are about to remove: " user "."
.			"`nWould you like to remove the cookie linked to this account aswell?"
.			"`n`nBy choosing ""No"", you can simply add the account back later on and you will still be able to log in without inputting your password (unless the cookie expires)."
.			"`n`nBy choosing ""Yes"", we will log you on the account then ask you to choose ""Disconnect"" from within Blizzard App (this will delete the cookie)."
	IfMsgBox, Yes
	{
		SplashTextOn("Instructions - Removing an account","We are now logging you on the account."
		.												 "`nOnce the Blizzard App has started, click on the Blizzard logo on the top left and choose ""Disconnect""."
		.												 "`nThe tool will resume once you completely close the Blizzard App.")
		WinWait,% "Instructions - Removing an account ahk_pid " DllCall("GetCurrentProcessId")
		WinSet, Transparent, 200,% "Instructions - Removing an account ahk_pid " DllCall("GetCurrentProcessId")
		GUI_BNetLogin_Login_Func(user, "")
		Process, Wait, Battle.net.exe
		Process, WaitClose, Battle.net.exe
		SplashTextOff()
		GoSub GUI_BNetLogin_RemoveAccount_EditConfig
		GUI_BNetLogin_SaveSettings()
		GUI_BNetLogin()
	}
	IfMsgBox, No
	{
		GoSub GUI_BNetLogin_RemoveAccount_EditConfig
		GUI_BNetLogin_SaveSettings()
		GUI_BNetLogin()
	}
	IfMsgBox, Cancel
	{
		Gui, BNetLogin:Show
	}
	Return

	GUI_BNetLogin_RemoveAccount_EditConfig:
		Loop, Parse, emails,% "D,"
		{
			if (A_LoopField != user)
				newEmails .= A_LoopField ","
		}
		lastChar := SubStr(newEmails, 0) ; Get last char
		if (lastChar = ",")
			StringTrimRight, newEmails, newEmails, 1

		Set_BNet_Config("SavedAccountNames", newEmails)

	Return

}

GUI_BNetLogin_BrowseLauncher() {
	global BNetLogin_Handles

	Gui, BNetLogin:+OwnDialogs

	FileSelectFile, selectedFile, 1, F:\Jeux\Battle.net_, Browse to your Battle.net Launcher.exe,% "(Battle.net Launcher.exe; Battle.net*Launcher.exe)"
	if (!selectedFile)
		Return

	GuiControl, BNetLogin:,% BNetLogin_Handles.EDIT_BNetLauncher,% selectedFile
}

GUI_BNetLogin_Submit() {
	global BNetLogin_Submit := {}
	global BNetLogin_Handles

	Sleep 10
	for ctrlName, handle in BNetLogin_Handles
	{
		GuiControlGet, content, BNetLogin:,% handle
		BNetLogin_Submit[ctrlName] := content
	}
	Sleep 10
}

GUI_BNetLogin_SaveSettings() {
	global BNetLogin_Submit, ProgramValues, BNetLogin_Values

	iniFile := ProgramValues.Ini_File

	GUI_BNetLogin_Submit()
	
	Set_Local_Config("SETTINGS", "Launcher", """" BNetLogin_Submit.EDIT_BNetLauncher """")
	Set_Local_Config("SETTINGS", "Disable_AutoStart", BNetLogin_Submit.CB_DisableAutoStart)

	bNetLauncher := Parse_BNet_Config("Path")
	if (bNetLauncher != BNetLogin_Submit.EDIT_BNetLauncher) && FileExist(BNetLogin_Submit.EDIT_BNetLauncher) {
		BNetLogin_Values.Launcher := BNetLogin_Submit.EDIT_BNetLauncher
		Set_BNet_Config("Path", BNetLogin_Submit.EDIT_BNetLauncher)
	}
}

GUI_BNetLogin_Login_Func(_user="NULL", _game="NULL") {
	global BNetLogin_Values, BNetLogin_Tabs

	Gui, BNetLogin:Hide

	GUI_BNetLogin_SaveSettings()

	user := (_user != "NULL")?(_user):(BNetLogin_Values.User)
	launcher := BNetLogin_Values.Launcher
	game := (_game != "NULL")?(_game):(BNetLogin_Values.Game)

	gameID := Get_Game_ID(game)

	Gui, BNetLogin:Submit, NoHide
	Gui, BNetLogin:+OwnDialogs

	if !FileExist(launcher) {
		SoundPlay, *16
		ToolTip, The launcher could not be found!
		SetTimer, RemoveToolTip, -2500
		GUI_BNetLogin_OnTabSelect(BNetLogin_Tabs.Settings)
		Return
	}
	if !(user) {
		SoundPlay, *16
		ToolTip, No account selected!
		SetTimer, RemoveToolTip, -2500
		GUI_BNetLogin_OnTabSelect(BNetLogin_Tabs.Accounts)
		Return
	}

	BNet_Close() ; Process needs to be closed prior to editing the file, as bNet updates the file upon closing.
	Set_BNet_Login(user)
	BNet_Run(game)

	GUI_BNetLogin_Close()
}

GUI_BNetLogin_OnGameSelect(CtrlHwnd) {
	global BNetLogin_Games, BNetLogin_Values
	static isFirstTime := True

	disableAutoStart := Get_Local_Config("SETTINGS", "Disable_AutoStart")
	disableAutoStart := (disableAutoStart="ERROR")?(0):(disableAutoStart)

	for gameName, handle in BNetLogin_Games {
		if (CtrlHwnd = handle) {
			BNetLogin_Values.Game := gameName
			GuiControl, BNetLogin:+Disabled,% handle
			
			if (isFirstTime && !disableAutoStart) {
				isFirstTime := False
				GUI_BNetLogin_Login_Func()
			}
		}
		else {
			GuiControl, BNetLogin:-Disabled,% handle
		}
	}
}

GUI_BNetLogin_OnLvSelect(CtrlHwnd, GuiEvent, EventInfo) {
	global BNetLogin_Tabs, BNetLogin_Values, ProgramValues, LV_RightClick
	static isFirstTime := True
	static accountName

	disableAutoStart := Get_Local_Config("SETTINGS", "Disable_AutoStart")
	disableAutoStart := (disableAutoStart="ERROR")?(0):(disableAutoStart)

	Gui, %A_Gui%:+OwnDialogs
	isFirstTime := True ; Always move to the next tab

	if GuiEvent in Normal,D,I,K
	{
		GoSub %A_ThisFunc%_Get_Selected

		if (isFirstTime && isEmail && !disableAutoStart) { ; Switch to "Games" tab.
			isFirstTime := False
			SetTimer, %A_ThisFunc%_Select_GamesTab, -200
		}		
	}
	if (GuiEvent = "RightClick") {
		LV_RightClick := true
		GoSub %A_ThisFunc%_Get_Selected

		try Menu, RClickMenu, DeleteAll
		Menu, RClickMenu, Add, Add a new account, GUI_BNetLogin_AddAccount
		Menu, RClickMenu, Add, Remove selected account, GUI_BNetLogin_RemoveAccount
		Menu, RClickMenu, Show
	}
	Return

	GUI_BNetLogin_OnLvSelect_Select_GamesTab:
		GUI_BNetLogin_OnTabSelect(BNetLogin_Tabs["Games"])
	Return

	GUI_BNetLogin_OnLvSelect_Get_Selected:
	; LV_GetText(string, A_EventInfo) is unreliable. A_EventInfo will sometimes not contain the correct row ID.
	; LV_GetNext() seems to be the best alternative. Though, it rises an issue when no row is selected.
	;	Instead of retrieving a blank value, it will retrieve the same value as the previously selected row ID.
	;	As workaround, when the user does not select any row, we re-highlight the previously selected one.
		rowID := LV_GetNext(0, "F")
		if (EventInfo = 0 && !isFirstTime) {
			LV_Modify(rowID, "+Select")
		}
		LV_GetText(accountName, rowID)

		isEmail := Is_Email(accountName)
		if (!isEmail) {
			LV_Modify(rowID, "-Select")
			BNetLogin_Values.User := 
			accountName := 
			Return
		}
		LV_Modify(rowID, "+Select")

		BNetLogin_Values.User := accountName
	Return

}

GUI_BNetLogin_OnTabSelect(CtrlHwnd) {
	global BNetLogin_Tabs, BNetLogin_Handles, LV_RightClick

	if (LV_RightClick) {
		LV_RightClick := false
		Return
	}

	for tabName, handle in BNetLogin_Tabs {
		if (CtrlHwnd = handle) {
			GuiControl, BNetLogin:+Disabled,% handle
			GuiControl, BNetLogin:ChooseString,% BNetLogin_Tabs["Handle"],% "|" tabName

			if (tabName = "Settings")
				GuiControl, BNetLogin:Hide,% BNetLogin_Handles["BTN_Login"]
			else
				GuiControl, BNetLogin:Show,% BNetLogin_Handles["BTN_Login"]
		}
		else {
			GuiControl, BNetLogin:-Disabled,% handle
		}
	}
}

;==================================================================================================================
;											BNet App
;==================================================================================================================

BNet_Close() {
	Process, Close, Battle.net.exe
	Process, WaitClose, Battle.net.exe
}

Get_Game_ID(which) {
;	Game IDs used by the battlenet:// parameter
;	HotS can use both "Hero" and "heroes"
	allGameIDS := {	Destiny_2:"DST2"
					,Diablo_3:"D3"
					,Hearthstone:"WTCG"
					,Heroes_of_the_Storm:"Hero"
					,Overwatch:"Pro"
					,StarCraft_2:"starcraft"
					,StarCraft_Remastered:"SCR"
					,World_of_Warcraft:"WoW"}

	if (which = "all")
		return allGameIDS
  
	which := StrReplace(which, A_Space, "_")
	gameID := allGameIDS[which]
	Return gameID
}

BNet_Run(game="") {
	bNetLauncher := Parse_BNet_Config("Path")
	game := StrReplace(game, A_Space, "_")

	game := (game && game != "None")?(game):("")

	if (game) {
		gameID := Get_Game_ID(game)
	}

	SplitPath, bnetLauncher, , bnetFolder
	Run,% bnetLauncher,% bnetFolder

;	Wait until launcher is loaded, to use GameID parameter
	if (gameID) {
		DetectHiddenWin := A_DetectHiddenWindows
		DetectHiddenWindows, Off
		WinWait, ahk_exe Battle.net.exe
		DetectHiddenWindows, %DetectHiddenWin%

		Run,% bNetLauncher " battlenet://" gameID
	}
	else if (game && !gameID) {
		MsgBox, ,% A_ScriptName,% "Unknown value for """ game """, please report this issue."
	}
}

Get_BNet_Config() {
	global ProgramValues, BNetSettings
	static bNetConfigFile

	bNetConfigFile:= ProgramValues.BNet_Config_File

	fileObj := FileOpen(bNetConfigFile, "r", UTF-8-RAW)
	fileContent := fileObj.Read()
	fileObj.Close()

	return fileContent
}

Parse_BNet_Config(mode="") {
	global BNetSettings, BNetSettingsRegEx

	bNetFileContent := Get_BNet_Config()

	parsedJSON := JSON.Load(bNetFileContent)
	if (mode="SavedAccountNames") {
		return parsedJSON.Client.SavedAccountNames
	}
	else if (mode = "Path") {
		for sectName, key in parsedJSON {
			strLenght := StrLen(sectName)
			if (strLenght = 16) { ; Those random numbers/letters sections always have 16 chars
				subKey := parsedJSON[sectName]
				bNetPath := subKey.Path "\Battle.net Launcher.exe"
				if FileExist(bNetPath)
					Return bNetPath
			}
		}
	}
}

Set_BNet_Config(key, value) {
	global BNetSettings, BNetSettingsRegEx, ProgramValues

	static regExSavedAccounts, regExPath
	static bNetFileContent, bNetFile
	regExSavedAccounts := BNetSettingsRegEx.SavedAccountNames
	regExPath := BNetSettingsRegEx.Path
	bNetFileContent := Get_BNet_Config()
	bNetFile := ProgramValues.BNet_Config_File

	if (key="SavedAccountNames") {
		strNewSavedAccounts := StrReplace(regExSavedAccounts, "(.*?)", value)

		fileObj := FileOpen(bNetFile, "w", UTF-8-RAW) ; Overwrite existing file, make it empty.
		newStr := RegExReplace(bNetFileContent, regExSavedAccounts, strNewSavedAccounts) ; Set account order

		fileObj.Write(newStr)
		fileObj.Close()
	}
	else if (key="Path") {
		SplitPath, value, , OutDir, OutExtension
		if (OutExtension = "exe")
			value := OutDir ; Only get the directory
		if !InStr(value, "\\") {
			value := StrReplace(value, "\", "\\") ; Add double backslash, it's a JSON.
		}

		strNewPath := StrReplace(regExPath, "(.*?)", value)
		fileObj := FileOpen(bNetFile, "w", UTF-8-RAW) ; Overwrite existing file, make it empty.
		newStr := RegExReplace(bNetFileContent, regExPath, strNewPath)

		fileObj.Write(newStr)
		fileObj.Close()
	}
}

Set_BNet_Login(email) {
	accountsList := Parse_BNet_Config("SavedAccountNames")
	newAccountsList := email
	Loop, Parse, accountsList,% "," ; Sorts the accounts list. Set the selected account email as the first item. 
	{
		if (A_LoopField != email)
			newAccountsList .= "," A_LoopField
	}

	Set_BNet_Config("SavedAccountNames", newAccountsList)
}

;==================================================================================================================
;											Local config files
;==================================================================================================================

Create_Local_File() {
	global ProgramValues

	sect := "PROGRAM"
	keysAndValues := {	Last_Update_Check:"1994042612310000"
						,FileName:A_ScriptName
						,PID:ProgramValues.PID}

	for iniKey, iniValue in keysAndValues {
		currentValue := Get_Local_Config(sect, iniKey)

		if (iniKey = "Last_Update_Check") { ; Make sure value is time format
			EnvAdd, currentValue, 1, Seconds
			if !(currentValue) || (currentValue = 1)
				currentValue := "ERROR"
		}
		if iniKey in FileName,PID ; These values are instance specific
		{
			currentValue := "ERROR"
		}
		if (currentValue = "ERROR") {
			Set_Local_Config(sect, iniKey, iniValue)
		}
	}

	sect := "SETTINGS"
	keysAndValues := { 	Auto_Update:1
						,Launcher:""""""
						,Disable_AutoStart:"0"}

	for iniKey, iniValue in keysAndValues {
		currentValue := Get_Local_Config(sect, iniKey)
		if (currentValue = "ERROR") {
			Set_Local_Config(sect, iniKey, iniValue)
		}
	}
}

Extract_Assets() {
	global ProgramValues
	static 0 ; Bypass warning "local same as global" for var 0

	if (A_IsCompiled) {
		#Include, *i File_Install.ahk
		Return
	}

;	File location
	installFile := A_ScriptDir "\File_Install.ahk"
	FileDelete,% installFile

;	File_Install.ahk
	appendToFile := "#SingleInstance Force`n"
				 .	"#NoTrayIcon`n`n"

;	Pass ProgramValues to file
	appendToFile .= "tempParams := {}`n"
				 .	"Loop, %0% {`n"
				 .	"	param := `%A_Index`%`n"
				 . 	"	if RegExMatch(param, ""/Resources_Folder=(.*)"", found) {`n"
				 . 	"		tempParams.Resources_Folder := found1`n"
				 . 	"	}`n"
				 . 	"	if RegExMatch(param, ""/Game_Icons_Folder=(.*)"", found) {`n"
				 . 	"		tempParams.Game_Icons_Folder := found1`n"
				 . 	"	}`n"
				 .	"	ProgramValues := tempParams`n"
				 . 	"}`n"

;	\resources\
	resFolder := A_ScriptDir "\resources"
	allowedExt := "png,ico"
	appendToFile .= "`n; \resources\`n"

	appendToFile .= "if !( InStr(FileExist(ProgramValues.Resources_Folder), ""D"") )`n"
				  . "	FileCreateDir,`% ProgramValues.Resources_Folder `n"

	Loop, Files,% resFolder "\*"
	{
		RegExMatch(A_LoopFileFullPath, "\\resources\\(.*)", path)
		filePath := "resources\" path1

		if A_LoopFileExt in %allowedExt%
			appendToFile .= "FileInstall, " filePath ",`% ProgramValues.Resources_Folder """ "\" A_LoopFileName """" ", 1`n"
	} 

;	\resources\games_icons\
	resFolder := A_ScriptDir "\resources\games_icons"
	allowedExt := "png"
	appendToFile .= "`n; \resources\games_icons\`n"

	appendToFile .= "if !( InStr(FileExist(ProgramValues.Game_Icons_Folder), ""D"") )`n"
				  . "	FileCreateDir,`% ProgramValues.Game_Icons_Folder `n"

	Loop, Files,% resFolder "\*"
	{
		RegExMatch(A_LoopFileFullPath, "\\resources\\(.*)", path)
		filePath := "resources\" path1

		if A_LoopFileExt in %allowedExt%
			appendToFile .= "FileInstall, " filePath ",`% ProgramValues.Game_Icons_Folder """ "\" A_LoopFileName """" ", 1`n"
	} 

;	ADD TO FILE
	FileAppend,% appendToFile "`n",% installFile
	Sleep 10
	RunWait,% installFile
		   . " /Resources_Folder=" 	"""" ProgramValues.Resources_Folder """"
		   . " /Game_Icons_Folder=" 	"""" ProgramValues.Game_Icons_Folder """"
}

;==================================================================================================================
;											Local config files
;==================================================================================================================

Set_Local_Config(sect, key, val) {
	global ProgramValues

	IniWrite,% val,% ProgramValues.Ini_File,% sect,% key
}

Get_Local_Config(sect, key) {
	global ProgramValues

	IniRead, val,% ProgramValues.Ini_File,% sect,% key
	if (val && val != "ERROR") || (val = 0)
		Return val
	else Return "ERROR"
}

;==================================================================================================================
;											Splash text
;==================================================================================================================

SplashTextOn(title, msg, waitForClose=false, useSpaceToClose=false) {
	global SPACEBAR_WAIT

	if (useSpaceToClose) {
		SPACEBAR_WAIT := true
		msg .= "`n`nPress [ Space ] to close this window."
	}
	else {
		SPACEBAR_WAIT := false
	}

	Gui, Splash:Destroy
	Gui, Splash:+AlwaysOnTop -SysMenu +hwndhGUISplash
	Gui, Splash:Margin, 0, 0
	Gui, Splash:Font, S10 cBlack, Segoe UI

	Gui, Splash:Add, Text, Center hwndhMSG,% msg
	coords := Get_Control_Coords("Splash", hMSG)
	w := coords.W, h := coords.H
	GuiControl, Splash:Move,% hMSG,% "x5 w" coords.W " h" coords.H

	Gui, Splash:Show,% "w" coords.W+10 " h" coords.H+5,% title
	WinWait, ahk_id %hGUISplash%
	if (waitForClose)
		WinWaitClose, ahk_id %hGUISplash%
}

SplashTextOff() {
	global SPACEBAR_WAIT
	SPACEBAR_WAIT := false

	Gui, Splash:Destroy
}

;==================================================================================================================
;											Update funcs
;==================================================================================================================

UpdateCheck(force=false, prompt=false) {
	global ProgramValues, SPACEBAR_WAIT

	autoupdate := Get_Local_Config("SETTINGS", "Auto_Update")
	lastUpdateCheck := Get_Local_Config("PROGRAM", "Last_Update_Check")
	if (force) ; Fake the last update check, so it's higher than 35mins
		lastUpdateCheck := 1994042612310000

	timeDif := A_Now
	timeDif -= lastUpdateCheck, Minutes

	if !(timeDif > 35) ; Hasn't been longer than 35mins since last check, cancel to avoid spamming GitHub API
		Return

	if FileExist(ProgramValues.Updater_File)
		FileDelete,% ProgramValues.Updater_File

	Set_Local_Config("PROGRAM", "Last_Update_Check", A_Now)

	releaseInfos := GetLatestRelease_Infos(ProgramValues.Github_User, ProgramValues.Github_Repo)
	onlineVer := releaseInfos.name
	onlineDownload := releaseInfos.assets.1.browser_download_url

	if (prompt) {
		if (!onlineVer || !onlineDownload) {
			SplashTextOn(ProgramValues.Name " - Updating Error", "There was an issue when retrieving the latest release from GitHub API"
			.											"`nIf this keeps on happening, please try updating manually."
			.											"`nYou can find the GitHub repository link in the ""Opts"" tab.", 1, 1)
		}
		else if (onlineVer && onlineDownload) && (onlineVer != ProgramValues.Version) {
			if (autoupdate) {
				FileDownload(ProgramValues.Updater_Link, ProgramValues.Updater_File)
				Run_Updater(onlineDownload)
			}
			Else
				ShowUpdatePrompt(onlineVer, onlineDownload)
			Return
		}
	}

	Return {Version:onlineVer, Download:onlineDownload}
}

ShowUpdatePrompt(ver, dl) {
	global ProgramValues

	MsgBox, 4100, Update detected (v%ver%),% "Current version:" A_Tab ProgramValues.Version
	.										 "`nOnline version: " A_Tab ver
	.										 "`n"
	.										 "`nWould you like to update now?"
	.										 "`nThe entire updating process is automated."
	IfMsgBox, Yes
	{
		success := FileDownload(ProgramValues.Updater_Link, ProgramValues.Updater_File)
		if (success)
			Run_Updater(dl)
	}
}

;==================================================================================================================
;											Misc Stuff
;==================================================================================================================

GitHub_Link:
Run,% ProgramValues.GitHub
Return
Reddit_Link:
Run,% ProgramValues.Reddit
Return
Blizzard_Link:
Run,% ProgramValues.Blizzard
Return
Paypal_Link:
Run,% ProgramValues.Paypal
Return

Tray_Refresh() {
;			Refreshes the Tray Icons, to remove any "leftovers"
;			Should work both for Windows 7 and 10
	WM_MOUSEMOVE := 0x200
	HiddenWindows := A_DetectHiddenWindows
	DetectHiddenWindows, On
	TrayTitle := "AHK_class Shell_TrayWnd"
	ControlNN := "ToolbarWindow322"
	IcSz := 24
	Loop, 8
	{
		index := A_Index
		if ( index = 1 || index = 3 || index = 5 || index = 7 ) {
			IcSz := 24
		}
		else if ( index = 2 || index = 4 || index = 6 || index = 8 ) {
			IcSz := 32
		}
		if ( index = 1 || index = 2 ) {
			TrayTitle := "AHK_class Shell_TrayWnd"
			ControlNN := "ToolbarWindow322"
		}
		else if ( index = 3 || index = 4 ) {
			TrayTitle := "AHK_class NotifyIconOverflowWindow"
			ControlNN := "ToolbarWindow321"
		}
		if ( index = 5 || index = 6 ) {
			TrayTitle := "AHK_class Shell_TrayWnd"
			ControlNN := "ToolbarWindow321"
		}
		else if ( index = 7 || index = 8 ) {
			TrayTitle := "AHK_class NotifyIconOverflowWindow"
			ControlNN := "ToolbarWindow322"
		}
		ControlGetPos, xTray,yTray,wdTray,htTray, %ControlNN%, %TrayTitle%
		y := htTray - 10
		While (y > 0)
		{
			x := wdTray - IcSz/2
			While (x > 0)
			{
				point := (y << 16) + x
				PostMessage, %WM_MOUSEMOVE%, 0, %point%, %ControlNN%, %TrayTitle%
				x -= IcSz/2
			}
			y -= IcSz/2
		}
	}
	DetectHiddenWindows, %HiddenWindows%
	Return
}

Run_Updater(downloadLink) {
	global ProgramValues

	updaterLink 		:= ProgramValues.Updater_Link

	Set_Local_Config("PROGRAM", "LastUpdate", A_Now)
	Run,% ProgramValues.Updater_File 
	. " /Name=""" ProgramValues.Name  """"
	. " /File_Name=""" A_ScriptDir "\" ProgramValues.Name ".exe" """"
	. " /Local_Folder=""" ProgramValues.Local_Folder """"
	. " /Ini_File=""" ProgramValues.Ini_File """"
	. " /NewVersion_Link=""" downloadLink """"
	ExitApp
}

Get_Control_Coords(guiName, ctrlHandler) {
/*		Retrieve a control's position and return them in an array.
		The reason of this function is because the variable content would be blank
			unless its sub-variables (coordsX, coordsY, ...) were set to global.
			(Weird AHK bug)
*/
	GuiControlGet, coords, %guiName%:Pos,% ctrlHandler
	return {X:coordsX,Y:coordsY,W:coordsW,H:coordsH}
}

RemoveToolTip() {
	ToolTip
}

Is_Email(string) {
	if RegExMatch(string, ".*@.*\..*")
		return True
	else return False
}

Reload_Func() {
	Sleep 10
	Reload
	Sleep 10000
}

Exit_Func(ExitReason, ExitCode) {
	if ExitReason not in Reload
		ExitApp
}

#Include lib/third-party/AddToolTip.ahk
#Include lib/third-party/Class ImageButton.ahk
#Include lib/third-party/JSON.ahk
#Include lib/third-party/LV_SetSelColors.ahk
#Include lib/GitHubReleasesAPI.ahk
#Include lib/FileDownload.ahk
