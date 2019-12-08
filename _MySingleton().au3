Func _MySingleton($sOccurrenceName, $iFlag = 0)
	; Recently noticed _Singleton() never returns false on my laptop
	; so I wrote this simple emulator using the old hidden window trick.
	Local $WTMM = Opt('WinTitleMatchMode', 3)
	Local $vReturn = 0
	Local $sObfuscateWinTitle = 'MYSINGLETON:\\' & $sOccurrenceName
	Local $hCheck = WinGetHandle($sObfuscateWinTitle)
	If Not WinExists($sObfuscateWinTitle) Then
		$vReturn = GUICreate($sObfuscateWinTitle)
		GUICtrlCreateLabel(@AutoItPID, 0, 0)
	ElseIf $iFlag = 0 Then
		Exit 19821102
	EndIf
	Opt('WinTitleMatchMode', $WTMM)
	Return SetExtended($hCheck, $vReturn)
EndFunc