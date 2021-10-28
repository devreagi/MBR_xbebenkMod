; #FUNCTION# ====================================================================================================================
; Name ..........: Clan Games
; Description ...: This file contains the Clan Games algorithm
; Syntax ........: ---
; Parameters ....: ---
; Return values .: ---
; Author ........: ViperZ And Uncle Xbenk 01-2018
; Modified ......: ProMac 02/2018 [v2 and v3] , ProMac 08/2018 v4 , GrumpyHog 08/2020
; Remarks .......: This file is part of MyBotRun. Copyright 2018
;                  MyBotRun is distributed under the terms of the GNU GPL
; Related .......: ---
; Link ..........: https://www.mybot.run
; Example .......: ---
;================================================================================================================================
Func _ClanGames($test = False)
	
	$g_bIsBBevent = False ;just to be sure, reset to false
	
	; Check If this Feature is Enable on GUI.
	If Not $g_bChkClanGamesEnabled Then Return
	
	Local $sINIPath = StringReplace($g_sProfileConfigPath, "config.ini", "ClanGames_config.ini")
	If Not FileExists($sINIPath) Then ClanGamesChallenges("", True, $sINIPath, $g_bChkClanGamesDebug)

	ClickAway()
	CheckMainScreen(False)
	If _Sleep(500) Then Return
	SetLog("Entering Clan Games", $COLOR_INFO)
	If Not $g_bRunState Then Return
	; Local and Static Variables
	Local $TabChallengesPosition[2] = [820, 130]
	Local $sTimeRemain = "", $sEventName = "", $getCapture = True
	Local Static $YourAccScore[10][2] = [[-1, True], [-1, True], [-1, True], [-1, True], [-1, True], [-1, True], [-1, True], [-1, True], [-1, True], [-1, True]]

	; Initial Timer
	Local $hTimer = TimerInit()
	
	; Let's selected only the necessary images 
	Local $sImagePath = @ScriptDir & "\imgxml\Resources\ClanGamesImages\Challenges"
	Local $sTempPath = @TempDir & "\" & $g_sProfileCurrentName & "\Challenges\"

	;Remove All previous file (in case setting changed)
	DirRemove($sTempPath, $DIR_REMOVE)

	If $g_bChkClanGamesLoot Then ClanGameImageCopy($sImagePath, $sTempPath, "L") ;L for Loot
	If $g_bChkClanGamesBattle Then ClanGameImageCopy($sImagePath, $sTempPath, "B") ;B for Battle
	If $g_bChkClanGamesDes Then ClanGameImageCopy($sImagePath, $sTempPath, "D") ;D for Destruction
	If $g_bChkClanGamesAirTroop Then ClanGameImageCopy($sImagePath, $sTempPath, "A") ;A for AirTroops
	If $g_bChkClanGamesGroundTroop Then ClanGameImageCopy($sImagePath, $sTempPath, "G") ;G for GroundTroops

	If $g_bChkClanGamesMiscellaneous Then ClanGameImageCopy($sImagePath, $sTempPath, "M") ;M for Misc
    If $g_bChkClanGamesSpell Then ClanGameImageCopy($sImagePath, $sTempPath, "S") ;S for GroundTroops
    If $g_bChkClanGamesBBBattle Then ClanGameImageCopy($sImagePath, $sTempPath, "BBB") ;BBB for BB Battle
    If $g_bChkClanGamesBBDes Then ClanGameImageCopy($sImagePath, $sTempPath, "BBD") ;BBD for BB Destruction
	If $g_bChkClanGamesBBTroops Then ClanGameImageCopy($sImagePath, $sTempPath, "BBT") ;BBT for BB Troops
	
	;now we need to copy selected challenge before checking current running event is not wrong event selected
	
	; Enter on Clan Games window
	If IsClanGamesWindow() Then
		; Let's get some information , like Remain Timer, Score and limit
		Local $aiScoreLimit = GetTimesAndScores()
		If $aiScoreLimit = -1 Or UBound($aiScoreLimit) <> 2 Then
			ClickAway() ;need clickaway, as we are leaving
			Return
		Else
			SetLog("Your Score is: " & $aiScoreLimit[0], $COLOR_INFO)
			If _Sleep(500) Then Return
			If $g_bDebugClick Then SaveDebugImage("ClanGames_Challenges", True)
			Local $sTimeCG
			If $aiScoreLimit[0] = $aiScoreLimit[1] Then
				SetLog("Your score limit is reached! Congrats")
				ClickAway()
				Return
			ElseIf $aiScoreLimit[0] + 300 > $aiScoreLimit[1] Then
				SetLog("Your almost reached max point")
				If $g_bChkClanGamesStopBeforeReachAndPurge Then
					If IsEventRunning() Then Return
					$sTimeCG = ConvertOCRTime("ClanGames()", $g_sClanGamesTimeRemaining, True)
					Setlog("Clan Games Minute Remain: " & $sTimeCG)
					If $g_bChkClanGamesPurgeAny And $sTimeCG > 1440 Then ; purge, but not purge on last day of clangames
						SetLog("Stop before completing your limit and only Purge")
						SetLog("Lets only purge 1 most top event", $COLOR_WARNING)
						ForcePurgeEvent(False, True)
						ClickAway()
						Return
					EndIf
				EndIf
			EndIf
			If $YourAccScore[$g_iCurAccount][0] = -1 Then $YourAccScore[$g_iCurAccount][0] = $aiScoreLimit[0]
		EndIf
	Else
		ClickAway()
		Return
	EndIf

	;check cooldown purge
	If CooldownTime() Then Return
	If Not $g_bRunState Then Return ;trap pause or stop bot
	If IsEventRunning() Then Return
	If Not $g_bRunState Then Return ;trap pause or stop bot

	UpdateStats()
	
	Local $HowManyImages = _FileListToArray($sTempPath, "*", $FLTA_FILES)
	If IsArray($HowManyImages) Then
		Setlog($HowManyImages[0] & " Events to search")
	Else
		Setlog("ClanGames-Error on $HowManyImages: " & @error)
		Return
	EndIf

	; To store the detections
	; [0]=ChallengeName [1]=EventName [2]=Xaxis [3]=Yaxis
	Local $aAllDetectionsOnScreen[0][4]

	Local $sClanGamesWindow = GetDiamondFromRect("300,155,765,550")
	Local $aCurrentDetection = findMultiple($sTempPath, $sClanGamesWindow, $sClanGamesWindow, 0, 1000, 0, "objectname,objectpoints", True)
	Local $aEachDetection

	If $g_bChkClanGamesDebug Then Setlog("_ClanGames findMultiple (in " & Round(TimerDiff($hTimer) / 1000, 2) & " seconds)", $COLOR_INFO)
	$hTimer = TimerInit()

	; Let's split Names and Coordinates and populate a new array
	If UBound($aCurrentDetection) > 0 Then

		; Temp Variables
		Local $FullImageName, $StringCoordinates, $sString, $tempObbj, $tempObbjs, $aNames
		Local $BBCheck[2] = ["BBD-WallDes", "BBD-BuildingDes"]
		
		For $i = 0 To UBound($aCurrentDetection) - 1
			If _Sleep(50) Then Return ; just in case of PAUSE
			If Not $g_bRunState Then Return ; Stop Button

			$aEachDetection = $aCurrentDetection[$i]
			; Justto debug
			SetDebugLog(_ArrayToString($aEachDetection))

			$FullImageName = String($aEachDetection[0])
			$StringCoordinates = $aEachDetection[1]

			If $FullImageName = "" Or $StringCoordinates = "" Then ContinueLoop
			
			; Exist more than One coordinate!?
			If StringInStr($StringCoordinates, "|") Then
				; Code to test the string if exist anomalies on string
				$StringCoordinates = StringReplace($StringCoordinates, "||", "|")
				$sString = StringRight($StringCoordinates, 1)
				If $sString = "|" Then $StringCoordinates = StringTrimRight($StringCoordinates, 1)
				; Split the coordinates
				$tempObbjs = StringSplit($StringCoordinates, "|", $STR_NOCOUNT)
				; Just get the first [0]
				$tempObbj = StringSplit($tempObbjs[0], ",", $STR_NOCOUNT) ;  will be a string : 708,360
				If UBound($tempObbj) <> 2 Then ContinueLoop
			Else
				$tempObbj = StringSplit($StringCoordinates, ",", $STR_NOCOUNT) ;  will be a string : 708,360
				If UBound($tempObbj) <> 2 Then ContinueLoop
			EndIf
			
			For $x = 0 To UBound($BBCheck) - 1
				If $FullImageName = $BBCheck[$x] Then 
					If $g_bChkClanGamesDebug Then SetLog("Detection for " & $FullImageName & " :", $COLOR_INFO)
					If Not IsBBChallenge($tempObbj[0],$tempObbj[1]) Then 
						If $g_bChkClanGamesDebug Then SetLog("False Detection, Skip this Challenge", $COLOR_ERROR)
						ContinueLoop 2
					Else
						If $g_bChkClanGamesDebug Then SetLog("OK, Continue", $COLOR_SUCCESS)
					Endif
				EndIf
			Next
			
			$aNames = StringSplit($FullImageName, "-", $STR_NOCOUNT)
			SetDebugLog("filename: " & $FullImageName & " $aNames[0] = " & $aNames[0] & " $aNames[1]= " & $aNames[1], $COLOR_ORANGE)
			ReDim $aAllDetectionsOnScreen[UBound($aAllDetectionsOnScreen) + 1][4]
			$aAllDetectionsOnScreen[UBound($aAllDetectionsOnScreen) - 1][0] = $aNames[0] ; Challenge Name
			$aAllDetectionsOnScreen[UBound($aAllDetectionsOnScreen) - 1][1] = $aNames[1] ; Event Name
			$aAllDetectionsOnScreen[UBound($aAllDetectionsOnScreen) - 1][2] = $tempObbj[0] ; Xaxis
			$aAllDetectionsOnScreen[UBound($aAllDetectionsOnScreen) - 1][3] = $tempObbj[1] ; Yaxis
		Next
	EndIf

	Local $aSelectChallenges[0][5]

	If UBound($aAllDetectionsOnScreen) > 0 Then
		For $i = 0 To UBound($aAllDetectionsOnScreen) - 1
            ;If IsBBChallenge($aAllDetectionsOnScreen[$i][2], $aAllDetectionsOnScreen[$i][3]) and $g_bChkClanGamesBBBattle == 0 and $g_bChkClanGamesBBDes == 0 Then ContinueLoop ; only skip if it is a BB challenge not supported

			Switch $aAllDetectionsOnScreen[$i][0]
				Case "L"
					If Not $g_bChkClanGamesLoot Then ContinueLoop
					;[0] = Path Directory , [1] = Name , [2] = TH level , [3] = Difficulty Level , [4] = Time to do it
					Local $LootChallenges = ClanGamesChallenges("$LootChallenges", False, $sINIPath, $g_bChkClanGamesDebug)
					For $j = 0 To UBound($LootChallenges) - 1
						; Match the names
						If $aAllDetectionsOnScreen[$i][1] = $LootChallenges[$j][0] Then
							; Verify your TH level and Challenge kind
							If $g_iTownHallLevel < $LootChallenges[$j][2] Then ExitLoop
							; Disable this event from INI File
							If $LootChallenges[$j][3] = 0 Then ExitLoop
							; [0]Event Name Full Name  , [1] Xaxis ,  [2] Yaxis , [3] difficulty
							Local $aArray = [$LootChallenges[$j][1], $aAllDetectionsOnScreen[$i][2], $aAllDetectionsOnScreen[$i][3], $LootChallenges[$j][3]]
						EndIf
					Next
				Case "A"
					If Not $g_bChkClanGamesAirTroop Then ContinueLoop
					;[0] = Path Directory , [1] = Event Name , [2] = TH level , [3] = Event Quantities
					Local $AirTroopChallenges = ClanGamesChallenges("$AirTroopChallenges", False, $sINIPath, $g_bChkClanGamesDebug)
					For $j = 0 To UBound($AirTroopChallenges) - 1
						; Match the names
						If $aAllDetectionsOnScreen[$i][1] = $AirTroopChallenges[$j][0] Then
							; Verify if the Troops exist in your Army Composition
							Local $TroopIndex = Int(Eval("eTroop" & $AirTroopChallenges[$j][1]))
							; If doesn't Exist the Troop on your Army
							If $g_aiCurrentTroops[$TroopIndex] < 1 Then
								If $g_bChkClanGamesDebug Then SetLog("[" & $AirTroopChallenges[$j][1] & "] No " & $g_asTroopNames[$TroopIndex] & " on your army composition.")
								ExitLoop
								; If Exist BUT not is required quantities
							ElseIf $g_aiCurrentTroops[$TroopIndex] > 0 And $g_aiCurrentTroops[$TroopIndex] < $AirTroopChallenges[$j][3] Then
								If $g_bChkClanGamesDebug Then SetLog("[" & $AirTroopChallenges[$j][1] & "] You need more " & $g_asTroopNames[$TroopIndex] & " [" & $g_aiCurrentTroops[$TroopIndex] & "/" & $AirTroopChallenges[$j][3] & "]")
								ExitLoop
							EndIf
							; [0]Event Name Full Name  , [1] Xaxis ,  [2] Yaxis , [3] difficulty
							Local $aArray[4] = [$AirTroopChallenges[$j][1], $aAllDetectionsOnScreen[$i][2], $aAllDetectionsOnScreen[$i][3], 1]
						EndIf
					Next

				Case "S" ; - grumpy
					If Not $g_bChkClanGamesSpell Then ContinueLoop
					;[0] = Path Directory , [1] = Event Name , [2] = TH level , [3] = Event Quantities
					Local $SpellChallenges = ClanGamesChallenges("$SpellChallenges", False, $sINIPath, $g_bChkClanGamesDebug) ; load all spell challenges
					For $j = 0 To UBound($SpellChallenges) - 1 ; loop through all challenges
						; Match the names
						If $aAllDetectionsOnScreen[$i][1] = $SpellChallenges[$j][0] Then
							; Verify if the Spell exist in your Army Composition
							Local $SpellIndex = Int(Eval("eSpell" & $SpellChallenges[$j][1])) ; assign $SpellIndex enum second column of array is spell name line 740 in GlobalVariables
							; If doesn't Exist the Troop on your Army
							If $g_aiCurrentSpells[$SpellIndex] < 1 Then
								If $g_bChkClanGamesDebug Then SetLog("[" & $SpellChallenges[$j][1] & "] No " & $g_asSpellNames[$SpellIndex] & " on your army composition.")
								ExitLoop
								; If Exist BUT not is required quantities
							ElseIf $g_aiCurrentSpells[$SpellIndex] > 0 And $g_aiCurrentSpells[$SpellIndex] < $SpellChallenges[$j][3] Then
								If $g_bChkClanGamesDebug Then SetLog("[" & $SpellChallenges[$j][1] & "] You need more " & $g_asSpellNames[$SpellIndex] & " [" & $g_aiCurrentSpells[$SpellIndex] & "/" & $SpellChallenges[$j][3] & "]")
								ExitLoop
							EndIf
							; [0]Event Name Full Name  , [1] Xaxis ,  [2] Yaxis , [3] difficulty
							Local $aArray[4] = [$SpellChallenges[$j][1], $aAllDetectionsOnScreen[$i][2], $aAllDetectionsOnScreen[$i][3], 1]
						EndIf
					Next

			   Case "G"
					If Not $g_bChkClanGamesGroundTroop Then ContinueLoop
					;[0] = Path Directory , [1] = Event Name , [2] = TH level , [3] = Event Quantities
					Local $GroundTroopChallenges = ClanGamesChallenges("$GroundTroopChallenges", False, $sINIPath, $g_bChkClanGamesDebug)
					For $j = 0 To UBound($GroundTroopChallenges) - 1
						; Match the names
						If $aAllDetectionsOnScreen[$i][1] = $GroundTroopChallenges[$j][0] Then
							; Verify if the Troops exist in your Army Composition
							Local $TroopIndex = Int(Eval("eTroop" & $GroundTroopChallenges[$j][1]))
							; If doesn't Exist the Troop on your Army
							If $g_aiCurrentTroops[$TroopIndex] < 1 Then
								If $g_bChkClanGamesDebug Then SetLog("[" & $GroundTroopChallenges[$j][1] & "] No " & $g_asTroopNames[$TroopIndex] & " on your army composition.")
								ExitLoop
								; If Exist BUT not is required quantities
							ElseIf $g_aiCurrentTroops[$TroopIndex] > 0 And $g_aiCurrentTroops[$TroopIndex] < $GroundTroopChallenges[$j][3] Then
								If $g_bChkClanGamesDebug Then SetLog("[" & $GroundTroopChallenges[$j][1] & "] You need more " & $g_asTroopNames[$TroopIndex] & " [" & $g_aiCurrentTroops[$TroopIndex] & "/" & $GroundTroopChallenges[$j][3] & "]")
								ExitLoop
							EndIf
							; [0]Event Name Full Name  , [1] Xaxis ,  [2] Yaxis , [3] difficulty
							Local $aArray[4] = [$GroundTroopChallenges[$j][1], $aAllDetectionsOnScreen[$i][2], $aAllDetectionsOnScreen[$i][3], 1]
						EndIf
					 Next

				Case "B"
					If Not $g_bChkClanGamesBattle Then ContinueLoop
					;[0] = Path Directory , [1] = Event Name , [2] = TH level , [3] = Difficulty Level , [4] = Time to do it
					Local $BattleChallenges = ClanGamesChallenges("$BattleChallenges", False, $sINIPath, $g_bChkClanGamesDebug)
					For $j = 0 To UBound($BattleChallenges) - 1
						; Match the names
						If $aAllDetectionsOnScreen[$i][1] = $BattleChallenges[$j][0] Then
							; Verify the TH level and a few Challenge to destroy TH specific level
							If $BattleChallenges[$j][1] = "Scrappy 6s" And ($g_iTownHallLevel < 5 Or $g_iTownHallLevel > 7) Then ExitLoop        ; TH level 5-6-7
							If $BattleChallenges[$j][1] = "Super 7s" And ($g_iTownHallLevel < 6 Or $g_iTownHallLevel > 8) Then ExitLoop            ; TH level 6-7-8
							If $BattleChallenges[$j][1] = "Exciting 8s" And ($g_iTownHallLevel < 7 Or $g_iTownHallLevel > 9) Then ExitLoop        ; TH level 7-8-9
							If $BattleChallenges[$j][1] = "Noble 9s" And ($g_iTownHallLevel < 8 Or $g_iTownHallLevel > 10) Then ExitLoop        ; TH level 8-9-10
							If $BattleChallenges[$j][1] = "Terrific 10s" And ($g_iTownHallLevel < 9 Or $g_iTownHallLevel > 11) Then ExitLoop    ; TH level 9-10-11
							If $BattleChallenges[$j][1] = "Exotic 11s" And ($g_iTownHallLevel < 10 Or $g_iTownHallLevel > 12) Then ExitLoop     ; TH level 10-11-12
							If $BattleChallenges[$j][1] = "Triumphant 12s" And $g_iTownHallLevel < 11 Then ExitLoop  ; TH level 11-12-13
						    If $BattleChallenges[$j][1] = "Tremendous 13s" And $g_iTownHallLevel < 12 Then ExitLoop  ; TH level 12-13

							; Verify your TH level and Challenge
							If $g_iTownHallLevel < $BattleChallenges[$j][2] Then ExitLoop
							; Disable this event from INI File
							If $BattleChallenges[$j][3] = 0 Then ExitLoop
							; If you are a TH13 , doesn't exist the TH14 yet
							If $BattleChallenges[$j][1] = "Attack Up" And $g_iTownHallLevel >= 13 Then ExitLoop
							; Check your Trophy Range
							If $BattleChallenges[$j][1] = "Slaying The Titans" And (Int($g_aiCurrentLoot[$eLootTrophy]) < 4100 or Int($g_aiCurrentLoot[$eLootTrophy]) > 5000) Then ExitLoop

						    If $BattleChallenges[$j][1] = "Clash of Legends" And Int($g_aiCurrentLoot[$eLootTrophy]) < 5000 Then ExitLoop

							; Check if exist a probability to use any Spell
							; If $BattleChallenges[$j][1] = "No-Magic Zone" And ($g_bSmartZapEnable = True Or ($g_iMatchMode = $DB And $g_aiAttackAlgorithm[$DB] = 1) Or ($g_iMatchMode = $LB And $g_aiAttackAlgorithm[$LB] = 1)) Then ExitLoop
							; same as above, but SmartZap as condition removed, cause SZ does not necessary triggers every attack
							If $BattleChallenges[$j][1] = "No-Magic Zone" And (($g_iMatchMode = $DB And $g_aiAttackAlgorithm[$DB] = 1) Or ($g_iMatchMode = $LB And $g_aiAttackAlgorithm[$LB] = 1)) Then ExitLoop
							; Check if you are using Heroes
							If $BattleChallenges[$j][1] = "No Heroics Allowed" And ((Int($g_aiAttackUseHeroes[$DB]) > $eHeroNone And $g_iMatchMode = $DB) Or (Int($g_aiAttackUseHeroes[$LB]) > $eHeroNone And $g_iMatchMode = $LB)) Then ExitLoop
							; [0]Event Name Full Name  , [1] Xaxis ,  [2] Yaxis , [3] difficulty
							Local $aArray[4] = [$BattleChallenges[$j][1], $aAllDetectionsOnScreen[$i][2], $aAllDetectionsOnScreen[$i][3], $BattleChallenges[$j][3]]
						EndIf
					Next
				Case "D"
					If Not $g_bChkClanGamesDes Then ContinueLoop
					;[0] = Path Directory , [1] = Event Name , [2] = TH level , [3] = Difficulty Level , [4] = Time to do it
					Local $DestructionChallenges = ClanGamesChallenges("$DestructionChallenges", False, $sINIPath, $g_bChkClanGamesDebug)
					For $j = 0 To UBound($DestructionChallenges) - 1
						; Match the names
						If $aAllDetectionsOnScreen[$i][1] = $DestructionChallenges[$j][0] Then
							; Verify your TH level and Challenge kind
							If $g_iTownHallLevel < $DestructionChallenges[$j][2] Then ExitLoop

							; Disable this event from INI File
							If $DestructionChallenges[$j][3] = 0 Then ExitLoop

							; Check if you are using Heroes
							If $DestructionChallenges[$j][1] = "Hero Level Hunter" Or _
									$DestructionChallenges[$j][1] = "King Level Hunter" Or _
									$DestructionChallenges[$j][1] = "Queen Level Hunter" Or _
									$DestructionChallenges[$j][1] = "Warden Level Hunter" And ((Int($g_aiAttackUseHeroes[$DB]) = $eHeroNone And $g_iMatchMode = $DB) Or (Int($g_aiAttackUseHeroes[$LB]) = $eHeroNone And $g_iMatchMode = $LB)) Then ExitLoop
							; [0]Event Name Full Name  , [1] Xaxis ,  [2] Yaxis , [3] difficulty
							Local $aArray[4] = [$DestructionChallenges[$j][1], $aAllDetectionsOnScreen[$i][2], $aAllDetectionsOnScreen[$i][3], $DestructionChallenges[$j][3]]
						EndIf
					Next
				Case "M"
					If Not $g_bChkClanGamesMiscellaneous Then ContinueLoop
					;[0] = Path Directory , [1] = Event Name , [2] = TH level , [3] = Difficulty Level , [4] = Time to do it
					Local $MiscChallenges = ClanGamesChallenges("$MiscChallenges", False, $sINIPath, $g_bChkClanGamesDebug)
					For $j = 0 To UBound($MiscChallenges) - 1
						; Match the names
						If $aAllDetectionsOnScreen[$i][1] = $MiscChallenges[$j][0] Then
							; Disable this event from INI File
							If $MiscChallenges[$j][3] = 0 Then ExitLoop

							; Exceptions :
							; 1 - "Gardening Exercise" needs at least a Free Builder and "Remove Obstacles" enabled
							If $MiscChallenges[$j][1] = "Gardening Exercise" And ($g_iFreeBuilderCount < 1 Or Not $g_bChkCleanYard) Then ExitLoop

							; 2 - Verify your TH level and Challenge kind
							If $g_iTownHallLevel < $MiscChallenges[$j][2] Then ExitLoop

							; 3 - If you don't Donate Troops
							If $MiscChallenges[$j][1] = "Helping Hand" And Not $g_iActiveDonate Then ExitLoop

							; 4 - If you don't Donate Spells , $g_aiPrepDon[2] = Donate Spells , $g_aiPrepDon[3] = Donate All Spells [PrepareDonateCC()]
							If $MiscChallenges[$j][1] = "Donate Spells" And ($g_aiPrepDon[2] = 0 And $g_aiPrepDon[3] = 0) Then ExitLoop

							; 5 - If you don't use Blimp
							If $MiscChallenges[$j][1] = "Battle Blimp" And ($g_aiAttackUseSiege[$DB] = 2 Or $g_aiAttackUseSiege[$LB] = 2) And $g_aiArmyCompSiegeMachines[$eSiegeBattleBlimp] = 0 Then ExitLoop

							; 6 - If you don't use Wrecker
							If $MiscChallenges[$j][1] = "Wall Wrecker" And ($g_aiAttackUseSiege[$DB] = 1 Or $g_aiAttackUseSiege[$LB] = 1) And $g_aiArmyCompSiegeMachines[$eSiegeWallWrecker] = 0 Then ExitLoop

							If $MiscChallenges[$j][1] = "Stone Slammer" And ($g_aiAttackUseSiege[$DB] = 3 Or $g_aiAttackUseSiege[$LB] = 3) And $g_aiArmyCompSiegeMachines[$eSiegeStoneSlammer] = 0 Then ExitLoop

							If $MiscChallenges[$j][1] = "Siege Barrack" And ($g_aiAttackUseSiege[$DB] = 4 Or $g_aiAttackUseSiege[$LB] = 4) And $g_aiArmyCompSiegeMachines[$eSiegeBarracks] = 0 Then ExitLoop

							If $MiscChallenges[$j][1] = "Log Launcher" And ($g_aiAttackUseSiege[$DB] = 5 Or $g_aiAttackUseSiege[$LB] = 5) And $g_aiArmyCompSiegeMachines[$eSiegeLogLauncher] = 0 Then ExitLoop

							; [0]Event Name Full Name  , [1] Xaxis ,  [2] Yaxis , [3] difficulty
							Local $aArray[4] = [$MiscChallenges[$j][1], $aAllDetectionsOnScreen[$i][2], $aAllDetectionsOnScreen[$i][3], $MiscChallenges[$j][3]]
						EndIf
					Next
                Case "BBB" ; BB Battle challenges
                    If Not $g_bChkClanGamesBBBattle Then ContinueLoop

                    ;[0] = Path Directory , [1] = Event Name , [2] = TH level , [3] = Difficulty Level , [4] = Time to do it
                    Local $BBBattleChallenges = ClanGamesChallenges("$BBBattleChallenges", False, $sINIPath, $g_bChkClanGamesDebug)
                    For $j = 0 To UBound($BBBattleChallenges) - 1
                        ; Match the names
                        If $aAllDetectionsOnScreen[$i][1] = $BBBattleChallenges[$j][0] Then

                            ; Verify your TH level and Challenge kind
                            ; If $g_iBBTownHallLevel < $DestructionChallenges[$j][2] Then ExitLoop ; adding soon

                            Local $aArray[4] = [$BBBattleChallenges[$j][1], $aAllDetectionsOnScreen[$i][2], $aAllDetectionsOnScreen[$i][3], $BBBattleChallenges[$j][3]]
                        EndIf
                    Next
                Case "BBD" ; BB Destruction challenges
					If Not $g_bChkClanGamesBBDes Then ContinueLoop

                    ;[0] = Path Directory , [1] = Event Name , [2] = TH level , [3] = Difficulty Level , [4] = Time to do it
                    Local $BBDestructionChallenges = ClanGamesChallenges("$BBDestructionChallenges", False, $sINIPath, $g_bChkClanGamesDebug)
                    For $j = 0 To UBound($BBDestructionChallenges) - 1
						; Match the names
                        If $aAllDetectionsOnScreen[$i][1] = $BBDestructionChallenges[$j][0] Then
							Local $aArray[4] = [$BBDestructionChallenges[$j][1], $aAllDetectionsOnScreen[$i][2], $aAllDetectionsOnScreen[$i][3], $BBDestructionChallenges[$j][3]]
                        EndIf
                    Next
				Case "BBT" ; BB Troop challenges
					If Not $g_bChkClanGamesBBTroops Then ContinueLoop

                    ;[0] = Path Directory , [1] = Event Name , [2] = TH level , [3] = Difficulty Level , [4] = Time to do it
                    Local $BBTroopsChallenges = ClanGamesChallenges("$BBTroopChallenges", False, $sINIPath, $g_bChkClanGamesDebug)
                    For $j = 0 To UBound($BBTroopsChallenges) - 1
                        ; Match the names
                        If $aAllDetectionsOnScreen[$i][1] = $BBTroopsChallenges[$j][0] Then
							Local $aArray[4] = [$BBTroopsChallenges[$j][1], $aAllDetectionsOnScreen[$i][2], $aAllDetectionsOnScreen[$i][3], $BBTroopsChallenges[$j][3]]
                        EndIf
                    Next
			EndSwitch
			If IsDeclared("aArray") And $aArray[0] <> "" Then
				ReDim $aSelectChallenges[UBound($aSelectChallenges) + 1][5]
				$aSelectChallenges[UBound($aSelectChallenges) - 1][0] = $aArray[0] ; Event Name Full Name
				$aSelectChallenges[UBound($aSelectChallenges) - 1][1] = $aArray[1] ; Xaxis
				$aSelectChallenges[UBound($aSelectChallenges) - 1][2] = $aArray[2] ; Yaxis
				$aSelectChallenges[UBound($aSelectChallenges) - 1][3] = $aArray[3] ; difficulty
				$aSelectChallenges[UBound($aSelectChallenges) - 1][4] = 0 ; timer minutes
				$aArray[0] = ""
			EndIf
		Next
	EndIf

	If $g_bChkClanGamesDebug Then Setlog("_ClanGames aAllDetectionsOnScreen (in " & Round(TimerDiff($hTimer) / 1000, 2) & " seconds)", $COLOR_INFO)
	$hTimer = TimerInit()

	; Sort by Yaxis , TOP to Bottom
	_ArraySort($aSelectChallenges, 0, 0, 0, 2)

	If UBound($aSelectChallenges) > 0 Then
		; let's get the Event timing
		For $i = 0 To UBound($aSelectChallenges) - 1
			Setlog("Detected " & $aSelectChallenges[$i][0] & " difficulty of " & $aSelectChallenges[$i][3])
			Click($aSelectChallenges[$i][1], $aSelectChallenges[$i][2])
			If _Sleep(1500) Then Return
			Local $EventHours = GetEventInformation()
			Setlog("Time: " & $EventHours & " min", $COLOR_INFO)
			Click($aSelectChallenges[$i][1], $aSelectChallenges[$i][2])
			If _Sleep(250) Then Return
			$aSelectChallenges[$i][4] = Number($EventHours)
		Next

		; let's get the 60 minutes events and remove from array
		Local $aTempSelectChallenges[0][5]
		For $i = 0 To UBound($aSelectChallenges) - 1
			If $aSelectChallenges[$i][4] = 60 And $g_bChkClanGames60 Then
				Setlog($aSelectChallenges[$i][0] & " unselected, is a 60min event!", $COLOR_INFO)
				ContinueLoop
			EndIf
			ReDim $aTempSelectChallenges[UBound($aTempSelectChallenges) + 1][5]
			$aTempSelectChallenges[UBound($aTempSelectChallenges) - 1][0] = $aSelectChallenges[$i][0]
			$aTempSelectChallenges[UBound($aTempSelectChallenges) - 1][1] = $aSelectChallenges[$i][1]
			$aTempSelectChallenges[UBound($aTempSelectChallenges) - 1][2] = $aSelectChallenges[$i][2]
			$aTempSelectChallenges[UBound($aTempSelectChallenges) - 1][3] = $aSelectChallenges[$i][3]
			$aTempSelectChallenges[UBound($aTempSelectChallenges) - 1][4] = $aSelectChallenges[$i][4]
		Next

		; Drop to top again , because coordinates Xaxis and Yaxis
		ClickP($TabChallengesPosition, 2, 0, "#Tab")
		If _sleep(250) Then Return
		ClickDrag(807, 210, 807, 385, 500)
		If _Sleep(500) Then Return
	EndIf

	; After removing is necessary check Ubound
	If IsDeclared("aTempSelectChallenges") Then
		If UBound($aTempSelectChallenges) > 0 Then
			SetDebugLog("$aTempSelectChallenges: " & _ArrayToString($aTempSelectChallenges))
			; Sort by difficulties
			;_ArraySort($aTempSelectChallenges, 0, 0, 0, 3)
			
			; Sort by time
			_ArraySort($aTempSelectChallenges, 1, 4, 0, 3)

			Setlog("Next Event will be " & $aTempSelectChallenges[0][0] & " to make in " & $aTempSelectChallenges[0][4] & " min.")
			; Select and Start EVENT
			$sEventName = $aTempSelectChallenges[0][0]
			Click($aTempSelectChallenges[0][1], $aTempSelectChallenges[0][2])
			If _Sleep(1750) Then Return
			If ClickOnEvent($YourAccScore, $aiScoreLimit, $sEventName, $getCapture) Then Return
			; Some error occurred let's click on Challenges Tab and proceeds
			ClickP($TabChallengesPosition, 2, 0, "#Tab")
		EndIf
	EndIf

	If $g_bChkClanGamesPurgeAny Then ; still have to purge, because no enabled event on setting found
		SetLog("Still have to purge, because no enabled event on setting found", $COLOR_WARNING)
		SetLog("No Event found, lets purge 1 most top event", $COLOR_WARNING)
		ForcePurgeEvent(False, True)
		ClickAway()
		If _Sleep(1000) Then Return
	Else
		SetLog("No Event found, Check your settings", $COLOR_WARNING)
		ClickAway()
		If _Sleep(2000) Then Return
	EndIf
EndFunc ;==>_ClanGames

Func ClanGameImageCopy($sImagePath, $sTempPath, $sImageType = Default)
	If $sImageType = Default Then Return
	Switch $sImageType
		Case "D"
			Local $CGDes = ClanGamesChallenges("$DestructionChallenges")
			For $i = 0 To UBound($g_aCmbCGDes) - 1
				If $g_aCmbCGDes[$i] >= 0 Then
					If $g_bChkClanGamesDebug Then SetLog("[" & $i & "]" & "DestructionChallenges: " & $CGDes[$g_aCmbCGDes[$i]][0], $COLOR_DEBUG)
					FileCopy($sImagePath & "\" & $sImageType & "-" & $CGDes[$g_aCmbCGDes[$i]][0] & "_*.xml", $sTempPath, $FC_OVERWRITE + $FC_CREATEPATH)
				EndIf
			Next
		Case "A"
			Local $AirTroopChallenges = ClanGamesChallenges("$AirTroopChallenges")
			For $i = 0 To UBound($g_aCmbCGAirTroops) - 1
				If $g_aCmbCGAirTroops[$i] >= 0 Then
					If $g_bChkClanGamesDebug Then SetLog("[" & $i & "]" & "AirTroopChallenges: " & $AirTroopChallenges[$g_aCmbCGAirTroops[$i]][0], $COLOR_DEBUG)
					FileCopy($sImagePath & "\" & $sImageType & "-" & $AirTroopChallenges[$g_aCmbCGAirTroops[$i]][0] & "_*.xml", $sTempPath, $FC_OVERWRITE + $FC_CREATEPATH)
				EndIf
			Next
		Case "G"
			Local $GroundTroopChallenges = ClanGamesChallenges("$GroundTroopChallenges")
			For $i = 0 To UBound($g_aCmbCGGroundTroops) - 1
				If $g_aCmbCGGroundTroops[$i] >= 0 Then
					If $g_bChkClanGamesDebug Then SetLog("[" & $i & "]" & "GroundTroopChallenges: " & $GroundTroopChallenges[$g_aCmbCGGroundTroops[$i]][0], $COLOR_DEBUG)
					FileCopy($sImagePath & "\" & $sImageType & "-" & $GroundTroopChallenges[$g_aCmbCGGroundTroops[$i]][0] & "_*.xml", $sTempPath, $FC_OVERWRITE + $FC_CREATEPATH)
				EndIf
			Next
		Case "BBD"
			Local $BBDesChallenges = ClanGamesChallenges("$BBDestructionChallenges")
			For $i = 0 To UBound($g_aCmbCGBBDes) - 1
				If $g_aCmbCGBBDes[$i] >= 0 Then
					If $g_bChkClanGamesDebug Then SetLog("[" & $i & "]" & "BBDestructionChallenges: " & $BBDesChallenges[$g_aCmbCGBBDes[$i]][0], $COLOR_DEBUG)
					FileCopy($sImagePath & "\" & $sImageType & "-" & $BBDesChallenges[$g_aCmbCGBBDes[$i]][0] & "_*.xml", $sTempPath, $FC_OVERWRITE + $FC_CREATEPATH)
				EndIf
			Next
		Case "BBT"
			Local $BBTroopsChallenges = ClanGamesChallenges("$BBTroopChallenges")
			For $i = 0 To UBound($g_aCmbCGBBTroops) - 1
				If $g_aCmbCGBBTroops[$i] >= 0 Then
					If $g_bChkClanGamesDebug Then SetLog("[" & $i & "]" & "BBTroopChallenges: " & $BBTroopsChallenges[$g_aCmbCGBBTroops[$i]][0], $COLOR_DEBUG)
					FileCopy($sImagePath & "\" & $sImageType & "-" & $BBTroopsChallenges[$g_aCmbCGBBTroops[$i]][0] & "_*.xml", $sTempPath, $FC_OVERWRITE + $FC_CREATEPATH)
				EndIf
			Next
		Case "S"
			Local $SChallenges = ClanGamesChallenges("$SpellChallenges")
			For $i = 0 To UBound($g_aCmbCGSpells) - 1
				If $g_aCmbCGSpells[$i] >= 0 Then
					If $g_bChkClanGamesDebug Then SetLog("[" & $i & "]" & "SpellChallenges: " & $SChallenges[$g_aCmbCGSpells[$i]][0], $COLOR_DEBUG)
					FileCopy($sImagePath & "\" & $sImageType & "-" & $SChallenges[$g_aCmbCGSpells[$i]][0] & "_*.xml", $sTempPath, $FC_OVERWRITE + $FC_CREATEPATH)
				EndIf
			Next
		Case Else
			If $g_bChkClanGamesDebug Then SetLog("Rest Challenges: " & $sImageType & "-" & "*.xml", $COLOR_DEBUG)
			FileCopy($sImagePath & "\" & $sImageType & "-" & "*.xml", $sTempPath, $FC_OVERWRITE + $FC_CREATEPATH)
	EndSwitch
EndFunc ;==>ClanGameImageCopy

Func IsClanGamesWindow($getCapture = True)
	Local $sState, $bRet = False

	If QuickMIS("BC1", $g_sImgCaravan, 230, 55, 330, 155, $getCapture, False) Then
		SetLog("Caravan available! Entering Clan Games", $COLOR_SUCCESS)
		Click($g_iQuickMISX + 230, $g_iQuickMISY + 55)
		; Just wait for window open
		If _Sleep(2500) Then Return
		$sState = IsClanGamesRunning()
		Switch $sState
			Case "Prepare"
				$bRet = False
			Case "Running"
				$bRet = True
			Case "Ended"
				$bRet = False
		EndSwitch
	Else
		SetLog("Caravan not available", $COLOR_WARNING)
		$sState = "Not Running"
		$bRet = False
	EndIf

	SetLog("Clan Games State is : " & $sState, $COLOR_INFO)
	Return $bRet
EndFunc   ;==>IsClanGamesWindow

Func IsClanGamesRunning($getCapture = True) ;to check whether clangames current state, return string of the state "prepare" "running" "end"
	Local $aGameTime[4] = [384, 388, 0xFFFFFF, 10]
	Local $sState = "Running"
	If QuickMIS("BC1", $g_sImgWindow, 70, 100, 150, 150, $getCapture, False) Then
		SetLog("Window Opened", $COLOR_DEBUG)
		If QuickMIS("BC1", $g_sImgReward, 580, 480, 830, 570, $getCapture, False) Then
			SetLog("Your Reward is Ready", $COLOR_INFO)
			$sState = "Ended"
		EndIf
	Else
		If _CheckPixel($aGameTime, True) Then
			Local $sTimeRemain = getOcrTimeGameTime(380, 461) ; read Clan Games waiting time
			SetLog("Clan Games will start in " & $sTimeRemain, $COLOR_INFO)
			$g_sClanGamesTimeRemaining = $sTimeRemain
			$sState = "Prepare"
		EndIf
		SetLog("Clan Games Window Not Opened", $COLOR_DEBUG)
		$sState = "Cannot open ClanGames"
	EndIf
	Return $sState
EndFunc ;==>IsClanGamesRunning

Func GetTimesAndScores()
	Local $iRestScore = -1, $sYourGameScore = "", $aiScoreLimit, $sTimeRemain = 0

	;Ocr for game time remaining
	$sTimeRemain = StringReplace(getOcrTimeGameTime(55, 470), " ", "") ; read Clan Games waiting time

	;Check if OCR returned a valid timer format
	If Not StringRegExp($sTimeRemain, "([0-2]?[0-9]?[DdHhSs]+)", $STR_REGEXPMATCH, 1) Then
		SetLog("getOcrTimeGameTime(): no valid return value (" & $sTimeRemain & ")", $COLOR_ERROR)
	EndIf

	SetLog("Clan Games time remaining: " & $sTimeRemain, $COLOR_INFO)

	; This Loop is just to check if the Score is changing , when you complete a previous events is necessary to take some time
	For $i = 0 To 10
		$sYourGameScore = getOcrYourScore(45, 530) ;  Read your Score
		If $g_bChkClanGamesDebug Then SetLog("Your OCR score: " & $sYourGameScore)
		$sYourGameScore = StringReplace($sYourGameScore, "#", "/")
		$aiScoreLimit = StringSplit($sYourGameScore, "/", $STR_NOCOUNT)
		If UBound($aiScoreLimit, 1) > 1 Then
			If $iRestScore = Int($aiScoreLimit[0]) Then ExitLoop
			$iRestScore = Int($aiScoreLimit[0])
		Else
			Return -1
		EndIf
		If _Sleep(800) Then Return
		If $i = 10 Then Return -1
	Next

	;Update Values
	$g_sClanGamesScore = $sYourGameScore
	$g_sClanGamesTimeRemaining = $sTimeRemain

	$aiScoreLimit[0] = Int($aiScoreLimit[0])
	$aiScoreLimit[1] = Int($aiScoreLimit[1])
	Return $aiScoreLimit
EndFunc   ;==>GetTimesAndScores

Func CooldownTime($getCapture = True)
	;check cooldown purge
	Local $aiCoolDown = decodeSingleCoord(findImage("Cooldown", $g_sImgCoolPurge & "\*.xml", GetDiamondFromRect("480,370,570,410"), 1, True, Default))
	If IsArray($aiCoolDown) And UBound($aiCoolDown, 1) >= 2 Then
		SetLog("Cooldown Purge Detected", $COLOR_INFO)
		ClickAway()
		Return True
	EndIf
	Return False
EndFunc   ;==>CooldownTime

Func IsEventRunning($bOpenWindow = False)
	Local $aEventFailed[4] = [300, 255, 0xEA2B24, 20]
	Local $aEventPurged[4] = [300, 266, 0x57c68f, 20]
	
	If $bOpenWindow Then
		ClickAway()
		SetLog("Entering Clan Games", $COLOR_INFO)
		If Not IsClanGamesWindow() Then Return
	EndIf

	; Check if any event is running or not
	If Not _ColorCheck(_GetPixelColor(300, 266, True), Hex(0x53E050, 6), 5) Then ; Green Bar from First Position
		;Check if Event failed
		If _CheckPixel($aEventFailed, True) Then
			SetLog("Couldn't finish last event! Lets trash it and look for a new one", $COLOR_INFO)
			If TrashFailedEvent() Then
				If _Sleep(3000) Then Return ;Add sleep here, to wait ClanGames Challenge Tile ordered again as 1 has been deleted
				Return False
			Else
				SetLog("Error happend while trashing failed event", $COLOR_ERROR)
				ClickAway()
				Return True
			EndIf
		ElseIf _CheckPixel($aEventPurged, True) Then
				SetLog("An event purge cooldown in progress!", $COLOR_WARNING)
				ClickAway()
				Return True
		Else
			SetLog("An event is already in progress!", $COLOR_SUCCESS)
			
			;check if its Enabled Challenge, if not = purge
			If QuickMIS("BC1", @TempDir & "\" & $g_sProfileCurrentName & "\Challenges\", 300, 160, 380, 240, True, False) Then
				SetLog("Active Challenge is Enabled on Setting, OK!!", $COLOR_DEBUG)
				;check if Challenge is BB Challenge, enabling force BB attack
				If $g_bChkForceBBAttackOnClanGames Then
					
					Click(340,210)
					If _Sleep(1000) Then Return
					SetLog("Re-Check If Running Challenge is BB Event or No?", $COLOR_DEBUG)
					If QuickMIS("BC1", $g_sImgVersus, 425, 180, 700, 235, True, False) Then
						Setlog("Running Challenge is BB Challenge", $COLOR_INFO)
						$g_bIsBBevent = True
					Else
						Setlog("Running Challenge is MainVillage Challenge", $COLOR_INFO)
						$g_bIsBBevent = False
					EndIf
				EndIf
			Else
				Setlog("Active Challenge Not Enabled on Setting! started by mistake?", $COLOR_ERROR)
				ForcePurgeEvent(False, False)
			EndIf
			ClickAway()
			Return True
		EndIf
	Else
		SetLog("No event under progress", $COLOR_INFO)
		Return False
	EndIf
	Return False
EndFunc   ;==>IsEventRunning

Func ClickOnEvent(ByRef $YourAccScore, $ScoreLimits, $sEventName, $getCapture)
	If Not $YourAccScore[$g_iCurAccount][1] Then
		Local $Text = "", $color = $COLOR_SUCCESS
		If $YourAccScore[$g_iCurAccount][0] <> $ScoreLimits[0] Then
			$Text = "You on " & $ScoreLimits[0] - $YourAccScore[$g_iCurAccount][0] & "points in last Event"
		Else
			$Text = "You could not complete the last event!"
			$color = $COLOR_WARNING
		EndIf
		SetLog($Text, $color)
		_FileWriteLog($g_sProfileLogsPath & "\ClanGames.log", " [" & $g_sProfileCurrentName & "] - " & $Text)
	EndIf
	$YourAccScore[$g_iCurAccount][1] = False
	$YourAccScore[$g_iCurAccount][0] = $ScoreLimits[0]
	If $g_bChkClanGamesDebug Then SetLog("ClickOnEvent $YourAccScore[" & $g_iCurAccount & "][1]: " & $YourAccScore[$g_iCurAccount][1])
	If $g_bChkClanGamesDebug Then SetLog("ClickOnEvent $YourAccScore[" & $g_iCurAccount & "][0]: " & $YourAccScore[$g_iCurAccount][0])
	If Not StartsEvent($sEventName, False, $getCapture, $g_bChkClanGamesDebug) Then Return False
	ClickAway()
	Return True
EndFunc   ;==>ClickOnEvent

Func StartsEvent($sEventName, $g_bPurgeJob = False, $getCapture = True, $g_bChkClanGamesDebug = False)
	If Not $g_bRunState Then Return

	If QuickMIS("BC1", $g_sImgStart, 220, 150, 830, 580, $getCapture, False) Then
		Local $Timer = GetEventTimeInMinutes($g_iQuickMISX + 220, $g_iQuickMISY + 150)
		SetLog("Starting Event" & " [" & $Timer & " min]", $COLOR_SUCCESS)
		Click($g_iQuickMISX + 220, $g_iQuickMISY + 150)
		GUICtrlSetData($g_hTxtClanGamesLog, @CRLF & _NowDate() & " " & _NowTime() & " [" & $g_sProfileCurrentName & "] - Starting " & $sEventName & " for " & $Timer & " min", 1)
		_FileWriteLog($g_sProfileLogsPath & "\ClanGames.log", " [" & $g_sProfileCurrentName & "] - Starting " & $sEventName & " for " & $Timer & " min")
		
		If $g_bPurgeJob Then
			If _Sleep(2500) Then Return
			If QuickMIS("BC1", $g_sImgTrashPurge, 400, 200, 700, 350, True, False) Then
				Click($g_iQuickMISX + 400, $g_iQuickMISY + 200)
				If _Sleep(1500) Then Return
				SetLog("Click Trash", $COLOR_INFO)
				If QuickMIS("BC1", $g_sImgOkayPurge, 440, 400, 580, 450, True, False) Then
					SetLog("Click OK", $COLOR_INFO)
					Click($g_iQuickMISX + 440, $g_iQuickMISY + 400)
					SetLog("StartsEvent and Purge job!", $COLOR_SUCCESS)
					GUICtrlSetData($g_hTxtClanGamesLog, @CRLF & _NowDate() & " " & _NowTime() & " [" & $g_sProfileCurrentName & "] - Purging Event ", 1)
					_FileWriteLog($g_sProfileLogsPath & "\ClanGames.log", " [" & $g_sProfileCurrentName & "] - Purging Event ")
					ClickAway()
				Else
					SetLog("$g_sImgOkayPurge Issue", $COLOR_ERROR)
					Return False
				EndIf
			Else
				SetLog("$g_sImgTrashPurge Issue", $COLOR_ERROR)
				Return False
			EndIf
		EndIf
		
		;check if Challenge is BB Challenge, enabling force BB attack
		If $g_bChkForceBBAttackOnClanGames Then
			Click(450,75) ;Click Clan Tab
			If _Sleep(3000) Then Return
			Click(300,75) ;Click Challenge Tab
			If _Sleep(500) Then Return
			Click(340,210) ;Click Active Challenge
			If _Sleep(1000) Then Return
			
			SetLog("Re-Check If Running Challenge is BB Event or No?", $COLOR_DEBUG)
			If QuickMIS("BC1", $g_sImgVersus, 425, 180, 700, 235, True, False) Then
				Setlog("Running Challenge is BB Challenge", $COLOR_INFO)
				$g_bIsBBevent = True
			Else
				Setlog("Running Challenge is MainVillage Challenge", $COLOR_INFO)
				$g_bIsBBevent = False
			EndIf
		EndIf
		Return True
	Else
		SetLog("Didn't Get the Green Start Button Event", $COLOR_WARNING)
		If $g_bChkClanGamesDebug Then SetLog("[X: " & 220 & " Y:" & 150 & " X1: " & 830 & " Y1: " & 580 & "]", $COLOR_WARNING)
		ClickAway()
		Return False
	EndIf

EndFunc   ;==>StartsEvent

Func PurgeEvent($directoryImage, $sEventName, $getCapture = True)
	SetLog("Checking Builder Base Challenges to Purge", $COLOR_DEBUG)
	; Screen coordinates for ScreenCapture
	Local $x = 281, $y = 150, $x1 = 775, $y1 = 545
	If QuickMIS("BC1", $directoryImage, $x, $y, $x1, $y1, $getCapture, False) Then
		Click($g_iQuickMISX + $x, $g_iQuickMISY + $y)
		; Start and Purge at same time
		SetLog("Starting Impossible Job to purge", $COLOR_INFO)
		If _Sleep(1500) Then Return
		If StartsEvent($sEventName, True, $getCapture, $g_bChkClanGamesDebug) Then
			ClickAway()
			Return True
		EndIf
	EndIf
	Return False
EndFunc   ;==>PurgeEvent

Func ForcePurgeEvent($bTest = False, $startFirst = True)
	Local $SearchArea

	Click(340,200) ;Most Top Challenge

	If _Sleep(1000) Then Return
	If $startFirst Then
		SetLog("ForcePurgeEvent: No event Found, Start and Purge a Challenge", $COLOR_INFO)
		If StartAndPurgeEvent($bTest) Then
			ClickAway()
			Return True
		EndIf
	Else
		SetLog("ForcePurgeEvent: Purge a Wrong Challenge", $COLOR_INFO)
		If QuickMIS("BC1", $g_sImgTrashPurge, 400, 200, 700, 350, True, False) Then
			Click($g_iQuickMISX + 400, $g_iQuickMISY + 200)
			If _Sleep(1200) Then Return
			SetLog("Click Trash", $COLOR_INFO)
			If QuickMIS("BC1", $g_sImgOkayPurge, 440, 400, 580, 450, True, False) Then
				SetLog("Click OK", $COLOR_INFO)
				If $bTest Then Return
				Click($g_iQuickMISX + 440, $g_iQuickMISY + 400)
				If _Sleep(1500) Then Return
				GUICtrlSetData($g_hTxtClanGamesLog, @CRLF & _NowDate() & " " & _NowTime() & " [" & $g_sProfileCurrentName & "] - ForcePurgeEvent: Purge a Wrong Challenge ", 1)
				_FileWriteLog($g_sProfileLogsPath & "\ClanGames.log", " [" & $g_sProfileCurrentName & "] - ForcePurgeEvent: Purge a Wrong Challenge ")
			Else
				SetLog("$g_sImgOkayPurge Issue", $COLOR_ERROR)
				Return False
			EndIf
		Else
			SetLog("$g_sImgTrashPurge Issue", $COLOR_ERROR)
			Return False
		EndIf
	EndIf
	Return False
EndFunc   ;==>ForcePurgeEvent

Func StartAndPurgeEvent($bTest = False)

	If QuickMIS("BC1", $g_sImgStart, 220, 150, 700, 400, True, False) Then
		Local $Timer = GetEventTimeInMinutes($g_iQuickMISX + 220, $g_iQuickMISY + 150)
		SetLog("Starting  Event" & " [" & $Timer & " min]", $COLOR_SUCCESS)
		Click($g_iQuickMISX + 220, $g_iQuickMISY + 150)
		GUICtrlSetData($g_hTxtClanGamesLog, @CRLF & _NowDate() & " " & _NowTime() & " [" & $g_sProfileCurrentName & "] - Starting Purge for " & $Timer & " min", 1)
		_FileWriteLog($g_sProfileLogsPath & "\ClanGames.log", " [" & $g_sProfileCurrentName & "] - Starting Purge for " & $Timer & " min")

		If _Sleep(3000) Then Return
		If QuickMIS("BC1", $g_sImgTrashPurge, 400, 200, 700, 350, True, False) Then
			Click($g_iQuickMISX + 400, $g_iQuickMISY + 200)
			If _Sleep(3000) Then Return
			SetLog("Click Trash", $COLOR_INFO)
			If QuickMIS("BC1", $g_sImgOkayPurge, 440, 400, 580, 450, True, False) Then
				SetLog("Click OK", $COLOR_INFO)
				If $bTest Then Return
				Click($g_iQuickMISX + 440, $g_iQuickMISY + 400)
				SetLog("StartAndPurgeEvent event!", $COLOR_SUCCESS)
				GUICtrlSetData($g_hTxtClanGamesLog, @CRLF & _NowDate() & " " & _NowTime() & " [" & $g_sProfileCurrentName & "] - StartAndPurgeEvent: No event Found ", 1)
				_FileWriteLog($g_sProfileLogsPath & "\ClanGames.log", " [" & $g_sProfileCurrentName & "] - StartAndPurgeEvent: No event Found ")
				ClickAway()
			Else
				SetLog("$g_sImgOkayPurge Issue", $COLOR_ERROR)
				Return False
			EndIf
		Else
			SetLog("$g_sImgTrashPurge Issue", $COLOR_ERROR)
			Return False
		EndIf
	EndIf
	ClickAway()
	Return True
EndFunc

Func TrashFailedEvent()
	;Look for the red cross on failed event
	If Not ClickB("EventFailed") Then
		SetLog("Could not find the failed event icon!", $COLOR_ERROR)
		Return False
	EndIf

	If _Sleep(1000) Then Return

	;Look for the red trash event Button and press it
	If Not ClickB("TrashEvent") Then
		SetLog("Could not find the trash event button!", $COLOR_ERROR)
		Return False
	EndIf

	If _Sleep(500) Then Return
	Return True
EndFunc   ;==>TrashFailedEvent

Func GetEventTimeInMinutes($iXStartBtn, $iYStartBtn, $bIsStartBtn = True)

	Local $XAxis = $iXStartBtn - 163 ; Related to Start Button
	Local $YAxis = $iYStartBtn + 8 ; Related to Start Button

	If Not $bIsStartBtn Then
		$XAxis = $iXStartBtn - 163 ; Related to Trash Button
		$YAxis = $iYStartBtn + 8 ; Related to Trash Button
	EndIf

	Local $Ocr = getOcrEventTime($XAxis, $YAxis)
	If $Ocr = "1" Then $Ocr = "1d"
	If $Ocr = "2" Then $Ocr = "2d"
    Return ConvertOCRTime("ClanGames()", $Ocr, True)
EndFunc   ;==>GetEventTimeInMinutes

Func GetEventInformation()
	If QuickMIS("BC1", $g_sImgStart, 220, 150, 830, 580, True, False) Then
		Return GetEventTimeInMinutes($g_iQuickMISX + 220, $g_iQuickMISY + 150)
	Else
		Return 0
	EndIf
EndFunc   ;==>GetEventInformation


Func IsBBChallenge($i = Default, $j = Default)

	Local $BorderX[4] = [292, 418, 546, 669]
	Local $BorderY[3] = [205, 363, 520]
	Local $iColumn, $iRow, $bReturn

	Switch $i
		Case $BorderX[0] To $BorderX[1]
			$iColumn = 1
		Case $BorderX[1] To $BorderX[2]
			$iColumn = 2
		Case $BorderX[1] To $BorderX[3]
			$iColumn = 3
		Case Else
			$iColumn = 4
	EndSwitch

	Switch $j
		Case $BorderY[0]-50 To $BorderY[1]-50
			$iRow = 1
		Case $BorderY[1]-50 To $BorderY[2]-50
			$iRow = 2
		Case Else
			$iRow = 3
	EndSwitch
	If $g_bChkClanGamesDebug Then SetLog("Row: " & $iRow & ", Column : " & $iColumn, $COLOR_DEBUG)
	For $y = 0 To 2
		For $x = 0 To 3
			If $iRow = ($y+1) And $iColumn = ($x+1) Then 
				;Search image border, our image is MainVillage event border, so If found return False
				If QuickMIS("BC1", $g_sImgBorder, $BorderX[$x] - 50, $BorderY[$y] - 50, $BorderX[$x] + 50, $BorderY[$y] + 50, True, False) Then
					If $g_bChkClanGamesDebug Then SetLog("IsBBChallenge = False", $COLOR_ERROR)
					Return False
				Else
					If $g_bChkClanGamesDebug Then SetLog("IsBBChallenge = True", $COLOR_INFO)
					Return True
				EndIf
			EndIf
		Next
	Next
	
EndFunc ;==>IsBBChallenge

; Just for any button test
Func ClanGames($bTest = False)
	Local $bWasRunState = $g_bRunState
	$g_bRunState = True
	Local $temp = $g_bChkClanGamesDebug
	Local $debug = $g_bDebugSetlog
	$g_bDebugSetlog = True
	$g_bChkClanGamesDebug = True
	Local $tempCurrentTroops = $g_aiCurrentTroops
	For $i = 0 To UBound($g_aiCurrentTroops) - 1
		$g_aiCurrentTroops[$i] = 50
	Next
	Local $Result = _ClanGames(True)
	$g_aiCurrentTroops = $tempCurrentTroops
	$g_bRunState = $bWasRunState
	$g_bChkClanGamesDebug = $temp
	$g_bDebugSetlog = $debug
	Return $Result
EndFunc   ;==>ClanGames

#Tidy_Off
Func ClanGamesChallenges($sReturnArray, $makeIni = False, $sINIPath = "", $bDebug = False)

	;[0]=ImageName 	 					[1]=Challenge Name		[3]=THlevel 	[4]=Priority/TroopsNeeded 	[5]=Extra/to use in future
	Local $LootChallenges[6][5] = [ _
			["GoldChallenge", 			"Gold Challenge", 				 7,  5, 8], _ ; Loot 150,000 Gold from a single Multiplayer Battle				|8h 	|50
			["ElixirChallenge", 		"Elixir Challenge", 			 7,  5, 8], _ ; Loot 150,000 Elixir from a single Multiplayer Battle 			|8h 	|50
			["DarkEChallenge", 			"Dark Elixir Challenge", 		 8,  5, 8], _ ; Loot 1,500 Dark elixir from a single Multiplayer Battle			|8h 	|50
			["GoldGrab", 				"Gold Grab", 					 3,  1, 1], _ ; Loot a total of 500,000 TO 1,500,000 from Multiplayer Battle 	|1h-2d 	|100-600
			["ElixirEmbezz", 			"Elixir Embezzlement", 			 3,  1, 1], _ ; Loot a total of 500,000 TO 1,500,000 from Multiplayer Battle 	|1h-2d 	|100-600
			["DarkEHeist", 				"Dark Elixir Heist", 			 9,  3, 1]]   ; Loot a total of 1,500 TO 12,500 from Multiplayer Battle 		|1h-2d 	|100-600

	Local $AirTroopChallenges[14][5] = [ _
			["Ball", 					"Balloon", 						 4, 12, 1], _ ; Earn 2-5 Stars from Multiplayer Battles using 12 Balloons		|3h-8h	|40-100
			["Heal", 					"Healer", 						 4, 12, 1], _ ; Earn 2-5 Stars from Multiplayer Battles using 12 Balloons		|3h-8h	|40-100
			["Drag", 					"Dragon", 						 7,  6, 1], _ ; Earn 2-5 Stars from Multiplayer Battles using 6 Dragons			|3h-8h	|40-100
			["BabyD", 					"Baby Dragon", 					 9,  2, 1], _ ; Earn 2-5 Stars from Multiplayer Battles using 4 Baby Dragons	|3h-8h	|40-100
			["Edrag", 					"Electro Dragon", 				10,  2, 1], _ ; Earn 2-4 Stars from Multiplayer Battles using 2 Electro Dragon	|3h-8h	|40-300
			["RDrag", 					"Dragon Rider", 				10,  2, 1], _ ; Earn 2-4 Stars from Multiplayer Battles using 2 Electro Dragon	|3h-8h	|40-300
			["Mini", 					"Minion", 						 7, 10, 1], _ ; Earn 2-5 Stars from Multiplayer Battles using 20 Minions		|3h-8h	|40-100
			["Lava", 					"Lavahound", 					 9,  1, 1], _ ; Earn 2-5 Stars from Multiplayer Battles using 3 Lava Hounds		|3h-8h	|40-100
			["RBall", 					"Rocket Balloon", 				12,  4, 1], _ ;
			["Smini", 					"Super Minion", 				12,  4, 1], _ ;
			["InfernoD",				"Inferno Dragon", 				12,  1, 1], _ ;
			["IceH", 					"Ice Hound", 					13,  1, 1], _ ;
			["BattleB", 				"Battle Blimp", 				10,  5, 1], _ ; moved to air troops
			["StoneS",	 				"Stone Slammer", 				10,  5, 1]]   ; moved to air troops

	Local $GroundTroopChallenges[27][5] = [ _
			["Arch", 					"Archer", 						 1, 10, 1], _ ; Earn 2-5 Stars from Multiplayer Battles using 30 Barbarians		|3h-8h	|40-100
			["Barb", 					"Barbarian", 					 1, 30, 1], _ ; Earn 2-5 Stars from Multiplayer Battles using 30 Archers		|3h-8h	|40-100
			["Giant", 					"Giant", 						 1, 10, 1], _ ; Earn 2-5 Stars from Multiplayer Battles using 10 Giants			|3h-8h	|40-100
			["Gobl", 					"Goblin", 						 2, 20, 1], _ ; Earn 2-5 Stars from Multiplayer Battles using 20 Goblins		|3h-8h	|40-100
			["Wall", 					"WallBreaker", 					 3,  2, 1], _ ; Earn 2-5 Stars from Multiplayer Battles using 6 Wall Breakers	|3h-8h	|40-100
			["Wiza", 					"Wizard", 						 5,  6, 1], _ ; Earn 2-5 Stars from Multiplayer Battles using 12 Wizards		|3h-8h	|40-100
			["Hogs", 					"HogRider", 					 7, 10, 1], _ ; Earn 2-5 Stars from Multiplayer Battles using 10 Hog Riders		|3h-8h	|40-100
			["Mine", 					"Miner", 						10,  8, 1], _ ; Earn 2-5 Stars from Multiplayer Battles using 8 Miners			|3h-8h	|40-100
			["Pekk", 					"Pekka", 						 8,  1, 1], _ ; updated 25/01/2021
			["Witc", 					"Witch", 						 9,  2, 1], _ ; Earn 2-5 Stars from Multiplayer Battles using 2 Witches			|3h-8h	|40-100
			["Bowl", 					"Bowler", 						10,  8, 1], _ ; Earn 2-5 Stars from Multiplayer Battles using 8 Bowlers			|3h-8h	|40-100
			["Valk", 					"Valkyrie", 					 8,  4, 1], _ ; Earn 2-5 Stars from Multiplayer Battles using 8 Valkyries		|3h-8h	|40-100
			["Gole", 					"Golem", 						 8,  2, 1], _ ; Earn 2-5 Stars from Multiplayer Battles using 2 Golems			|3h-8h	|40-100
			["Yeti", 					"Yeti", 						 12, 1, 1], _ ; check quantity
			["IceG", 					"IceGolem", 					 11, 2, 1], _ ; check quantity
			["Hunt", 					"HeadHunters", 					 12, 2, 1], _ ; updated 25/01/2021
			["Sbarb", 					"SuperBarbarian", 				 11, 4, 1], _ ; updated 25/01/2021
			["Sarch", 					"SuperArcher", 					 11, 1, 1], _ ; check quantity missing xml
			["Sgiant", 					"SuperGiant", 					 12, 1, 1], _ ; check quantity
			["Sgobl", 					"SneakyGoblin", 				 11, 1, 1], _ ; check quantity
			["Swall", 					"SuperWallBreaker", 			 11, 1, 1], _ ; check quantity
			["Swiza", 					"SuperWizard",					 12, 1, 1], _ ; check quantity missing xml
			["Svalk", 					"SuperValkyrie",				 12, 2, 1], _ ; updated 25/01/2021
			["Switc", 					"SuperWitch", 					 12, 1, 1], _ ; check quantity
			["WallW", 					"Wall Wrecker", 				10,  5, 1], _ ; moved to ground troops
			["SiegeB", 					"Siege Barrack", 				10,  5, 1], _ ; moved to ground troops
			["LogL", 					"Log Launcher", 				10,  5, 1]]   ; moved to ground troops

	Local $BattleChallenges[21][5] = [ _
			["Start", 					"Star Collector", 				 3,  1, 8], _ ; Collect a total of 6-18 stars from Multiplayer Battles			|8h-2d	|100-600
			["Destruction", 			"Lord of Destruction", 			 3,  1, 8], _ ; Gather a total of 100%-500% destruction from Multi Battles		|8h-2d	|100-600
			["PileOfVictores", 			"Pile Of Victories", 			 3,  1, 8], _ ; Win 2-8 Multiplayer Battles										|8h-2d	|100-600
			["StarThree", 				"Hunt for Three Stars", 		10,  5, 8], _ ; Score a perfect 3 Stars in Multiplayer Battles					|8h 	|200
			["WinningStreak", 			"Winning Streak", 				 9,  5, 8], _ ; Win 2-8 Multiplayer Battles in a row							|8h-2d	|100-600
			["SlayingTitans", 			"Slaying The Titans", 			11,  2, 5], _ ; Win 5 Multiplayer Battles In Tital LEague						|5h		|300
			["NoHero", 					"No Heroics Allowed", 			 3,  5, 8], _ ; Win stars without using Heroes									|8h		|100
			["NoMagic", 				"No-Magic Zone", 				 3,  5, 8], _ ; Win stars without using Spells									|8h		|100
			["Scrappy6s", 				"Scrappy 6s", 					 6,  1, 8], _ ; Gain 3 Stars Against Town Hall level 6							|8h		|200
			["Super7s", 				"Super 7s", 					 7,  1, 8], _ ; Gain 3 Stars Against Town Hall level 7							|8h		|200
			["Exciting8s", 				"Exciting 8s", 					 8,  1, 8], _ ; Gain 3 Stars Against Town Hall level 8							|8h		|200
			["Noble9s", 				"Noble 9s", 					 9,  1, 8], _ ; Gain 3 Stars Against Town Hall level 9							|8h		|200
			["Terrific10s", 			"Terrific 10s", 				10,  1, 8], _ ; Gain 3 Stars Against Town Hall level 10							|8h		|200
			["Exotic11s", 			    "Exotic 11s", 					11,  1, 8], _ ; Gain 3 Stars Against Town Hall level 11							|8h		|200
			["Triumphant12s", 			"Triumphant 12s", 				12,  1, 8], _ ; Gain 3 Stars Against Town Hall level 12							|8h		|200
			["AttackUp", 				"Attack Up", 					 3,  1, 8], _ ; Gain 3 Stars Against Town Hall a level higher					|8h		|200
			["ClashOfLegends", 			"Clash of Legends", 			11,  2, 5], _ ;
			["GainStarsFromClanWars",	"3 Stars From Clan War",		 6,  0, 5], _ ;
			["SpeedyStars", 			"3 Stars in 60 seconds",		 6,  2, 5], _ ;
			["SuperCharge", 			"Deploy SuperTroops",			 6,  2, 5], _ ;
			["Tremendous13s", 			"Tremendous 13s", 				13,  1, 8]]   ;

	Local $DestructionChallenges[33][5] = [ _
			["Cannon", 					"Cannon", 				 3,  1, 1], _ ; Destroy 5-25 Cannons in Multiplayer Battles					|1h-8h	|75-350
			["ArcherT", 				"Archer Tower", 		 3,  1, 1], _ ; Destroy 5-20 Archer Towers in Multiplayer Battles			|1h-8h	|75-350
			["BuilderHut", 				"Builder Hut", 		     3,  1, 1], _ ; Destroy 4-12 BuilderHut in Multiplayer Battles				|1h-8h	|40-350
			["Mortar", 					"Mortar", 				 3,  1, 1], _ ; Destroy 4-12 Mortars in Multiplayer Battles					|1h-8h	|40-350
			["AirD", 					"Air Defenses", 		 7,  2, 1], _ ; Destroy 3-12 Air Defenses in Multiplayer Battles			|1h-8h	|40-350
			["WizardT", 				"Wizard Tower", 		 3,  1, 1], _ ; Destroy 4-12 Wizard Towers in Multiplayer Battles			|1h-8h	|40-350
			["AirSweepers", 			"Air Sweepers", 		 8,  4, 1], _ ; Destroy 2-6 Air Sweepers in Multiplayer Battles				|1h-8h	|40-350
			["Tesla", 					"Tesla Towers", 		 7,  5, 1], _ ; Destroy 4-12 Hidden Teslas in Multiplayer Battles			|1h-8h	|50-350
			["BombT", 					"Bomb Towers", 			 8,  2, 1], _ ; Destroy 2 Bomb Towers in Multiplayer Battles				|1h-8h	|50-350
			["Xbow", 					"X-Bows", 				 9,  5, 1], _ ; Destroy 3-12 X-Bows in Multiplayer Battles					|1h-8h	|50-350
			["Inferno", 				"Inferno Towers", 		11,  5, 1], _ ; Destroy 2 Inferno Towers in Multiplayer Battles				|1h-2d	|50-600
			["EagleA", 					"Eagle Artillery", 	    11,  5, 1], _ ; Destroy 1-7 Eagle Artillery in Multiplayer Battles			|1h-2d	|50-600
			["ClanC", 					"Clan Castle", 			 5,  2, 1], _ ; Destroy 1-4 Clan Castle in Multiplayer Battles				|1h-8h	|40-350
			["GoldSRaid", 				"Gold Storage", 		 3,  2, 1], _ ; Destroy 3-15 Gold Storages in Multiplayer Battles			|1h-8h	|40-350
			["ElixirSRaid", 			"Elixir Storage", 		 3,  1, 1], _ ; Destroy 3-15 Elixir Storages in Multiplayer Battles			|1h-8h	|40-350
			["DarkEStorageRaid", 		"Dark Elixir Storage", 	 8,  3, 1], _ ; Destroy 1-4 Dark Elixir Storage in Multiplayer Battles		|1h-8h	|40-350
			["GoldM", 					"Gold Mine", 			 3,  1, 1], _ ; Destroy 6-20 Gold Mines in Multiplayer Battles				|1h-8h	|40-350
			["ElixirPump", 				"Elixir Pump", 		 	 3,  1, 1], _ ; Destroy 6-20 Elixir Collectors in Multiplayer Battles		|1h-8h	|40-350
			["DarkEPlumbers", 			"Dark Elixir Drill", 	 3,  1, 1], _ ; Destroy 2-8 Dark Elixir Drills in Multiplayer Battles		|1h-8h	|40-350
			["Laboratory", 				"Laboratory", 			 3,  1, 1], _ ; Destroy 2-6 Laboratories in Multiplayer Battles				|1h-8h	|40-200
			["SFacto", 					"Spell Factory", 		 3,  1, 1], _ ; Destroy 2-6 Spell Factories in Multiplayer Battles			|1h-8h	|40-200
			["DESpell", 				"Dark Spell Factory", 	 8,  1, 1], _ ; Destroy 2-6 Dark Spell Factories in Multiplayer Battles		|1h-8h	|40-200
			["WallWhacker", 			"Wall Whacker", 		 3,  1, 1], _ ; Destroy 50-250 Walls in Multiplayer Battles					|
			["BBreakdown",	 			"Building Breakdown", 	 3,  1, 1], _ ; Destroy 50-250 Buildings in Multiplayer Battles					|
			["BKaltar", 				"Barbarian King Altars", 9,  4, 1], _ ; Destroy 2-5 Barbarian King Altars in Multiplayer Battles	|1h-8h	|50-150
			["AQaltar", 				"Archer Queen Altars", 	10,  5, 1], _ ; Destroy 2-5 Archer Queen Altars in Multiplayer Battles		|1h-8h	|50-150
			["GWaltar", 				"Grand Warden Altars", 	11,  5, 1], _ ; Destroy 2-5 Grand Warden Altars in Multiplayer Battles		|1h-8h	|50-150
			["HeroLevelHunter", 		"Hero Level Hunter", 	 9,  5, 8], _ ; Knockout 125 Level Heroes on Multiplayer Battles			|8h		|100
			["KingLevelHunter", 		"King Level Hunter", 	 9,  5, 8], _ ; Knockout 50 Level King on Multiplayer Battles				|8h		|100
			["QueenLevelHunt", 			"Queen Level Hunter", 	10,  5, 8], _ ; Knockout 50 Level Queen on Multiplayer Battles				|8h		|100
			["WardenLevelHunter", 		"Warden Level Hunter", 	11,  5, 8], _ ; Knockout 20 Level Warden on Multiplayer Battles				|8h		|100
			["ArmyCamp", 				"Destroy ArmyCamp", 	11,  5, 1], _ ; Knockout 20 Level Warden on Multiplayer Battles				|8h		|100
			["ScatterShotSabotage",		"ScatterShot",			13,  5, 1]]   ;


	Local $MiscChallenges[3][5] = [ _
			["Gard", 					"Gardening Exercise", 			 3,  6, 8], _ ; Clear 5 obstacles from your Home Village or Builder Base		|8h	|50
			["DonateSpell", 			"Donate Spells", 				 9,  6, 8], _ ; Donate a total of 10 housing space worth of spells				|8h	|50
			["DonateTroop", 			"Helping Hand", 				 6,  6, 8]]   ; Donate a total of 100 housing space worth of troops				|8h	|50


	Local $SpellChallenges[11][5] = [ _
			["LSpell", 					"Lightning", 					 6,  5, 1], _ ;
			["HSpell", 					"Heal",							 6,  5, 1], _ ; updated 25/01/2021
			["RSpell", 					"Rage", 					 	 6,  5, 1], _ ;
			["JSpell", 					"Jump", 					 	 6,  5, 1], _ ;
			["FSpell", 					"Freeze", 					 	 9,  5, 1], _ ;
			["CSpell", 					"Clone", 					 	11,  5, 1], _ ;
			["PSpell", 					"Poison", 					 	 6,  5, 1], _ ;
			["ESpell", 					"Earthquake", 					 6,  5, 1], _ ;
			["HaSpell", 				"Haste",	 					 6,  5, 1], _ ; updated 25/01/2021
			["SkSpell",					"Skeleton", 					11,  5, 1], _ ;
			["BtSpell",					"Bat", 					 		10,  5, 1]]   ;

    Local $BBBattleChallenges[4][5] = [ _
            ["StarM",					"BB Star Master",				2,  1, 1], _ ; Earn 6 - 24 stars on the BB
            ["Victories",				"BB Victories",					2,  5, 1], _ ; Earn 3 - 6 victories on the BB
			["StarTimed",				"BB Star Timed",				2,  2, 1], _
            ["Destruction",				"BB Destruction",				2,  1, 1]] ; Earn 225% - 900% on BB attacks

	Local $BBDestructionChallenges[16][5] = [ _
            ["Airbomb",					"Air Bomb",                 	2,  1, 1], _
			["BuildingDes",             "BB Building",					2,  1, 1], _
			["BuilderHall",             "BuilderHall",					2,  1, 1], _
            ["Cannon",                 	"BB Cannon",                  	2,  1, 1], _ 
			["ClockTower",             	"Clock Tower",                 	2,  1, 1], _ 
            ["DoubleCannon",         	"Double Cannon",             	2,  1, 1], _
			["FireCrackers",         	"Fire Crackers",              	2,  1, 1], _
			["GemMine",                 "Gem Mine",                  	2,  1, 1], _
			["GiantCannon",             "Giant Cannon",               	2,  1, 1], _
			["GuardPost",               "Guard Post",                 	2,  1, 1], _
			["MegaTesla",               "Mega Tesla",               	2,  1, 1], _
			["MultiMortar",             "Multi Mortar",               	2,  1, 1], _
			["Roaster",                 "Roaster",			            2,  1, 1], _
			["StarLab",                 "Star Laboratory",              2,  1, 1], _
			["WallDes",             	"Wall Whacker",              	2,  1, 1], _
			["Crusher",             	"Crusher",                 		2,  1, 1]]

	Local $BBTroopsChallenges[11][5] = [ _
            ["RBarb",					"Raged Barbarian",              2,  1, 1], _ ;BB Troops
            ["SArch",                 	"Sneaky Archer",                2,  1, 1], _
            ["BGiant",         			"Boxer Giant",             		2,  1, 1], _
			["BMini",         			"Beta Minion",              	2,  1, 1], _
			["Bomber",                 	"Bomber",                  		2,  1, 1], _
			["BabyD",               	"Baby Dragon",                 	2,  1, 1], _
			["CannCart",             	"Cannon Cart",               	2,  1, 1], _
			["NWitch",                 	"Night Witch",                 	2,  1, 1], _
			["DShip",                 	"Drop Ship",                  	2,  1, 1], _
			["SPekka",                 	"Super Pekka",                  2,  1, 1], _
			["HGlider",                 "Hog Glider",                  	2,  1, 1]]


	; Just in Case
	Local $LocalINI = $sINIPath
	If $LocalINI = "" Then $LocalINI = StringReplace($g_sProfileConfigPath, "config.ini", "ClanGames_config.ini")

	If $bDebug Then Setlog(" - Ini Path: " & $LocalINI)

	; Variables to use
	Local $section[4] = ["Loot Challenges", "Battle Challenges", "Destruction Challenges", "Misc Challenges"]
	Local $array[4] = [$LootChallenges, $BattleChallenges, $DestructionChallenges, $MiscChallenges]
	Local $ResultIni = "", $TempChallenge, $tempXSector

	; Store variables
	If Not $makeIni Then

		Switch $sReturnArray
			Case "$AirTroopChallenges"
				Return $AirTroopChallenges
			Case "$GroundTroopChallenges"
				Return $GroundTroopChallenges
			Case "$SpellChallenges"
				Return $SpellChallenges
            Case "$BBBattleChallenges"
                Return $BBBattleChallenges
			Case "$BBDestructionChallenges"
				Return $BBDestructionChallenges
			Case "$BBTroopChallenges"
				Return $BBTroopsChallenges

			Case "$LootChallenges"
				$TempChallenge = $array[0]
				$tempXSector = $section[0]
			Case "$BattleChallenges"
				$TempChallenge = $array[1]
				$tempXSector = $section[1]
			Case "$DestructionChallenges"
				$TempChallenge = $array[2]
				$tempXSector = $section[2]
			Case "$MiscChallenges"
				$TempChallenge = $array[3]
				$tempXSector = $section[3]
		EndSwitch
		; Read INI File
		If $bDebug Then SetLog("[" & $tempXSector & "]")
		For $j = 0 To UBound($TempChallenge) - 1
			$ResultIni = Int(IniRead($LocalINI, $tempXSector, $TempChallenge[$j][1], $TempChallenge[$j][3]))
			$TempChallenge[$j][3] = IsNumber($ResultIni) = 1 ? Int($ResultIni) : 0
			If $TempChallenge[$j][3] > 5 Then $TempChallenge[$j][3] = 5
			If $TempChallenge[$j][3] < 0 Then $TempChallenge[$j][3] = 0
			If $bDebug Then SetLog(" - " & $TempChallenge[$j][1] & ": " & $TempChallenge[$j][3])
			$ResultIni = ""
		Next
		Return $TempChallenge
	Else

		; Write INI File
		Local $File = FileOpen($LocalINI, $FO_APPEND)
		Local $HelpText = "; - MyBotRun 2020 - " & @CRLF & _
				"; - 'Event name' = 'Priority' [1~5][easiest to the hardest] , '0' to disable the event" & @CRLF & _
				"; - Remember on GUI you can enable/disable an entire Section" & @CRLF & _
				"; - Do not change any event name" & @CRLF & _
				"; - Deleting this file will restore the defaults values." & @CRLF & @CRLF
		FileWrite($File, $HelpText)
		FileClose($File)
		For $i = 0 To UBound($array) - 1
			$TempChallenge = $array[$i]
			If $bDebug Then Setlog("[" & $section[$i] & "]")
			For $j = 0 To UBound($TempChallenge) - 1
				If IniWrite($LocalINI, $section[$i], $TempChallenge[$j][1], $TempChallenge[$j][3]) <> 1 Then SetLog("Error on :" & $section[$i] & "|" & $TempChallenge[$j][1], $COLOR_WARNING)
				If $bDebug Then SetLog(" - " & $TempChallenge[$j][1] & ": " & $TempChallenge[$j][3])
				If _sleep(100) Then Return
			Next
			$TempChallenge = Null
		Next
	EndIf
EndFunc   ;==>ClanGamesChallenges
#Tidy_Off
