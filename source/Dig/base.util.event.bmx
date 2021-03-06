Rem
	====================================================================
	Event Manager
	====================================================================

	This class provides an event manager handling all incoming events.


	====================================================================
	If not otherwise stated, the following code is available under the
	following licence:

	LICENCE: zlib/libpng

	Copyright (C) 2002-2014 Ronny Otto, digidea.de

	This software is provided 'as-is', without any express or
	implied warranty. In no event will the authors be held liable
	for any	damages arising from the use of this software.

	Permission is granted to anyone to use this software for any
	purpose, including commercial applications, and to alter it
	and redistribute it freely, subject to the following restrictions:

	1. The origin of this software must not be misrepresented; you
	   must not claim that you wrote the original software. If you use
	   this software in a product, an acknowledgment in the product
	   documentation would be appreciated but is not required.

	2. Altered source versions must be plainly marked as such, and
	   must not be misrepresented as being the original software.

	3. This notice may not be removed or altered from any source
	   distribution.
	====================================================================
EndRem
SuperStrict
Import brl.Map
Import brl.Reflection
'Import brl.retro
?Threaded
Import Brl.threads
?
Import "base.util.logger.bmx"
Import "base.util.data.bmx"
Import "base.util.time.bmx"




Global EventManager:TEventManager = New TEventManager

Type TEventManager
	'holding events
	Field _events:TList = New TList
	'current time
	Field _ticks:Int = -1
	'list of eventhandlers waiting for trigger
	Field _listeners:TMap = CreateMap()


	'returns how many update ticks are gone since start
	Method getTicks:Int()
		Return _ticks
	End Method


	'initialize the event manager
	Method Init()
		'Assert _ticks = -1, "TEventManager: preparing to start event manager while already started"
		If _ticks = -1
			'sort by age
			_events.Sort()
			'begin
			_ticks = Time.GetTimeGone()
			TLogger.Log("TEventManager.Init()", "OK", LOG_LOADING)
		EndIf
	End Method


	'returns whether the manager was started
	Method isStarted:Int()
		Return _ticks > -1
	End Method


	'returns whether the manager has nothing to do
	Method isFinished:Int()
		Return _events.IsEmpty()
	End Method


	Method GetRegisteredListenersCount:int()
		local count:int = 0
		For local list:TList = EachIn _listeners.Values()
			For local listener:TEventListenerBase = EachIn list
				count :+1
			Next
		Next
		return count
	End Method


	'add a new listener to a trigger
	Method registerListener:TLink(trigger:String, eventListener:TEventListenerBase)
		trigger = Lower(trigger)
		Local listeners:TList = TList(_listeners.ValueForKey(trigger))
		If listeners = Null									'if not existing, create a new list
			listeners = CreateList()
			_listeners.Insert(trigger, listeners)
		EndIf
		Return listeners.AddLast(eventListener)					'add to list of listeners
	End Method


	'register a function getting called as soon as a trigger is fired
	Method registerListenerFunction:TLink( trigger:String, _function(triggeredByEvent:TEventBase), limitToSender:Object=Null, limitToReceiver:Object=Null )
		Return registerListener( trigger, TEventListenerRunFunction.Create(_function, limitToSender, limitToReceiver) )
	End Method


	'register a method getting called as soon as a trigger is fired
	Method registerListenerMethod:TLink( trigger:String, objectInstance:Object, methodName:String, limitToSender:Object=Null, limitToReceiver:Object=Null )
		Return registerListener( trigger, TEventListenerRunMethod.Create(objectInstance, methodName, limitToSender, limitToReceiver) )
	End Method


	'remove an event listener from a trigger
	Method unregisterListener(trigger:String, eventListener:TEventListenerBase)
		Local listeners:TList = TList(_listeners.ValueForKey( Lower(trigger) ))
		If listeners <> Null Then listeners.remove(eventListener)
	End Method


	'remove all listeners having the given receiver or sender as limit
	Method unregisterListenerByLimit(limitReceiver:Object=Null, limitSender:Object=Null)
		For Local list:TList = EachIn _listeners
			For Local listener:TEventListenerBase = EachIn list
				'if one of both limits hits, remove that listener
				If ObjectsAreEqual(listener._limitToSender, limitSender) Or..
				   ObjectsAreEqual(listener._limitToReceiver, limitReceiver)
					list.remove(listener)
				EndIf
			Next
		Next
	End Method


	'removes all listeners listening to a specific trigger
	Method unregisterListenersByTrigger(trigger:String, limitReceiver:Object=Null, limitSender:Object=Null)
		'remove all of that trigger
		If Not limitReceiver And Not limitSender
			_listeners.remove( Lower(trigger) )
		'remove all defined by limits
		Else
			Local triggerListeners:TList = TList(_listeners.ValueForKey( Lower(trigger) ))
			For Local listener:TEventListenerBase = EachIn triggerListeners
				'if one of both limits hits, remove that listener
				If ObjectsAreEqual(listener._limitToSender, limitSender) Or..
				   ObjectsAreEqual(listener._limitToReceiver, limitReceiver)
					triggerListeners.remove(listener)
				EndIf
			Next
		EndIf
	End Method


	'removes a listener using its list link
	Method unregisterListenerByLink(link:TLink)
		link.remove()
	End Method


	'add a new event to the list
	Method registerEvent(event:TEventBase)
		_events.AddLast(event)
	End Method


	'runs all listeners NOW ...returns amount of listeners
	Method triggerEvent:Int(triggeredByEvent:TEventBase)
		?Threaded
		'if we have systemonly-event we cannot do it in a subthread
		'instead we just add that event to the upcoming events list
		If triggeredByEvent._channel = 1
			If CurrentThread()<>MainThread() Then registerEvent(triggeredByEvent)
		EndIf
		?


		Local listeners:TList = TList(_listeners.ValueForKey( Lower(triggeredByEvent._trigger) ))
		If listeners
			For Local listener:TEventListenerBase = EachIn listeners
				listener.onEvent(triggeredByEvent)
				'stop triggering the event if ONE of them vetos
				If triggeredByEvent.isVeto() Then Exit
			Next
			Return listeners.count()
		EndIf
		Return 0
	End Method


	'update the event manager - call this each cycle of your app loop
	Method update(onlyChannel:Int=Null)
		if not isStarted() then Init()
		'Assert _ticks >= 0, "TEventManager: updating event manager that hasn't been prepared"
		_processEvents(onlyChannel)
		_ticks = Time.GetTimeGone()
	End Method


	'process all events currently in the queue
	Method _processEvents(onlyChannel:Int=Null)
		If Not _events.IsEmpty()
			Local event:TEventBase = TEventBase(_events.First()) 			' get the next event
			If event<> Null
				If onlyChannel<>Null
					'system
					?Threaded
					If event._channel = 1 And event._channel <> onlyChannel
						If CurrentThread()<>MainThread() Then Return
					EndIf
					?
				EndIf

'				Assert startTime >= self._ticks, "TEventManager: an future event didn't get triggered in time"
				If event.getStartTime() <= _ticks			' is it time for this event?
					event.onEvent()							' start event
					If event._trigger <> ""					' only trigger event if _trigger is set
						triggerEvent( event )
					EndIf
					_events.RemoveFirst()			' remove from list
					_processEvents()				' another event may start on the same ticks - check again
				EndIf
			EndIf
		EndIf
	End Method


	'check whether a checkedObject equals to a limitObject
	'1) is the same object
	'2) is of the same type
	'3) is extended from same type
	Function ObjectsAreEqual:int(checkedObject:object, limit:object)
		'one of both is empty
		if not checkedObject then return FALSE
		if not limit then return FALSE
		'same object
		if checkedObject = limit then return TRUE

		'check if both are strings
		if string(limit) and string(checkedObject)
			return string(limit) = string(checkedObject)
		endif

		'check if classname / type is the same (type-name given as limit )
		if string(limit)<>null
			local typeId:TTypeId = TTypeId.ForName(string(limit))
			'if we haven't got a valid classname
			if not typeId then return FALSE
			'if checked object is same type or does extend from that type
			if TTypeId.ForObject(checkedObject).ExtendsType(typeId) then return TRUE
		endif

		return FALSE
	End Function
End Type




'simple basic class for an event listener
Type TEventListenerBase
	Field _limitToSender:Object
	Field _limitToReceiver:Object


	'what to do if the event happens
	Method OnEvent:Int(triggeredByEvent:TEventBase) Abstract


	'returns whether to ignore the incoming event (eg. limits...)
	'an event can be ignored if the sender<>limitSender or receiver<>limitReceiver
	Method ignoreEvent:Int(triggerEvent:TEventBase)
		If triggerEvent = Null Then Return True

		'Check limit for "sender"
		'if the listener wants a special sender but the event does not have one... ignore
		'old if self._limitToSender and triggerEvent._sender
		'new
		If _limitToSender
			'we want a sender but got none - ignore (albeit objects are NOT equal)
			If Not triggerEvent._sender Then Return True

			If Not TEventManager.ObjectsAreEqual(triggerEvent._sender, _limitToSender) Then Return True
		EndIf

		'Check limit for "receiver" - but only if receiver is set
		'if the listener wants a special receiver but the event does not have one... ignore
		'old: if self._limitToReceiver and triggerEvent._receiver
		'new
		If _limitToReceiver
			'we want a receiver but got none - ignore (albeit objects are NOT equal)
			If Not triggerEvent._receiver Then Return True

			If Not TEventManager.ObjectsAreEqual(triggerEvent._receiver, _limitToReceiver) Then Return True
		EndIf

		Return False
	End Method
End Type




Type TEventListenerRunMethod Extends TEventListenerBase
	Field _methodName:String = ""
	Field _objectInstance:Object


	Function Create:TEventListenerRunMethod(objectInstance:Object, methodName:String, limitToSender:Object=Null, limitToReceiver:Object=Null )
		Local obj:TEventListenerRunMethod = New TEventListenerRunMethod
		obj._methodName			= methodName
		obj._objectInstance		= objectInstance
		obj._limitToSender		= limitToSender
		obj._limitToReceiver	= limitToReceiver
		Return obj
	End Function


	Method OnEvent:Int(triggerEvent:TEventBase)
		If triggerEvent = Null Then Return 0

		If Not Self.ignoreEvent(triggerEvent)
			Local id:TTypeId		= TTypeId.ForObject( _objectInstance )
			Local update:TMethod	= id.FindMethod( _methodName )

			update.Invoke(_objectInstance ,[triggerEvent])
			Return True
		EndIf

		Return True
	End Method
End Type




Type TEventListenerRunFunction Extends TEventListenerBase
	Field _function:int(triggeredByEvent:TEventBase)


	Function Create:TEventListenerRunFunction(_function(triggeredByEvent:TEventBase), limitToSender:Object=Null, limitToReceiver:Object=Null )
		Local obj:TEventListenerRunFunction = New TEventListenerRunFunction
		obj._function			= _function
		obj._limitToSender		= limitToSender
		obj._limitToReceiver	= limitToReceiver
		Return obj
	End Function


	Method OnEvent:Int(triggerEvent:TEventBase)
		If triggerEvent = Null Then Return 0

		If Not ignoreEvent(triggerEvent) Then Return _function(triggerEvent)

		Return True
	End Method
End Type




Type TEventBase
	Field _startTime:Int
	Field _trigger:String = ""
	Field _sender:Object = Null
	Field _receiver:Object = Null
	Field _data:Object
	Field _status:Int = 0
	Field _channel:Int = 0		'no special channel

	Const STATUS_VETO:Int = 1
	Const STATUS_ACCEPTED:Int = 2


	Method getStartTime:Int()
		Return _startTime
	End Method


	Method setStartTime:TEventBase(newStartTime:Int=0)
		_startTime = newStartTime
		Return Self
	End Method


	Method delayStart:TEventBase(delayMilliseconds:Int=0)
		_startTime :+ delayMilliseconds

		Return Self
	End Method


	Method setStatus(status:Int, enable:Int=True)
		If enable
			_status :| status
		Else
			_status :& ~status
		EndIf
	End Method


	Method setVeto(bool:Int=True)
		setStatus(STATUS_VETO, bool)
	End Method


	Method isVeto:Int()
		Return (_status & STATUS_VETO)
	End Method


	Method setAccepted(bool:Int=True)
		setStatus(STATUS_ACCEPTED, bool)
	End Method


	Method isAccepted:Int()
		Return (_status & STATUS_ACCEPTED)
	End Method


	Method onEvent()
	End Method


	Method GetReceiver:Object()
		Return _receiver
	End Method


	Method GetSender:Object()
		Return _sender
	End Method


	Method GetData:TData()
		Return TData(_data)
	End Method


	Method getTrigger:String()
		Return Lower(_trigger)
	End Method


	'returns wether trigger is the same
	Method isTrigger:Int(trigger:String)
		Return _trigger = Lower(trigger)
	End Method


	Method Trigger:TEventBase()
		EventManager.triggerEvent(self)
		return self
	End Method


	Method Register:TEventBase()
		EventManager.registerEvent(self)
		return self
	End Method


	' to sort the event queue by time
	Method Compare:Int(other:Object)
		Local event:TEventBase = TEventBase(other)
		If Not event Then Return Super.Compare(other)

		If getStartTime() > event.getStartTime() Then Return 1 .. 			' i'm newer
		Else If getStartTime() < event.getStartTime() Then Return -1 ..	' they're newer
		Else Return 0
	End Method
End Type




Type TEventSimple Extends TEventBase
	Function Create:TEventSimple(trigger:String, data:Object=Null, sender:Object=Null, receiver:Object=Null, channel:Int=0)
		If data = Null Then data = New TData
		Local obj:TEventSimple = New TEventSimple
		obj._trigger	= Lower(trigger)
		obj._data	 	= data
		obj._sender		= sender
		obj._receiver	= receiver
		obj._channel	= channel
		obj.setStartTime( EventManager.getTicks() )
		Return obj
	End Function
End Type
