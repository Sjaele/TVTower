Type TScreenHandler_ProgrammePlanner
	Global showPlannerShortCutHintTime:int = 0
	Global showPlannerShortCutHintFadeAmount:int = 1
	Global planningDay:int = -1
	Global talkToProgrammePlanner:int = TRUE		'set to FALSE for deleting gui objects without modifying the plan
	Global DrawnOnProgrammePlannerBG:int = 0
	Global ProgrammePlannerButtons:TGUIButton[6]
	Global PPprogrammeList:TgfxProgrammelist
	Global PPcontractList:TgfxContractlist
	Global fastNavigateTimer:TIntervalTimer = TIntervalTimer.Create(250)
	Global fastNavigateInitialTimer:int = 250
	Global fastNavigationUsedContinuously:int = FALSE
	Global plannerNextDayButton:TGUIButton
	Global plannerPreviousDayButton:TGUIButton
	Global openedProgrammeListThisVisit:int = False

	Global hoveredGuiProgrammePlanElement:TGuiProgrammePlanElement = null
	Global draggedGuiProgrammePlanElement:TGuiProgrammePlanElement = null
	'graphical lists for interaction with blocks
	Global haveToRefreshGuiElements:int = TRUE
	Global GuiListProgrammes:TGUIProgrammePlanSlotList
	Global GuiListAdvertisements:TGUIProgrammePlanSlotList


	Function Init:int()
		'add gfx to background image
		If Not DrawnOnProgrammePlannerBG then InitProgrammePlannerBackground()

		'===== CREATE GUI LISTS =====
		'the visual gap between 0-11 and 12-23 hour
		local gapBetweenHours:int = 45
		local area:TRectangle = new TRectangle.Init(45,5,625,12 * GetSpriteFromRegistry("pp_programmeblock1").area.GetH())

		GuiListProgrammes = new TGUIProgrammePlanSlotList.Create(area.position, area.dimension, "programmeplanner")
		GuiListProgrammes.Init("pp_programmeblock1", GetSpriteFromRegistry("pp_adblock1").area.GetW() + gapBetweenHours)
		GuiListProgrammes.isType = TBroadcastMaterial.TYPE_PROGRAMME

		GuiListAdvertisements = new TGUIProgrammePlanSlotList.Create(new TVec2D.Init(area.GetX() + GetSpriteFromRegistry("pp_programmeblock1").area.GetW(), area.GetY()), area.dimension, "programmeplanner")
		GuiListAdvertisements.Init("pp_adblock1", GetSpriteFromRegistry("pp_programmeblock1").area.GetW() + gapBetweenHours)
		GuiListAdvertisements.isType = TBroadcastMaterial.TYPE_ADVERTISEMENT

		'init lists
		PPprogrammeList	= new TgfxProgrammelist.Create(669, 8)
		PPcontractList = new TgfxContractlist.Create(669, 8)

		'buttons
		plannerNextDayButton = new TGUIButton.Create(new TVec2D.Init(768, 6), new TVec2D.Init(28, 28), ">", "programmeplanner_buttons")
		plannerNextDayButton.spriteName = "gfx_gui_button.datasheet"

		plannerPreviousDayButton = new TGUIButton.Create(new TVec2D.Init(684, 6), new TVec2D.Init(28, 28), "<", "programmeplanner_buttons")
		plannerPreviousDayButton.spriteName = "gfx_gui_button.datasheet"

		'so we can handle clicks to the daychange-buttons while some
		'programmeplan elements are dragged
		'ATTENTION: this makes the button drop-targets, so take care of
		'vetoing try-drop-events
		plannerNextDayButton.SetOption(GUI_OBJECT_ACCEPTS_DROP)
		plannerPreviousDayButton.SetOption(GUI_OBJECT_ACCEPTS_DROP)
		EventManager.registerListenerFunction("guiobject.onTryDropOnTarget", onTryDropProgrammePlanElementOnDayButton, "TGUIProgrammePlanElement")


		ProgrammePlannerButtons[0] = new TGUIButton.Create(new TVec2D.Init(686, 41 + 0*54), null, GetLocale("PLANNER_ADS"), "programmeplanner_buttons")
		ProgrammePlannerButtons[0].spriteName = "gfx_programmeplanner_btn_ads"

		ProgrammePlannerButtons[1] = new TGUIButton.Create(new TVec2D.Init(686, 41 + 1*54), null, GetLocale("PLANNER_PROGRAMME"), "programmeplanner_buttons")
		ProgrammePlannerButtons[1].spriteName = "gfx_programmeplanner_btn_programme"

		ProgrammePlannerButtons[2] = new TGUIButton.Create(new TVec2D.Init(686, 41 + 2*54), null, GetLocale("PLANNER_FINANCES"), "programmeplanner_buttons")
		ProgrammePlannerButtons[2].spriteName = "gfx_programmeplanner_btn_financials"

		ProgrammePlannerButtons[3] = new TGUIButton.Create(new TVec2D.Init(686, 41 + 3*54), null, GetLocale("PLANNER_STATISTICS"), "programmeplanner_buttons")
		ProgrammePlannerButtons[3].spriteName = "gfx_programmeplanner_btn_statistics"

		ProgrammePlannerButtons[4] = new TGUIButton.Create(new TVec2D.Init(686, 41 + 4*54), null, GetLocale("PLANNER_MESSAGES"), "programmeplanner_buttons")
		ProgrammePlannerButtons[4].spriteName = "gfx_programmeplanner_btn_messages"

		ProgrammePlannerButtons[5] = new TGUIButton.Create(new TVec2D.Init(686, 41 + 5*54), null, GetLocale("PLANNER_UNKNOWN"), "programmeplanner_buttons")
		ProgrammePlannerButtons[5].spriteName = "gfx_programmeplanner_btn_unknown"

		for local i:int = 0 to 5
			ProgrammePlannerButtons[i].SetAutoSizeMode(TGUIButton.AUTO_SIZE_MODE_SPRITE, TGUIButton.AUTO_SIZE_MODE_SPRITE)
			ProgrammePlannerButtons[i].caption.SetContentPosition(ALIGN_CENTER, ALIGN_TOP)
			ProgrammePlannerButtons[i].caption.SetFont( GetBitmapFont("Default", 10, BOLDFONT) )

			ProgrammePlannerButtons[i].SetCaptionOffset(0,42)
		Next
	'	TGUILabel.SetTypeFont( null )


		'===== REGISTER EVENTS =====

		'for all office rooms - register if someone goes into the programmeplanner
		local screen:TScreen = ScreenCollection.GetScreen("screen_office_programmeplanner")

		'player enters screen - reset the guilists
		if screen then EventManager.registerListenerFunction("screen.onEnter", onEnterProgrammePlannerScreen, screen)
		'player leaves screen - only without dragged blocks
		EventManager.registerListenerFunction("screen.OnLeave", onLeaveProgrammePlannerScreen, screen)
		'player leaves office forcefully - clean up
		EventManager.registerListenerFunction("figure.onForcefullyLeaveRoom", onForcefullyLeaveRoom)

		'to react on changes in the programmePlan (eg. contract finished)
		EventManager.registerListenerFunction("programmeplan.addObject", onChangeProgrammePlan)
		EventManager.registerListenerFunction("programmeplan.removeObject", onChangeProgrammePlan)
		'also react on "group changes" like removing unneeded adspots
		EventManager.registerListenerFunction("programmeplan.removeObjectInstances", onChangeProgrammePlan)


		'begin drop - to intercept if dropping ad to programme which does not allow Ad-Show
		EventManager.registerListenerFunction("guiobject.onTryDropOnTarget", onTryDropProgrammePlanElement, "TGUIProgrammePlanElement")
		'drag/drop ... from or to one of the two lists
		EventManager.registerListenerFunction("guiList.removeItem", onRemoveItemFromSlotList, GuiListProgrammes)
		EventManager.registerListenerFunction("guiList.removeItem", onRemoveItemFromSlotList, GuiListAdvertisements)
		EventManager.registerListenerFunction("guiList.addItem", onAddItemToSlotList, GuiListProgrammes)
		EventManager.registerListenerFunction("guiList.addItem", onAddItemToSlotList, GuiListAdvertisements)
		'so we can forbid adding to a "past"-slot
		EventManager.registerListenerFunction("guiList.TryAddItem", onTryAddItemToSlotList, GuiListProgrammes)
		EventManager.registerListenerFunction("guiList.TryAddItem", onTryAddItemToSlotList, GuiListAdvertisements)
		'we want to know if we hover a specific block - to show a datasheet
		EventManager.registerListenerFunction("guiGameObject.OnMouseOver", onMouseOverProgrammePlanElement, "TGUIProgrammePlanElement" )
		'these lists want to delete the item if a right mouse click happens...
		EventManager.registerListenerFunction("guiobject.onClick", onClickProgrammePlanElement, "TGUIProgrammePlanElement")
		'handle dragging of dayChangeProgrammePlanElements (eg. when dropping an item on them)
		'in this case - send them to GuiManager (like freshly created to avoid a history)
		EventManager.registerListenerFunction("guiobject.onDrag", onDragProgrammePlanElement, "TGUIProgrammePlanElement")
		'we want to handle drops on the same guilist slot (might be other planning day)
		EventManager.registerListenerFunction("guiobject.onDropBack", onDropProgrammePlanElementBack, "TGUIProgrammePlanElement")

		'intercept dragging items if we want a SHIFT/CTRL-copy/nextepisode
		EventManager.registerListenerFunction("guiobject.onTryDrag", onTryDragProgrammePlanElement, "TGUIProgrammePlanElement")
		'handle dropping at the end of the list (for dragging overlapped items)
		EventManager.registerListenerFunction("programmeplan.addObject", onProgrammePlanAddObject)

		'we want to colorize the list background depending on minute
		'EventManager.registerListenerFunction("Game.OnMinute",	onGameMinute)

		'we are interested in the programmeplanner buttons
		EventManager.registerListenerFunction("guiobject.onClick", onProgrammePlannerButtonClick, "TGUIButton" )


		TRoomHandler._RegisterScreenHandler( onUpdateProgrammePlanner, onDrawProgrammePlanner, ScreenCollection.GetScreen("screen_office_programmeplanner") )

		'===== REGISTER EVENTS =====
		'handle savegame loading (remove old gui elements)
		EventManager.registerListenerFunction("SaveGame.OnBeginLoad", onSaveGameBeginLoad)

		'inform if language changes
		EventManager.registerListenerFunction("Language.onSetLanguage", onSetLanguage)
	End Function


	Function onSetLanguage:int(triggerEvent:TEventBase)
		SetLanguage()
	End Function


	Function SetLanguage()
		'programmeplanner
		if ProgrammePlannerButtons[0]
			ProgrammePlannerButtons[0].SetCaption(GetLocale("PLANNER_ADS"))
			ProgrammePlannerButtons[1].SetCaption(GetLocale("PLANNER_PROGRAMME"))
			ProgrammePlannerButtons[2].SetCaption(GetLocale("PLANNER_FINANCES"))
			ProgrammePlannerButtons[3].SetCaption(GetLocale("PLANNER_IMAGE"))
			ProgrammePlannerButtons[4].SetCaption(GetLocale("PLANNER_MESSAGES"))
			ProgrammePlannerButtons[5].SetCaption(GetLocale("PLANNER_UNKNOWN"))
		endif
	End Function


	Function onSaveGameBeginLoad(triggerEvent:TEventBase)
		'as soon as a savegame gets loaded, we remove every
		'guiElement this room manages
		'Afterwards we force the room to update the gui elements
		'during next update.
		'Not RefreshGUIElements() in this function as the
		'new programmes are not loaded yet
		hoveredGuiProgrammePlanElement = null
		draggedGuiProgrammePlanElement = null

		RemoveAllGuiElements(TRUE)
	End Function
	

	Function IsMyRoom:int(room:TRoomBase)
		For local i:int = 1 to 4
			if room = GetRoomCollection().GetFirstByDetails("office", i) then return True
		Next
		return False
	End Function



	'called as soon as a players figure is forced to leave a room
	Function onForcefullyLeaveRoom:int( triggerEvent:TEventBase )
		'only handle the players figure
		if TFigure(triggerEvent.GetSender()) <> GetPlayerCollection().Get().figure then return False
		'only handle offices
		if not IsMyRoom(TRoomBase(triggerEvent.GetReceiver())) then return False


		'=== PROGRAMMEPLANNER ===
		'close lists
		PPprogrammeList.SetOpen(0)
		PPcontractList.SetOpen(0)

		AbortScreenActions()
	End Function	


	'call this function if the visual user actions need to get
	'aborted
	'clear the screen (remove dragged elements)
	Function AbortScreenActions:Int()
		'=== PROGRAMMEPLANNER ===
		if draggedGuiProgrammePlanElement
			'Try to drop back the element, except it is a freshly
			'created one
			if draggedGuiProgrammePlanElement.inList
				draggedGuiProgrammePlanElement.dropBackToOrigin()
			endif
			'successful or not - get rid of the gui element
			'(if it was a clone with no dropback-possibility this
			'just removes the clone, no worries)
			draggedGuiProgrammePlanElement = null
			hoveredGuiProgrammePlanElement = null
		endif

		'Try to drop back dragged elements
		For local obj:TGUIProgrammePlanElement = eachIn GuiManager.ListDragged
			obj.dropBackToOrigin()
			'successful or not - get rid of the gui element
			obj.Remove()
		Next

		'=== STATIONMAP ===
		'...

		'=== IMAGE SCREEN ===
		'...

		'...
	End Function


	Function RefreshHoveredProgrammePlanElement:int()
		For local guiObject:TGuiProgrammePlanElement = eachin GuiListProgrammes._slots
			if guiObject.isDragged() or guiObject.mouseOver
				hoveredGuiProgrammePlanElement = guiObject
				return True
			endif
		Next
		For local guiObject:TGuiProgrammePlanElement = eachin GuiListAdvertisements._slots
			if guiObject.isDragged() or guiObject.mouseOver
				hoveredGuiProgrammePlanElement = guiObject
				return True
			endif
		Next
		For local guiObject:TGuiProgrammePlanElement = eachin GuiManager.ListDragged
			if guiObject.isDragged() or guiObject.mouseOver
				hoveredGuiProgrammePlanElement = guiObject
				return True
			endif
		Next
		return False
	End Function


	'=== EVENTS ===

	'clear the guilist if a player enters
	'screens are only handled by real players
	Function onEnterProgrammePlannerScreen:int(triggerEvent:TEventBase)
		'==== EMPTY/DELETE GUI-ELEMENTS =====
		hoveredGuiProgrammePlanElement = null
		draggedGuiProgrammePlanElement = null

		'remove all entries
		RemoveAllGuiElements(true)
		RefreshGUIElements()

		'=== INITIALIZE VIEW ===
		'set the planning day to the current one
		ChangePlanningDay(GetWorldTime().GetDay())
	End Function


	Function onLeaveProgrammePlannerScreen:int( triggerEvent:TEventBase )
		'do not allow leaving with a list open
		if PPprogrammeList.enabled Or PPcontractList.enabled
			PPprogrammeList.SetOpen(0)
			PPcontractList.SetOpen(0)
			triggerEvent.SetVeto()
			return FALSE
		endif

		'do not allow leaving as long as we have a dragged block
		if draggedGuiProgrammePlanElement
			triggerEvent.setVeto()
			return FALSE
		endif


		if openedProgrammeListThisVisit
			GetPlayerCollection().Get().GetProgrammeCollection().ClearJustAddedProgrammeLicences()
		endif

		return TRUE
	End Function	


	'if players are in the office during changes
	'to their programme plan, react to...
	Function onChangeProgrammePlan:int( triggerEvent:TEventBase )
		if not TRoomHandler.CheckPlayerInRoom("office") then return FALSE

		'is it our plan?
		local plan:TPlayerProgrammePlan = TPlayerProgrammePlan(triggerEvent.GetSender())
		if not plan then return FALSE
		if plan.owner <> GetPlayerCollection().playerID then return FALSE

		'recreate gui elements
		RefreshGuiElements()
		'refetch the hovered element (if there was one before)
		'so it can get drawn correctly in the render calls until the
		'next update call would fetch the hovered item again
		FindHoveredPlanElement()
	End Function


	'handle dragging dayChange elements (give them to GuiManager)
	'this way the newly dragged item is kind of a "newly" created
	'item without history of a former slot etc.
	Function onDragProgrammePlanElement:int(triggerEvent:TEventBase)
		local item:TGUIProgrammePlanElement = TGUIProgrammePlanElement(triggerEvent.GetSender())
		if not item then return FALSE

		'check if we somehow dragged a dayChange element
		'if so : remove it from the list and let the GuiManager manage it
		if item = GuiListProgrammes.dayChangeGuiProgrammePlanElement
			GuiManager.AddDragged(GuiListProgrammes.dayChangeGuiProgrammePlanElement)
			GuiListProgrammes.dayChangeGuiProgrammePlanElement = null
			return TRUE
		endif
		if item = GuiListAdvertisements.dayChangeGuiProgrammePlanElement
			GuiManager.AddDragged(GuiListAdvertisements.dayChangeGuiProgrammePlanElement)
			GuiListAdvertisements.dayChangeGuiProgrammePlanElement = null
			return TRUE
		endif
		return FALSE
	End Function


	Function onTryDragProgrammePlanElement:int(triggerEvent:TEventBase)
		local item:TGUIProgrammePlanElement = TGUIProgrammePlanElement(triggerEvent.GetSender())
		if not item then return FALSE

		if CreateNextEpisodeOrCopyByShortcut(item)
			triggerEvent.SetVeto()
			return FALSE
		endif

		'dragging is ok
		return TRUE
	End Function


	'handle adding items at the end of a day
	'so the removed material can be recreated as dragged gui items
	Function onProgrammePlanAddObject:int(triggerEvent:TEventBase)
		local removedObjects:object[] = object[](triggerEvent.GetData().get("removedObjects"))
		local addedObject:TBroadcastMaterial = TBroadcastMaterial(triggerEvent.GetData().get("object"))
		if not removedObjects then return FALSE
		if not addedObject then return FALSE
		'also not interested if the programme ends before midnight
		if addedObject.programmedHour + addedObject.getBlocks() <= 24 then return FALSE

		'create new gui items for all removed ones
		'this also includes todays programmes:
		'ex: added 5block to 21:00 - removed programme from 23:00-24:00 gets added again too
		for local i:int = 0 to removedObjects.length-1
			local material:TBroadcastMaterial = TBroadcastMaterial(removedObjects[i])
			if material then new TGUIProgrammePlanElement.CreateWithBroadcastMaterial(material, "programmePlanner").drag()
		Next
		return FALSE
	End Function


	'intercept if item does not allow dropping on specific lists
	'eg. certain ads as programme if they do not allow no commercial shows
	Function onTryDropProgrammePlanElement:int(triggerEvent:TEventBase)
		local item:TGUIProgrammePlanElement = TGUIProgrammePlanElement(triggerEvent.GetSender())
		if not item then return FALSE
		
		local list:TGUIProgrammePlanSlotList = TGUIProgrammePlanSlotList(triggerEvent.GetReceiver())
		if not list then return FALSE

		'check if that item is allowed to get dropped on such a list

		'up to now: all are allowed
		return TRUE
	End Function


	Function onTryDropProgrammePlanElementOnDayButton:int(triggerEvent:TEventBase)
		local item:TGUIProgrammePlanElement = TGUIProgrammePlanElement(triggerEvent.GetSender())
		if not item then return FALSE

		'dropping on daychangebuttons means trying to change the day
		'while elements are dragged
		if plannerPreviousDayButton = triggerEvent.GetReceiver()
			triggerEvent.SetVeto()

			ChangePlanningDay(planningDay-1)
			'reset mousebutton
			MouseManager.ResetKey(1)

			return False
		elseif plannerNextDayButton = triggerEvent.GetReceiver()
			triggerEvent.SetVeto()

			ChangePlanningDay(planningDay+1)
			'reset mousebutton
			MouseManager.ResetKey(1)

			return False
		endif
	End Function
	

	'remove the material from the programme plan
	Function onRemoveItemFromSlotList:int(triggerEvent:TEventBase)
		local list:TGUIProgrammePlanSlotList = TGUIProgrammePlanSlotList(triggerEvent.GetSender())
		local item:TGUIProgrammePlanElement = TGUIProgrammePlanElement(triggerEvent.GetData().get("item"))
		local slot:int = triggerEvent.GetData().getInt("slot", -1)

		if not list or not item or slot = -1 then return FALSE

		'we removed the item but do not want the planner to know
		if not talkToProgrammePlanner then return TRUE

		if list = GuiListProgrammes
			if not GetPlayerCollection().Get().GetProgrammePlan().RemoveProgramme(item.broadcastMaterial)
				print "[WARNING] dragged item from programmelist - removing from programmeplan at "+slot+":00 - FAILED"
			endif
		elseif list = GuiListAdvertisements
			if not GetPlayerCollection().Get().GetProgrammePlan().RemoveAdvertisement(item.broadcastMaterial)
				print "[WARNING] dragged item from adlist - removing from programmeplan at "+slot+":00 - FAILED"
			endif
		else
			print "[ERROR] dragged item from unknown list - removing from programmeplan at "+slot+":00 - FAILED"
		endif


		return TRUE
	End Function


	'handle if a programme is dropped on the same slot but different
	'planning day
	Function onDropProgrammePlanElementBack:int(triggerEvent:TEventBase)
		local list:TGUIProgrammePlanSlotList = TGUIProgrammePlanSlotList(triggerEvent.GetReceiver())
		local item:TGUIProgrammePlanElement = TGUIProgrammePlanElement(triggerEvent.GetSender())

		'is the gui item coming from another day?
		'remove it from there (was "silenced" during automatic mode)
		if List = GuiListProgrammes or list = GuiListAdvertisements
			if item.plannedOnDay >= 0 and item.plannedOnDay <> list.planDay
				if item.lastList = GuiListAdvertisements
					if not GetPlayerCollection().Get().GetProgrammePlan().RemoveAdvertisement(item.broadcastMaterial)
						print "[ERROR] dropped item from another day on active day - removal in other days adlist FAILED"
						return False
					Endif
				ElseIf item.lastList = GuiListProgrammes
					if not GetPlayerCollection().Get().GetProgrammePlan().RemoveProgramme(item.broadcastMaterial)
						print "[ERROR] dropped item from another day on active day - removal in other days programmelist FAILED"
						return False
					Endif
				Endif
			Endif
		EndIf

	End Function

	'add the material to the programme plan
	'added shortcuts for faster placement here as this event
	'is emitted on successful placements (avoids multiple dragged blocks
	'while dropping not possible)
	Function onAddItemToSlotList:int(triggerEvent:TEventBase)
		local list:TGUIProgrammePlanSlotList = TGUIProgrammePlanSlotList(triggerEvent.GetSender())
		local item:TGUIProgrammePlanElement = TGUIProgrammePlanElement(triggerEvent.GetData().get("item"))
		local slot:int = triggerEvent.GetData().getInt("slot", -1)
		if not list or not item or slot = -1 then return FALSE

		'we removed the item but do not want the planner to know
		if not talkToProgrammePlanner then return TRUE


		'is the gui item coming from another day?
		'remove it from there (was "silenced" during automatic mode)
		if List = GuiListProgrammes or list = GuiListAdvertisements
			if item.plannedOnDay >= 0 and item.plannedOnDay <> list.planDay
				if item.lastList = GuiListAdvertisements
					if not GetPlayerCollection().Get().GetProgrammePlan().RemoveAdvertisement(item.broadcastMaterial)
						print "[ERROR] dropped item from another day on active day - removal in other days adlist FAILED"
						return False
					Endif
				ElseIf item.lastList = GuiListProgrammes
					if not GetPlayerCollection().Get().GetProgrammePlan().RemoveProgramme(item.broadcastMaterial)
						print "[ERROR] dropped item from another day on active day - removal in other days programmelist FAILED"
						return False
					Endif
				Endif
			Endif
		EndIf


		if list = GuiListProgrammes
			'is the gui item coming from another day?
			'remove it from there (was "silenced" during automatic mode)
			if item.plannedOnDay >= 0 and item.plannedOnDay <> list.planDay
				if not GetPlayerCollection().Get().GetProgrammePlan().RemoveProgramme(item.broadcastMaterial)
					print "[ERROR] dropped item on programmelist - removal from other day FAILED"
					return False
				endif
			Endif

			if not GetPlayerCollection().Get().GetProgrammePlan().SetProgrammeSlot(item.broadcastMaterial, planningDay, slot)
				print "[WARNING] dropped item on programmelist - adding to programmeplan at "+slot+":00 - FAILED"
				return FALSE
			endif
			'set indicator on which day the item is planned
			'  (this saves some processing time - else we could request
			'   the day from the players ProgrammePlan)
			item.plannedOnDay = list.planDay
		elseif list = GuiListAdvertisements
			if not GetPlayerCollection().Get().GetProgrammePlan().SetAdvertisementSlot(item.broadcastMaterial, planningDay, slot)
				print "[WARNING] dropped item on adlist - adding to programmeplan at "+slot+":00 - FAILED"
				return FALSE
			endif
			'set indicator on which day the item is planned
			'  (this saves some processing time - else we could request
			'   the day from the players ProgrammePlan)
			item.plannedOnDay = list.planDay
		else
			print "[ERROR] dropped item on unknown list - adding to programmeplan at "+slot+":00 - FAILED"
			return FALSE
		endif

		'if a shortcut is pressed - create copy/next episode
		'CreateNextEpisodeOrCopyByShortcut(item)

		return TRUE
	End Function


	'checks if it is allowed to occupy the the targeted slot (eg. slot lies in the past)
	Function onTryAddItemToSlotList:int(triggerEvent:TEventBase)
		local list:TGUIProgrammePlanSlotList = TGUIProgrammePlanSlotList(triggerEvent.GetSender())
		local item:TGUIProgrammePlanElement = TGUIProgrammePlanElement(triggerEvent.GetData().get("item"))
		local slot:int = triggerEvent.GetData().getInt("slot", -1)
		if not list or not item or slot = -1 then return FALSE

		'only check slot state if interacting with the programme planner
		if talkToProgrammePlanner
			'already running or in the past
			if list.GetSlotState(slot) = 2
				triggerEvent.SetVeto()
				return FALSE
			endif
		endif
		return TRUE
	End Function


	'right mouse button click: remove the block from the player's programmePlan
	'left mouse button click: check shortcuts and create a copy/nextepisode-block
	Function onClickProgrammePlanElement:int(triggerEvent:TEventBase)
		local item:TGUIProgrammePlanElement= TGUIProgrammePlanElement(triggerEvent._sender)
		if not item then print "onClickProgrammePlanElement got wrong sender";return false

		'left mouse button
		if triggerEvent.GetData().getInt("button",0) = 1
			'special handling for special items
			'-> remove dayChangeObjects from plan if dragging (and allowed)
			if not item.isDragged() and item.isDragable() and talkToProgrammePlanner
				if item = GuiListAdvertisements.dayChangeGuiProgrammePlanElement
					if GetPlayerCollection().Get().GetProgrammePlan().RemoveAdvertisement(item.broadcastMaterial)
						GuiListAdvertisements.dayChangeGuiProgrammePlanElement = null
					endif
				elseif item = GuiListProgrammes.dayChangeGuiProgrammePlanElement
					if GetPlayerCollection().Get().GetProgrammePlan().RemoveProgramme(item.broadcastMaterial)
						GuiLisTProgrammes.dayChangeGuiProgrammePlanElement = null
					endif
				endif
			endif


			'if shortcut is used on a dragged item ... it gets executed
			'on a successful drop, no need to do it here before
			if item.isDragged() then return FALSE

			'assisting shortcuts create new guiobjects
			if CreateNextEpisodeOrCopyByShortcut(item)
				'do not try to drag the object - we did something special
				triggerEvent.SetVeto()
				return FALSE
			endif

			return TRUE
		endif

		'right mouse button - delete
		if triggerEvent.GetData().getInt("button",0) = 2
			'ignore wrong types and NON-dragged items
			if not item.isDragged() then return FALSE

			'remove if special
			if item = GuiListAdvertisements.dayChangeGuiProgrammePlanElement then GuiListAdvertisements.dayChangeGuiProgrammePlanElement = null
			if item = GuiListProgrammes.dayChangeGuiProgrammePlanElement then GuiListProgrammes.dayChangeGuiProgrammePlanElement = null

			'will automatically rebuild at correct spot if needed
			item.remove()
			item = null

			'remove right click - to avoid leaving the room
			MouseManager.ResetKey(2)
		endif
	End Function


	Function onMouseOverProgrammePlanElement:int(triggerEvent:TEventBase)
		local item:TGUIProgrammePlanElement = TGUIProgrammePlanElement(triggerEvent.GetSender())
		if not item then return FALSE

		'only assign the first hovered item (to avoid having the lowest of a stack)
		if not hoveredGuiProgrammePlanElement
			hoveredGuiProgrammePlanElement = item
			TGUIProgrammePlanElement.hoveredElement = item

			if item.isDragged()
				draggedGuiProgrammePlanElement = item
				'if we have an item dragged... we cannot have a menu open
				PPprogrammeList.SetOpen(0)
				PPcontractList.SetOpen(0)
			endif
		endif

		return TRUE
	End Function


	Function onDrawProgrammePlanner:int( triggerEvent:TEventBase )
		'local screen:TScreen	= TScreen(triggerEvent._sender)
		local room:TRoom		= TRoom( triggerEvent.GetData().get("room") )
		if not room then return 0

		GUIManager.Draw("programmeplanner",,, GUIMANAGER_TYPES_NONDRAGGED)

		'overlay old days
		If GetWorldTime().getDay() > planningDay
			SetColor 100,100,100
			SetAlpha 0.5
			DrawRect(5,5,675,400)
			SetColor 255,255,255
			SetAlpha 1.0
		EndIf


		GetSpriteFromRegistry("screen_programmeplanner_overlay").Draw(0,0)

		'time indicator
		If planningDay = GetWorldTime().getDay() Then SetColor 0,100,0
		If planningDay < GetWorldTime().getDay() Then SetColor 100,100,0
		If planningDay > GetWorldTime().getDay() Then SetColor 0,0,0
		local day:int = 1+ planningDay - GetWorldTime().getDay(GetWorldTime().GetTimeStart())
		'GetBitmapFont("default", 11).drawBlock(day+". "+GetLocale("DAY")+"~n"+GetWorldTime().GetFormattedDayLong(day),712, 6, 56, 30, ALIGN_CENTER_CENTER)
		GetBitmapFont("default", 11).drawBlock(day+". "+GetLocale("DAY"),712, 7, 56, 26, ALIGN_CENTER_TOP)
		GetBitmapFont("default", 10).drawBlock(GetWorldTime().GetFormattedDayLong(day),712, 7, 56, 26, ALIGN_CENTER_BOTTOM)
		SetColor 255,255,255

		GUIManager.Draw("programmeplanner_buttons",,, GUIMANAGER_TYPES_NONDRAGGED)
		GUIManager.Draw("programmeplanner|programmeplanner_buttons",,, GUIMANAGER_TYPES_DRAGGED)


		SetColor 255,255,255
		If room.owner = GetPlayerCollection().playerID
			If PPprogrammeList.GetOpen() > 0
				PPprogrammeList.Draw()
				openedProgrammeListThisVisit = True
			endif
			If PPcontractList.GetOpen() > 0 Then PPcontractList.Draw()
			'draw lists sheet
			If PPprogrammeList.GetOpen() and PPprogrammeList.hoveredLicence
				PPprogrammeList.hoveredLicence.ShowSheet(30,20)
			endif
			'If PPcontractList.GetOpen() and
			if PPcontractList.hoveredAdContract
				PPcontractList.hoveredAdContract.ShowSheet(30,20)
			endif
		EndIf

		'if not hoveredGuiProgrammePlanElement then RefreshHoveredProgrammePlanElement()
		if hoveredGuiProgrammePlanElement
			'draw the current sheet
			hoveredGuiProgrammePlanElement.DrawSheet(30, 35, 700)
		endif


		local oldAlpha:Float = GetAlpha()
		if showPlannerShortCutHintTime > 0
			SetAlpha Min(1.0, 2.0*showPlannerShortCutHintTime/100.0)
			GetBitmapFont("Default", 11, BOLDFONT).drawBlock(GetLocale("HINT_PROGRAMMEPLANER_SHORTCUTS"), 3, 368, 660, 15, new TVec2D.Init(ALIGN_CENTER), TColor.CreateGrey(75),2,1,0.20)
		endif

		local pulse:Float = Sin(Time.GetTimeGone() / 10)
		SetAlpha Max(0.75, -pulse) * oldAlpha
		DrawOval(5+pulse,367+pulse,15-2*pulse,15-2*pulse)
		SetAlpha oldAlpha
		GetBitmapFont("Default", 20, BOLDFONT).drawStyled("?", 7, 367, TColor.Create(50,50,150),2,1,0.25)
	End Function


	Function onUpdateProgrammePlanner:int( triggerEvent:TEventBase )
		'local screen:TScreen	= TScreen(triggerEvent._sender)
		local room:TRoom		= TRoom( triggerEvent.GetData().get("room") )
		if not room then return 0

		'if not initialized, do so
		if planningDay = -1 then planningDay = GetWorldTime().getDay()


		'if we have a licence dragged ... we should take care of "ESC"-Key
		if KeyManager.IsHit(KEY_ESCAPE) then AbortScreenActions()

		Game.cursorstate = 0

		'set all slots occupied or not
		local day:int = GetWorldTime().getDay()
		local hour:int = GetWorldTime().GetDayHour()
		local minute:int = GetWorldTime().GetDayMinute()
		for local i:int = 0 to 23
			if not TPlayerProgrammePlan.IsUseableTimeSlot(TBroadcastMaterial.TYPE_PROGRAMME, planningDay, i, day, hour, minute)
				GuiListProgrammes.SetSlotState(i, 2)
			else
				GuiListProgrammes.SetSlotState(i, 0)
			endif
			if not TPlayerProgrammePlan.IsUseableTimeSlot(TBroadcastMaterial.TYPE_ADVERTISEMENT, planningDay, i, day, hour, minute)
				GuiListAdvertisements.SetSlotState(i, 2)
			else
				GuiListAdvertisements.SetSlotState(i, 0)
			endif
		Next

		'delete unused and create new gui elements
		if haveToRefreshGuiElements
				RefreshGuiElements()
				'reassign a potential hovered/dragged element
				FindHoveredPlanElement()
		endif

		if planningDay-1 < GetWorldTime().getDay(GetWorldTime().GetTimeStart())
			plannerPreviousDayButton.disable()
		else
			plannerPreviousDayButton.enable()
		endif
		

		'reset hovered and dragged gui objects - gets repopulated automagically
		hoveredGuiProgrammePlanElement = null
		draggedGuiProgrammePlanElement = null
		TGUIProgrammePlanElement.hoveredElement = null

		'RON
		'fast movement is possible with keys
		'we use doAction as this allows a decreasing time
		'while keeping the original interval backupped
		if fastNavigateTimer.isExpired()
			if not KEYMANAGER.isDown(KEY_PAGEUP) and not KEYMANAGER.isDown(KEY_PAGEDOWN)
				fastNavigationUsedContinuously = FALSE
			endif
			if KEYMANAGER.isDown(KEY_PAGEUP)
				ChangePlanningDay(planningDay-1)
				fastNavigationUsedContinuously = TRUE
			endif
			if KEYMANAGER.isDown(KEY_PAGEDOWN)
				ChangePlanningDay(planningDay+1)
				fastNavigationUsedContinuously = TRUE
			endif

			'modify action time AND reset timer
			if fastNavigationUsedContinuously
				'decrease action time each time a bit more...
				fastNavigateTimer.setInterval( Max(50, fastNavigateTimer.GetInterval() * 0.9), true )
			else
				'set to initial value
				fastNavigateTimer.setInterval( fastNavigateInitialTimer, true )
			endif
		endif


		local listsOpened:int = (PPprogrammeList.enabled Or PPcontractList.enabled)
		'only handly programmeblocks if the lists are closed
		'else you will end up with nearly no space on the screen not showing
		'a licence sheet.
		if not listsOpened
			GUIManager.Update("programmeplanner|programmeplanner_buttons")
		'if a list is opened, we cannot have a hovered gui element
		else
			hoveredGuiProgrammePlanElement = null
			'but still have to check for clicks on the buttons
			GUIManager.Update("programmeplanner_buttons")
		endif


		If room.owner = GetPlayerCollection().playerID
			PPprogrammeList.Update()
			PPcontractList.Update()
		EndIf

		'hide or show help
		If THelper.IsIn(MouseManager.x, MouseManager.y, 0,365,20,20)
			showPlannerShortCutHintTime = 90
			showPlannerShortCutHintFadeAmount = 1
		else
			showPlannerShortCutHintTime = Max(showPlannerShortCutHintTime-showPlannerShortCutHintFadeAmount, 0)
			showPlannerShortCutHintFadeAmount:+1
		endif
	End Function


	Function onProgrammePlannerButtonClick:int( triggerEvent:TEventBase )
		local button:TGUIButton = TGUIButton( triggerEvent._sender )
		if not button then return 0

		'only react if the click came from the left mouse button
		if triggerEvent.GetData().getInt("button",0) <> 1 then return TRUE


		if button = plannerNextDayButton
			ChangePlanningDay(planningDay+1)
			'reset mousebutton
			MouseManager.ResetKey(1)
			return True
		elseif button = plannerPreviousDayButton
			ChangePlanningDay(planningDay-1)
			'reset mousebutton
			MouseManager.ResetKey(1)
			return True
		endif
			


		'close both lists
		PPcontractList.SetOpen(0)
		PPprogrammeList.SetOpen(0)

		'reset mousebutton
		MouseManager.ResetKey(1)

		'open others?
		If button = ProgrammePlannerButtons[0] Then return PPcontractList.SetOpen(1)		'opens contract list
		If button = ProgrammePlannerButtons[1] Then return PPprogrammeList.SetOpen(1)		'opens programme genre list

		If button = ProgrammePlannerButtons[2] then return ScreenCollection.GoToSubScreen("screen_office_financials")
		If button = ProgrammePlannerButtons[3] then return ScreenCollection.GoToSubScreen("screen_office_statistics")
		'If button = ProgrammePlannerButtons[4] then return ScreenCollection.GoToSubScreen("screen_office_messages")
		'If button = ProgrammePlannerButtons[5] then return ScreenCollection.GoToSubScreen("screen_office_unknown")
	End Function


	'=== COMMON FUNCTIONS / HELPERS ===


	Function CreateNextEpisodeOrCopyByShortcut:int(item:TGUIProgrammePlanElement)
		if not item then return FALSE
		'only react to items which got freshly created
		if not item.inList then return FALSE

		'assisting shortcuts create new guiobjects
		'shift: next episode
		'ctrl : programme again
		if KEYMANAGER.IsDown(KEY_LSHIFT) OR KEYMANAGER.IsDown(KEY_RSHIFT)
			'reset key
			KEYMANAGER.ResetKey(KEY_LSHIFT)
			KEYMANAGER.ResetKey(KEY_RSHIFT)
			CreateNextEpisodeOrCopy(item, FALSE)
			return TRUE
		elseif KEYMANAGER.IsDown(KEY_LCONTROL) OR KEYMANAGER.IsDown(KEY_RCONTROL)
			KEYMANAGER.ResetKey(KEY_LCONTROL)
			KEYMANAGER.ResetKey(KEY_RCONTROL)
			CreateNextEpisodeOrCopy(item, TRUE)
			return TRUE
		endif
		'nothing clicked
		return FALSE
	End Function


	Function CreateNextEpisodeOrCopy:int(item:TGUIProgrammePlanElement, createCopy:int=TRUE)
		local newMaterial:TBroadcastMaterial = null

		'copy:         for ads and programmes create a new object based
		'              on licence or contract
		'next episode: for ads: create a copy
		'              for movies and series: rely on a licence-function
		'              which returns the next licence of a series/collection
		'              OR the first one if already on the latest spot

		select item.broadcastMaterial.materialType
			case TBroadcastMaterial.TYPE_ADVERTISEMENT
				newMaterial = new TAdvertisement.Create(TAdvertisement(item.broadcastMaterial).contract)

			case TBroadcastMaterial.TYPE_PROGRAMME
				if CreateCopy
					newMaterial = new TProgramme.Create(TProgramme(item.broadcastMaterial).licence)
				else
					local licence:TProgrammeLicence = TProgramme(item.broadcastMaterial).licence.GetNextSubLicence()
					'if no licence was given, the licence is for a normal movie...
					if not licence then licence = TProgramme(item.broadcastMaterial).licence
					newMaterial = new TProgramme.Create(licence)
				endif
		end select

		'create and drag
		if newMaterial
			local guiObject:TGUIProgrammePlanElement = new TGUIProgrammePlanElement.CreateWithBroadcastMaterial(newMaterial, "programmePlanner")
			guiObject.drag()
			'remove position backup so a "dropback" does not work, and
			'the item does not drop back to "0,0"
			guiObject.positionBackup = null
		endif
	End Function


	Function ChangePlanningDay:int(day:int=0)
		planningDay = day
		'limit to start day
		If planningDay < GetWorldTime().getDay(GetWorldTime().GetTimeStart()) Then planningDay = GetWorldTime().getDay(GetWorldTime().GetTimeStart())

		'adjust slotlists (to hide ghosts on differing days)
		GuiListProgrammes.planDay = planningDay
		GuiListAdvertisements.planDay = planningDay

		'FALSE: without removing dragged
		'->ONLY keeps newly created, not ones dragged from a slot
		RemoveAllGuiElements(FALSE)

		RefreshGuiElements()
		FindHoveredPlanElement()
	end Function


	'deletes all gui elements (eg. for rebuilding)
	Function RemoveAllGuiElements:int(removeDragged:int=TRUE)
		'do not inform programmeplanner!
		local oldTalk:int =	talkToProgrammePlanner
		talkToProgrammePlanner = False

'		Rem
'			this is problematic as this could bug out the programmePlan
		'keep the dragged entries if wanted so
		For local guiObject:TGuiProgrammePlanElement = eachin GuiListProgrammes._slots
			if not guiObject then continue
			if removeDragged or not guiObject.IsDragged()
				guiObject.remove()
				guiObject = null
			endif
		Next
		For local guiObject:TGuiProgrammePlanElement = eachin GuiListAdvertisements._slots
			if not guiObject then continue
			if removeDragged or not guiObject.IsDragged()
				guiObject.remove()
				guiObject = null
			endif
		Next
'		End Rem

		'remove dragged ones of gui manager
		if removeDragged
			For local guiObject:TGuiProgrammePlanElement = eachin GuiManager.listDragged
				guiObject.remove()
				guiObject = null
			Next
		endif

		'to recreate everything during next update...
		haveToRefreshGuiElements = TRUE

		'set to backupped value
		talkToProgrammePlanner = oldTalk
	End Function


	Function FindHoveredPlanElement:int()
'		hoveredGuiProgrammePlanElement = Null

		local obj:TGUIProgrammePlanElement
		For obj = eachin GuiManager.ListDragged
			if obj.containsXY(MouseManager.x, MouseManager.y)
				hoveredGuiProgrammePlanElement = obj
				return True
			endif
		Next
		For obj = eachin GuiListProgrammes._slots
			if obj.containsXY(MouseManager.x, MouseManager.y)
				hoveredGuiProgrammePlanElement = obj
				return True
			endif
		Next
		For obj = eachin GuiListAdvertisements._slots
			if obj.containsXY(MouseManager.x, MouseManager.y)
				hoveredGuiProgrammePlanElement = obj
				return True
			endif
		Next
	End Function


	Function RefreshGuiElements:int()
		'do not inform programmeplanner!
		local oldTalk:int =	talkToProgrammePlanner
		talkToProgrammePlanner = False

		'===== REMOVE UNUSED =====
		 
		'remove overnight
		if GuiListProgrammes.daychangeGuiProgrammePlanElement
			GuiListProgrammes.daychangeGuiProgrammePlanElement.remove()
			GuiListProgrammes.daychangeGuiProgrammePlanElement = null
		endif
		if GuiListAdvertisements.daychangeGuiProgrammePlanElement
			GuiListAdvertisements.daychangeGuiProgrammePlanElement.remove()
			GuiListAdvertisements.daychangeGuiProgrammePlanElement = null
		endif

		local currDay:int = planningDay
		if currDay = -1 then currDay = GetWorldTime().getDay()

		
		For local guiObject:TGuiProgrammePlanElement = eachin GuiListProgrammes._slots
			if guiObject.isDragged() then continue
			'check if programmed on the current day
			if guiObject.broadcastMaterial.isProgrammedForDay(currDay) then continue
			'print "GuiListProgramme has obsolete programme: "+guiObject.broadcastMaterial.GetTitle()
			guiObject.remove()
			guiObject = null
		Next
		For local guiObject:TGuiProgrammePlanElement = eachin GuiListAdvertisements._slots
			if guiObject.isDragged() then continue
			'check if programmed on the current day
			if guiObject.broadcastMaterial.isProgrammedForDay(currDay) then continue
			'print "GuiListAdvertisement has obsolete ad: "+guiObject.broadcastMaterial.GetTitle()
			guiObject.remove()
			guiObject = null
		Next


		'===== CREATE NEW =====
		'create missing gui elements for all programmes/ads
		local daysProgramme:TBroadcastMaterial[] = GetPlayerCollection().Get().GetProgrammePlan().GetProgrammesInTimeSpan(planningDay, 0, planningDay, 23)
		For local obj:TBroadcastMaterial = eachin daysProgramme
			if not obj then continue
			'if already included - skip it
			if GuiListProgrammes.ContainsBroadcastMaterial(obj) then continue
			
			'DAYCHANGE
			'skip programmes started yesterday (they are stored individually)
			if obj.programmedDay < planningDay and planningDay > 0
				'set to the obj still running at the begin of the planning day
				GuiListProgrammes.SetDayChangeBroadcastMaterial(obj, planningDay)
				continue
			endif

			'DRAGGED
			'check if we find it in the GuiManagers list of dragged items
			local foundInDragged:int = FALSE
			for local draggedGuiProgrammePlanElement:TGUIProgrammePlanElement = eachin GuiManager.ListDragged
				if draggedGuiProgrammePlanElement.broadcastMaterial = obj
					foundInDragged = TRUE
					continue
				endif
			Next
			if foundInDragged then continue

			'NORMAL MISSING
			if GuiListProgrammes.getFreeSlot() < 0
				print "[ERROR] ProgrammePlanner: should add programme but no empty slot left"
				continue
			endif

			local block:TGUIProgrammePlanElement = new TGUIProgrammePlanElement.CreateWithBroadcastMaterial(obj)
			'print "ADD GuiListProgramme - missed new programme: "+obj.GetTitle() +" -> created block:"+block._id

			if not GuiListProgrammes.addItem(block, string(obj.programmedHour))
				print "ADD ERROR - could not add programme"
			else
				'set value so a dropped block will get the correct ghost image
				block.lastListType = GuiListProgrammes.isType
			endif
		Next


		'ad list (can contain ads, programmes, ...)
		local daysAdvertisements:TBroadcastMaterial[] = GetPlayerCollection().Get().GetProgrammePlan().GetAdvertisementsInTimeSpan(planningDay, 0, planningDay, 23)
		For local obj:TBroadcastMaterial = eachin daysAdvertisements
			if not obj then continue

			'if already included - skip it
			if GuiListAdvertisements.ContainsBroadcastMaterial(obj) then continue

			'DAYCHANGE
			'skip programmes started yesterday (they are stored individually)
			if obj.programmedDay < planningDay and planningDay > 0
				'set to the obj still running at the begin of the planning day
				GuiListProgrammes.SetDayChangeBroadcastMaterial(obj, planningDay)
				continue
			endif

			'DRAGGED
			'check if we find it in the GuiManagers list of dragged items
			local foundInDragged:int = FALSE
			for local draggedGuiProgrammePlanElement:TGUIProgrammePlanElement = eachin GuiManager.ListDragged
				if draggedGuiProgrammePlanElement.broadcastMaterial = obj
					foundInDragged = TRUE
					continue
				endif
			Next
			if foundInDragged then continue

			'NORMAL MISSING
			if GuiListAdvertisements.getFreeSlot() < 0
				print "[ERROR] ProgrammePlanner: should add advertisement but no empty slot left"
				continue
			endif

			local block:TGUIProgrammePlanElement = new TGUIProgrammePlanElement.CreateWithBroadcastMaterial(obj, "programmePlanner")
			'print "ADD GuiListAdvertisements - missed new advertisement: "+obj.GetTitle()

			if not GuiListAdvertisements.addItem(block, string(obj.programmedHour))
				print "ADD ERROR - could not add advertisement"
			endif
		Next


		haveToRefreshGuiElements = FALSE

		'set to backupped value
		talkToProgrammePlanner = oldTalk
	End Function


	'add gfx to background
	Function InitProgrammePlannerBackground:int()
		Local roomImg:TImage				= GetSpriteFromRegistry("screen_bg_programmeplanner").parent.image
		Local Pix:TPixmap					= LockImage(roomImg)
		Local gfx_ProgrammeBlock1:TImage	= GetSpriteFromRegistry("pp_programmeblock1").GetImage()
		Local gfx_AdBlock1:TImage			= GetSpriteFromRegistry("pp_adblock1").GetImage()

		'block"shade" on bg
		local shadeColor:TColor = TColor.CreateGrey(200, 0.3)
		For Local j:Int = 0 To 11
			DrawImageOnImage(gfx_Programmeblock1, Pix, 45, 5 + j * 30, shadeColor)
			DrawImageOnImage(gfx_Programmeblock1, Pix, 380, 5 + j * 30, shadeColor)
			DrawImageOnImage(gfx_Adblock1, Pix, 45 + ImageWidth(gfx_Programmeblock1), 5 + j * 30, shadeColor)
			DrawImageOnImage(gfx_Adblock1, Pix, 380 + ImageWidth(gfx_Programmeblock1), 5 + j * 30, shadeColor)
		Next


		'set target for font
		TBitmapFont.setRenderTarget(roomImg)

		local fontColor:TColor = TColor.CreateGrey(240)

		SetAlpha 0.75
rem
		For Local i:Int = 0 To 11
			'right side
			GetBitmapFontManager().baseFontBold.DrawBlock( (i + 12) + ":00", 341, 5 + i * 30, 39, 30, ALIGN_CENTER_CENTER, fontColor, 2,1,0.25)
			'left side
			local text:string = i + ":00"
			If i < 10 then text = "0" + text
			GetBitmapFontManager().baseFontBold.DrawBlock( text, 6, 5 + i * 30, 39, 30, ALIGN_CENTER_CENTER, fontColor, 2,1,0.25)
		Next
endrem
		'only hour, not hour:00
		For Local i:Int = 0 To 11
			'right side
			GetBitmapFontManager().baseFontBold.DrawBlock( (i + 12), 341, 5 + i * 30, 39, 30, ALIGN_CENTER_CENTER, fontColor, 2,1,0.25)
			'left side
			local text:string = i
			If i < 10 then text = "0" + text
			GetBitmapFontManager().baseFontBold.DrawBlock( text, 6, 5 + i * 30, 39, 30, ALIGN_CENTER_CENTER, fontColor, 2,1,0.25)
		Next
		SetAlpha 1.0
		DrawnOnProgrammePlannerBG = True

		'reset target for font
		TBitmapFont.setRenderTarget(null)
	End Function
End Type