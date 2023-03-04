#SingleInstance Force
#NoTrayIcon

tempParams := {}
Loop, %0% {
	param := %A_Index%
	if RegExMatch(param, "/Resources_Folder=(.*)", found) {
		tempParams.Resources_Folder := found1
	}
	if RegExMatch(param, "/Game_Icons_Folder=(.*)", found) {
		tempParams.Game_Icons_Folder := found1
	}
	ProgramValues := tempParams
}

; \resources\
if !( InStr(FileExist(ProgramValues.Resources_Folder), "D") )
	FileCreateDir,% ProgramValues.Resources_Folder 
FileInstall, resources\Donate_Paypal.png,% ProgramValues.Resources_Folder "\Donate_Paypal.png", 1
FileInstall, resources\icon.ico,% ProgramValues.Resources_Folder "\icon.ico", 1

; \resources\games_icons\
if !( InStr(FileExist(ProgramValues.Game_Icons_Folder), "D") )
	FileCreateDir,% ProgramValues.Game_Icons_Folder 
FileInstall, resources\games_icons\Destiny_2.png,% ProgramValues.Game_Icons_Folder "\Destiny_2.png", 1
FileInstall, resources\games_icons\Diablo_3.png,% ProgramValues.Game_Icons_Folder "\Diablo_3.png", 1
FileInstall, resources\games_icons\Hearthstone.png,% ProgramValues.Game_Icons_Folder "\Hearthstone.png", 1
FileInstall, resources\games_icons\Heroes_of_the_Storm.png,% ProgramValues.Game_Icons_Folder "\Heroes_of_the_Storm.png", 1
FileInstall, resources\games_icons\Overwatch.png,% ProgramValues.Game_Icons_Folder "\Overwatch.png", 1
FileInstall, resources\games_icons\StarCraft_2.png,% ProgramValues.Game_Icons_Folder "\StarCraft_2.png", 1
FileInstall, resources\games_icons\StarCraft_Remastered.png,% ProgramValues.Game_Icons_Folder "\StarCraft_Remastered.png", 1
FileInstall, resources\games_icons\World_of_Warcraft.png,% ProgramValues.Game_Icons_Folder "\World_of_Warcraft.png", 1

