﻿Type TGUINewsList extends TGUIListBase

    Method Create:TGUINewsList(position:TVec2D = null, dimension:TVec2D = null, limitState:String = "")
		Super.Create(position, dimension, limitState)
		return self
	End Method


	Method ContainsNews:int(news:TNews)
		for local guiNews:TGUINews = eachin entries
			if guiNews.news = news then return TRUE
		Next
		return FALSE
	End Method
End Type




Type TGUINewsSlotList extends TGUISlotList

    Method Create:TGUINewsSlotList(position:TVec2D = null, dimension:TVec2D = null, limitState:String = "")
		Super.Create(position, dimension, limitState)
		return self
	End Method


	Method ContainsNews:int(news:TNews)
		for local i:int = 0 to self.GetSlotAmount()-1
			local guiNews:TGUINews = TGUINews( self.GetItemBySlot(i) )
			if guiNews and guiNews.news = news then return TRUE
		Next
		return FALSE
	End Method
End Type




'base element for list items in the programme planner
Type TGUIProgrammePlanElement extends TGUIGameListItem
	Field broadcastMaterial:TBroadcastMaterial
	Field inList:TGUISlotList
	Field lastList:TGUISlotList
	Field lastListType:int = 0
	Field lastSlot:int = 0
	Field plannedOnDay:int = -1
	Field imageBaseName:string = "pp_programmeblock1"

	Global ghostAlpha:float = 0.8

	'for hover effects
	Global hoveredElement:TGUIProgrammePlanElement = null


    Method Create:TGUIProgrammePlanElement(pos:TVec2D=null, dimension:TVec2D=null, value:String="")
		if not dimension then dimension = new TVec2D.Init(120,20)
		Super.Create(pos, dimension, value)
		return self
	End Method


	Method CreateWithBroadcastMaterial:TGUIProgrammePlanElement(material:TBroadcastMaterial, limitToState:string="")
		Create()
		SetLimitToState(limitToState)
		SetBroadcastMaterial(material)
		return self
	End Method


	Method SetBroadcastMaterial:int(material:TBroadcastMaterial = null)
		'alow simple setter without param
		if not material and broadcastMaterial then material = broadcastMaterial

		broadcastMaterial = material
		if material
			'now we can calculate the item dimensions
			Resize(GetSpriteFromRegistry(GetAssetBaseName()+"1").area.GetW(), GetSpriteFromRegistry(GetAssetBaseName()+"1").area.GetH() * material.getBlocks())

			'set handle (center for dragged objects) to half of a 1-Block
			self.setHandle(new TVec2D.Init(GetSpriteFromRegistry(GetAssetBaseName()+"1").area.GetW()/2, GetSpriteFromRegistry(GetAssetBaseName()+"1").area.GetH()/2))
		endif
	End Method


	Method GetBlocks:int()
		If isDragged() and not hasOption(GUI_OBJECT_DRAWMODE_GHOST)
			return broadcastMaterial.GetBlocks(broadcastMaterial.materialType)
		endif
		if lastListType > 0 then return broadcastMaterial.GetBlocks(lastListType)
		return broadcastMaterial.GetBlocks()
	End Method


	Method GetAssetBaseName:string()
		local viewType:int = 0

		'dragged and not asked during ghost mode drawing
		If isDragged() and not hasOption(GUI_OBJECT_DRAWMODE_GHOST)
			viewType = broadcastMaterial.materialType
		'ghost mode
		elseIf isDragged() and hasOption(GUI_OBJECT_DRAWMODE_GHOST) and lastListType > 0
			viewType = lastListType
		else
			viewType = broadcastMaterial.usedAsType
		endif

		if viewType = broadcastMaterial.TYPE_PROGRAMME
			imageBaseName = "pp_programmeblock"
		elseif viewType = broadcastMaterial.TYPE_ADVERTISEMENT
			imageBaseName = "pp_adblock"
		else 'default
			imageBaseName = "pp_programmeblock"
		endif

		return imageBaseName
	End Method


	'override default to enable splitted blocks (one left, two right etc.)
	Method containsXY:int(x:float,y:float)
		if isDragged() or broadcastMaterial.GetBlocks() = 1
			return GetScreenRect().containsXY(x,y)
		endif

		For Local i:Int = 1 To GetBlocks()
			local resultRect:TRectangle = null
			if self._parent
				resultRect = self._parent.GetScreenRect()
				'get the intersecting rectangle between parentRect and blockRect
				'the x,y-values are screen coordinates!
				resultRect = resultRect.intersectRect(GetBlockRect(i))
			else
				resultRect = GetBlockRect(i)
			endif
			if resultRect and resultRect.containsXY(x,y) then return TRUE
		Next
		return FALSE
	End Method


	Method GetBlockRect:TRectangle(block:int=1)
		local pos:TVec2D = null
		'dragged and not in DrawGhostMode
		If isDragged() and not hasOption(GUI_OBJECT_DRAWMODE_GHOST)
			pos = new TVec2D.Init(GetScreenX(), GetScreenY())
			if block > 1
				pos.addXY(0, GetSpriteFromRegistry(GetAssetBaseName()+"1").area.GetH() * (block - 1))
			endif
		else
			local startSlot:int = lastSlot
			local list:TGUISlotList = lastList
			if inList
				list = self.inList
				startSlot = self.inList.GetSlot(self)
			endif

			if list
				pos = list.GetSlotCoord(startSlot + block-1).ToVec2D()
				pos.addXY(list.getScreenX(), list.getScreenY())
			else
				pos = new TVec2D.Init(self.GetScreenX(),self.GetScreenY())
				pos.addXY(0, GetSpriteFromRegistry(GetAssetBaseName()+"1").area.GetH() * (block - 1))
				'print "block: "+block+"  "+pos.GetIntX()+","+pos.GetIntY()
			endif
		endif

		return new TRectangle.Init(pos.x,pos.y, self.rect.getW(), GetSpriteFromRegistry(GetAssetBaseName()+"1").area.GetH())
	End Method



	'override default update-method
	Method Update:int()
		super.Update()

		Select broadcastMaterial.state
			case broadcastMaterial.STATE_NORMAL
					setOption(GUI_OBJECT_DRAGABLE, TRUE)
			case broadcastMaterial.STATE_RUNNING
					setOption(GUI_OBJECT_DRAGABLE, FALSE)
			case broadcastMaterial.STATE_OK
					setOption(GUI_OBJECT_DRAGABLE, FALSE)
			case broadcastMaterial.STATE_FAILED
					setOption(GUI_OBJECT_DRAGABLE, FALSE)
		End Select

		'no longer allowed to have this item dragged
		if isDragged() and not hasOption(GUI_OBJECT_DRAGABLE)
			print "RONNY: FORCE DROP"
			dropBackToOrigin()
		endif

		if not broadcastMaterial
			'print "[ERROR] TGUIProgrammePlanElement.Update: broadcastMaterial not set."
			return FALSE
		endif


		'set mouse to "hover"
		if broadcastMaterial.GetOwner() = GetPlayerCollection().playerID and mouseover then Game.cursorstate = 1
		'set mouse to "dragged"
		if isDragged() then Game.cursorstate = 2
	End Method


	'draws the background
	Method DrawBlockBackground:int(variant:string="")

		Local titleIsVisible:Int = FALSE
		local drawPos:TVec2D = new TVec2D.Init(GetScreenX(), GetScreenY())
		'if dragged and not in ghost mode
		If isDragged() and not hasOption(GUI_OBJECT_DRAWMODE_GHOST)
			if broadcastMaterial.state = broadcastMaterial.STATE_NORMAL Then variant = "_dragged"
		endif

		local blocks:int = GetBlocks()
		For Local i:Int = 1 To blocks
			Local _blockPosition:Int = 1
			If i > 1
				if i < blocks Then _blockPosition = 2
				if i = blocks Then _blockPosition = 3
			endif

			'draw non-dragged OR ghost
			If not isDragged() OR hasOption(GUI_OBJECT_DRAWMODE_GHOST)
				'skip invisible parts
				local startSlot:int = 0
				if self.inList
					startSlot = self.inList.GetSlot(self)
				elseif self.lastList and isDragged()
					startSlot = self.lastSlot
				else
					startSlot = self.lastSlot
				endif
				If startSlot+i-1 < 0 then continue
				if startSlot+i-1 >= 24 then continue
			endif
			drawPos = GetBlockRect(i).position

			Select _blockPosition
				case 1	'top
						'if only 1 block, use special graphics
						If blocks = 1
							GetSpriteFromRegistry(GetAssetBaseName()+"1"+variant).Draw(GetScreenX(), GetScreenY())
						Else
							GetSpriteFromRegistry(GetAssetBaseName()+"2"+variant).DrawClipped(new TRectangle.Init(drawPos.x, drawPos.y, -1, 30))
						EndIf
						'xrated
						if TProgramme(broadcastMaterial) and TProgramme(broadcastMaterial).data.IsXRated()
							GetSpriteFromRegistry("pp_xrated").Draw(GetScreenX() + GetSpriteFromRegistry(GetAssetBaseName()+"1"+variant).GetWidth(), GetScreenY(),  -1, new TVec2D.Init(ALIGN_RIGHT, ALIGN_TOP))
						endif
						'paid
						if TProgramme(broadcastMaterial) and TProgramme(broadcastMaterial).data.IsPaid()
							GetSpriteFromRegistry("pp_paid").Draw(GetScreenX() + GetSpriteFromRegistry(GetAssetBaseName()+"1"+variant).GetWidth(), GetScreenY(),  -1, new TVec2D.Init(ALIGN_RIGHT, ALIGN_TOP))
						endif

						titleIsVisible = TRUE
				case 2	'middle
						GetSpriteFromRegistry(GetAssetBaseName()+"2"+variant).DrawClipped(new TRectangle.Init(drawPos.x, drawPos.y, -1, 15), new TVec2D.Init(0, 30))
						drawPos.addXY(0,15)
						GetSpriteFromRegistry(GetAssetBaseName()+"2"+variant).DrawClipped(new TRectangle.Init(drawPos.x, drawPos.y, -1, 15), new TVec2D.Init(0, 30))
				case 3	'bottom
						GetSpriteFromRegistry(GetAssetBaseName()+"2"+variant).DrawClipped(new TRectangle.Init(drawPos.x, drawpos.y, -1, 30), new TVec2D.Init(0, 30))
			End Select
		Next
		return titleIsVisible
	End Method


	'returns whether a ghost can be drawn or false, if there is a
	'reason not to do so
	Method CanDrawGhost:int()
		if IsDragged() and TGUIProgrammePlanSlotList(lastList)
			'if guiblock is planned on another day then what the list
			'of the ghost has set, we wont display the ghost
			if plannedOnDay <> TGUIProgrammePlanSlotList(lastList).planDay
				return False
			else
				return True
			endif
		endif
		return TRUE
	End Method


	'draw the programmeblock inclusive text
    'zeichnet den Programmblock inklusive Text
	Method DrawContent:int()
		'check if we have to skip ghost drawing
		if hasOption(GUI_OBJECT_DRAWMODE_GHOST) and not CanDrawGhost() then return False


		if not broadcastMaterial
			SetColor 255,0,0
			DrawRect(GetScreenX(), GetScreenY(), 150,20)
			SetColor 255,255,255
			GetBitmapFontManager().basefontBold.Draw("no broadcastMaterial", GetScreenX()+5, GetScreenY()+3)
			return FALSE
		endif

		'If isDragged() Then state = 0
		Select broadcastMaterial.state
			case broadcastMaterial.STATE_NORMAL
					SetColor 255,255,255
			case broadcastMaterial.STATE_RUNNING
					SetColor 255,230,120
			case broadcastMaterial.STATE_OK
					SetColor 200,255,200
			case broadcastMaterial.STATE_FAILED
					SetColor 250,150,120
		End Select

		'draw the default background

		local titleIsVisible:int = DrawBlockBackground()
		SetColor 255,255,255

		'there is an hovered item
		if hoveredElement
			local oldAlpha:float = GetAlpha()
			'i am the hovered one (but not in ghost mode)
			'we could also check "self.mouseover", this way we could
			'override it without changing the objects "behaviour" (if there is one)
			if self = hoveredElement
				if not hasOption(GUI_OBJECT_DRAWMODE_GHOST)
					SetBlend LightBlend
					SetAlpha 0.30*oldAlpha
					SetColor 120,170,255
					DrawBlockBackground()
					SetAlpha oldAlpha
					SetBlend AlphaBlend
				endif
			'i have the same licence/programme...
			elseif self.broadcastMaterial.GetReferenceID() = hoveredElement.broadcastMaterial.GetReferenceID()
				SetBlend LightBlend
				SetAlpha 0.15*oldAlpha
				'SetColor 150,150,250
				SetColor 120,170,255
				DrawBlockBackground()
				SetColor 250,255,255
				SetAlpha oldAlpha
				SetBlend AlphaBlend
			endif
			SetColor 255,255,255
		endif

		If titleIsVisible
			local useType:int = broadcastMaterial.usedAsType
			if hasOption(GUI_OBJECT_DRAWMODE_GHOST) and lastListType > 0
				useType = lastListType
			endif

			Select useType
				case broadcastMaterial.TYPE_PROGRAMME
					DrawProgrammeBlockText(new TRectangle.Init(GetScreenX(), GetScreenY(), GetSpriteFromRegistry(GetAssetBaseName()+"1").area.GetW()-1,-1))
				case broadcastMaterial.TYPE_ADVERTISEMENT
					DrawAdvertisementBlockText(new TRectangle.Init(GetScreenX(), GetScreenY(), GetSpriteFromRegistry(GetAssetBaseName()+"2").area.GetW()-4,-1))
			end Select
		endif
	End Method


	Method DrawProgrammeBlockText:int(textArea:TRectangle, titleColor:TColor=null, textColor:TColor=null)
		Local title:String			= broadcastMaterial.GetTitle()
		Local titleAppend:string	= ""
		Local text:string			= ""
		Local text2:string			= ""

		Select broadcastMaterial.materialType
			'we got a programme used as programme
			case broadcastMaterial.TYPE_PROGRAMME
				if TProgramme(broadcastMaterial)
					Local programme:TProgramme	= TProgramme(broadcastMaterial)
					text = programme.data.getGenreString()
					if programme.isSeries()
						'use the genre of the parent
						text = programme.licence.parentLicence.data.getGenreString()
						title = programme.licence.parentLicence.GetTitle()
						'uncomment if you wish episode number in title
						'titleAppend = " (" + programme.GetEpisodeNumber() + "/" + programme.GetEpisodeCount() + ")"
						text:+"-"+GetLocale("SERIES_SINGULAR")
						text2 = "Ep.: " + (programme.GetEpisodeNumber()+1) + "/" + programme.GetEpisodeCount()
					endif
				endif
			'we got an advertisement used as programme (aka Tele-Shopping)
			case broadcastMaterial.TYPE_ADVERTISEMENT
				if TAdvertisement(broadcastMaterial)
					Local advertisement:TAdvertisement = TAdvertisement(broadcastMaterial)
					text = GetLocale("INFOMERCIAL")
				endif
		End Select


		Local maxWidth:Int			= textArea.GetW()
		Local titleFont:TBitmapFont = GetBitmapFont("DefaultThin", 12, BOLDFONT)
		Local useFont:TBitmapFont	= GetBitmapFont("Default", 12, ITALICFONT)
		If not titleColor Then titleColor = TColor.Create(0,0,0)
		If not textColor Then textColor = TColor.Create(50,50,50)

		'shorten the title to fit into the block
		While titleFont.getWidth(title + titleAppend) > maxWidth And title.length > 4
			title = title[..title.length-3]+".."
		Wend
		'add eg. "(1/10)"
		title = title + titleAppend

		'draw
		titleFont.drawBlock(title, textArea.position.GetIntX() + 5, textArea.position.GetIntY() +2, textArea.GetW() - 5, 18, null, titleColor, 0, True, 1.0, FALSE)
		useFont.draw(text, textArea.position.GetIntX() + 5, textArea.position.GetIntY() + 17, textColor)
		useFont.draw(text2, textArea.position.GetIntX() + 138, textArea.position.GetIntY() + 17, textColor)

		SetColor 255,255,255
	End Method


	Method DrawAdvertisementBlockText(textArea:TRectangle, titleColor:TColor=null, textColor:TColor=null)
		Local title:String			= broadcastMaterial.GetTitle()
		Local titleAppend:string	= ""
		Local text:string			= "123"
		Local text2:string			= "" 'right aligned on same spot as text

		Select broadcastMaterial.materialType
			'we got an advertisement used as advertisement
			case broadcastMaterial.TYPE_ADVERTISEMENT
				If TAdvertisement(broadcastMaterial)
					Local advertisement:TAdvertisement = TAdvertisement(broadcastMaterial)
					If advertisement.isState(advertisement.STATE_FAILED)
						text = "------"
					else
						if advertisement.contract.isSuccessful()
							text = "- OK -"
						else
							text = GetPlayerProgrammePlanCollection().Get(advertisement.owner).GetAdvertisementSpotNumber(advertisement) + "/" + advertisement.contract.GetSpotCount()
						endif
					EndIf
				EndIf
			'we got an programme used as advertisement (aka programmetrailer)
			case broadcastMaterial.TYPE_PROGRAMME
				if TProgramme(broadcastMaterial)
					Local programme:TProgramme	= TProgramme(broadcastMaterial)
					text = GetLocale("TRAILER")
					'red corner mark should be enough to recognized X-rated
					'removing "FSK18" from text removes the bug that this text
					'does not fit into the rectangle on Windows systems
					'if programme.data.xrated then text = GetLocale("X_RATED")+"-"+text
				endif
		End Select

		'draw
		If not titleColor Then titleColor = TColor.Create(0,0,0)
		If not textColor Then textColor = TColor.Create(50,50,50)

		GetBitmapFont("DefaultThin", 10, BOLDFONT).drawBlock(title, textArea.position.GetIntX() + 3, textArea.position.GetIntY() + 2, textArea.GetW(), 18, null, TColor.CreateGrey(0), 0,1,1.0, FALSE)
		textColor.setRGB()
		GetBitmapFont("Default", 10).drawBlock(text, textArea.position.GetIntX() + 3, textArea.position.GetIntY() + 17, TextArea.GetW(), 30)
		GetBitmapFont("Default", 10).drawBlock(text2,textArea.position.GetIntX() + 3, textArea.position.GetIntY() + 17, TextArea.GetW(), 20, new TVec2D.Init(ALIGN_RIGHT))
		SetColor 255,255,255 'eigentlich alte Farbe wiederherstellen
	End Method


	Method DrawSheet(leftX:int=30, rightX:int=30, width:int=0)
		local sheetY:float 	= 20
		local sheetX:float 	= leftX
		local sheetAlign:int= 0
		if width = 0 then width = GetGraphicsManager().GetWidth()
		'if mouse on left side of area - align sheet on right side
		if MouseManager.x < width/2
			sheetX = width - rightX
			sheetAlign = 1
		endif

		'by default nothing is shown
		'because we already have hover effects
		rem
			SetColor 0,0,0
			SetAlpha 0.2
			Local x:Float = self.GetScreenX()
			Local tri:Float[]
			if sheetAlign=0
				tri = [sheetX+20,sheetY+25,sheetX+20,sheetY+90,self.GetScreenX()+self.GetScreenWidth()/2.0+3,self.GetScreenY()+self.GetScreenHeight()/2.0]
			else
				tri = [sheetX-20,sheetY+25,sheetX-20,sheetY+90,self.GetScreenX()+self.GetScreenWidth()/2.0+3,self.GetScreenY()+self.GetScreenHeight()/2.0]
			endif
			DrawPoly(tri)
			SetColor 255,255,255
			SetAlpha 1.0
		endrem
		self.broadcastMaterial.ShowSheet(sheetX,sheetY, sheetAlign)
	End Method
End Type





'list to handle elements in the programmeplan (ads and programmes)
Type TGUIProgrammePlanSlotList extends TGUISlotList
	'sollten nicht gebraucht werden - die "slotpositionen" muessten auch herhalten
	'koennen
	Field zoneLeft:TRectangle		= new TRectangle.Init(0, 0, 200, 350)
	Field zoneRight:TRectangle		= new TRectangle.Init(300, 0, 200, 350)

	'what day this slotlist is planning currently
	Field planDay:int = -1

	'holding the object representing a programme started a day earlier (eg. 23:00-01:00)
	'this should not get handled by panels but the list itself (only interaction is
	'drag-n-drop handling)
	Field daychangeGuiProgrammePlanElement:TGUIProgrammePlanElement

	Field slotBackground:TSprite= null
	Field blockDimension:TVec2D		= null
	Field acceptTypes:int			= 0
	Field isType:int				= 0
	Global registeredGlobalListeners:int = FALSE

    Method Create:TGUIProgrammePlanSlotList(position:TVec2D = null, dimension:TVec2D = null, limitState:String = "")
		Super.Create(position, dimension, limitState)

		SetOrientation(GUI_OBJECT_ORIENTATION_VERTICAL)
		self.resize( dimension.x, dimension.y)
		self.Init("pp_programmeblock1")
		self.SetItemLimit(24)
		self._fixedSlotDimension = TRUE

		self.acceptTypes :| TBroadcastMaterial.TYPE_PROGRAMME
		self.acceptTypes :| TBroadcastMaterial.TYPE_ADVERTISEMENT
		self.isType = TBroadcastMaterial.TYPE_PROGRAMME



		SetAcceptDrop("TGUIProgrammePlanElement")
		SetAutofillSlots(FALSE)

		'===== REGISTER EVENTS =====
		'nobody was against dropping the item - so transform according to the lists type
		EventManager.registerListenerMethod("guiobject.onFinishDrop", self, "onFinishDropProgrammePlanElement", "TGUIProgrammePlanElement", self)
		'nobody was against dragging the item - so transform according to the items base type
		'attention: "drag" does not have a "receiver"-list like a drop has..
		'so we would have to check vs slot-elements here
		'that is why we just use a global listener... for all programmeslotlists (prog and ad)
		if not registeredGlobalListeners
			EventManager.registerListenerFunction("guiobject.onFinishDrag", onFinishDragProgrammePlanElement, "TGUIProgrammePlanElement")
			registeredGlobalListeners = TRUE
		endif
		return self
	End Method


	Method Init:int(spriteName:string="", displaceX:int = 0)
		self.zoneLeft.dimension.SetXY(GetSpriteFromRegistry(spriteName).area.GetW(), 12 * GetSpriteFromRegistry(spriteName).area.GetH())
		self.zoneRight.dimension.SetXY(GetSpriteFromRegistry(spriteName).area.GetW(), 12 * GetSpriteFromRegistry(spriteName).area.GetH())

		self.slotBackground = GetSpriteFromRegistry(spriteName)

		self.blockDimension = new TVec2D.Init(slotBackground.area.GetW(), slotBackground.area.GetH())
		SetSlotMinDimension(blockDimension.GetIntX(), blockDimension.GetIntY())

		self.SetEntryDisplacement(slotBackground.area.GetW() + displaceX , -12 * slotBackground.area.GetH(), 12) '12 is stepping
	End Method


	'override to remove daychange-object too
	Method EmptyList:int()
		Super.EmptyList()
		if dayChangeGuiProgrammePlanElement
			dayChangeGuiProgrammePlanElement.remove()
			dayChangeGuiProgrammePlanElement = null
		endif
	End Method


	'handle successful drops of broadcastmaterial on the list
	Method onFinishDropProgrammePlanElement:int(triggerEvent:TEventBase)
		'resize that item to conform to the list
		local item:TGUIProgrammePlanElement = TGUIProgrammePlanElement(triggerEvent.GetSender())
		if not item then return FALSE

		item.lastListType = isType
		'resizes item according to usage type
		item.broadcastMaterial.setUsedAsType(isType)

		item.SetBroadcastMaterial()

		return TRUE
	End Method


	'handle successful drags of broadcastmaterial
	Function onFinishDragProgrammePlanElement:int(triggerEvent:TEventBase)
		'resize that item to conform to the list
		local item:TGUIProgrammePlanElement = TGUIProgrammePlanElement(triggerEvent.GetSender())
		if not item then return FALSE

		'resizes item according to usage type
		item.broadcastMaterial.setUsedAsType(item.broadcastMaterial.materialType)
		item.SetBroadcastMaterial()

		return TRUE
	End Function


	'override default behaviour for zones
	Method SetEntryDisplacement(x:float=0.0, y:float=0.0, stepping:int=1)
		super.SetEntryDisplacement(x,y,stepping)

		'move right zone according to setup
		zoneRight.position.SetX(x)
	End Method


	Method SetDayChangeBroadcastMaterial:int(material:TBroadcastMaterial, day:int=-1)
		local guiElement:TGUIProgrammePlanElement = dayChangeGuiProgrammePlanElement
		if guiElement
			'clear out old gui element
			guiElement.remove()
		else
			guiElement = new TGUIProgrammePlanElement.Create()
		endif
		'assign programme
		guiElement.SetBroadcastMaterial(material)

		'move the element to the correct position
		'1. find out when it was send:
		'   just ask the plan when the programme at "0:00" really started
		local startHour:int = 0
		local player:TPlayer = GetPlayerCollection().Get(material.owner)
		if player
			if day < 0 then day = GetWorldTime().GetDay()
			startHour = player.GetProgrammePlan().GetObjectStartHour(material.materialType,day,0)
			'get a 0-23 value
			startHour = startHour mod 24
		else
			print "[ERROR] No player found for ~qprogramme~q in SetDayChangeBroadcastMaterial"
			startHour = 23 'nur als beispiel, spaeter entfernen
'			return FALSE
		endif

		'2. set the position of that element so that the "todays blocks" are starting at
		'   0:00
		local firstSlotCoord:TVec2D = GetSlotOrCoord(0).ToVec2D()
		local blocksRunYesterday:int = 24 - startHour
		guiElement.lastSlot = - blocksRunYesterday
		guiElement.rect.position.CopyFrom(firstSlotCoord)
		'move above 0:00 (gets hidden automatically)
		guiElement.rect.position.addXY(0, -1 * blocksRunYesterday * blockDimension.GetIntY() )

		dayChangeGuiProgrammePlanElement = guiElement


		'assign parent
		guiEntriesPanel.addChild(dayChangeGuiProgrammePlanElement)

		return TRUE
	End Method


	'override default "default accept behaviour" of onDrop
	Method onDrop:int(triggerEvent:TEventBase)
		local dropCoord:TVec2D = TVec2D(triggerEvent.GetData().get("coord"))
		if not dropCoord then return FALSE

		if self.containsXY(dropCoord.x, dropCoord.y)
			triggerEvent.setAccepted(true)
			'print "TGUIProgrammePlanSlotList.onDrop: coord="+dropCoord.getIntX()+","+dropCoord.getIntY()
			return TRUE
		else
			return FALSE
		endif
	End Method


	Method ContainsBroadcastMaterial:int(material:TBroadcastMaterial)
		'check special programme from yesterday
		if self.dayChangeGuiProgrammePlanElement
			if self.daychangeGuiProgrammePlanElement.broadcastMaterial = material then return TRUE
		endif

		for local i:int = 0 to self.GetSlotAmount()-1
			local block:TGUIProgrammePlanElement = TGUIProgrammePlanElement(self.GetItemBySlot(i))
			if not block then continue
			if block.broadcastMaterial = material then return TRUE
		Next
		return FALSE
	End Method


	'override default to also recognize slots occupied by prior ones
	Method GetItemBySlot:TGUIobject(slot:int)
		if slot < 0 or slot > _slots.length-1 then return Null

		'if no item is at the given slot, check prior ones
		if _slots[slot] = null
			'check regular slots
			local parentSlot:int = slot-1
			while parentSlot > 0
				if _slots[parentSlot]
					'only return if the prior one is running long enough
					' - else it also returns programmes with empty slots between
					local blocks:int = TGUIProgrammePlanElement(_slots[parentSlot]).broadcastMaterial.getBlocks(isType)
					if blocks > (slot - parentSlot) then return _slots[parentslot]
				endif
				parentSlot:-1
			wend
			'no item found in regular slots but already are at start
			'-> check special programme from yesterday (if existing it is the searched one)
			if daychangeGuiProgrammePlanElement
				local blocks:int = daychangeGuiProgrammePlanElement.broadcastMaterial.getBlocks(isType)
				'lastSlot is a negative value from 0
				'-> -3 means 3 blocks already run yesterday
				local blocksToday:int = blocks + dayChangeGuiProgrammePlanElement.lastSlot
				if blocksToday > slot then return daychangeGuiProgrammePlanElement
			endif

			return null
		endif

		return _slots[slot]
	End Method


	'overridden method to check slots after the block-slot for occupation too
	Method SetItemToSlot:int(item:TGUIobject,slot:int)
		local itemSlot:int = self.GetSlot(item)
		'somehow we try to place an item at the place where the item
		'already resides
		if itemSlot = slot then return TRUE

		local guiElement:TGUIProgrammePlanElement = TGUIProgrammePlanElement(item)
		if not guiElement then return FALSE

		'is there another item?
		local slotStart:int = slot
		local slotEnd:int = slot + guiElement.broadcastMaterial.getBlocks(isType)-1

		'to check previous ones we try to find a previous one
		'then we check if it reaches "our" slot or ends earlier
		local previousItemSlot:int = GetPreviousUsedSlot(slot)
		if previousItemSlot > -1
			local previousGuiElement:TGUIProgrammePlanElement = TGUIProgrammePlanElement(getItemBySlot(previousItemSlot))
			if previousGuiElement and previousItemSlot + previousGuiElement.GetBlocks()-1 >= slotStart
				slotStart = previousItemSlot
			endif
		endif

		for local i:int = slotStart to slotEnd
			local dragItem:TGUIProgrammePlanElement = TGUIProgrammePlanElement(getItemBySlot(i))

			'only drag an item once
			if dragItem 'and not dragItem.isDragged()
				'do not allow if the underlying item cannot get dragged
				if not dragItem.isDragable() then return FALSE

				'ask others if they want to intercept that exchange
				local event:TEventSimple = TEventSimple.Create( "guiSlotList.onBeginReplaceSlotItem", new TData.Add("source", item).Add("target", dragItem).AddNumber("slot",slot), self)
				EventManager.triggerEvent(event)

				if not event.isVeto()
					'remove the other one from the panel
					if dragItem._parent then dragItem._parent.RemoveChild(dragItem)

					'drag the other one
					dragItem.drag()
					'unset the occupied slot
					_SetSlot(i, null)

					EventManager.triggerEvent(TEventSimple.Create( "guiSlotList.onReplaceSlotItem", new TData.Add("source", item).Add("target", dragItem).AddNumber("slot",slot) , self))
				endif
				'skip slots occupied by this item
				i:+ (dragItem.broadcastMaterial.GetBlocks(isType)-1)
			endif
		Next

		'if the item is already on the list, remove it from the former slot
		_SetSlot(itemSlot, null)

		'set the item to the new slot
		_SetSlot(slot, item)

		 'panel manages it now | RON 03.01.14
		guiEntriesPanel.addChild(item)

		RecalculateElements()

		return TRUE
	End Method


	'overriden Method: so it does not accept a certain
	'kind of programme (movies - series)
	'plus it drags items in other occupied slots
	Method AddItem:int(item:TGUIobject, extra:object=null)
		local guiElement:TGUIProgrammePlanElement = TGUIProgrammePlanElement(item)
		if not guiElement then return FALSE

		'something odd happened - no material
		if not guiElement.broadcastMaterial then return FALSE
		'list does not accept type? stop adding the item.
		if not(acceptTypes & guiElement.broadcastMaterial.usedAsType) then return FALSE
		'item is not allowed to drop there ? stop adding the item.
		if not(acceptTypes & guiElement.broadcastMaterial.useableAsType) then return FALSE

		local addToSlot:int = -1
		local extraIsRawSlot:int = FALSE
		if string(extra)<>"" then addToSlot= int( string(extra) );extraIsRawSlot=TRUE

		'search for first free slot
		if _autofillSlots then addToSlot = self.getFreeSlot()
		'auto slot requested
		if extraIsRawSlot and addToSlot = -1 then addToSlot = getFreeSlot()

		'no free slot or none given? find out on which slot we are dropping
		'if possible, drag the other one and drop the new
		if addToSlot < 0
			local data:TData = TData(extra)
			if not data then return FALSE

			local dropCoord:TVec2D = TVec2D(data.get("coord"))
			if not dropCoord then return FALSE

			'set slot to land
			addToSlot = GetSlotByCoord(dropCoord)
			'no slot was hit
			if addToSlot < 0 then return FALSE
		endif

		'ask if an add to this slot is ok
		local event:TEventSimple =  TEventSimple.Create("guiList.TryAddItem", new TData.Add("item", item).AddNumber("slot",addToSlot) , self)
		EventManager.triggerEvent(event)
		if event.isVeto() then return FALSE

		'check underlying slots
		for local i:int = 0 to guiElement.broadcastMaterial.getBlocks(isType)-1
			'return if there is an underlying item which cannot get dragged
			local dragItem:TGUIProgrammePlanElement = TGUIProgrammePlanElement(getItemBySlot(addToSlot + i))
			if not dragItem then continue

			'check if the programme can be dragged
			'this should not be the case if the programme already run
			if not dragItem.isDragable() then print "NOT DRAGABLE UNDERLAYING";return FALSE
		Next


		'set self as the list the items is belonging to
		'this also drags underlying items if possible
		if SetItemToSlot(guiElement, addToSlot)
			guiElement.lastList = guiElement.inList
			guiElement.inList = self
			if not guiElement.lastList
				guiElement.lastList = self
				guiElement.lastListType = isType
			endif

			return TRUE
		endif
	End Method


	'override RemoveItem-Handler to include inList-property (and type check)
	Method RemoveItem:int(item:TGUIobject)
		local guiElement:TGUIProgrammePlanElement = TGUIProgrammePlanElement(item)
		if not guiElement then return FALSE

		if super.RemoveItem(guiElement)
			guiElement.lastList = guiElement.inList
			'inList is only set for manual drags
			'while a replacement-drag has no inList (and no last Slot)
			if guiElement.inList
				guiElement.lastSlot = guiElement.inList.GetSlot(self)
			else
				guiElement.lastSlot = -1
			endif

			guiElement.inList = null
			return TRUE
		else
			return FALSE
		endif
	End Method


	'override default "rectangle"-check to include splitted panels
	Method containsXY:int(x:float,y:float)
		'convert to local coord
		x :-GetScreenX()
		y :-GetScreenY()

		if zoneLeft.containsXY(x,y) or zoneRight.containsXY(x,y)
			return TRUE
		else
			return FALSE
		endif
	End Method


	Method Update:int()
		if dayChangeGuiProgrammePlanElement then dayChangeGuiProgrammePlanElement.Update()

		super.Update()
	End Method


	Method DrawContent:int()
		local atPoint:TVec2D = GetScreenPos()
		local pos:TVec2D = null
		For local i:int = 0 to _slotsState.length-1
			'skip occupied slots
			if _slots[i]
				if TGUIProgrammePlanElement(_slots[i])
					i :+ TGUIProgrammePlanElement(_slots[i]).GetBlocks()-1
					continue
				endif
			endif

			if _slotsState[i] = 0 then continue

			pos = GetSlotOrCoord(i).ToVec2D()
			'disabled
			if _slotsState[i] = 1 then SetColor 100,100,100
			'occupied
			if _slotsState[i] = 2 then SetColor 250,150,120

			SetAlpha 0.35
			SlotBackground.Draw(atPoint.GetX()+pos.getX(), atPoint.GetY()+pos.getY())
			SetAlpha 1.0
			SetColor 255,255,255
		Next

		if dayChangeGuiProgrammePlanElement then dayChangeGuiProgrammePlanElement.draw()
	End Method
End Type




Type TPlannerList
	Field openState:int		= 0		'0=enabled 1=openedgenres 2=openedmovies 3=openedepisodes = 1
	Field currentGenre:Int	=-1
	Field enabled:Int		= 0
	Field Pos:TVec2D 		= new TVec2D.Init()
	Field entriesRect:TRectangle
	Field entrySize:TVec2D = new TVec2D

	Method getOpen:Int()
		return self.openState and enabled
	End Method
End Type




'the programmelist shown in the programmeplaner
Type TgfxProgrammelist extends TPlannerList
	Field displaceEpisodeTapes:TVec2D = new TVec2D.Init(6,5)
	'area of all genres/filters including top/bottom-area
	Field genresRect:TRectangle
	Field genresCount:int = -1
	Field genreSize:TVec2D = new TVec2D
	Field currentEntry:int = -1
	Field currentSubEntry:int = -1
	Field subEntriesRect:TRectangle

	'licence with children
	Field hoveredParentalLicence:TProgrammeLicence = Null
	'licence 
	Field hoveredLicence:TProgrammeLicence = Null

	const MODE_PROGRAMMEPLANNER:int=0	'creates a GuiProgrammePlanElement
	const MODE_ARCHIVE:int=1			'creates a GuiProgrammeLicence

	

	Method Create:TgfxProgrammelist(x:Int, y:Int)
		genreSize = GetSpriteFromRegistry("gfx_programmegenres_entry.default").area.dimension.copy()
		entrySize = GetSpriteFromRegistry("gfx_programmeentries_entry.default").area.dimension.copy()

		'right align the list
		Pos.SetXY(x - genreSize.GetX(), y)

		'recalculate dimension of the area of all genres
		genresRect = new TRectangle.Init(Pos.GetX(), Pos.GetY(), genreSize.GetX(), 0)
		genresRect.dimension.y :+ GetSpriteFromRegistry("gfx_programmegenres_top.default").area.GetH()
		genresRect.dimension.y :+ TProgrammeLicenceFilter.GetVisibleCount() * genreSize.GetY()
		genresRect.dimension.y :+ GetSpriteFromRegistry("gfx_programmegenres_bottom.default").area.GetH()

		'recalculate dimension of the area of all entries (also if not all slots occupied)
		entriesRect = new TRectangle.Init(genresRect.GetX() - 175, genresRect.GetY(), entrySize.GetX(), 0)
		entriesRect.dimension.y :+ GetSpriteFromRegistry("gfx_programmeentries_top.default").area.GetH()
		entriesRect.dimension.y :+ GameRules.maxProgrammeLicencesPerFilter * entrySize.GetY()
		entriesRect.dimension.y :+ GetSpriteFromRegistry("gfx_programmeentries_bottom.default").area.GetH()

		'recalculate dimension of the area of all entries (also if not all slots occupied)
		subEntriesRect = new TRectangle.Init(entriesRect.GetX() + 175, entriesRect.GetY(), entrySize.GetX(), 0)
		subEntriesRect.dimension.y :+ GetSpriteFromRegistry("gfx_programmeentries_top.default").area.GetH()
		subEntriesRect.dimension.y :+ 10 * entrySize.GetY()
		subEntriesRect.dimension.y :+ GetSpriteFromRegistry("gfx_programmeentries_bottom.default").area.GetH()

		Return self
	End Method


	Method Draw:Int()
		if not enabled then return FALSE

		'draw genre selector
		If self.openState >=1
			'mark new genres
			'TODO: do this part in programmecollection (only on add/remove)
			local visibleFilters:TProgrammeLicenceFilter[] = TProgrammeLicenceFilter.GetVisible()
			local containsNew:int[visibleFilters.length]

			For local licence:TProgrammeLicence = EachIn GetPlayerCollection().Get().GetProgrammeCollection().justAddedProgrammeLicences
				'check all filters if they take care of this licence
				for local i:int = 0 until visibleFilters.length
					'no check needed if already done
					if containsNew[i] then continue

					if visibleFilters[i].DoesFilter(licence)
						containsNew[i] = 1
						'do not check other filters
						exit
					endif
				Next
			Next

			'=== DRAW ===
			local currSprite:TSprite
			'maybe it has changed since initialization
			genreSize = GetSpriteFromRegistry("gfx_programmegenres_entry.default").area.dimension.copy()
			local currY:int = genresRect.GetY()
			local currX:int = genresRect.GetX()
			local textRect:TRectangle = new TRectangle.Init(currX + 13, currY, genreSize.x - 12 - 5, genreSize.y)
			 
			local oldAlpha:float = GetAlpha()
			local programmeCollection:TPlayerProgrammeCollection = GetPlayerCollection().Get().GetProgrammeCollection()

			'draw each visible filter
			local filter:TProgrammeLicenceFilter
			For local i:int = 0 until visibleFilters.length
				local entryPositionType:string = "entry"
				if i = 0 then entryPositionType = "first"
				if i = visibleFilters.length-1 then entryPositionType = "last"

				local entryDrawType:string = "default"
				'highlighted - if genre contains new entries
				if containsNew[i] = 1 then entryDrawType = "highlighted"
				'active - if genre is the currently used (selected to see tapes)
				if i = currentGenre then entryDrawType = "active"
				'hovered - draw hover effect if hovering
				'can only haver if no episode list is open
				if self.openState <3 and THelper.MouseIn(currX, currY, genreSize.GetX(), genreSize.GetY()-1) then entryDrawType="hovered"

				'add "top" portion when drawing first item
				'do this in the for loop, so the entrydrawType is known
				'(top-portion could contain color code of the drawType)
				if i = 0
					currSprite = GetSpriteFromRegistry("gfx_programmegenres_top."+entryDrawType)
					currSprite.draw(currX, currY)
					currY :+ currSprite.area.GetH()
				endif

				'draw background
				GetSpriteFromRegistry("gfx_programmegenres_"+entryPositionType+"."+entryDrawType).draw(currX,currY)

				'genre background contains a 2px splitter (bottom + top)
				'so add 1 pixel to textY
				textRect.position.SetY(currY + 1)


				Local licenceCount:Int = programmeCollection.GetFilteredLicenceCount(visibleFilters[i])
				Local filterName:string = visibleFilters[i].GetCaption()

				
				If licenceCount > 0
					GetBitmapFontManager().baseFont.drawBlock(filterName + " (" +licenceCount+ ")", textRect.GetX(), textRect.GetY(), textRect.GetW(), textRect.GetH(), ALIGN_LEFT_CENTER, TColor.clBlack)
rem
					SetAlpha 0.6; SetColor 0, 255, 0
					'takes 20% of fps...
					For Local i:Int = 0 To genrecount -1
						DrawLine(currX + 121 + i * 2, currY + 4 + lineHeight*genres - 1, currX + 121 + i * 2, currY + 17 + lineHeight*genres - 1)
					Next
endrem
				else
					SetAlpha 0.25 * GetAlpha()
					GetBitmapFontManager().baseFont.drawBlock(filterName, textRect.GetX(), textRect.GetY(), textRect.GetW(), textRect.GetH(), ALIGN_LEFT_CENTER, TColor.clBlack)
					SetAlpha 4 * GetAlpha()
				EndIf
				'advance to next line
				currY:+ genreSize.y

				'add "bottom" portion when drawing last item
				'do this in the for loop, so the entrydrawType is known
				'(top-portion could contain color code of the drawType)
				if i = visibleFilters.length-1
					currSprite = GetSpriteFromRegistry("gfx_programmegenres_bottom."+entryDrawType)
					currSprite.draw(currX, currY)
					currY :+ currSprite.area.GetH()
				endif
			Next
		EndIf

		'draw tapes of current genre + episodes of a selected series
		If self.openState >=2 and currentGenre >= 0
			DrawTapes(currentgenre)
		EndIf

		'draw episodes background
		If self.openState >=3
			if currentGenre >= 0 then DrawSubTapes(hoveredParentalLicence)
		endif

	End Method


	Method DrawTapes:Int(filterIndex:Int=-1)
		'skip drawing tapes if no genreGroup is selected
		if filterIndex < 0 then return FALSE


		local currSprite:TSprite
		'maybe it has changed since initialization
		entrySize = GetSpriteFromRegistry("gfx_programmeentries_entry.default").area.dimension.copy()
		local currY:int = entriesRect.GetY()
		local currX:int = entriesRect.GetX()
		local font:TBitmapFont = GetBitmapFont("Default", 10)
			 
		local programmeCollection:TPlayerProgrammeCollection = GetPlayerCollection().Get().GetProgrammeCollection()
		local filter:TProgrammeLicenceFilter = TProgrammeLicenceFilter.GetAtIndex(filterIndex)
		local licences:TProgrammeLicence[] = programmeCollection.GetLicencesByFilter(filter)
		'draw slots, even if empty
		For local i:int = 0 until GameRules.maxProgrammeLicencesPerFilter
			local entryPositionType:string = "entry"
			if i = 0 then entryPositionType = "first"
			if i = GameRules.maxProgrammeLicencesPerFilter-1 then entryPositionType = "last"

			local entryDrawType:string = "default"
			local tapeDrawType:string = "default"
			if i < licences.length 
				'== BACKGROUND ==
				'planned is more important than new - both only happen
				'on startprogrammes
				if licences[i].IsPlanned()
					entryDrawType = "planned"
					tapeDrawType = "planned"
				else
					'switch background to "new" if the licence is a just-added-one
					For local licence:TProgrammeLicence = EachIn GetPlayerCollection().Get().GetProgrammeCollection().justAddedProgrammeLicences
						if licences[i] = licence
							entryDrawType = "new"
							tapeDrawType = "new"
							exit
						endif
					Next
				endif
			endif

			
			'=== BACKGROUND ===
			'add "top" portion when drawing first item
			'do this in the for loop, so the entrydrawType is known
			'(top-portion could contain color code of the drawType)
			if i = 0
				currSprite = GetSpriteFromRegistry("gfx_programmeentries_top."+entryDrawType)
				currSprite.draw(currX, currY)
				currY :+ currSprite.area.GetH()
			endif
			GetSpriteFromRegistry("gfx_programmeentries_"+entryPositionType+"."+entryDrawType).draw(currX,currY)


			'=== DRAW TAPE===
			if i < licences.length
				'== ADJUST TAPE TYPE ==
				'do that afterwards because now "new" and "planned" are
				'already handled

				'active - if tape is the currently used
				if i = currentEntry then tapeDrawType = "hovered"
				'hovered - draw hover effect if hovering
				if THelper.MouseIn(currX, currY, entrySize.GetX(), entrySize.GetY()-1) then tapeDrawType="hovered"


				if licences[i].isMovie()
					GetSpriteFromRegistry("gfx_programmetape_movie."+tapeDrawType).draw(currX + 8, currY+1)
				else
					GetSpriteFromRegistry("gfx_programmetape_series."+tapeDrawType).draw(currX + 8, currY+1)
				endif
				font.drawBlock(licences[i].GetTitle(), currX + 22, currY + 3, 150,15, ALIGN_LEFT_CENTER, TColor.clBlack ,0, True, 1.0, False)

			endif


			'advance to next line
			currY:+ entrySize.y

			'add "bottom" portion when drawing last item
			'do this in the for loop, so the entrydrawType is known
			'(top-portion could contain color code of the drawType)
			if i = GameRules.maxProgrammeLicencesPerFilter-1
				currSprite = GetSpriteFromRegistry("gfx_programmeentries_bottom."+entryDrawType)
				currSprite.draw(currX, currY)
				currY :+ currSprite.area.GetH()
			endif
		Next
	End Method


	Method UpdateTapes:Int(filterIndex:Int=-1, mode:int=0)
		'skip doing something without a selected filter
		If filterIndex < 0 then return FALSE

		local currY:int = entriesRect.GetY() + GetSpriteFromRegistry("gfx_programmeentries_top.default").area.GetH()

		local programmeCollection:TPlayerProgrammeCollection = GetPlayerCollection().Get().GetProgrammeCollection()
		local filter:TProgrammeLicenceFilter = TProgrammeLicenceFilter.GetAtIndex(filterIndex)
		local licences:TProgrammeLicence[] = programmeCollection.GetLicencesByFilter(filter)

		For local i:int = 0 until licences.length

			if THelper.MouseIn(entriesRect.GetX(), currY, entrySize.GetX(), entrySize.GetY()-1)
				Game.cursorstate = 1
				local doneSomething:int = FALSE
				'store for sheet-display
				hoveredLicence = licences[i]
				If MOUSEMANAGER.IsHit(1)
					if mode = MODE_PROGRAMMEPLANNER
						If licences[i].isMovie()
							'create and drag new block
							new TGUIProgrammePlanElement.CreateWithBroadcastMaterial( new TProgramme.Create(licences[i]), "programmePlanner" ).drag()
							SetOpen(0)
							doneSomething = true
						Else
							'set the hoveredParentalLicence so the episodes-list is drawn
							hoveredParentalLicence = licences[i]
							SetOpen(3)
							doneSomething = true
						EndIf
					elseif mode = MODE_ARCHIVE
						'create a dragged block
						local obj:TGUIProgrammeLicence = new TGUIProgrammeLicence.CreateWithLicence(licences[i])
						obj.SetLimitToState("archive")
						obj.drag()

						SetOpen(0)
						doneSomething = true
					endif

					'something changed, so stop looping through rest
					if doneSomething
						MOUSEMANAGER.resetKey(1)
						MOUSEMANAGER.resetClicked(1)
						return TRUE
					endif
				endif
			endif

			'next tape
			currY :+ entrySize.y
		Next
		return FALSE
	End Method


	Method DrawSubTapes:Int(parentLicence:TProgrammeLicence)
		if not parentLicence then return FALSE

		local hoveredLicence:TProgrammeLicence = null
		local currSprite:TSprite
		local currY:int = subEntriesRect.GetY()
		local currX:int = subEntriesRect.GetX()
		local font:TBitmapFont = GetBitmapFont("Default", 10)

		
		For Local i:Int = 0 To parentLicence.GetSubLicenceCount()-1
			Local licence:TProgrammeLicence = parentLicence.GetsubLicenceAtIndex(i)

			local entryPositionType:string = "entry"
			if i = 0 then entryPositionType = "first"
			if i = parentLicence.GetSubLicenceCount()-1 then entryPositionType = "last"

			local entryDrawType:string = "default"
			local tapeDrawType:string = "default"
			if licence
				'== BACKGROUND ==
				if licence.IsPlanned()
					entryDrawType = "planned"
					tapeDrawType = "planned"
				endif
			endif

			
			'=== BACKGROUND ===
			'add "top" portion when drawing first item
			'do this in the for loop, so the entrydrawType is known
			'(top-portion could contain color code of the drawType)
			if i = 0
				currSprite = GetSpriteFromRegistry("gfx_programmeentries_top."+entryDrawType)
				currSprite.draw(currX, currY)
				currY :+ currSprite.area.GetH()
			endif
			GetSpriteFromRegistry("gfx_programmeentries_"+entryPositionType+"."+entryDrawType).draw(currX,currY)


			'=== DRAW TAPE===
			if licence
				'== ADJUST TAPE TYPE ==
				'active - if tape is the currently used
				if i = currentSubEntry then tapeDrawType = "hovered"
				'hovered - draw hover effect if hovering
				if THelper.MouseIn(currX, currY, entrySize.GetX(), entrySize.GetY()-3) then tapeDrawType="hovered"

				if licence.isMovie()
					GetSpriteFromRegistry("gfx_programmetape_movie."+tapeDrawType).draw(currX + 8, currY+1)
				else
					GetSpriteFromRegistry("gfx_programmetape_series."+tapeDrawType).draw(currX + 8, currY+1)
				endif
				font.drawBlock("(" + (i+1) + "/" + parentLicence.GetSubLicenceCount() + ") " + licence.GetTitle(), currX + 22, currY + 3, 150,15, ALIGN_LEFT_CENTER, TColor.clBlack ,0, True, 1.0, False)
			endif


			'advance to next line
			currY:+ genreSize.y

			'add "bottom" portion when drawing last item
			'do this in the for loop, so the entrydrawType is known
			'(top-portion could contain color code of the drawType)
			if i = parentLicence.GetSubLicenceCount()-1
				currSprite = GetSpriteFromRegistry("gfx_programmeentries_bottom."+entryDrawType)
				currSprite.draw(currX, currY)
				currY :+ currSprite.area.GetH()
			endif
		Next
	End Method


	Method UpdateSubTapes:Int(parentLicence:TProgrammeLicence)
		if not parentLicence then return False
		
		local currY:int = subEntriesRect.GetY() + GetSpriteFromRegistry("gfx_programmeentries_top.default").area.GetH()


		For Local i:Int = 0 To parentLicence.GetSubLicenceCount()-1
			Local licence:TProgrammeLicence = parentLicence.GetsubLicenceAtIndex(i)

			if licence
				if THelper.MouseIn(subEntriesRect.GetX(), currY, entrySize.GetX(), entrySize.GetY()-1)
					Game.cursorstate = 1

					'store for sheet-display
					hoveredLicence = licence
					If MOUSEMANAGER.IsHit(1)
						'create and drag new block
						new TGUIProgrammePlanElement.CreateWithBroadcastMaterial( new TProgramme.Create(licence), "programmePlanner" ).drag()
						SetOpen(0)
						MOUSEMANAGER.resetKey(1)
						return TRUE
					endif
				endif
			endif

			'next tape
			currY :+ entrySize.y
		Next
		return FALSE
	End Method


	Method Update:int(mode:int=0)
		'gets repopulated automagically if hovered
		hoveredLicence = null

		'if not "open", do nothing (including checking right clicks)
		If not GetOpen() then Return False

		'clicking on the genre selector -> select Genre
		'instead of isClicked (butten must be "normal" then)
		'we use "hit" (as soon as mouse button down)
		local genresStartY:int = GetSpriteFromRegistry("gfx_programmegenres_top.default").area.GetH()

		'only react to genre area if episode area is not open
		if openState <3
			If MOUSEMANAGER.IsHit(1) AND THelper.MouseIn(genresRect.GetX(), genresRect.GetY() + genresStartY, genresRect.GetW(), genreSize.GetY()*TProgrammeLicenceFilter.GetVisibleCount())
				SetOpen(2)
				local visibleFilters:TProgrammeLicenceFilter[] = TProgrammeLicenceFilter.GetVisible()
				currentGenre = Max(0, Min(visibleFilters.length-1, Floor((MouseManager.y - (genresRect.GetY() + genresStartY)) / genreSize.GetY())))
				MOUSEMANAGER.ResetKey(1)
			EndIf
		endif

		'if the genre is selected, also take care of its programmes
		If self.openState >=2
			If currentgenre >= 0 Then UpdateTapes(currentgenre, mode)
			'series episodes are only available in mode 0, so no mode-param to give
			If hoveredParentalLicence Then UpdateSubTapes(hoveredParentalLicence)
		EndIf

		'close if clicked outside - simple mode: so big rect
		if MouseManager.isHit(1) ' and mode=MODE_ARCHIVE
			local closeMe:int = TRUE
			'in all cases the genre selector is opened
			if genresRect.containsXY(MouseManager.x, MouseManager.y) then closeMe = FALSE
			'check tape rect
			if openState >=2 and entriesRect.containsXY(MouseManager.x, MouseManager.y)  then closeMe = FALSE
			'check episodetape rect
			if openState >=3 and subEntriesRect.containsXY(MouseManager.x, MouseManager.y)  then closeMe = FALSE

			if closeMe
				SetOpen(0)
				'MouseManager.ResetKey(1)
			endif
		endif
	End Method


	Method SetOpen:Int(newState:Int)
		newState = Max(0, newState)
		if newState <= 1 then currentgenre=-1
		if newState <= 2 then hoveredParentalLicence=Null
		If newState = 0
			enabled = 0
		else
			enabled = 1
		endif

		self.openState = newState
	End Method
End Type




'the adspot/contractlist shown in the programmeplaner
Type TgfxContractlist extends TPlannerList
	Field hoveredAdContract:TAdContract = null

	Method Create:TgfxContractlist(x:Int, y:Int)
		entrySize = GetSpriteFromRegistry("gfx_programmeentries_entry.default").area.dimension.copy()

		'right align the list
		Pos.SetXY(x - entrySize.GetX(), y)

		'recalculate dimension of the area of all entries (also if not all slots occupied)
		entriesRect = new TRectangle.Init(Pos.GetX(), Pos.GetY(), entrySize.GetX(), 0)
		entriesRect.dimension.y :+ GetSpriteFromRegistry("gfx_programmeentries_top.default").area.GetH()
		entriesRect.dimension.y :+ GameRules.maxContracts * entrySize.GetY()
		entriesRect.dimension.y :+ GetSpriteFromRegistry("gfx_programmeentries_bottom.default").area.GetH()

		Return self
	End Method


	Method Draw:Int()
		If not enabled or self.openState < 1 then return False

		local currSprite:TSprite
		'maybe it has changed since initialization
		entrySize = GetSpriteFromRegistry("gfx_programmeentries_entry.default").area.dimension.copy()
		local currX:int = entriesRect.GetX()
		local currY:int = entriesRect.GetY()
		local font:TBitmapFont = GetBitmapFont("Default", 10)

		local programmeCollection:TPlayerProgrammeCollection = GetPlayerCollection().Get().GetProgrammeCollection()
		'draw slots, even if empty
		For local i:int = 0 until 10 'GameRules.maxContracts
			local contract:TAdContract = programmeCollection.GetAdContractAtIndex(i)

			local entryPositionType:string = "entry"
			if i = 0 then entryPositionType = "first"
			if i = GameRules.maxContracts-1 then entryPositionType = "last"

		
			'=== BACKGROUND ===
			'add "top" portion when drawing first item
			'do this in the for loop, so the entrydrawType is known
			'(top-portion could contain color code of the drawType)
			if i = 0
				currSprite = GetSpriteFromRegistry("gfx_programmeentries_top.default")
				currSprite.draw(currX, currY)
				currY :+ currSprite.area.GetH()
			endif
			GetSpriteFromRegistry("gfx_programmeentries_"+entryPositionType+".default").draw(currX,currY)


			'=== DRAW TAPE===
			if contract
				'hovered - draw hover effect if hovering
				if THelper.MouseIn(currX, currY, entrySize.GetX(), entrySize.GetY()-1)
					GetSpriteFromRegistry("gfx_programmetape_movie.hovered").draw(currX + 8, currY+1)
				else
					GetSpriteFromRegistry("gfx_programmetape_movie.default").draw(currX + 8, currY+1)
				endif
				font.drawBlock(contract.GetTitle(), currX + 22, currY + 3, 150,15, ALIGN_LEFT_CENTER, TColor.clBlack ,0, True, 1.0, False)
			endif


			'advance to next line
			currY:+ entrySize.y

			'add "bottom" portion when drawing last item
			'do this in the for loop, so the entrydrawType is known
			'(top-portion could contain color code of the drawType)
			if i = GameRules.maxContracts-1
				currSprite = GetSpriteFromRegistry("gfx_programmeentries_bottom.default")
				currSprite.draw(currX, currY)
				currY :+ currSprite.area.GetH()
			endif
		Next
	End Method


	Method Update:int()
		'gets repopulated if an contract is hovered
		hoveredAdContract = null

		If not enabled then return FALSE

		if self.openState >= 1
			local currY:int = entriesRect.GetY() + GetSpriteFromRegistry("gfx_programmeentries_top.default").area.GetH()

			local programmeCollection:TPlayerProgrammeCollection = GetPlayerCollection().Get().GetProgrammeCollection()
			For local i:int = 0 until GameRules.maxContracts
				local contract:TAdContract = programmeCollection.GetAdContractAtIndex(i)

				if contract and THelper.MouseIn(entriesRect.GetX(), currY, entrySize.GetX(), entrySize.GetY()-1)
					'store for outside use (eg. displaying a sheet)
					hoveredAdContract = contract

					Game.cursorstate = 1
					If MOUSEMANAGER.IsHit(1)
						new TGUIProgrammePlanElement.CreateWithBroadcastMaterial( new TAdvertisement.Create(contract), "programmePlanner" ).drag()
						MOUSEMANAGER.resetKey(1)
						SetOpen(0)
					EndIf
				endif

				'next tape
				currY :+ entrySize.y
			Next
		endif

		If MOUSEMANAGER.IsHit(2)
			SetOpen(0)
			MOUSEMANAGER.resetKey(2)
		endif

		'close if mouse hit outside - simple mode: so big rect
		if MouseManager.IsHit(1)
			if not entriesRect.containsXY(MouseManager.x, MouseManager.y)
				SetOpen(0)
				'MouseManager.ResetKey(1)
			endif
		endif
	End Method


	Method SetOpen:Int(newState:Int)
		newState = Max(0, newState)
		If newState <= 0 Then enabled = 0 else enabled = 1
		self.openState = newState
	End Method
End Type





'Programmeblocks used in Auction-Screen
'they do not need to have gui/non-gui objects as no special
'handling is done (just clicking)
Type TAuctionProgrammeBlocks extends TGameObject {_exposeToLua="selected"}
	Field area:TRectangle = new TRectangle.Init(0,0,0,0)
	Field licence:TProgrammeLicence		'the licence getting auctionated (a series, movie or collection)
	Field bestBid:int = 0				'what was bidden for that licence
	Field bestBidder:int = 0			'what was bidden for that licence
	Field slot:int = 0					'for ordering (and displaying sheets without overlapping)
	Field bidSavings:float = 0.75		'how much to shape of the original price
	Field _imageWithText:TImage = Null	'cached image

	Global bidSavingsMaximum:float		= 0.85			'base value
	Global bidSavingsMinimum:float		= 0.50			'base value
	Global bidSavingsDecreaseBy:float	= 0.05			'reduce the bidSavings-value per day
	Global List:TList = CreateList()	'list of all blocks

	'todo/idea: we could add a "started" and a "endTime"-field so
	'           auctions do not end at midnight but individually


	Method Create:TAuctionProgrammeBlocks(slot:Int=0, licence:TProgrammeLicence)
		self.area.position.SetXY(140 + (slot Mod 2) * 260, 80 + Ceil(slot / 2) * 60)
		self.area.dimension.CopyFrom(GetSpriteFromRegistry("gfx_auctionmovie").area.dimension)
		self.slot = slot
		self.Refill(licence)
		List.AddLast(self)

		'sort so that slot1 comes before slot2 without having to matter about creation order
		TAuctionProgrammeBlocks.list.sort(True, TAuctionProgrammeBlocks.sort)
		Return self
	End Method


	Function GetByLicence:TAuctionProgrammeBlocks(licence:TProgrammeLicence, licenceID:int=-1)
		For local obj:TAuctionProgrammeBlocks = eachin List
			if licence and obj.licence = licence then return obj
			if obj.licence.id = licenceID then return obj
		Next
		return null
	End Function


	Function Sort:Int(o1:Object, o2:Object)
		Local s1:TAuctionProgrammeBlocks = TAuctionProgrammeBlocks(o1)
		Local s2:TAuctionProgrammeBlocks = TAuctionProgrammeBlocks(o2)
		If Not s2 Then Return 1                  ' Objekt nicht gefunden, an das Ende der Liste setzen
        Return (s1.slot)-(s2.slot)
	End Function


	'give all won auctions to the winners
	Function EndAllAuctions()
		For Local obj:TAuctionProgrammeBlocks = EachIn TAuctionProgrammeBlocks.List
			obj.EndAuction()
		Next
	End Function


	'sets another licence into the slot
	Method Refill:int(programmeLicence:TProgrammeLicence=null)
		licence = programmeLicence
		local minPrice:int = 200000

		while not licence and minPrice >= 0
			licence = GetProgrammeLicenceCollection().GetRandomWithPrice(minPrice)
			'lower the requirements
			if not licence then minPrice :- 10000
		Wend
		if not licence then THROW "[ERROR] TAuctionProgrammeBlocks.Refill - no licence"

		'set licence owner to "-1" so it gets not returned again from Random-Getter
		licence.SetOwner(-1)

		'reset cache
		_imageWithText = Null
		'reset bids
		bestBid = 0
		bestBidder = 0
		bidSavings = bidSavingsMaximum

		'emit event
		EventManager.triggerEvent(TEventSimple.Create("ProgrammeLicenceAuction.Refill", new TData.Add("licence", licence).AddNumber("slot", slot), self))
	End Method


	Method EndAuction:int()
		If not licence then return FALSE

		if bestBidder
			local player:TPlayer = GetPlayerCollection().Get(bestBidder)
			player.GetProgrammeCollection().AddProgrammeLicence(licence)
			Print "player "+player.name + " won the auction for: "+licence.GetTitle()
		End If
		EventManager.triggerEvent(TEventSimple.Create("ProgrammeLicenceAuction.endAuction", new TData.Add("licence", licence).AddNumber("bestBidder", bestBidder).AddNumber("bestBid", bestBid).AddNumber("bidSavings", bidSavings), self))

		'found nobody to buy this licence
		'so we decrease price a bit
		if not bestBidder
			self.bidSavings :- self.bidSavingsDecreaseBy
		Endif

		'if we had a bidder or found nobody with the allowed price minimum
		'we add another licence to this block and reset everything
		if bestBidder or self.bidSavings < self.bidSavingsMinimum
			Refill()
		endif
	End Method


	Method GetLicence:TProgrammeLicence()  {_exposeToLua}
		return licence
	End Method


	Method SetBid:int(playerID:Int)
		local player:TPlayer = GetPlayerCollection().Get(playerID)
		If not player then return -1
		'if the playerID was -1 ("auto") we should assure we have a correct id now
		playerID = player.playerID
		'already highest bidder, no need to add another bid
		if playerID = bestBidder then return 0


		local price:int = GetNextBid()
		If player.getFinance().PayAuctionBid(price, self.GetLicence())
			'another player was highest bidder, we pay him back the
			'bid he gave (which is the currently highest bid...)
			If bestBidder and GetPlayerCollection().Get(bestBidder)
				GetPlayerFinanceCollection().Get(bestBidder).PayBackAuctionBid(bestBid, self)
			EndIf
			'set new bid values
			bestBidder = playerID
			bestBid = price

			'reset so cache gets renewed
			_imageWithText = null

			EventManager.triggerEvent(TEventSimple.Create("ProgrammeLicenceAuction.setBid", new TData.Add("licence", licence).AddNumber("bestBidder", bestBidder).AddNumber("bestBid", bestBid), self))
		EndIf
		return price
	End Method


	Method GetNextBid:int() {_exposeToLua}
		Local nextBid:Int = 0
		'no bid done yet, next bid is the licences price cut by 25%
		if bestBid = 0
			nextBid = licence.getPrice() * 0.75
		else
			nextBid = bestBid

			If nextBid < 100000
				nextBid :+ 10000
			Else If nextBid >= 100000 And nextBid < 250000
				nextBid :+ 25000
			Else If nextBid >= 250000 And nextBid < 750000
				nextBid :+ 50000
			Else If nextBid >= 750000
				nextBid :+ 75000
			EndIf
		endif

		return nextBid
	End Method


	Method ShowSheet:Int(x:Int,y:Int)
		licence.ShowSheet(x,y)
	End Method


    'draw the Block inclusive text
    'zeichnet den Block inklusive Text
    Method Draw()
		SetColor 255,255,255  'normal
		'not yet cached?
	    If not _imageWithText
			'print "renew cache for "+self.licence.GetTitle()
			_imageWithText = GetSpriteFromRegistry("gfx_auctionmovie").GetImageCopy()
			if not _imageWithText then THROW "GetImage Error for gfx_auctionmovie"

			local pix:TPixmap = LockImage(_imageWithText)
			local font:TBitmapFont		= GetBitmapFont("Default", 12)
			local titleFont:TBitmapFont	= GetBitmapFont("Default", 12, BOLDFONT)

			'set target for fonts
			TBitmapFont.setRenderTarget(_imageWithText)

			If bestBidder
				local player:TPlayer = GetPlayerCollection().Get(bestBidder)
				titleFont.drawStyled(player.name, 31,33, player.color, 2, 1, 0.25)
			else
				font.drawStyled(GetLocale("AUCTION_WITHOUT_BID"), 31,33, TColor.CreateGrey(150), 0, 1, 0.25)
			EndIf
			titleFont.drawBlock(licence.GetTitle(), 31,5, 215,30, null, TColor.clBlack, 1, 1, 0.50)

			font.drawBlock(GetLocale("AUCTION_MAKE_BID")+": "+TFunctions.DottedValue(GetNextBid())+CURRENCYSIGN, 31,33, 212,20, new TVec2D.Init(ALIGN_RIGHT), TColor.clBlack, 1)

			'reset target for fonts
			TBitmapFont.setRenderTarget(null)
	    EndIf
		SetColor 255,255,255
		SetAlpha 1
		DrawImage(_imageWithText, area.GetX(), area.GetY())
    End Method


	Function DrawAll()
		For Local obj:TAuctionProgrammeBlocks = EachIn List
			obj.Draw()
		Next

		'draw sheets (must be afterwards to avoid overlapping (itemA Sheet itemB itemC) )
		For Local obj:TAuctionProgrammeBlocks = EachIn List
			if obj.area.containsXY(MouseManager.x, MouseManager.y)
				local leftX:int = 30, rightX:int = 30
				local sheetY:float 	= 20
				local sheetX:float 	= leftX
				local sheetAlign:int= 0
				'if mouse on left side of screen - align sheet on right side
				if MouseManager.x < GetGraphicsManager().GetWidth()/2
					sheetX = GetGraphicsManager().GetWidth() - rightX
					sheetAlign = 1
				endif

				SetBlend LightBlend
				SetAlpha 0.20
				GetSpriteFromRegistry("gfx_auctionmovie").Draw(obj.area.GetX(), obj.area.GetY())
				SetAlpha 1.0
				SetBlend AlphaBlend


				obj.licence.ShowSheet(sheetX, sheetY, sheetAlign, TBroadcastMaterial.TYPE_PROGRAMME)
				Exit
			endif
		Next
	End Function



	Function UpdateAll:int()
		'without clicks we do not need to handle things
		if not MOUSEMANAGER.IsClicked(1) then return FALSE

		For Local obj:TAuctionProgrammeBlocks = EachIn TAuctionProgrammeBlocks.List
			if obj.bestBidder <> GetPlayerCollection().playerID And obj.area.containsXY(MouseManager.x, MouseManager.y)
				obj.SetBid( GetPlayerCollection().playerID )  'set the bid
				MOUSEMANAGER.ResetKey(1)
				return TRUE
			EndIf
		Next
	End Function

End Type






'a graphical representation of programmes/news/ads...
Type TGUINews extends TGUIGameListItem
	Field news:TNews = Null
	Field imageBaseName:string = "gfx_news_sheet"
	Field cacheTextOverlay:TImage

    Method Create:TGUINews(pos:TVec2D=null, dimension:TVec2D=null, value:String="")
		Super.Create(pos, dimension, value)

		return self
	End Method

	Method SetNews:int(news:TNews)
		self.news = news
		if news
			'now we can calculate the item width
			self.Resize( GetSpriteFromRegistry(Self.imageBaseName+news.newsEvent.genre).area.GetW(), GetSpriteFromRegistry(Self.imageBaseName+news.newsEvent.genre).area.GetH() )
		endif
		'self.SetLimitToState("Newsplanner")

		'as the news inflicts the sorting algorithm - resort
		GUIManager.sortLists()
	End Method


	Method Compare:int(Other:Object)
		local otherBlock:TGUINews = TGUINews(Other)
		If otherBlock<>null
			'both items are dragged - check time
			if self._flags & GUI_OBJECT_DRAGGED AND otherBlock._flags & GUI_OBJECT_DRAGGED
				'if a drag was earlier -> move to top
				if self._timeDragged < otherBlock._timeDragged then Return 1
				if self._timeDragged > otherBlock._timeDragged then Return -1
				return 0
			endif

			if self.news and otherBlock.news
				local publishDifference:int = self.news.GetPublishTime() - otherBlock.news.GetPublishTime()

				'self is newer ("later") than other
				if publishDifference>0 then return -1
				'self is older than other
				if publishDifference<0 then return 1
				'self is same age than other
				if publishDifference=0 then return Super.Compare(Other)
			endif
		endif

		return Super.Compare(Other)
	End Method


	'override default update-method
	Method Update:int()
		super.Update()

		'set mouse to "hover"
		if news.owner = GetPlayerCollection().playerID or news.owner <= 0 and mouseover then Game.cursorstate = 1
		'set mouse to "dragged"
		if isDragged() then Game.cursorstate = 2
	End Method


	Method DrawTextOverlay()
		local screenX:float = int(GetScreenX())
		local screenY:float = int(GetScreenY())

		'===== CREATE CACHE IF MISSING =====
		if not cacheTextOverlay
			cacheTextOverlay = TFunctions.CreateEmptyImage(rect.GetW(), rect.GetH())
'			cacheTextOverlay = CreateImage(rect.GetW(), rect.GetH(), DYNAMICIMAGE | FILTEREDIMAGE)

			'render to image
			TBitmapFont.SetRenderTarget(cacheTextOverlay)

			'default texts (title, text,...)
			GetBitmapFontManager().basefontBold.drawBlock(news.GetTitle(), 15, 2, 330, 15, null, TColor.CreateGrey(20))
			GetBitmapFontManager().baseFont.drawBlock(news.GetDescription(), 15, 17, 340, 50 + 8, null, TColor.CreateGrey(100))

			local oldAlpha:float = GetAlpha()
			SetAlpha 0.3*oldAlpha
			GetBitmapFont("Default", 9).drawBlock(news.GetGenreString(), 15, 73, 120, 15, null, TColor.clBlack)
			SetAlpha 1.0*oldAlpha

			'set back to screen Rendering
			TBitmapFont.SetRenderTarget(null)
		endif

		'===== DRAW CACHE =====
		DrawImage(cacheTextOverlay, screenX, screenY)
	End Method


	Method DrawContent()
		State = 0
		SetColor 255,255,255

		if self.RestrictViewPort()
			local screenX:float = int(GetScreenX())
			local screenY:float = int(GetScreenY())

			local oldAlpha:float = GetAlpha()
			local itemAlpha:float = 1.0
			'fade out dragged
			if isDragged() then itemAlpha = 0.25 + 0.5^GuiManager.GetDraggedNumber(self)

			SetAlpha oldAlpha*itemAlpha
			'background - no "_dragged" to add to name
			GetSpriteFromRegistry(Self.imageBaseName+news.GetGenre()).Draw(screenX, screenY)

			'highlight hovered news (except already dragged)
			if not isDragged() and self = RoomHandler_News.hoveredGuiNews
				local oldAlpha:float = GetAlpha()
				SetBlend LightBlend
				SetAlpha 0.30*oldAlpha
				SetColor 150,150,150
				GetSpriteFromRegistry(Self.imageBaseName+news.GetGenre()).Draw(screenX, screenY)
				SetAlpha oldAlpha
				SetBlend AlphaBlend
			endif

			'===== DRAW CACHED TEXTS =====
			'creates cache if needed
			DrawTextOverlay()

			'===== DRAW NON-CACHED TEXTS =====
			if not news.paid
				GetBitmapFontManager().basefontBold.drawBlock(news.GetPrice() + ",-", screenX + 262, screenY + 70, 90, -1, new TVec2D.Init(ALIGN_RIGHT), TColor.clBlack)
			else
				GetBitmapFontManager().basefontBold.drawBlock(news.GetPrice() + ",-", screenX + 262, screenY + 70, 90, -1, new TVec2D.Init(ALIGN_RIGHT), TColor.CreateGrey(50))
			endif

			Select GetWorldTime().GetDay() - GetWorldTime().GetDay(news.GetHappenedtime())
				case 0	GetBitmapFontManager().baseFont.drawBlock(GetLocale("TODAY")+" " + GetWorldTime().GetFormattedTime(news.GetHappenedtime()), screenX + 90, screenY + 73, 140, 15, new TVec2D.Init(ALIGN_RIGHT), TColor.clBlack )
				case 1	GetBitmapFontManager().baseFont.drawBlock("("+GetLocale("OLD")+") "+GetLocale("YESTERDAY")+" "+ GetWorldTime().GetFormattedTime(news.GetHappenedtime()), screenX + 90, screenY + 73, 140, 15, new TVec2D.Init(ALIGN_RIGHT), TColor.clBlack)
				case 2	GetBitmapFontManager().baseFont.drawBlock("("+GetLocale("OLD")+") "+GetLocale("TWO_DAYS_AGO")+" " + GetWorldTime().GetFormattedTime(news.GetHappenedtime()), screenX + 90, screenY + 73, 140, 15, new TVec2D.Init(ALIGN_RIGHT), TColor.clBlack)
			End Select

			SetColor 255, 255, 255
			SetAlpha oldAlpha
	
			self.resetViewport()
		endif

		if TVTDebugInfos
			local oldAlpha:Float = GetAlpha()
			SetAlpha oldAlpha * 0.75
			SetColor 0,0,0

			local w:int = rect.GetW()
			local h:int = rect.GetH()
			local screenX:float = int(GetScreenX())
			local screenY:float = int(GetScreenY())
			DrawRect(screenX, screenY, w,h)
		
			SetColor 255,255,255
			SetAlpha 1.0

			local textY:int = screenY + 2
			local fontBold:TBitmapFont = GetBitmapFontManager().basefontBold
			local fontNormal:TBitmapFont = GetBitmapFontManager().basefont
			
			fontBold.draw("News: " + news.newsEvent.GetTitle(), screenX + 5, textY)
			textY :+ 14	
			fontNormal.draw("Preis: " + news.GetPrice()+"  (Preismodifikator: "+news.newsEvent.priceModifier+")", screenX + 5, textY)
			textY :+ 12	
			fontNormal.draw("Qualitaet: "+news.GetQuality() +" (Event:"+ news.newsEvent.quality + ")", screenX + 5, textY)
			textY :+ 12	
			fontNormal.draw("Attraktivitaet: "+news.newsEvent.GetAttractiveness()+"    Aktualitaet: " + news.newsEvent.ComputeTopicality(), screenX + 5, textY)
			textY :+ 12	
			fontNormal.draw("Alter: " + Long(GetWorldTime().GetTimeGone() - news.GetHappenedtime()) + " Sekunden  (" + (GetWorldTime().GetDay() - GetWorldTime().GetDay(news.GetHappenedtime())) + " Tage)", screenX + 5, textY)
			textY :+ 12	
			rem
			local eventCan:string = ""
			if news.newsEvent.skippable
				eventCan :+ "ueberspringbar)"
			else
				eventCan :+ "nicht ueberspringbar"
			endif
			if eventCan <> "" then eventCan :+ ",  "
			if news.newsEvent.reuseable
				eventCan :+ "erneut nutzbar"
			else
				eventCan :+ "nicht erneut nutzbar"
			endif
			
			fontNormal.draw("Ist: " + eventCan, screenX + 5, textY)
			textY :+ 12	
			endrem
			fontNormal.draw("Effekte: " + news.newsEvent.happenEffects.Length + "x onHappen, "+news.newsEvent.broadcastEffects.Length + "x onBroadcast    Newstyp: " + news.newsEvent.newsType + "   Genre: "+news.newsEvent.genre, screenX + 5, textY)
			textY :+ 12	

			SetAlpha oldAlpha
		Endif
	End Method
End Type




Type TGUIProgrammeLicenceSlotList extends TGUISlotList
	field  acceptType:int		= 0	'accept all
	Global acceptAll:int		= 0
	Global acceptMovies:int		= 1
	Global acceptSeries:int		= 2

    Method Create:TGUIProgrammeLicenceSlotList(position:TVec2D = null, dimension:TVec2D = null, limitState:String = "")
		Super.Create(position, dimension, limitState)

		'albeit the list base already handles drop on itself
		'we want to intercept too -- to stop dropping if not
		'enough money is available
		'---alternatively we could intercept programmeblocks-drag-event
		'EventManager.registerListenerFunction( "guiobject.onDropOnTarget", self.onDropOnTarget, accept, self)

		return self
	End Method


	Method ContainsLicence:int(licence:TProgrammeLicence)
		for local i:int = 0 to self.GetSlotAmount()-1
			local block:TGUIProgrammeLicence = TGUIProgrammeLicence(self.GetItemBySlot(i))
			if block and block.licence = licence then return TRUE
		Next
		return FALSE
	End Method


	'overriden Method: so it does not accept a certain
	'kind of programme (movies - series)
	Method AddItem:int(item:TGUIobject, extra:object=null)
		local coverBlock:TGUIProgrammeLicence = TGUIProgrammeLicence(item)
		if not coverBlock then return FALSE

		'something odd happened - no licence
		if not coverBlock.licence then return FALSE

		if acceptType > 0
			'movies and series do not accept collections or episodes
			if acceptType = acceptMovies and coverBlock.licence.isSeries() then return FALSE
			if acceptType = acceptSeries and coverBlock.licence.isMovie() then return FALSE
		endif

		if super.AddItem(item,extra)
			'print "added an item ... slot state:" + self.GetUnusedSlotAmount()+"/"+self.GetSlotAmount()
			return true
		endif

		return FALSE
	End Method
End Type



'a graphical representation of programmes to buy/sell/archive...
Type TGUIProgrammeLicence extends TGUIGameListItem
	Field licence:TProgrammeLicence


    Method Create:TGUIProgrammeLicence(pos:TVec2D=null, dimension:TVec2D=null, value:String="")
		Super.Create(pos, dimension, value)

		'override defaults - with the default genre identifier
		'(eg. "undefined" -> "gfx_movie_undefined")
		self.assetNameDefault = "gfx_movie_"+TVTProgrammeGenre.GetGenreStringID(-1)
		self.assetNameDragged = "gfx_movie_"+TVTProgrammeGenre.GetGenreStringID(-1)

		return self
	End Method


	Method CreateWithLicence:TGUIProgrammeLicence(licence:TProgrammeLicence)
		self.Create()
		self.setProgrammeLicence(licence)
		return self
	End Method


	Method SetProgrammeLicence:TGUIProgrammeLicence(licence:TProgrammeLicence)
		self.licence = licence

		'get the string identifier of the genre (eg. "adventure" or "action")
		local genreString:string = TVTProgrammeGenre.GetGenreStringID(licence.GetGenre())
		local assetName:string = ""

		'if it is a collection or series
		if licence.isCollection()
			assetName = "gfx_movie_" + genreString
		elseif licence.isSeries()
			assetName = "gfx_series_" + genreString
		else
			assetName = "gfx_movie_" + genreString
		endif

		'use the name of the returned sprite - default or specific one
		assetName = GetSpriteFromRegistry(assetName, assetNameDefault).GetName()

		'check if "dragged" exists
		local assetNameDragged:string = assetName+".dragged"
		if GetSpriteFromRegistry(assetNameDragged).GetName() <> assetNameDragged
			assetNameDragged = assetName
		endif
		
		self.InitAssets(assetName, assetNameDragged)

		return self
	End Method


	'override to only allow dragging for affordable or own licences
	Method IsDragable:Int() 
		If Super.IsDragable()
			return (licence.owner = GetPlayerCollection().playerID or (licence.owner <= 0 and IsAffordable()))
		Else
			return False
		EndIf
	End Method


	Method IsAffordable:Int()
		return GetPlayerCollection().Get().getFinance().canAfford(licence.getPrice())
	End Method


	Method DrawSheet(leftX:int=30, rightX:int=30)
'		self.parentBlock.DrawSheet()
		local sheetY:float 	= 20
		local sheetX:float 	= leftX
		local sheetAlign:int= 0
		'if mouse on left side of screen - align sheet on right side
		if MouseManager.x < GetGraphicsManager().GetWidth()/2
			sheetX = GetGraphicsManager().GetWidth() - rightX
			sheetAlign = 1
		endif

		SetColor 0,0,0
		SetAlpha 0.2
		Local x:Float = self.GetScreenX()
		Local tri:Float[]=[sheetX+20,sheetY+25,sheetX+20,sheetY+90,self.GetScreenX()+self.GetScreenWidth()/2.0+3,self.GetScreenY()+self.GetScreenHeight()/2.0]
		DrawPoly(tri)
		SetColor 255,255,255
		SetAlpha 1.0

		self.licence.ShowSheet(sheetX,sheetY, sheetAlign, TBroadcastMaterial.TYPE_PROGRAMME)
	End Method


	Method Draw:Int()
		SetColor 255,255,255

		'make faded as soon as not "dragable" for us
		if licence.owner <> GetPlayerCollection().playerID and (licence.owner<=0 and not IsAffordable()) then SetAlpha 0.75
		Super.Draw()
		SetAlpha 1.0
	End Method
End Type






'a graphical representation of contracts at the ad-agency ...
Type TGuiAdContract extends TGUIGameListItem
	Field contract:TAdContract


    Method Create:TGuiAdContract(pos:TVec2D=null, dimension:TVec2D=null, value:String="")
		Super.Create(pos, dimension, value)

		self.assetNameDefault = "gfx_contracts_0"
		self.assetNameDragged = "gfx_contracts_0_dragged"

		return self
	End Method


	Method CreateWithContract:TGuiAdContract(contract:TAdContract)
		self.Create()
		self.setContract(contract)
		return self
	End Method


	Method SetContract:TGuiAdContract(contract:TAdContract)
		self.contract		= contract
		'targetgroup is between 0-9
		self.InitAssets(GetAssetName(contract.GetLimitedToTargetGroup(), FALSE), GetAssetName(contract.GetLimitedToTargetGroup(), TRUE))

		return self
	End Method


	Method GetAssetName:string(targetGroup:int=-1, dragged:int=FALSE)
		if targetGroup < 0 and contract then targetGroup = contract.GetLimitedToTargetGroup()
		local result:string = "gfx_contracts_" + Min(9,Max(0, targetGroup))
		if dragged then result = result + "_dragged"
		return result
	End Method


	'override default update-method
	Method Update:int()
		super.Update()

		'disable dragging if not signable
		if contract.owner <= 0
			if not contract.IsAvailableToSign(GetPlayer().playerID)
				SetOption(GUI_OBJECT_DRAGABLE, False)
			else
				SetOption(GUI_OBJECT_DRAGABLE, True)
			endif
		endif
			

		'set mouse to "hover"
		if contract.owner = GetPlayer().playerID or contract.owner <= 0 and mouseover then Game.cursorstate = 1
				
		
		'set mouse to "dragged"
		if isDragged() then Game.cursorstate = 2
	End Method


	Method DrawSheet(leftX:int=30, rightX:int=30)
		local sheetY:float 	= 20
		local sheetX:float 	= leftX
		local sheetAlign:int= 0
		'if mouse on left side of screen - align sheet on right side
		'METHOD 1
		'instead of using the half screen width, we use another
		'value to remove "flipping" when hovering over the desk-list
		'if MouseManager.x < RoomHandler_AdAgency.suitcasePos.GetX()
		'METHOD 2
		'just use the half of a screen - ensures the data sheet does not overlap
		'the object
		if MouseManager.x < GetGraphicsManager().GetWidth()/2
			sheetX = GetGraphicsManager().GetWidth() - rightX
			sheetAlign = 1
		endif

		SetColor 0,0,0
		SetAlpha 0.2
		Local x:Float = self.GetScreenX()
		Local tri:Float[]=[sheetX+20,sheetY+25,sheetX+20,sheetY+90,self.GetScreenX()+self.GetScreenWidth()/2.0+3,self.GetScreenY()+self.GetScreenHeight()/2.0]
		DrawPoly(tri)
		SetColor 255,255,255
		SetAlpha 1.0

		self.contract.ShowSheet(sheetX,sheetY, sheetAlign, TBroadcastMaterial.TYPE_ADVERTISEMENT)
	End Method


	Method DrawGhost()
		'by default a shaded version of the gui element is drawn at the original position
		self.SetOption(GUI_OBJECT_IGNORE_POSITIONMODIFIERS, TRUE)
		SetAlpha 0.5

		local backupAssetName:string = self.asset.getName()
		self.asset = GetSpriteFromRegistry(assetNameDefault)
		self.Draw()
		self.asset = GetSpriteFromRegistry(backupAssetName)

		SetAlpha 1.0
		self.SetOption(GUI_OBJECT_IGNORE_POSITIONMODIFIERS, FALSE)
	End Method


	Method Draw:Int()
		SetColor 255,255,255
		local oldCol:TColor = new TColor.Get()

		'make faded as soon as not "dragable" for us
		if not isDragable()
			'in our collection
			if contract.owner = GetPlayerCollection().playerID
				SetAlpha 0.80*oldCol.a
				SetColor 200,200,200
			else
				SetAlpha 0.70*oldCol.a
				SetColor 250,200,150
			endif
		endif

		Super.Draw()

		oldCol.SetRGBA()
	End Method
End Type




Type TGUIAdContractSlotList extends TGUISlotList

    Method Create:TGUIAdContractSlotList(position:TVec2D = null, dimension:TVec2D = null, limitState:String = "")
		Super.Create(position, dimension, limitState)
		return self
	End Method


	Method ContainsContract:int(contract:TAdContract)
		for local i:int = 0 to self.GetSlotAmount()-1
			local block:TGuiAdContract = TGuiAdContract( self.GetItemBySlot(i) )
			if block and block.contract = contract then return TRUE
		Next
		return FALSE
	End Method


	'override to add sort
	Method AddItem:int(item:TGUIobject, extra:object=null)
		if super.AddItem(item, extra)
			GUIManager.sortLists()
			return TRUE
		endif
		return FALSE
	End Method


	'override default event handler
	Function onDropOnTarget:int( triggerEvent:TEventBase )
		local item:TGUIListItem = TGUIListItem(triggerEvent.GetSender())
		if item = Null then return FALSE

		'ATTENTION:
		'Item is still in dragged state!
		'Keep this in mind when sorting the items

		'only handle if coming from another list ?
		local parent:TGUIobject = item._parent
		if TGUIPanel(parent) then parent = TGUIPanel(parent)._parent
		local fromList:TGUIListBase = TGUIListBase(parent)
		if not fromList then return FALSE

		local toList:TGUIListBase = TGUIListBase(triggerEvent.GetReceiver())
		if not toList then return FALSE

		local data:TData = triggerEvent.getData()
		if not data then return FALSE

		'move item if possible
		fromList.removeItem(item)
		'try to add the item, if not able, readd
		if not toList.addItem(item, data)
			if fromList.addItem(item) then return TRUE

			'not able to add to "toList" but also not to "fromList"
			'so set veto and keep the item dragged
			triggerEvent.setVeto()
		endif


		return TRUE
	End Function
End Type

