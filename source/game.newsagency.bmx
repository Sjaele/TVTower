﻿'likely a kind of agency providing news...
'at the moment only a base object
Type TNewsAgency
	'when to announce a new newsevent
	Field NextEventTime:Double = -1
	'check for a new news every x-y minutes
	Field NextEventTimeInterval:int[] = [180, 330]


	'=== WEATHER HANDLING ===
	'time of last weather event/news
	Field weatherUpdateTime:Double = 0
	'announce new weather every x-y minutes
	Field weatherUpdateTimeInterval:int[] = [360, 720]
	Field weatherType:int = 0

	
	'=== TERRORIST HANDLING ===
	'both parties (VR and FR) have their own array entry
	'when to update aggression the next time
	Field terroristUpdateTime:Double = 0
	'update terrorists aggression every x-y minutes
	Field terroristUpdateTimeInterval:int[] = [30, 45]
	'level of terrorists aggression (each level = new news)
	'party 2 starts later
	Field terroristAggressionLevel:Int[] = [0, -1]
	'progress in the given aggression level (0 - 1.0)
	Field terroristAggressionLevelProgress:Float[] = [0.0, 0.0]
	'rate the aggression level progresses each game hour
	Field terroristAggressionLevelProgressRate:Float[][] = [ [0.05,0.09], [0.05,0.09] ]	


	Global _instance:TNewsAgency


	Function GetInstance:TNewsAgency()
		if not _instance then _instance = new TNewsAgency
		return _instance
	End Function


	Method Update:int()
		'All players update their newsagency on their own.
		'As we use "randRange" this will produce the same random values
		'on all clients - so they should be sync'd all the time.
		
		ProcessUpcomingNewsEvents()

		If NextEventTime < GetWorldTime().GetTimeGone() Then AnnounceNewNewsEvent()
		If terroristUpdateTime < GetWorldTime().GetTimeGone() Then UpdateTerrorists()
		If weatherUpdateTime < GetWorldTime().GetTimeGone() Then UpdateWeather()
	End Method


	Method UpdateTerrorists:int()
		'set next update time (between min-max interval)
		terroristUpdateTime = GetWorldTime().GetTimeGone() + 60*randRange(terroristUpdateTimeInterval[0], terroristUpdateTimeInterval[1])

		'who is the mainaggressor? - this parties levelProgress grows faster
		local mainAggressor:int = (terroristAggressionLevel[1] + terroristAggressionLevelProgress[1] > terroristAggressionLevel[0] + terroristAggressionLevelProgress[0])


		'adjust level progress
		For local i:int = 0 to 1
			'randRange uses "ints", so convert 1.0 to 100
			local increase:Float = 0.01 * randRange(terroristAggressionLevelProgressRate[i][0]*100, terroristAggressionLevelProgressRate[i][1]*100)
			'if not the mainaggressor, grow slower
			if i <> mainAggressor then increase :* 0.5

			'each level has its custom increasement
			'so responses come faster and faster
			Select terroristAggressionLevel[i]
				case 1
					terroristAggressionLevelProgress[i] :+ 1.1 * increase
				case 2
					terroristAggressionLevelProgress[i] :+ 1.2 * increase
				case 3
					terroristAggressionLevelProgress[i] :+ 1.3 * increase
				case 4
					terroristAggressionLevelProgress[i] :+ 1.5 * increase
				default
					terroristAggressionLevelProgress[i] :+ increase
			End Select
		Next

		'handle "level ups"
		For local i:int = 0 to 1
			'skip if no level up happens
			if terroristAggressionLevelProgress[i] < 1.0 then continue

			'set to next level
			terroristAggressionLevel[i] :+ 1
			'if progress was 1.05, keep the 0.05 for the new level
			terroristAggressionLevelProgress[i] :- 1.0

			'announce news for levels 1-4
			if terroristAggressionLevel[i] < 5
				local newsEvent:TNewsEvent = GetTerroristNewsEvent(i)
				If newsEvent then announceNewsEvent(newsEvent, GetWorldTime().GetTimeGone() + 0)
			endif

			'reset level if limit reached, also delay by 2 levels so
			'things do not happen one after another
			if terroristAggressionLevel[i] >= 5 + 1
				'reset to level 0
				terroristAggressionLevel[i] = 0
			endif
		Next
	End Method


	Method GetTerroristNewsEvent:TNewsEvent(terroristGroup:int = 0)
		Local aggressionLevel:int = terroristAggressionLevel[terroristGroup]
		Local quality:Float = 0.01 * (randRange(50,60) + aggressionLevel * 5)
		Local price:Float = 1.0 + 0.01 * (randRange(45,50) + aggressionLevel * 5)
		Local title:String
		Local description:String

		local genre:int = TNewsEvent.GENRE_POLITICS
		Select aggressionLevel
			case 1
				if terroristGroup = 1
					title = "Botschafter der VR Duban beleidigt Amtskollegen"
					description = "Es ist ein Eklat: ein Botschafter der VR Duban beleidigte seinen Amtskollegen aus der Freien Republik Duban."
				else
					title = "Botschafter der FR Duban beschimpft Nachbarn"
					description = "Das kann nicht sein: ein Botschafter der FR Duban beleidigte den Repräsentanten der Volksrepublik Duban."
				endif
			case 2
				if terroristGroup = 1
					title = "Botschafter verprügelt"
					description = "Auf dem Heimweg wurde der Botschafter der VR Duban in der Tiefgarage bewusstlos geschlagen. Zeugen sahen einen PKW der FR Duban davonfahren."
				else
					title = "Wohnung eines Botschafters verwüstet"
					description = "Die Wohnung des Botschafters der Freien Republik Duban wurde verwüstet. Hinweise deuten auf Kreise der VR DUBAN."
				endif
			case 3
				if terroristGroup = 1
					title = "VR Duban droht mit Vergeltung"
					description = "Die VR Duban droht offen mit Rache. Die Schuldigen sollen gefunden worden sein. Die Situation ist brenzlig."
				else
					title = "FR Duban warnt vor Konsequenzen"
					description = "Genug. So der knappe Wortlaut der Botschaft. Die FR Duban ergreift Gegenmaßnahmen."
				endif
			case 4
				title = "Die Polizei warnt vor Terroristen"
				description = "Die Polizei verlor die Spur zu einem kürzlich gesichteten Terroristen, er soll dubanischer Herkunft sein."
				'currents instead of politics
				genre = TNewsEvent.GENRE_CURRENTS
			default
				return null
		End Select

		local localizeTitle:TLocalizedString = new TLocalizedString
		localizeTitle.Set(title, "de")
		local localizeDescription:TLocalizedString = new TLocalizedString
		localizeDescription.Set(description, "de")


		Local NewsEvent:TNewsEvent = new TNewsEvent.Init("", localizeTitle, localizeDescription, genre, quality, price, TVTNewsType.InitialNewsByInGameEvent)

		'send out terrorist
		if aggressionLevel = 4
			local effect:TNewsEffect = new TNewsEffect

			effect.GetData().Add("figure", Game.terrorists[terroristGroup])
			'effect.GetData().Add("room", GetRoomCollection().GetRandom())
			if terroristGroup = 0
				effect.GetData().Add("room", GetRoomCollection().GetFirstByDetails("frduban"))
			else
				effect.GetData().Add("room", GetRoomCollection().GetFirstByDetails("vrduban"))
			endif
			effect._customEffectFunc = TFigureTerrorist.SendFigureToRoom

			NewsEvent.AddHappenEffect(effect)
		endif

		NewsEvent.doHappen() 'happen now
		GetNewsEventCollection().AddOneTimeEvent(NewsEvent)
		Return NewsEvent
	End Method
	


	Method UpdateWeather:int()
		weatherUpdateTime = GetWorldTime().GetTimeGone() + 60 * randRange(weatherUpdateTimeInterval[0], weatherUpdateTimeInterval[1])


		local newsEvent:TNewsEvent = GetWeatherNewsEvent()
		If newsEvent
			'Print "[LOCAL] UpdateWeather: added weather news title="+newsEvent.title+", day="+GetWorldTime().getDay(newsEvent.happenedtime)+", time="+GetWorldTime().GetFormattedTime(newsEvent.happenedtime)
			announceNewsEvent(newsEvent, GetWorldTime().GetTimeGone() + 0)
		EndIf

	End Method


	Method GetWeatherNewsEvent:TNewsEvent()
		'quality and price are nearly the same everytime
		Local quality:Float = 0.01 * randRange(50,60)
		Local price:Float = 1.0 + 0.01 * randRange(-5,10)
		'append 1 hour to both: forecast is done eg. at 7:30 - so it
		'cannot be a weatherforecast for 7-10 but for 8-11
		local beginHour:int = GetWorldTime().GetDayHour()+1
		local endHour:int = GetWorldTime().GetDayHour(weatherUpdateTime)+1
		Local description:string = ""
		local title:string = GetLocale("WEATHER_FORECAST_FOR_X_TILL_Y").replace("%BEGINHOUR%", beginHour).replace("%ENDHOUR%", endHour)
		local forecastHours:int = ceil((weatherUpdateTime - GetWorldTime().GetTimeGone()) / 3600.0)
		local weather:TWorldWeatherEntry
		'states
		local isRaining:int = 0
		local isSnowing:int = 0
		local isBelowZero:int = 0
		local isCloudy:int = 0
		local isClear:int = 0
		local isPartiallyCloudy:int = 0
		local isNight:int = 0
		local isDay:int = 0
		local sunHours:int = 0
		local sunAverage:float = 0.0
		local tempMin:int = 1000, tempMax:int = -1000

		'fetch next weather
		local upcomingWeather:TWorldWeatherEntry[forecastHours]
		For local i:int = 0 until forecastHours
			upcomingWeather[i] = GetWorld().Weather.GetUpcomingWeather(i+1)
		Next


		'check for specific states
		For weather = eachin upcomingWeather
			if GetWorldTime().IsNight(weather._time)
				isNight = True
			else
				isDay = True
			endif

			tempMin = Min(tempMin, weather.GetTemperature())
			tempMax = Max(tempMax, weather.GetTemperature())

			if weather.GetTemperature() < 0 then isBelowZero = True
			if weather.IsRaining() and weather.GetTemperature() >= 0 then isRaining = True
			if weather.GetTemperature() < 0 and weather.IsRaining() then isSnowing = True

			if weather.GetWorldWeather() = TWorldWeather.WEATHER_CLEAR
				isClear = True
			else
				isCloudy = True
			endif

			if weather.IsSunVisible() then sunHours :+1
		Next
		if isCloudy and isClear
			isPartiallyCloudy = True
			isCloudy = False
			isClear = False
		endif
		sunAverage = float(sunHours)/float(forecastHours)



		'construct text
		description = ""
		
		if isPartiallyCloudy
			description :+ GetLocale("SKY_IS_PARTIALLY_CLOUDY")+" "
		elseif isCloudy
			description :+ GetLocale("SKY_IS_OVERCAST")+" "
		elseif isClear
			description :+ GetLocale("SKY_IS_WITHOUT_CLOUDS")+" "
		endif
		
		if sunAverage = 1.0 and isDay
			if not isNight then description :+ GetLocale("SUN_SHINES_WHOLE_TIME")+" "
		elseif sunAverage > 0.5
			description :+ GetLocale("SUN_WINS_AGAINST_CLOUDS")+" "
		elseif sunAverage > 0
			description :+ GetLocale("SUN_IS_SHINING_SOMETIMES")+" "
		else
			description :+ GetLocale("SUN_IS_NOT_SHINING")+" "
		endif

		if isRaining and isSnowing
			description :+ GetLocale("RAIN_AND_SNOW_ALTERNATE")+" "
		elseif isRaining
			description :+ GetLocale("RAIN_IS_POSSIBLE")+" "
		elseif isSnowing
			description :+ GetLocale("SNOW_IS_FALLING")+" "
		endif

		if tempMin <> tempMax
			description :+ GetLocale("TEMPERATURES_ARE_BETWEEN_X_AND_Y").replace("%MINTEMPERATURE%", tempMin).replace("%MAXTEMPERATURE%", tempMax)
		else
			description :+ GetLocale("TEMPERATURE_IS_CONSTANT_AT_X").replace("%TEMPERATURE%", tempMin)
		endif

		local localizeTitle:TLocalizedString = new TLocalizedString
		localizeTitle.Set(title) 'use default lang
		local localizeDescription:TLocalizedString = new TLocalizedString
		localizeDescription.Set(description) 'use default lang
		
		Local NewsEvent:TNewsEvent = new TNewsEvent.Init("", localizeTitle, localizeDescription, TNewsEvent.GENRE_CURRENTS, quality, price, TVTNewsType.InitialNewsByInGameEvent)

		'TODO
		'add weather->audience effects
		'rain = more audience
		'sun = less audience
		'...

		NewsEvent.doHappen() 'happen now
		GetNewsEventCollection().AddOneTimeEvent(NewsEvent)

		Return NewsEvent
	End Method


	Method GetMovieNewsEvent:TNewsEvent()
		Local licence:TProgrammeLicence = Self._GetAnnouncableProgrammeLicence()
		If Not licence Then Return Null
		If Not licence.getData() Then Return Null

		licence.GetData().releaseAnnounced = True

		Local title:String = getLocale("NEWS_ANNOUNCE_MOVIE_TITLE"+Rand(1,2) )
		Local description:String = getLocale("NEWS_ANNOUNCE_MOVIE_DESCRIPTION"+Rand(1,4) )

		'if same director and main actor...
		If licence.GetData().getActor(1) = licence.GetData().getDirector(1)
			title = getLocale("NEWS_ANNOUNCE_MOVIE_ACTOR_IS_DIRECTOR_TITLE")
			description = getLocale("NEWS_ANNOUNCE_MOVIE_ACTOR_IS_DIRECTOR_DESCRIPTION")
		EndIf
		'if no actors ...
		If licence.GetData().getActor(1) = null
			title = getLocale("NEWS_ANNOUNCE_MOVIE_NO_ACTOR_TITLE")
			description = getLocale("NEWS_ANNOUNCE_MOVIE_NO_ACTOR_DESCRIPTION")
		EndIf

		'replace data
		title = Self._ReplaceProgrammeData(title, licence.GetData())
		description = Self._ReplaceProgrammeData(description, licence.GetData())

		local localizeTitle:TLocalizedString = new TLocalizedString
		localizeTitle.Set(title) 'use default lang
		local localizeDescription:TLocalizedString = new TLocalizedString
		localizeDescription.Set(description) 'use default lang
		
		'quality and price are based on the movies data
		'quality of movie news never can reach quality of "real" news
		'so cut them to a specific range (0-0.75) 
		local quality:Float = 0.75*licence.GetData().review
		'if outcome is less than 50%, it subtracts the price, else it increases
		local priceModifier:Float = 1.0 + 0.2 * (licence.GetData().outcome - 0.5)
		Local NewsEvent:TNewsEvent = new TNewsEvent.Init("", localizeTitle, localizeDescription, TNewsEvent.GENRE_SHOWBIZ, quality, priceModifier, TVTNewsType.InitialNewsByInGameEvent)
		NewsEvent.doHappen() 'happen now
		GetNewsEventCollection().AddOneTimeEvent(NewsEvent)
		
		Return NewsEvent
	End Method


	Method _ReplaceProgrammeData:String(text:String, data:TProgrammeData)
		local actor:TProgrammePersonBase
		local director:TProgrammePersonBase
		For Local i:Int = 1 To 2
			actor = data.GetActor(i)
			director = data.GetDirector(i)
			if actor
				text = text.Replace("%ACTORNAME"+i+"%", actor.GetFullName())
			endif
			if director
				text = text.Replace("%DIRECTORNAME"+i+"%", director.GetFullName())
			endif
		Next
		text = text.Replace("%MOVIETITLE%", data.GetTitle())

		Return text
	End Method


	'helper to get a movie which can be used for a news
	Method _GetAnnouncableProgrammeLicence:TProgrammeLicence()
		'filter to entries we need
		Local resultList:TList = CreateList()
		For local licence:TProgrammeLicence = EachIn GetProgrammeLicenceCollection().movies
			'ignore collection and episodes (which should not be in that list)
			If Not licence.getData() Then Continue

			'ignore if filtered out
			If licence.owner <> 0 Then Continue
			'ignore already announced movies
			If licence.getData().releaseAnnounced Then Continue
			'ignore unreleased
			If Not licence.ignoreUnreleasedProgrammes And licence.getData().year < licence._filterReleaseDateStart Or licence.getData().year > licence._filterReleaseDateEnd Then Continue
			'only add movies of "next X days" - 14 = 1 year
			Local licenceTime:Int = licence.GetData().year * GetWorldTime().GetDaysPerYear() + licence.getData().releaseDay
			If licenceTime > GetWorldTime().getDay() And licenceTime - GetWorldTime().getDay() < 14 Then resultList.addLast(licence)
		Next
		If resultList.count() > 0 Then Return GetProgrammeLicenceCollection().GetRandomFromList(resultList)

		Return Null
	End Method


	'announces planned news events (triggered by news some time before)
	Method ProcessUpcomingNewsEvents:Int()
		Local announced:Int = 0
		For local newsEvent:TNewsEvent = EachIn GetNewsEventCollection().GetUpcomingNewsList()
			'skip news events not happening yet
			If newsEvent.happenedTime > GetWorldTime().GetTimeGone() then continue
			newsEvent.doHappen()
			announceNewsEvent(newsEvent)
			announced:+1
		Next
		Return announced
	End Method


	Function GetNewsAbonnementDelay:Int(genre:Int, level:int) {_exposeToLua}
		if level = 3 then return 0
		if level = 2 then return 60
		if level = 1 then return 150 'not needed but better overview
		return 150
	End Function


	'Returns the extra charge for a news
	Function GetNewsRelativeExtraCharge:Float(genre:Int, level:int) {_exposeToLua}
		'up to now: ignore genre, all share the same values
		if level = 3 then return 0.20
		if level = 2 then return 0.10
		if level = 1 then return 0.00 'not needed but better overview
		return 0.00
	End Function


	'Returns the price for this level of a news abonnement
	Function GetNewsAbonnementPrice:Int(level:Int=0)
		if level = 1 then return 10000
		if level = 2 then return 20000
		if level = 3 then return 35000
		return 0
	End Function


	Method AddNewsEventToPlayer:Int(newsEvent:TNewsEvent, forPlayer:Int=-1, forceAdd:Int=False, fromNetwork:Int=0)
		local player:TPlayer = GetPlayerCollection().Get(forPlayer)
		'only add news/newsblock if player is Host/Player OR AI
		'If Not Game.isLocalPlayer(forPlayer) And Not Game.isAIPlayer(forPlayer) Then Return 'TODO: Wenn man gerade Spieler 2 ist/verfolgt (Taste 2) dann bekommt Spieler 1 keine News
		If Player.newsabonnements[newsEvent.genre] > 0 or forceAdd
			local news:TNews = TNews.Create("", 0, newsEvent)
			'Print "[LOCAL] AddNewsEventToPlayer "+forPlayer+": added news title="+news.GetTitle()+", day="+GetWorldTime().getDay(newsEvent.happenedtime)+", time="+GetWorldTime().GetFormattedTime(newsEvent.happenedtime)

			if Player.newsabonnements[newsEvent.genre] >0
				news.publishDelay = GetNewsAbonnementDelay(newsEvent.genre, Player.newsabonnements[newsEvent.genre] )
				news.priceModRelativeNewsAgency = GetNewsRelativeExtraCharge(newsEvent.genre, GetPlayerCollection().Get(forPlayer).GetNewsAbonnement(newsEvent.genre))
			Else
				news.publishDelay = 0
				news.priceModRelativeNewsAgency = 0.0
			endif

			'add to players collection
			player.GetProgrammeCollection().AddNews(news)
		EndIf
	End Method


	Method announceNewsEvent:Int(newsEvent:TNewsEvent, happenedTime:Int=0, forceAdd:Int=False)
		'do not "doHappen" here again - already done
		'newsEvent.doHappen(happenedTime)

		For Local i:Int = 1 To 4
			AddNewsEventToPlayer(newsEvent, i, forceAdd)
		Next
	End Method


	'generates a new news event from various sources (such as new
	'movie announcements, actor news ...)
	Method GenerateNewNewsEvent:TNewsEvent()
		local newsEvent:TNewsEvent = null

		'=== TYPE MOVIE NEWS ===
		'35% chance: try to load some movie news ("new movie announced...")
		If Not newsEvent And RandRange(1,100) < 35
			newsEvent = GetMovieNewsEvent()
		EndIf


		'=== TYPE RANDOM NEWS ===
		'if no "special case" triggered, just use a random news
		If Not newsEvent
			newsEvent = GetNewsEventCollection().GetRandomAvailable()
		EndIf

		return newsEvent
	End Method


	Method AnnounceNewNewsEvent:Int(delayAnnouncement:Int=0, forceAdd:Int=False)
		'=== CREATE A NEW NEWS ===
		Local newsEvent:TNewsEvent = GenerateNewNewsEvent()


		'=== ANNOUNCE THE NEWS ===
		'only announce if forced or somebody is listening
		If newsEvent
			local skipNews:int = newsEvent.IsSkippable()
			If skipNews
				For Local player:TPlayer = eachin GetPlayerCollection().players
					'a player listens to this genre, disallow skipping
					If player.newsabonnements[newsEvent.genre] > 0 Then skipNews = False
				Next
			EndIf

			If not skipNews or forceAdd
				'mark them as "happened", run triggers etc.
				'doing it HERE does not mark news as happened when nobody
				'listens and the news could get skipped
				newsEvent.doHappen()

				'Print "[LOCAL] AnnounceNewNews: added news title="+newsEvent.GetTitle()+", day="+GetWorldTime().getDay(newsEvent.happenedtime)+", time="+GetWorldTime().GetFormattedTime(newsEvent.happenedtime)
				announceNewsEvent(newsEvent, GetWorldTime().GetTimeGone() + delayAnnouncement, forceAdd)
			EndIf
		EndIf


		'=== ADJUST TIME FOR NEXT NEWS ANNOUNCEMENT ===
		ResetNextEventTime()
	End Method


	Method ResetNextEventTime:int()
		'adjust time until next news
		NextEventTime = GetWorldTime().GetTimeGone() + 60 * randRange(NextEventTimeInterval[0], NextEventTimeInterval[1])
		'50% chance to have an even longer time (up to 2x)
		If RandRange(0,10) > 5
			NextEventTime :+ randRange(NextEventTimeInterval[0], NextEventTimeInterval[1])
		EndIf
	End Method
End Type

'===== CONVENIENCE ACCESSOR =====
'return singleton instance
Function GetNewsAgency:TNewsAgency()
	Return TNewsAgency.GetInstance()
End Function
