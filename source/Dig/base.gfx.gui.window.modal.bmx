Rem
	===========================================================
	GUI Modal Window
	===========================================================
End Rem
SuperStrict
Import "base.util.virtualgraphics.bmx"
Import "base.util.interpolation.bmx"
Import "base.gfx.gui.window.base.bmx"
Import "base.gfx.gui.button.bmx"




Type TGUIModalWindow Extends TGUIWindowBase
	Field DarkenedArea:TRectangle = Null
	'the area the window centers to
	Field screenArea:TRectangle = Null
	Field buttons:TGUIButton[]
	Field autoAdjustHeight:Int = True
	'=== CLOSING VARIABLES ===
	'indicator if 
	Field closeActionStarted:int = 0
	'the time a close action started
	Field closeActionTime:int = 0
	'the time a close action runs
	Field closeActionDuration:int = 1000
	'the position of the widget when closing
	Field closeActionStartPosition:TVec2D = new TVec2D



	Method Create:TGUIModalWindow(pos:TVec2D, dimension:TVec2D, limitState:String = "")
		Super.Create(pos, dimension, limitState)

		setZIndex(10000)

		'by default just a "ok" button
		SetDialogueType(1)

		'set another panel background
		guiBackground.spriteBaseName = "gfx_gui_modalWindow"


		'we want to know if one clicks on a windows buttons
		AddEventListener(EventManager.registerListenerMethod("guiobject.onClick", Self, "onButtonClick"))

		'fire event so others know that the window is created
		EventManager.triggerEvent(TEventSimple.Create("guiModalWindow.onCreate", Self))
		Return Self
	End Method


	'easier setter for dialogue types
	Method SetDialogueType:Int(typeID:Int)
		For Local button:TGUIobject = EachIn Self.buttons
			button.remove()
			'DeleteChild(button)
		Next
		buttons = New TGUIButton[0] '0 sized array

		Select typeID
			'a default button
			Case 1
				buttons = buttons[..1]
				buttons[0] = New TGUIButton.Create(new TVec2D.Init(0, 0), new TVec2D.Init(120, -1), GetLocale("OK"))
				AddChild(buttons[0])
				'set to ignore parental padding (so it starts at 0,0)
				buttons[0].SetOption(GUI_OBJECT_IGNORE_PARENTPADDING, True)
			'yes and no button
			Case 2
				buttons = buttons[..2]
				buttons[0] = New TGUIButton.Create(new TVec2D.Init(0, 0), new TVec2D.Init(90, -1), GetLocale("YES"))
				buttons[1] = New TGUIButton.Create(new TVec2D.Init(0, 0), new TVec2D.Init(90, -1), GetLocale("NO"))
				AddChild(buttons[0])
				AddChild(buttons[1])
				'set to ignore parental padding (so it starts at 0,0)
				buttons[0].SetOption(GUI_OBJECT_IGNORE_PARENTPADDING, True)
				buttons[1].SetOption(GUI_OBJECT_IGNORE_PARENTPADDING, True)

		End Select
	End Method


	'size 0, 0 is not possible (leads to autosize)
	Method Resize(w:Float = 0, h:Float = 0)
		Super.Resize(w, h)
		'move button
		If buttons.length = 1
			buttons[0].rect.position.setXY(rect.GetW()/2 - buttons[0].rect.GetW()/2, GetScreenHeight() - 50)
		ElseIf buttons.length = 2
			buttons[0].rect.position.setXY(rect.GetW()/2 - buttons[0].rect.GetW() - 10, GetScreenHeight() - 50)
			buttons[1].rect.position.setXY(rect.GetW()/2 + 10, GetScreenHeight() - 50)
		EndIf

		Recenter()
	End Method


	'overwrite windowBase-method to recenter after appearance change
	Method onStatusAppearanceChange:int()
		Super.onStatusAppearanceChange()
		Recenter()
	End Method


	Method Recenter:Int(moveBy:TVec2D=Null)
		'center the window
		Local centerX:Float=0.0
		Local centerY:Float=0.0
		If Not screenArea
			centerX = VirtualWidth()/2
			centerY = VirtualHeight()/2
		Else
			centerX = screenArea.getX() + screenArea.GetW()/2
			centerY = screenArea.getY() + screenArea.GetH()/2
		EndIf

		If Not moveBy Then moveBy = new TVec2D.Init(0,0)
		rect.position.setXY(centerX - rect.getW()/2 + moveBy.getX(),centerY - rect.getH()/2 + moveBy.getY() )
	End Method


	'close the window (eg. with an animation)
	Method Close:Int(closeButton:Int=-1)
		'only close once :D
		if closeActionStarted then return False
		
		closeActionStarted = True
		closeActionTime = Time.GetTimeGone()
		closeActionStartPosition = rect.position.copy()

		'fire event so others know that the window is closed
		'and what button was used
		EventManager.triggerEvent(TEventSimple.Create("guiModalWindow.onClose", new TData.AddNumber("closeButton", closeButton) , Self))
	End Method


	Method canClose:Int()
		'is there an animation active?
		If closeActionStarted
			If closeActionTime + closeActionDuration < Time.GetTimeGone()
				Return True
			Else
				Return False
			EndIf
		Else
			Return True
		EndIf
	End Method


	'handle clicks on the various close buttons
	Method onButtonClick:Int( triggerEvent:TEventBase )
		Local sender:TGUIButton = TGUIButton(triggerEvent.GetSender())
		If sender = Null Then Return False

		For Local i:Int = 0 To Self.buttons.length - 1
			If Self.buttons[i] <> sender Then Continue

			'close window
			Self.close(i)
		Next
	End Method


	'override default update-method
	Method Update:Int()
		'maybe children intercept clicks...
		'so call Super.Update as it calls UpdateChildren already
		Super.Update()

		if Not GuiManager.GetKeystrokeReceiver() and KeyManager.IsHit(KEY_ESCAPE)
			'do not allow another ESC-press for 250ms
			KeyManager.blockKey(KEY_ESCAPE, 250)
			self.close()
		endif

		'remove the window as soon as there is no animation active
		'until then: play the animation
		If closeActionStarted and canClose()
			Self.remove()
			Return False
		EndIf

		'we manage drawing and updating our background
		If guiBackground then guiBackground.Update()

		'deactivate mousehandling for other underlying objects
		GUIManager._ignoreMouse = True
	End Method


	Method DrawContent()
		local oldCol:TColor = new TColor.Get()
		local newAlpha:Float = 1.0

		if closeActionStarted
			local yUntilScreenLeft:int = VirtualHeight() - (closeActionStartPosition.y + GetScreenHeight())
			newAlpha = 1.0 - TInterpolation.Linear(0.0, 1.0, Min(closeActionDuration, Time.GetTimeGone() - closeActionTime), closeActionDuration)
			recenter(new TVec2D.Init(0, - yUntilScreenLeft * TInterpolation.BackIn(0.0, 1.0, Min(closeActionDuration, Time.GetTimeGone() - closeActionTime), closeActionDuration)))

			'as text "wobbles" (drawn at INT position while sprites draw
			'with floats - so they seem to change offsets) we fade them
			'out earlier
			if guiCaptionTextBox then guiCaptionTextBox.alpha = 0.5 * newAlpha
			if guiTextBox then guiTextBox.alpha = 0.5 * newAlpha
		endif

		self.alpha = newAlpha

		SetAlpha(oldCol.a * alpha * 0.5)
		SetColor(0, 0, 0)
		If Not DarkenedArea
			DrawRect(0, 0, GraphicsWidth(), GraphicsHeight())
		Else
			DrawRect(DarkenedArea.getX(), DarkenedArea.getY(), DarkenedArea.getW(), DarkenedArea.getH())
		EndIf
		oldCol.SetRGBA()

		'we manage drawing and updating our background
		If guiBackground then guiBackground.Draw()
	End Method
End Type
