SuperStrict
Import "Dig/base.util.registry.spriteloader.bmx"
Import "Dig/base.gfx.bitmapfont.bmx"
Import "Dig/base.util.rectangle.bmx"
Import "Dig/base.util.input.bmx"
Import "Dig/base.util.helper.bmx"


Type TDialogue
	'list of TDialogueTexts
	Field _texts:TList = CreateList()
	Field _currentText:Int = 0
	Field _rect:TRectangle = new TRectangle.Init(0,0,0,0)


	Method SetArea:TDialogue(rect:TRectangle)
		_rect = rect.copy()
		Return Self
	End Method


	Method AddText(text:TDialogueTexts)
		_texts.AddLast(text)
	End Method


	Method AddTexts(texts:TDialogueTexts[])
		for local text:TDialogueTexts = EachIn texts
			_texts.AddLast(Text)
		Next
	End Method


	Method Update:Int()
		Local clicked:Int = 0
		if MouseManager.isClicked(1)
			clicked = 1
			MouseManager.resetKey(1)
		endif

		Local nextText:Int = _currentText
		If Self._texts.Count() > 0
			Local returnValue:Int = TDialogueTexts(_texts.ValueAtIndex(_currentText)).Update(Self._rect.getX() + 10, Self._rect.getY() + 10, Self._rect.getW() - 60, Self._rect.getH(), clicked)
			If returnValue <> - 1 Then nextText = returnValue
		EndIf
		_currentText = nextText
		If _currentText = -2 Then _currentText = 0;Return 0
		Return 1
	End Method


	Function DrawDialog(dialogueType:String="default", x:Int, y:Int, width:Int, Height:Int, DialogStart:String = "StartDownLeft", DialogStartMove:Int = 0, DialogText:String = "", DialogFont:TBitmapFont = Null)
		Local dx:Float, dy:Float
		Local DialogSprite:TSprite = GetSpriteFromRegistry(DialogStart)
		height = Max(95, height ) 'minheight
		If DialogStart = "StartLeftDown" Then dx = x - 48;dy = y + Height/3 + DialogStartMove;width:-48
		If DialogStart = "StartRightDown" Then dx = x + width - 12;dy = y + Height/2 + DialogStartMove;width:-48
		If DialogStart = "StartDownRight" Then dx = x + width/2 + DialogStartMove;dy = y + Height - 12;Height:-53
		If DialogStart = "StartDownLeft" Then dx = x + width/2 + DialogStartMove;dy = y + Height - 12;Height:-53

		GetSpriteFromRegistry("dialogue."+dialogueType).DrawArea(x,y,width,height)

		DialogSprite.Draw(dx, dy)
		If DialogText <> "" Then DialogFont.drawBlock(DialogText, x + 10, y + 10, width - 25, Height - 16, Null, TColor.clBlack)
	End Function



	Method Draw()
		SetColor 255, 255, 255
	    DrawDialog("default", _rect.getX(), _rect.getY(), _rect.getW(), _rect.getH(), "StartLeftDown", 0, "", GetBitmapFont("Default", 14))
		SetColor 0, 0, 0
		If Self._texts.Count() > 0
			TDialogueTexts(Self._texts.ValueAtIndex(Self._currentText)).Draw(Self._rect.getX() + 10, Self._rect.getY() + 10, Self._rect.getW() - 60, Self._rect.getH())
		endif
		SetColor 255, 255, 255
	End Method
End Type


'Answer - objects for dialogues
Type TDialogueAnswer
	Field _text:String = ""
	Field _leadsTo:Int = 0
	Field _onUseEvent:TEventBase
	Field _highlighted:Int = 0


	Function Create:TDialogueAnswer (text:String, leadsTo:Int = 0, onUseEvent:TEventBase= Null)
		Local obj:TDialogueAnswer = New TDialogueAnswer
		obj._text		= Text
		obj._leadsTo	= leadsTo
		obj._onUseEvent	= onUseEvent
		Return obj
	End Function


	Method Update:Int(x:Float, y:Float, w:Float, h:Float, clicked:Int = 0)
		Self._highlighted = False
		If THelper.MouseIn( x, y-2, w, GetBitmapFontManager().baseFont.getBlockHeight(Self._text, w, h))
			Self._highlighted = True
			If clicked
				'emit the event if there is one
				If _onUseEvent Then EventManager.triggerEvent(_onUseEvent)
				Return _leadsTo
			EndIf
		EndIf
		Return - 1
	End Method


	Method Draw(x:Float, y:Float, w:Float, h:Float)
		If Self._highlighted
			SetColor 200,100,100
			DrawOval(x, y +3, 6, 6)
			GetBitmapFont("Default", 13, BOLDFONT).drawBlock(Self._text, x+9, y-1, w-10, h, Null, TColor.Create(0, 0, 0))
		Else
			SetColor 0,0,0
			DrawOval(x, y +3, 6, 6)
			GetBitmapFont("Default", 13).drawBlock(Self._text, x+10, y, w-10, h, Null, TColor.Create(100, 100, 100))
		EndIf
	End Method
End Type




'Texts, maintext + list of answers to this said thing ;D
Type TDialogueTexts
	Field _text:String = ""
	Field _answers:TList = CreateList() 'of TDialogueAnswer
	Field _goTo:Int = -1


	Function Create:TDialogueTexts(text:String)
		Local obj:TDialogueTexts = New TDialogueTexts
		obj._text = Text
		Return obj
	End Function


	Method AddAnswer(answer:TDialogueAnswer)
		Self._answers.AddLast(answer)
	End Method


	Method Update:Int(x:Float, y:Float, w:Float, h:Float, clicked:Int = 0)
		Local ydisplace:Float = GetBitmapFont("Default", 14).drawBlock(Self._text, x, y, w, h).getY()
		ydisplace:+15 'displace answers a bit
		_goTo = -1
		For Local answer:TDialogueAnswer = EachIn(Self._answers)
			Local returnValue:Int = answer.Update(x + 9, y + ydisplace, w - 9, h, clicked)
			If returnValue <> - 1 Then _goTo = returnValue
			ydisplace:+GetBitmapFont("Default", 14).getHeight(answer._text) + 2
		Next
		Return _goTo
	End Method


	Method Draw(x:Float, y:Float, w:Float, h:Float)
		Local ydisplace:Float = GetBitmapFont("Default", 14).drawBlock(Self._text, x, y, w, h).getY()
		ydisplace:+15 'displace answers a bit

		Local lineHeight:Int = 2 + GetBitmapFont("Default", 14).GetMaxCharHeight()

		For Local answer:TDialogueAnswer = EachIn(Self._answers)
			answer.Draw(x, y + ydisplace, w, h)
			ydisplace:+ lineHeight
		Next
	End Method
End Type





