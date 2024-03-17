; #FUNCTION# ====================================================================================================================
; Name ..........: StarBonus
; Description ...: Checks for Star bonus window, and clicks ok to close window.
; Syntax ........: StarBonus()
; Parameters ....:
; Return values .: MonkeyHunter(2016-1)
; Modified ......: MonkeyHunter (05-2017)
; Remarks .......: This file is part of MyBot, previously known as ClashGameBot. Copyright 2015-2019
;                  MyBot is distributed under the terms of the GNU GPL
; Related .......:
; Link ..........: https://github.com/MyBotRun/MyBot/wiki
; Example .......: No
; ===============================================================================================================================
Func StarBonus()
	If $g_bDebugSetLog Then SetLog("Begin Star Bonus window check", $COLOR_DEBUG1)
	; Verify is Star bonus window open?
	If Not _CheckPixel($aIsMainGrayed, $g_bCapturePixel, Default, "IsMainGrayed") Then Return ; Star bonus window opens on main base view, and grays page.

	Local $aWindowChk1[4] = [135, 90, 0x244864, 15] ; Black Balloon
	Local $aWindowChk2[4] = [676, 90, 0x249CF9, 15] ; Blue header covering elixir bar

	If _Sleep($DELAYSTARBONUS100) Then Return

	; Verify actual star bonus window open
	If _CheckPixel($aWindowChk1, $g_bCapturePixel, Default, "Starbonus1") And _CheckPixel($aWindowChk2, $g_bCapturePixel, Default, "Starbonus2") Then
		; Find and Click Okay button
		Click(430, 530, 2, 50, "StarBonus: Click Okay Button") ; Click Okay Button
		If _Sleep($DELAYSTARBONUS500) Then Return
		Return True
	EndIf
	Return False
EndFunc   ;==>StarBonus
