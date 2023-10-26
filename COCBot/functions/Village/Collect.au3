; #FUNCTION# ====================================================================================================================
; Name ..........: Collect
; Description ...:
; Syntax ........: Collect()
; Parameters ....:
; Return values .: None
; Author ........:
; Modified ......: Sardo (08/2015), KnowJack(10/2015), kaganus (10/2015), ProMac (04/2016), Codeslinger69 (01/2017), Fliegerfaust (11/2017)
; Remarks .......: This file is part of MyBot, previously known as ClashGameBot. Copyright 2015-2019
;                  MyBot is distributed under the terms of the GNU GPL
; Related .......:
; Link ..........: https://github.com/MyBotRun/MyBot/wiki
; Example .......: No
; ===============================================================================================================================
#include-once

Func Collect($bCheckTreasury = True)
	If Not $g_bChkCollect Or Not $g_bRunState Then Return

	ClickAway()

	StartGainCost()
	checkAttackDisable($g_iTaBChkIdle) ; Early Take-A-Break detection

	If $g_bChkCollectCartFirst And ($g_iTxtCollectGold = 0 Or $g_aiCurrentLoot[$eLootGold] < Number($g_iTxtCollectGold) Or $g_iTxtCollectElixir = 0 Or $g_aiCurrentLoot[$eLootElixir] < Number($g_iTxtCollectElixir) Or $g_iTxtCollectDark = 0 Or $g_aiCurrentLoot[$eLootDarkElixir] < Number($g_iTxtCollectDark)) Then CollectLootCart()

	SetLog("Collecting Resources", $COLOR_INFO)
	If _Sleep($DELAYCOLLECT2) Then Return

	; Setup arrays, including default return values for $return
	Local $sFileName = ""
	Local $aCollectXY, $t

	Local $aResult = returnMultipleMatchesOwnVillage($g_sImgCollectResources)

	If UBound($aResult) > 1 Then ; we have an array with data of images found
		For $i = 1 To UBound($aResult) - 1 ; loop through array rows
			$sFileName = $aResult[$i][1] ; Filename
			$aCollectXY = $aResult[$i][5] ; Coords
			Switch StringLower($sFileName)
				Case "collectmines"
					If $g_iTxtCollectGold <> 0 And $g_aiCurrentLoot[$eLootGold] >= Number($g_iTxtCollectGold) Then
						SetLog("Gold is high enough, skip collecting", $COLOR_ACTION)
						ContinueLoop
					EndIf
				Case "collectelix"
					If $g_iTxtCollectElixir <> 0 And $g_aiCurrentLoot[$eLootElixir] >= Number($g_iTxtCollectElixir) Then
						SetLog("Elixir is high enough, skip collecting", $COLOR_ACTION)
						ContinueLoop
					EndIf
				Case "collectdelix"
					If $g_iTxtCollectDark <> 0 And $g_aiCurrentLoot[$eLootDarkElixir] >= Number($g_iTxtCollectDark) Then
						SetLog("Dark Elixier is high enough, skip collecting", $COLOR_ACTION)
						ContinueLoop
					EndIf
			EndSwitch
			If IsArray($aCollectXY) Then ; found array of locations
				$t = Random(0, UBound($aCollectXY) - 1, 1) ; SC May 2017 update only need to pick one of each to collect all
				SetDebugLog($sFileName & " found, random pick(" & $aCollectXY[$t][0] & "," & $aCollectXY[$t][1] & ")", $COLOR_GREEN)
				If IsMainPage() Then Click($aCollectXY[$t][0], $aCollectXY[$t][1], 1, 0, "#0430")
				If _Sleep($DELAYCOLLECT2) Then Return
			EndIf
		Next
	EndIf

	If _Sleep($DELAYCOLLECT3) Then Return
	If Not $g_bChkCollectCartFirst And ($g_iTxtCollectGold = 0 Or $g_aiCurrentLoot[$eLootGold] < Number($g_iTxtCollectGold) Or $g_iTxtCollectElixir = 0 Or $g_aiCurrentLoot[$eLootElixir] < Number($g_iTxtCollectElixir) Or $g_iTxtCollectDark = 0 Or $g_aiCurrentLoot[$eLootDarkElixir] < Number($g_iTxtCollectDark)) Then CollectLootCart()
	If $g_bChkTreasuryCollect And $bCheckTreasury Then TreasuryCollect()
	EndGainCost("Collect")
EndFunc   ;==>Collect

Func CollectLootCart()
	ZoomOutHelper("CollectLootCart")

	SetLog("Searching for a Loot Cart", $COLOR_INFO)
	If Not IsMainPage() Then Return
	If QuickMIS("BC1", $g_sImgCollectLootCart, 0, 180, 120, 300) Then 
		Click($g_iQuickMISX + 10, $g_iQuickMISY)
		If _Sleep(1000) Then Return
		If ClickB("CollectLootCart") Then
			SetLog("Clicking to collect loot cart.", $COLOR_SUCCESS)
		Else
			SetLog("Cannot find LootCart Collect Button", $COLOR_ERROR)
		EndIf
	Else
		SetLog("No Loot Cart found on your Village", $COLOR_SUCCESS)
	EndIf
EndFunc   ;==>CollectLootCart
