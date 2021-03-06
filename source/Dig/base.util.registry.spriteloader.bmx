SuperStrict
Import BRL.PNGLoader
Import "base.util.registry.bmx"
Import "base.util.registry.imageloader.bmx"

'register this loader
new TRegistrySpriteLoader.Init()


'===== LOADER IMPLEMENTATION =====
'loader caring about "<sprite>"-types
Type TRegistrySpriteLoader extends TRegistryImageLoader
	Method Init:Int()
		name = "Sprite"
		'we also load each image as sprite
		resourceNames = "sprite|spritepack|image"
		if not registered then Register()
	End Method


	'creates - modifies default resource
	Method CreateDefaultResource:Int()
		local img:TImage = TImage(GetRegistry().GetDefault("image"))
		if not img then return FALSE

		local sprite:TSprite = new TSprite.InitFromImage(img, "defaultsprite")
		'try to find a nine patch pattern
		sprite.EnableNinePatch()

		GetRegistry().SetDefault("sprite", sprite)
		GetRegistry().SetDefault("spritepack", sprite.parent)

		_createdDefaults = TRUE
	End Method


	'override image config loader - to add children (sprites) support
	Method GetConfigFromXML:TData(loader:TRegistryLoader, node:TxmlNode)
		local data:TData = Super.GetConfigFromXML(loader, node)


		local fieldNames:String[]
		fieldNames :+ ["name", "id"]
		fieldNames :+ ["x", "y", "w", "h"]
		fieldNames :+ ["offsetLeft", "offsetTop", "offsetRight", "offsetBottom"]
		fieldNames :+ ["paddingLeft", "paddingTop", "paddingRight", "paddingBottom"]
		fieldNames :+ ["frames|f"]
		fieldNames :+ ["ninepatch"]
		TXmlHelper.LoadValuesToData(node, data, fieldNames)


		'are there sprites defined ("children")
		Local childrenNode:TxmlNode = TXmlHelper.FindChild(node, "children")
		If not childrenNode then return data

		local childrenData:TData[]
		For Local childNode:TxmlNode = EachIn TXmlHelper.GetNodeChildElements(childrenNode)
			'load child config into a new data
			local childData:TData = new TData
			local childFieldNames:String[]
			childFieldNames :+ ["name", "id"]
			childFieldNames :+ ["x", "y", "w", "h"]
			childFieldNames :+ ["offsetLeft", "offsetTop", "offsetRight", "offsetBottom"]
			childFieldNames :+ ["paddingLeft", "paddingTop", "paddingRight", "paddingBottom"]
			childFieldNames :+ ["frames|f"]
			childFieldNames :+ ["ninepatch"]
			childFieldNames :+ ["rotated"]
			TXmlHelper.LoadValuesToData(childNode, childData, childFieldNames)

			'add child data
			childrenData :+ [childData]
		Next
		if len(childrenData)>0 then data.Add("childrenData", childrenData)

		return data
	End Method


	Method LoadFromConfig:int(data:TData, resourceName:string)
		resourceName = resourceName.ToLower()

		if resourceName = "sprite" then return LoadSpriteFromConfig(data)

		'also create sprites from images
		if resourceName = "image" then return LoadSpriteFromConfig(data)

		if resourceName = "spritepack" then return LoadSpritePackFromConfig(data)
	End Method



	Method LoadSpriteFromConfig:Int(data:TData)
		'create spritepack (name+"_pack") and sprite (name)
		local sprite:TSprite = new TSprite.InitFromConfig(data)
		if not sprite then return FALSE

		'colorize if needed
		If data.GetInt("r",-1) >= 0 And data.GetInt("g",-1) >= 0 And data.GetInt("r",-1) >= 0
			sprite.colorize( TColor.Create(data.GetInt("r"), data.GetInt("g"), data.GetInt("b")) )
		Endif

		'add to registry
		GetRegistry().Set(GetNameFromConfig(data), sprite)

		'load potential new sprites from scripts
		LoadScriptResults(data, sprite)


		'indicate that the loading was successful
		return True
	End Method



	Method LoadSpritePackFromConfig:Int(data:TData)
		local url:string = data.GetString("url")
		if url = "" then return FALSE

		'Print "LoadSpritePackResource: "+data.GetString("name") + " ["+url+"]"
		Local img:TImage = LoadImage(url, data.GetInt("flags", 0))
		'just return - so requests to the sprite should be using the
		'registries "default sprite" (if registry is used)
		if not img then print "ERROR: image "+string(url)+" not found.";return False
		
		Local spritePack:TSpritePack = new TSpritePack.Init(img, data.GetString("name"))
		'add spritepack to asset
		GetRegistry().Set(spritePack.name, spritePack)

		'add children
		local childrenData:TData[] = TData[](data.Get("childrenData"))

		For local childData:TData = eachin childrenData
			Local sprite:TSprite = new TSprite

		sprite.Init( ..
				spritePack, ..
				childData.GetString("name"), ..
				new TRectangle.Init( ..
					childData.GetInt("x"), ..
					childData.GetInt("y"), ..
					childData.GetInt("w"), ..
					childData.GetInt("h") ..
				), ..
				new TRectangle.Init( ..
					childData.GetInt("offsetTop"), ..
					childData.GetInt("offsetLeft"), ..
					childData.GetInt("offsetBottom"), ..
					childData.GetInt("offsetRight") ..
				), ..
				childData.GetInt("frames"), ..
				null, ..
				childData.GetInt("id", 0) ..
			)
			'rotation
			sprite.rotated = childData.GetInt("rotated", 0)
			'padding
			sprite.SetPadding(new TRectangle.Init(..
				childData.GetInt("paddingTop"), ..
				childData.GetInt("paddingLeft"), ..
				childData.GetInt("paddingBottom"), ..
				childData.GetInt("paddingRight") ..
			))

			'search for ninepatch
			if childData.GetBool("ninepatch")
				sprite.EnableNinePatch()
			endif

			'recolor/colorize?
			If childData.GetInt("r",-1) >= 0 And childData.GetInt("g",-1) >= 0 And childData.GetInt("b",-1) >= 0
				sprite.colorize( TColor.Create(childData.GetInt("r",-1),childData.GetInt("g",-1),childData.GetInt("b",-1)) )
			endif

			spritePack.addSprite(sprite)
			GetRegistry().Set(childData.GetString("name"), sprite)
		Next

		'load potential new sprites from scripts
		LoadScriptResults(data, spritePack)

		'indicate that the loading was successful
		return True
	End Method


	'OVERWRITTEN to add support for TSprite and TSpritepack
	'running a script configured with values contained in a data-object
	'objects are directly created within the function and added to
	'the registry
	Function RunScriptData:int(data:TData, parent:object)
		local dest:String = data.GetString("dest").toLower()
		local src:String = data.GetString("src")
		local color:TColor = TColor.Create(data.GetInt("r"), data.GetInt("g"), data.GetInt("b"))

		Select data.GetString("do").toUpper()
			'Create a colorized copy of the given image
			case "COLORIZECOPY"
				local parentImage:TImage
				If TImage(parent) then parentImage = TImage(parent)
				If TSpritePack(parent) then parentImage = TSpritePack(parent).image
				If TSprite(parent) then parentImage = TSprite(parent).GetImage()

				'check prerequisites
				If dest = "" or not parentImage then return FALSE

				local img:Timage = ColorizeImageCopy(parentImage, color)
				if not img then return FALSE
				'add to registry
				if TImage(parent)
					GetRegistry().Set(dest, img)
				elseif TSpritePack(parent)
					GetRegistry().Set(dest, new TSpritePack.Init(img, dest))
				elseif TSprite(parent)
					GetRegistry().Set(dest, new TSprite.InitFromImage(img, dest))
				endif


			'Copy the given Sprite on the spritesheet (spritepack image)
			case "COPYSPRITE"
				'check prerequisites
				If dest = "" Or src = "" then return FALSE
				if not TSpritepack(parent) then return FALSE
				TSpritepack(parent).CopySprite(src, dest, color)


			'Create a new sprite copied from another one
			case "ADDCOPYSPRITE"
				'check prerequisites
				If dest = "" Or src = "" then return FALSE
				If not TSpritepack(parent) then return FALSE

				Local srcSprite:TSprite = TSpritepack(parent).GetSprite(src)

				Local x:Int = data.GetInt("x", srcSprite.area.GetX())
				Local y:Int = data.GetInt("y", srcSprite.area.GetY())
				Local w:Int = data.GetInt("w", srcSprite.area.GetW())
				Local h:Int = data.GetInt("h", srcSprite.area.GetH())

				Local offsetTop:Int = data.GetInt("offsetTop", srcSprite.offset.GetTop())
				Local offsetLeft:Int = data.GetInt("offsetLeft", srcSprite.offset.GetLeft())
				Local offsetBottom:Int = data.GetInt("offsetBottom", srcSprite.offset.GetBottom())
				Local offsetRight:Int = data.GetInt("offsetRight", srcSprite.offset.GetRight())
				Local frames:Int = data.GetInt("frames", srcSprite.frames)

				'add to registry
				local sprite:TSprite
				sprite = TSpritepack(parent).AddSpritecopy(..
							src,..
							dest,..
							new TRectangle.Init(x,y,w,h),..
							new TRectangle.Init(offsetTop, offsetLeft, offsetBottom, offsetRight),..
							frames,..
							color..
						  )
				GetRegistry().Set(dest, sprite)


			Default
				Throw "sprite script contains unknown command: ~q"+data.GetString("do")+"~q"
		End Select
	End Function
End Type


'===== CONVENIENCE REGISTRY ACCESSORS =====
Function GetSpriteFromRegistry:TSprite(name:string, defaultNameOrSprite:object = Null)
	Return TSprite( GetRegistry().Get(name, defaultNameOrSprite, "sprite") )
End Function


Function GetSpriteGroupFromRegistry:TSprite[](baseName:string, defaultNameOrSprite:object = Null)
	local sprite:TSprite
	local result:TSprite[]
	local number:int = 1
	local maxNumber:int = 1000
	repeat
		'do not use "defaultType" or "defaultObject" - we want to know
		'if there is an object with this name
		sprite = TSprite( GetRegistry().Get(baseName+number) )
		number :+1

		if sprite then result :+ [sprite]
	until sprite = null or number >= maxNumber

	'add default one if nothing was found 
	if result.length = 0 and defaultNameOrSprite <> null
		if TSprite(defaultNameOrSprite)
			result :+ [TSprite(defaultNameOrSprite)]
		elseif string(defaultNameOrSprite) <> ""
			sprite = TSprite( GetRegistry().Get(string(defaultNameOrSprite), null, "sprite") )
			if sprite then result :+ [sprite]
		endif
	endif


	Return result
End Function