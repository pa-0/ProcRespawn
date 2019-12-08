#NoTrayIcon
#RequireAdmin
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=ProcRespawn.ico
#AutoIt3Wrapper_Compression=4
#AutoIt3Wrapper_UseX64=y
#AutoIt3Wrapper_Res_Fileversion=1.0.0.5
#AutoIt3Wrapper_Res_Fileversion_AutoIncrement=y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#include <Constants.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <GUIListView.au3>
#include <Array.au3>
#include <StaticConstants.au3>
#include <GUIMenu.au3>
#include <Misc.au3>

#include <_MySingleton().au3>

Opt('GUIOnEventMode', 1)
Opt('MustDeclareVars', 1)
Opt('TrayMenuMode', 1+2)
Opt('TrayOnEventMode', 1)

_MySingleton('ProcRespawn')

Global $sAppTitle = 'Process Respawn', $bHideNotify = 0, $bHideUnreadable = 1, _
	$hMainWindow, $lv_Monitor, $bt_Add, $bt_Remove, $bt_Params, $in_Interval, $bt_Shortcut, $bt_Exit, _
	$cm_Shortcut, $me_Startup, $mi_StartHide, $mi_StartShow, $me_Desktop, $mi_DeskHide, $mi_DeskShow, _
	$sConfigPath = @AppDataDir & '\therkSoft\' & $sAppTitle & '.ini', $iCheckTime = Int(IniRead($sConfigPath, 'Config', 'Time', 5))

FileClose(FileOpen($sConfigPath, 9)) ; Create config file
If $iCheckTime < 1 Then $iCheckTime = 1
If $CmdLine[0] And $CmdLine[1] = '/hide' Then $bHideNotify = 1

Main()

Func Main()
	TraySetState()
	TraySetToolTip($sAppTitle)
	TraySetClick(16)
	TraySetOnEvent($TRAY_EVENT_PRIMARYDOUBLE, '_TrayShow')
	TrayCreateItem('&Settings')
		TrayItemSetState(-1, 512)
		TrayItemSetOnEvent(-1, '_TrayShow')
	TrayCreateItem('E&xit')
		TrayItemSetOnEvent(-1, '_ProgramExit')

	$hMainWindow = GUICreate($sAppTitle, 400, 250, Default, Default, $WS_OVERLAPPEDWINDOW)
		GUISetOnEvent($GUI_EVENT_CLOSE, '_GenHandler')
	$lv_Monitor = GUICtrlCreateListView('Name|PID|Path|Parameters', 5, 5, 290, 240, BitOR($GUI_SS_DEFAULT_LISTVIEW, $LVS_NOSORTHEADER))
		GUICtrlSetResizing(-1, $GUI_DOCKBORDERS)

	Opt('GUIResizeMode', $GUI_DOCKSIZE+$GUI_DOCKTOP+$GUI_DOCKRIGHT)
	$bt_Add = GUICtrlCreateButton('&Add Process', 300, 5, 95, 25)
		GUICtrlSetOnEvent(-1, '_AddProcess')
	$bt_Remove = GUICtrlCreateButton('&Remove Process', 300, 35, 95, 25)
		GUICtrlSetOnEvent(-1, '_GenHandler')
	$bt_Params = GUICtrlCreateButton('Set &Parameters', 300, 65, 95, 25)
		GUICtrlSetOnEvent(-1, '_GenHandler')
	GUICtrlCreateLabel('&Frequency:', 300, 95, 55, 20, $SS_CENTERIMAGE)
	$in_Interval = GUICtrlCreateInput($iCheckTime, 355, 95, 20, 20)
		GUICtrlSetTip(-1, 'How frequently to check if processes are running.')
		GUICtrlSetOnEvent(-1, '_GenHandler')
	GUICtrlCreateLabel(' sec', 375, 95, 40, 20, $SS_CENTERIMAGE)

	Opt('GUIResizeMode', $GUI_DOCKSIZE+$GUI_DOCKBOTTOM+$GUI_DOCKRIGHT)
	$bt_Shortcut = GUICtrlCreateButton('Create Shortcut', 300, 190, 95, 25)
		GUICtrlSetOnEvent(-1, '_GenHandler')
	$bt_Exit = GUICtrlCreateButton('E&xit', 300, 220, 95, 25)
		GUICtrlSetOnEvent(-1, '_ProgramExit')

	$cm_Shortcut = GUICtrlCreateContextMenu(GUICtrlCreateDummy())
		$me_Startup = GUICtrlCreateMenu('Create shortcut in &Startup', $cm_Shortcut)
			$mi_StartShow = GUICtrlCreateMenuItem('&Show program window when launched', $me_Startup)
				GUICtrlSetOnEvent(-1, '_MakeShortcut')
			$mi_StartHide = GUICtrlCreateMenuItem('&Hide program window when launched', $me_Startup)
				GUICtrlSetOnEvent(-1, '_MakeShortcut')
		$me_Desktop = GUICtrlCreateMenu('Create shortcut on &Desktop', $cm_Shortcut)
			$mi_DeskShow = GUICtrlCreateMenuItem('&Show program window when launched', $me_Desktop)
				GUICtrlSetOnEvent(-1, '_MakeShortcut')
			$mi_DeskHide = GUICtrlCreateMenuItem('&Hide program window when launched', $me_Desktop)
				GUICtrlSetOnEvent(-1, '_MakeShortcut')

	_RefreshMonitorList()
	AdlibRegister('_RefreshMonitorList', $iCheckTime * 1000)
	If Not $bHideNotify Then GUISetState()

	ProcessWaitClose(@AutoItPID)
EndFunc

Func _TrayShow()
	GUISetState(@SW_SHOW, $hMainWindow)
	WinActivate($hMainWindow)
EndFunc

Func _ProgramExit()
	If MsgBox(0x2134, $sAppTitle, 'Are you sure you want to exit this program?' & @LF & '(Processes will not be monitored/restarted)') = 6 Then Exit
EndFunc

Func _GenHandler()
	Switch @GUI_CtrlId
		Case $in_Interval
			$iCheckTime = Int(GUICtrlRead($in_Interval))
			If $iCheckTime < 1 Then
				MsgBox(0x2030, $sAppTitle, 'Check time cannot be less than 1 second.')
				GUICtrlSetData($in_Interval, '1')
				$iCheckTime = 1
			EndIf
			IniWrite($sConfigPath, 'Config', 'Time', $iCheckTime)
			AdlibRegister('_RefreshMonitorList', $iCheckTime * 1000)

		Case $bt_Remove
			Local $iSel = _GUICtrlListView_GetNextItem($lv_Monitor)
			If $iSel = -1 Then Return

			Local $sProcName = _GUICtrlListView_GetItemText($lv_Monitor, $iSel, 0)
			If MsgBox(0x2124, $sAppTitle, 'Are you sure you want to stop monitoring this process? (' & $sProcName & ')', 0, $hMainWindow) = 6 Then
				IniDelete($sConfigPath, 'Processes', _IniEscape($sProcName))
				IniDelete($sConfigPath, 'ProcessParams', _IniEscape($sProcName))
				_RefreshMonitorList()
			EndIf

		Case $bt_Params
			Local $iSel = _GUICtrlListView_GetNextItem($lv_Monitor)
			If $iSel = -1 Then Return

			Local $sProcName = _GUICtrlListView_GetItemText($lv_Monitor, $iSel, 0)
			Local $sParams = _GUICtrlListView_GetItemText($lv_Monitor, $iSel, 3)
			$sParams = InputBox($sAppTitle, 'Enter parameters for process: ' & $sProcName, $sParams, '', 300, 120, Default, Default, 0, $hMainWindow)
			If $sParams Then
				IniWrite($sConfigPath, 'ProcessParams', _IniEscape($sProcName), $sParams)
				_RefreshMonitorList()
			EndIf

		Case $bt_Shortcut
			Local $aPos = WinGetPos(GUICtrlGetHandle($bt_Shortcut))
			If Not @error Then _GUICtrlMenu_TrackPopupMenu(GUICtrlGetHandle($cm_Shortcut), $hMainWindow, $aPos[0], $aPos[1] + $aPos[3])

		Case $GUI_EVENT_CLOSE
			GUISetState(@SW_HIDE, $hMainWindow)
			If Not $bHideNotify Then
				TrayTip($sAppTitle, 'The program window has been hidden. Double click this icon to see it again or right-click to choose Exit.', 5, 1)
				$bHideNotify = 1
			EndIf
	EndSwitch
EndFunc

Func _MakeShortcut()
	Local $sHide, $sPath = @DesktopDir
	Switch @GUI_CtrlId
		Case $mi_DeskHide
			$sHide = '/hide'
		Case $mi_StartShow
			$sPath = @StartupDir
		Case $mi_StartHide
			$sHide = '/hide'
			$sPath = @StartupDir
	EndSwitch

	FileCreateShortcut(@ScriptFullPath, $sPath & '\' & $sAppTitle & '.lnk', @ScriptDir, $sHide, '', @ScriptFullPath)
EndFunc

Func _AddProcess()
	Opt('GUIOnEventMode', 0)
	Local $gm, $hListWindow, $bt_ListAdd, $ch_ListRefresh, $bt_AddByPath

	$hListWindow = GUICreate($sAppTitle, 300, 300, Default, Default, BitOR($WS_MAXIMIZEBOX, $WS_CAPTION, $WS_POPUP, $WS_SYSMENU, $WS_SIZEBOX), Default, $hMainWindow)
	Global $lv_ListProcess = GUICtrlCreateListView('Name|PID|Path', 5, 5, 290, 265, BitOR($GUI_SS_DEFAULT_LISTVIEW, $LVS_NOSORTHEADER))
		GUICtrlSetResizing(-1, $GUI_DOCKBORDERS)
	Opt('GUIResizeMode', $GUI_DOCKSIZE+$GUI_DOCKBOTTOM+$GUI_DOCKLEFT)
	$bt_ListAdd = GUICtrlCreateButton('Add to Monitor', 5, 270, 90, 25)
	$ch_ListRefresh = GUICtrlCreateCheckbox('Refresh', 100, 270, 110, 25)

	$bt_AddByPath = GUICtrlCreateButton('Add by Path', 215, 270, 80, 25)
		GUICtrlSetResizing(-1, $GUI_DOCKSIZE+$GUI_DOCKBOTTOM+$GUI_DOCKRIGHT)
	_RefreshProcList()
	GUISetState()

	WinMove($hListWindow, '', (@DesktopWidth - 640) / 2, (@DesktopHeight - 480) / 2, 640, 480)

	WinSetState($hMainWindow, '', @SW_DISABLE)
	While 1
		$gm = GUIGetMsg()
		Switch $gm
			Case $bt_AddByPath
				Local $sFilePath = FileOpenDialog('Select program', '', 'Applications (*.exe)|All files (*.*)', 1+2, '', $hListWindow)
				If Not @error Then
					Local $sFileName = StringTrimLeft($sFilePath, StringInStr($sFilePath, '\', 0, -1))
					IniWrite($sConfigPath, 'Processes', _IniEscape($sFileName), _IniEscape($sFilePath))
					ExitLoop
				EndIf
			Case $bt_ListAdd
				Local $iSel = _GUICtrlListView_GetNextItem($lv_ListProcess)
				Local $sProcName = _GUICtrlListView_GetItemText($lv_ListProcess, $iSel, 0)
				Local $sProcPath = _GUICtrlListView_GetItemText($lv_ListProcess, $iSel, 2)
				IniWrite($sConfigPath, 'Processes', _IniEscape($sProcName), _IniEscape($sProcPath))
				ExitLoop
			Case $ch_ListRefresh
				If BitAND(GUICtrlRead($ch_ListRefresh), $GUI_CHECKED) Then
					_RefreshProcList()
					AdlibRegister('_RefreshProcList', 1000)
				Else
					AdlibUnRegister('_RefreshProcList')
				EndIf
			Case $GUI_EVENT_CLOSE
				ExitLoop
		EndSwitch
	WEnd
	AdlibUnRegister('_RefreshProcList')
	_RefreshMonitorList()
	GUIDelete($hListWindow)
	WinSetState($hMainWindow, '', @SW_ENABLE)
	WinActivate($hMainWindow)
	Opt('GUIOnEventMode', 1)
EndFunc

Func _RefreshMonitorList()
	Local $iSel = _GUICtrlListView_GetNextItem($lv_Monitor)
	_GUICtrlListView_BeginUpdate($lv_Monitor)
	_GUICtrlListView_DeleteAllItems($lv_Monitor)
	Local $aMonList = IniReadSection($sConfigPath, 'Processes')
	If @error Then Return _GUICtrlListView_EndUpdate($lv_Monitor)

	_ArraySort($aMonList, 0, 1, 0, 0)
	For $forMonList = 1 To $aMonList[0][0]
		$aMonList[$forMonList][0] = _IniUnescape($aMonList[$forMonList][0])
		$aMonList[$forMonList][1] = _IniUnescape($aMonList[$forMonList][1])

		Local $sParams = _IniUnescape(IniReadRaw($sConfigPath, 'ProcessParams', $aMonList[$forMonList][0], @LF))
		Local $iPID = _CheckProcessByPath($aMonList[$forMonList][1])
		If Not $iPID Then
			If $sParams <> @LF Then
				$iPID = Run('"' & $aMonList[$forMonList][1] & '"' & ' ' & $sParams)
			Else
				$iPID = Run('"' & $aMonList[$forMonList][1] & '"')
			EndIf
		EndIf
		GUICtrlCreateListViewItem($aMonList[$forMonList][0] & '|' & $iPID & '|' & $aMonList[$forMonList][1] & '|' & StringStripWS($sParams, 3), $lv_Monitor)
	Next
	_GUICtrlListView_EndUpdate($lv_Monitor)
	_GUICtrlListView_SetColumnWidth($lv_Monitor, 0, $LVSCW_AUTOSIZE)
	_GUICtrlListView_SetColumnWidth($lv_Monitor, 1, $LVSCW_AUTOSIZE)
	_GUICtrlListView_SetColumnWidth($lv_Monitor, 2, $LVSCW_AUTOSIZE)
	If $iSel <> -1 Then _GUICtrlListView_SetItemSelected($lv_Monitor, $iSel)
EndFunc

Func _RefreshProcList()
	Local $iSel = _GUICtrlListView_GetNextItem($lv_ListProcess)
	Local $aProcList = _ProcessListProperties()
	_ArraySort($aProcList, 0, 1, 0, 0)
	_GUICtrlListView_BeginUpdate($lv_ListProcess)
	_GUICtrlListView_DeleteAllItems($lv_ListProcess)
	For $forProcs = 1 To $aProcList[0][0]
		GUICtrlCreateListViewItem($aProcList[$forProcs][0] & '|' & $aProcList[$forProcs][1] & '|' & $aProcList[$forProcs][2], $lv_ListProcess)
	Next
	_GUICtrlListView_EndUpdate($lv_ListProcess)
	_GUICtrlListView_SetColumnWidth($lv_ListProcess, 0, $LVSCW_AUTOSIZE)
	_GUICtrlListView_SetColumnWidth($lv_ListProcess, 1, $LVSCW_AUTOSIZE)
	_GUICtrlListView_SetColumnWidth($lv_ListProcess, 2, $LVSCW_AUTOSIZE)
	If $iSel <> -1 Then _GUICtrlListView_SetItemSelected($lv_ListProcess, $iSel)
EndFunc

Func _CheckProcessByPath($sPath)
	Local $iReturn, $oWMI, $oResult
	$sPath = StringReplace($sPath, "\", "\\")
	$sPath = StringReplace($sPath, "'", "\'")
	$sPath = StringReplace($sPath, '"', '\"')

    ; Connect to WMI and get process objects
    $oWMI = ObjGet("winmgmts:{impersonationLevel=impersonate,authenticationLevel=pktPrivacy, (Debug)}!\\.\root\cimv2")
    If IsObj($oWMI) Then
		$oResult = $oWMI.ExecQuery("select ProcessId from win32_process where ExecutablePath = '" & $sPath & "'")

        If IsObj($oResult) Then
            ; Return for no matches
            If $oResult.count = 0 Then Return SetError(3, 0, 0)

            ; For each process...
            For $oProc In $oResult
                $iReturn = $oProc.ProcessId
            Next
        Else
            SetError(2); Error getting process collection from WMI
        EndIf
        ; release the collection object
		$oResult = 0
    Else
        SetError(1); Error connecting to WMI
    EndIf

    ; Return array
    Return $iReturn
EndFunc

Func _ProcessListProperties()
	Local $sReturn, $oWMI, $oResult, $aProcList[1][1], $n = 1

    ; Connect to WMI and get process objects
    $oWMI = ObjGet("winmgmts:{impersonationLevel=impersonate,authenticationLevel=pktPrivacy, (Debug)}!\\.\root\cimv2")
    If IsObj($oWMI) Then
		$oResult = $oWMI.ExecQuery("select name,ProcessId,ExecutablePath from win32_process")

        If IsObj($oResult) Then
            ; Return for no matches
            If $oResult.count = 0 Then Return $aProcList

            ; Size the array
            ReDim $aProcList[$oResult.count + 1][3]
            $aProcList[0][0] = UBound($aProcList) - 1

            ; For each process...
            For $oProc In $oResult
				If Not $oProc.ExecutablePath Then ContinueLoop
                $aProcList[$n][0] = $oProc.name
                $aProcList[$n][1] = $oProc.ProcessId
                $aProcList[$n][2] = $oProc.ExecutablePath
                $n += 1
            Next
			ReDim $aProcList[$n][3]
			$aProcList[0][0] = $n-1
        Else
            SetError(2); Error getting process collection from WMI
        EndIf
        ; release the collection object
        $oResult = 0
    Else
        SetError(1); Error connecting to WMI
    EndIf

    ; Return array
    Return $aProcList
EndFunc

Func IniReadRaw($sFile, $sSection, $sKey, $sDefault)
	Local $aSection = IniReadSection($sFile, $sSection)
	If @error Then Return $sDefault
	For $i = 1 To $aSection[0][0]
		If $aSection[$i][0] = $sKey Then Return $aSection[$i][1]
	Next
	Return $sDefault
EndFunc


Func _IniEscape($sString)
	Local $aSplit = StringSplit($sString, ''), $sOutput
	For $i = 1 to $aSplit[0]
		Switch $aSplit[$i]
			Case '=', ']', '[', '"', "'", '%'
				$sOutput &= '%' & Hex(Asc($aSplit[$i]), 2)
			Case Else
				$sOutput &= $aSplit[$i]
		EndSwitch
	Next
	Return $sOutput
EndFunc

Func _IniUnescape($sString)
	Local $aSplit = StringSplit($sString, '%')
	For $i = 2 To $aSplit[0]
		$aSplit[1] &= Chr(Dec(StringLeft($aSplit[$i], 2))) & StringTrimLeft($aSplit[$i], 2)
	Next
	Return $aSplit[1]
EndFunc