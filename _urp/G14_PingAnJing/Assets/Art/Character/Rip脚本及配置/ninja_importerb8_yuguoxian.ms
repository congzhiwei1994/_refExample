----------------------------------------
---Ninja Ripper 1.1.0 3D Max Importer---

---Importer version 1.3 beta7

---Modified by CarLuver69 on March 3 2013
---Please visit the Xentax thread to report bugs on my modified script.
---http://forum.xentax.com/viewtopic.php?f=33&t=9782

------------------------CHANGELOG------------------------

--You can now flip on the XZ axis if your models appear inverted!
--Added progress bar
--Removed a lot of unnecessary information being printed
--End of script will show a popup message with how long it took to import
--"Debug" mode allows you to turn on useless print messages, VERY SLOW.
--Program no longer hangs when importing many objects :D
--Imports are now 50 - 75% faster. I was able to import 2,001 objects in 1 minute and 30 seconds!
----------------------------------------


-- allow ~ 40 MB instead of just 7.5 MB. Prevents "Runtime Error: Out of scripter memory"
if (heapSize < 200000) then
        heapSize = 2000000
		
-- force useing one CPU core
if SysInfo.CPUCount == 1 then
     TargetAffinity = 1
    else (
     TargetAffinity = 0
     for CoreID = 2 to SysInfo.CPUCount do
      TargetAffinity = (Bit.Set TargetAffinity CoreID true)
    )
    SysInfo.ProcessAffinity = TargetAffinity


---Constants
global RipSignature   = 0xDEADC0DE
global RipFileVersion = 4



---Global vars
global g_ImportType = 1       --- Group/Single/List  (0,1,2)
global g_InputSrc   = ""      --- Source Dir/File
global g_VertexFormatRecog = 0 --- Auto/Manual  (0,1)
global g_Tex0_FileLev = 0

global g_PosX_Idx = -1
global g_PosY_Idx = -1
global g_PosZ_Idx = -1
global g_PosW_Idx = -1
	
global g_NormX_Idx = 0
global g_NormY_Idx = 0
global g_NormZ_Idx = 0

global g_ColorX_Idx = -1
global g_ColorY_Idx = -1
global g_ColorZ_Idx = -1
global g_ColorW_Idx = -1

global g_Tc0_X_Idx = -1
global g_Tc0_Y_Idx = -1
global g_Tc0_W_Idx = -1
global g_Tc0_Z_Idx = -1

global g_Tc1_X_Idx = -1
global g_Tc1_Y_Idx = -1
global g_Tc1_W_Idx = -1
global g_Tc1_Z_Idx = -1

global g_Tc2_X_Idx = -1
global g_Tc2_Y_Idx = -1
global g_Tc2_W_Idx = -1
global g_Tc2_Z_Idx = -1

global g_Tc3_X_Idx = -1
global g_Tc3_Y_Idx = -1
global g_Tc3_W_Idx = -1
global g_Tc3_Z_Idx = -1

global g_Tc4_X_Idx = -1
global g_Tc4_Y_Idx = -1
global g_Tc4_W_Idx = -1
global g_Tc4_Z_Idx = -1

global g_Tc5_X_Idx = -1
global g_Tc5_Y_Idx = -1
global g_Tc5_W_Idx = -1
global g_Tc5_Z_Idx = -1

global g_Tc6_X_Idx = -1
global g_Tc6_Y_Idx = -1
global g_Tc6_W_Idx = -1
global g_Tc6_Z_Idx = -1

--Globals additional 
global g_ninjaScale = 100
global g_ninjarotX = 90
global g_ninjarotY = 0
global g_ninjarotZ = 0
global g_flipPosX = 1
global g_flipUV = -1
global g_flipXZAxis = 0
global g_applyNormal = 0

global g_enabler = true

--Debug mode (DO NOT EDIT THIS HERE)
global g_debugMode = false

-- fn NinjaRotationMatrix =
-- (
-- 	local angles = eulerAngles 0 -0 -90
-- 	--local angles = eulerAngles g_ninjarotZ -g_ninjarotY -g_ninjarotX
-- 	return angles as matrix3
-- )


fn ReadStr bstream =
(
   local str = ""
   while true do
   (
      str0 = ReadByte bstream #unsigned
	  if str0 == 0 then exit
      str+= bit.intAsChar str0
   )
   str
)


fn  StringClear OrigStr =
(
	local Str = ""
	
	for j = 1 to OrigStr.count do (
		if OrigStr[ j ] != " " then( 
			Str = Str + OrigStr[ j ] 
		) 
	)
   Str
)


fn  CreateMeshName Num =
(
	local Str = "Mesh_"
	local StrNum = ""
	r0 = Num as Integer
	StrNum = formattedPrint r0 format:"#04u"

	Str = Str + StrNum as String
	Str = Str + ".rip"
	
	Str
)

fn printDebug dbgstr = (
	if g_debugMode == true do (
		print ((dbgstr) as string)
	)
)


----------------------------
fn ImportRip RipFilePath =
(
	f = fopen RipFilePath "rb"

	Signature     = readlong f #unsigned
	Version       = readlong f #unsigned

	if Version != RipFileVersion do(
		printDebug "Not RIP file"
		---print ( "FileSig: " + Version as String )
		---print ( "Sig : " + RipFileVersion as String )
		return 0
	)

	dwFacesCnt    = readlong f #unsigned
	dwVertexesCnt = readlong f #unsigned
	VertexSize    = readlong f #unsigned
	TextureFilesCnt= readlong f #unsigned
	ShaderFilesCnt= readlong f #unsigned
	VertexAttributesCnt= readlong f #unsigned

	
	printDebug ( "*****ImportRip() File: " + RipFilePath as String )
	printDebug ( "dwFacesCnt=" + dwFacesCnt as String )
	printDebug ( "dwVertexesCnt=" + dwVertexesCnt as String )
	printDebug ( "VertexAttributesCnt=" + VertexAttributesCnt as String )
	
	
	
	VertexAttribTypesArray= #()   ---Contain all types
	TextureFiles = #()
	ShaderFiles  = #()
	
	Face_array = #()
	Normal_array = #()
	Vert_array = #()
	Color_array = #()
	UV0_array = #()		
	UV1_array = #()
	UV2_array = #()
	UV3_array = #()
	UV4_array = #()
	UV5_array = #()
	UV6_array = #()
	
	TempPosIdx = 0      ---Get only first index attribute flag
	TempNormalIdx = 0
	TempTexCoordIdx = 0

	---Read vertex attributes
	for i = 1 to VertexAttributesCnt do (
		Semantic = ReadStr f
		SemanticIndex = readlong f #unsigned
		Offset = readlong f #unsigned
		Size   = readlong f #unsigned
		TypeMapElements = readlong f #unsigned
		for j = 1 to TypeMapElements do (
			TypeElement = readlong f #unsigned
			append VertexAttribTypesArray TypeElement
		)
		printDebug "------------"
		printDebug( "Semantic="+ Semantic )
		printDebug( "SemanticIndex=" + SemanticIndex as String )
		printDebug( "Offset=" + Offset as String )
		printDebug( "Size=" + Size as String )
		printDebug( "TypeMapElements=" + TypeMapElements as String )

		---Recognize semantic if "AUTO" set
		if g_VertexFormatRecog == 0 do ( ---AUTO recognition	
			if Semantic == "POSITION" do (  --- Get as "XYZ_"
				if TempPosIdx == 0 do (
					g_PosX_Idx = Offset / 4
					g_PosY_Idx = g_PosX_Idx + 1
					g_PosZ_Idx = g_PosX_Idx + 2
					
					TempPosIdx = TempPosIdx + 1
				)
			)
			
			if Semantic == "COLOR" do (
				if SemanticIndex == 0 do (
					if(TypeMapElements > 0)then g_ColorX_Idx = Offset / 4
					if(TypeMapElements > 1)then g_ColorY_Idx = g_ColorX_Idx + 1
					if(TypeMapElements > 2)then g_ColorZ_Idx = g_ColorX_Idx + 2
					if(TypeMapElements > 3)then g_ColorW_Idx = g_ColorX_Idx + 3
				)
			)
			
			if Semantic == "NORMAL" do (
				if TempNormalIdx == 0 do (
					g_NormX_Idx = Offset / 4
					g_NormY_Idx = g_NormX_Idx + 1
					g_NormZ_Idx = g_NormX_Idx + 2
					
					TempNormalIdx = TempNormalIdx + 1
				)
			)
			
			if Semantic == "TEXCOORD" do (
				if SemanticIndex == 0 then(
					if(TypeMapElements > 0)then g_Tc0_X_Idx = Offset / 4
					if(TypeMapElements > 1)then g_Tc0_Y_Idx = g_Tc0_X_Idx + 1
					if(TypeMapElements > 2)then g_Tc0_Z_Idx = g_Tc0_X_Idx + 2
					if(TypeMapElements > 3)then g_Tc0_W_Idx = g_Tc0_X_Idx + 3
				)
				else if SemanticIndex == 1 then(
					if(TypeMapElements > 0)then g_Tc1_X_Idx = Offset / 4
					if(TypeMapElements > 1)then g_Tc1_Y_Idx = g_Tc1_X_Idx + 1
					if(TypeMapElements > 2)then g_Tc1_Z_Idx = g_Tc1_X_Idx + 2
					if(TypeMapElements > 3)then g_Tc1_W_Idx = g_Tc1_X_Idx + 3
				)
				else if SemanticIndex == 2  then(
					if(TypeMapElements > 0)then g_Tc2_X_Idx = Offset / 4
					if(TypeMapElements > 1)then g_Tc2_Y_Idx = g_Tc2_X_Idx + 1
					if(TypeMapElements > 2)then g_Tc2_Z_Idx = g_Tc2_X_Idx + 2
					if(TypeMapElements > 3)then g_Tc2_W_Idx = g_Tc2_X_Idx + 3
				)
				else if SemanticIndex == 3 then(
					if(TypeMapElements > 0)then g_Tc3_X_Idx = Offset / 4
					if(TypeMapElements > 1)then g_Tc3_Y_Idx = g_Tc3_X_Idx + 1
					if(TypeMapElements > 2)then g_Tc3_Z_Idx = g_Tc3_X_Idx + 2
					if(TypeMapElements > 3)then g_Tc3_W_Idx = g_Tc3_X_Idx + 3
				)
				else if SemanticIndex == 4 then(
					if(TypeMapElements > 0)then g_Tc4_X_Idx = Offset / 4
					if(TypeMapElements > 1)then g_Tc4_Y_Idx = g_Tc4_X_Idx + 1
					if(TypeMapElements > 2)then g_Tc4_Z_Idx = g_Tc4_X_Idx + 2
					if(TypeMapElements > 3)then g_Tc4_W_Idx = g_Tc4_X_Idx + 3
				)
				else if SemanticIndex == 5 then(
					if(TypeMapElements > 0)then g_Tc5_X_Idx = Offset / 4
					if(TypeMapElements > 1)then g_Tc5_Y_Idx = g_Tc5_X_Idx + 1
					if(TypeMapElements > 2)then g_Tc5_Z_Idx = g_Tc5_X_Idx + 2
					if(TypeMapElements > 3)then g_Tc5_W_Idx = g_Tc5_X_Idx + 3
				)
				else if SemanticIndex == 6 then(
					if(TypeMapElements > 0)then g_Tc6_X_Idx = Offset / 4
					if(TypeMapElements > 1)then g_Tc6_Y_Idx = g_Tc6_X_Idx + 1
					if(TypeMapElements > 2)then g_Tc6_Z_Idx = g_Tc6_X_Idx + 2
					if(TypeMapElements > 3)then g_Tc6_W_Idx = g_Tc6_X_Idx + 3
				)
			)
		)
		
		
	)
	printDebug "-----------------------------"
	
	---Read texture files list to array ( if present )
	for i = 1 to TextureFilesCnt do (
		TexFile = ReadStr f
		append TextureFiles ( TexFile as String )
	)
	
	
	---Read shader files list to array ( if present )
	for i = 1 to ShaderFilesCnt do (
		ShaderFile = ReadStr f
		append ShaderFiles ( ShaderFile as String )
	)	
	
	
	
	printDebug ( "Texture Files:" )
	for i = 1 to TextureFiles.count do (
		printDebug ( TextureFiles[ i ] as String )
	)
	printDebug ( "------------" )
	
	
	
	---Read indexes
	for x = 1 to dwFacesCnt do(
		i0 = readlong f #unsigned
		i1 = readlong f #unsigned
		i2 = readlong f #unsigned
		if g_flipXZAxis == 1 then (
			append Face_array[i2+1,i1+1,i0+1]
		) else (
			append Face_array[i0+1,i1+1,i2+1]
		)
		
---		print( "idx0: " + i0 as String + " idx1: " + i1 as String + " idx2: " + i2 as String )
	)
	
	
	printDebug( "PosX idx: " + g_PosX_Idx as String )
	printDebug( "PosY idx: " + g_PosY_Idx as String )
	printDebug( "PosZ idx: " + g_PosZ_Idx as String )
	printDebug( "NormX idx: " + g_NormX_Idx as String )
	printDebug( "NormY idx: " + g_NormY_Idx as String )
	printDebug( "NormZ idx: " + g_NormZ_Idx as String )
	printDebug( "ColorX idx: " + g_ColorX_Idx as String )
	printDebug( "ColorY idx: " + g_ColorY_Idx as String )
	printDebug( "ColorZ idx: " + g_ColorZ_Idx as String )
	printDebug( "ColorW idx: " + g_ColorW_Idx as String )
	printDebug( "Tx0 idx: " + g_Tc0_X_Idx as String )
	printDebug( "Ty0 idx: " + g_Tc0_Y_Idx as String )
	printDebug( "Tz0 idx: " + g_Tc0_Z_Idx as String )
	printDebug( "Tw0 idx: " + g_Tc0_W_Idx as String )
	printDebug( "Tx1 idx: " + g_Tc1_X_Idx as String )
	printDebug( "Ty1 idx: " + g_Tc1_Y_Idx as String )
	printDebug( "Tz1 idx: " + g_Tc1_Z_Idx as String )
	printDebug( "Tw1 idx: " + g_Tc1_W_Idx as String )
	printDebug( "Tx2 idx: " + g_Tc2_X_Idx as String )
	printDebug( "Ty2 idx: " + g_Tc2_Y_Idx as String )
	printDebug( "Tz2 idx: " + g_Tc2_Z_Idx as String )
	printDebug( "Tw2 idx: " + g_Tc2_W_Idx as String )
	printDebug( "Tx3 idx: " + g_Tc3_X_Idx as String )
	printDebug( "Ty3 idx: " + g_Tc3_Y_Idx as String )
	printDebug( "Tz3 idx: " + g_Tc3_Z_Idx as String )
	printDebug( "Tw3 idx: " + g_Tc3_W_Idx as String )
	printDebug( "Tx4 idx: " + g_Tc4_X_Idx as String )
	printDebug( "Ty4 idx: " + g_Tc4_Y_Idx as String )
	printDebug( "Tz4 idx: " + g_Tc4_Z_Idx as String )
	printDebug( "Tw4 idx: " + g_Tc4_W_Idx as String )
	printDebug( "Tx5 idx: " + g_Tc5_X_Idx as String )
	printDebug( "Ty5 idx: " + g_Tc5_Y_Idx as String )
	printDebug( "Tz5 idx: " + g_Tc5_Z_Idx as String )
	printDebug( "Tw5 idx: " + g_Tc5_W_Idx as String )
	printDebug( "Tx6 idx: " + g_Tc6_X_Idx as String )
	printDebug( "Ty6 idx: " + g_Tc6_Y_Idx as String )
	printDebug( "Tz6 idx: " + g_Tc6_Z_Idx as String )
	printDebug( "Tw6 idx: " + g_Tc6_W_Idx as String )
	
	---Read vertexes
	for k = 1 to dwVertexesCnt do(
	
---		print ( "VertexIdx : " + (k-1) as String )
	
		vx = 0.0
		vy = 0.0
		vz = 0.0
		vw = 0.0
		nx = 0.0
		ny = 0.0
		nz = 0.0
		nw = 0.0
		colx = 0.0
		coly = 0.0
		colz = 0.0
		colw = 0.0
		
		tx0 = 0.0
		ty0 = 0.0
		tz0 = 0.0
		tw0 = 0.0
		
		tx1 = 0.0
		ty1 = 0.0
		tz1 = 0.0
		tw1 = 0.0
		
		tx2 = 0.0
		ty2 = 0.0
		tz2 = 0.0
		tw2 = 0.0
		
		tx3 = 0.0
		ty3 = 0.0
		tz3 = 0.0
		tw3 = 0.0
		
		tx4 = 0.0
		ty4 = 0.0
		tz4 = 0.0
		tw4 = 0.0
		
		tx5 = 0.0
		ty5 = 0.0
		tz5 = 0.0
		tw5 = 0.0
		
		tx6 = 0.0
		ty6 = 0.0
		tz6 = 0.0
		tw6 = 0.0
	
		for j = 0 to VertexAttribTypesArray.count - 1 do(
		
---			print ( "VertAttr Idx: " + j as String )
			ElementType = VertexAttribTypesArray[ j + 1 ]
			if ElementType == 0 then (  --- EFLOAT
				z = readfloat f
			)
			else if ElementType == 1 then (  ---EUINT
				z = readlong f #unsigned
			)
			else if ElementType == 2 then (  ---ESINT
				z = readlong f #signed
			)
			else (
				z = readlong f #unsigned
			)
			
			if j == g_PosX_Idx do vx = z
			if j == g_PosY_Idx do vy = z
			if j == g_PosZ_Idx do vz = z
			
			if j == g_NormX_Idx do nx = z
			if j == g_NormY_Idx do ny = z
			if j == g_NormZ_Idx do nz = z
				
			if j == g_ColorX_Idx do colx = z
			if j == g_ColorY_Idx do coly = z
			if j == g_ColorZ_Idx do colz = z
			if j == g_ColorW_Idx do colw = z
			
			if j == g_Tc0_X_Idx do tx0 = z
			if j == g_Tc0_Y_Idx do ty0 = z
			if j == g_Tc0_Z_Idx do tz0 = z
			if j == g_Tc0_W_Idx do tw0 = z
				
			if j == g_Tc1_X_Idx do tx1 = z
			if j == g_Tc1_Y_Idx do ty1 = z
			if j == g_Tc1_Z_Idx do tz1 = z
			if j == g_Tc1_W_Idx do tw1 = z
				
			if j == g_Tc2_X_Idx do tx2 = z
			if j == g_Tc2_Y_Idx do ty2 = z
			if j == g_Tc2_Z_Idx do tz2 = z
			if j == g_Tc2_W_Idx do tw2 = z
				
			if j == g_Tc3_X_Idx do tx3 = z
			if j == g_Tc3_Y_Idx do ty3 = z
			if j == g_Tc3_Z_Idx do tz3 = z
			if j == g_Tc3_W_Idx do tw3 = z
			
			if j == g_Tc4_X_Idx do tx4 = z
			if j == g_Tc4_Y_Idx do ty4 = z
			if j == g_Tc4_Z_Idx do tz4 = z
			if j == g_Tc4_W_Idx do tw4 = z
				
			if j == g_Tc5_X_Idx do tx5 = z
			if j == g_Tc5_Y_Idx do ty5 = z
			if j == g_Tc5_Z_Idx do tz5 = z
			if j == g_Tc5_W_Idx do tw5 = z
				
			if j == g_Tc6_X_Idx do tx6 = z
			if j == g_Tc6_Y_Idx do ty6 = z
			if j == g_Tc6_Z_Idx do tz6 = z
			if j == g_Tc6_W_Idx do tw6 = z
			
			vx = vx as Float
			vy = vy as Float
			vz = vz as Float
			
			nx = nx as Float
			ny = ny as Float
			nz = nz as Float
			
			colx = colx as Float
			coly = coly as Float
			colz = colz as Float
			colw = colw as Float
			
			tx0 = tx0 as Float
			ty0 = ty0 as Float
			tz0 = tz0 as Float
			tw0 = tw0 as Float
			
			tx1 = tx1 as Float
			ty1 = ty1 as Float
			tz1 = tz1 as Float
			tw1 = tw1 as Float
			
			tx2 = tx2 as Float
			ty2 = ty2 as Float
			tz2 = tz2 as Float
			tw2 = tw2 as Float
			
			tx3 = tx3 as Float
			ty3 = ty3 as Float
			tz3 = tz3 as Float
			tw3 = tw3 as Float
			
			tx4 = tx4 as Float
			ty4 = ty4 as Float
			tz4 = tz4 as Float
			tw4 = tw4 as Float
			
			tx5 = tx5 as Float
			ty5 = ty5 as Float
			tz5 = tz5 as Float
			tw5 = tw5 as Float
			
			tx6 = tx6 as Float
			ty6 = ty6 as Float
			tz6 = tz6 as Float
			tw6 = tw6 as Float
		)
		append Vert_array[(g_flipPosX * vx * g_ninjaScale),(vy * g_ninjaScale),(vz * g_ninjaScale)]
		append Normal_array [g_flipPosX * nx,ny,nz]
		-- 海岛的变换
		--append Normal_array [nx * 2.0 - 1.0,ny * 2.0 - 1.0,nz * 2.0 - 1.0]
		if g_ColorX_Idx != -1 then (
			append Color_array [colx,coly,colz,colw]
		)
		append UV0_array[tx0,ty0 * g_flipUV + 1,tz0,tw0]
		if g_Tc1_X_Idx != -1 then (
			append UV1_array[tx1,ty1 /** g_flipUV*/,tz1,tw1]
		)
		if g_Tc2_X_Idx != -1 then (
			append UV2_array[tx2,ty2 /** g_flipUV*/,tz2,tw2]
		)
		if g_Tc3_X_Idx != -1 then (
			append UV3_array[tx3,ty3 /** g_flipUV*/,tz3,tw3]
		)
		if g_Tc4_X_Idx != -1 then (
			append UV4_array[tx4,ty4 /** g_flipUV*/,tz4,tw4]
		)
		if g_Tc5_X_Idx != -1 then (
			append UV5_array[tx5,ty5 /** g_flipUV*/,tz5,tw5]
		)
		if g_Tc6_X_Idx != -1 then (
			append UV6_array[tx6,ty6 /** g_flipUV*/,tz6,tw6]
		)
		
---		print( "vx: " + vx as String + " vy: " + vy as String + " vz: " + vz as String )
---		print( "tu: " + tu as String + " tv: " + tv as String )
	)
	
	TexFile = TextureFiles [ 1 + g_Tex0_FileLev ]
	if TexFile == undefined do ( TexFile = "notexture.dds" )
	
	TexFileName = getFilenamePath RipFilePath 
	TexFileName = TexFileName + TexFile
	printDebug ( "TEXTURE FILE: " + TexFileName )
	
	---Material
-- 	thenewmaterial = multimaterial numsubs:1
-- 	thenewsubmaterial = standardmaterial name:TexFile
-- 	thenewsubmaterial.diffusemap = bitmaptexture name:TexFile
-- 	thenewsubmaterial.diffusemap.filename = TexFileName
-- 	thenewmaterial.materiallist[1] = thenewsubmaterial
-- 	showtexturemap thenewsubmaterial thenewsubmaterial.diffusemap true
		
	thenewmaterial = standardmaterial name:TexFile
	thenewmaterial.diffusemap = bitmaptexture name:TexFile
	thenewmaterial.diffusemap.filename = TexFileName
-- 	thenewmaterial.bumpmap = bitmaptexture name:TexFile
-- 	thenewmaterial.bumpmap.filename = TexFileName
	showtexturemap thenewmaterial thenewmaterial.diffusemap true
	
	-- 生成mesh
	msh = mesh vertices:Vert_array faces:Face_array
	
	
	local addMapCount = 0
	if UV0_array.count > 0 then ( addMapCount = addMapCount + 1 )
	if UV1_array.count > 0 then ( addMapCount = addMapCount + 1 )
	if UV2_array.count > 0 then ( addMapCount = addMapCount + 1 )
	if UV3_array.count > 0 then ( addMapCount = addMapCount + 1 )
	if UV4_array.count > 0 then ( addMapCount = addMapCount + 1 )
	if UV5_array.count > 0 then ( addMapCount = addMapCount + 1 )
	if UV6_array.count > 0 then ( addMapCount = addMapCount + 1 )
	
	-- 0 is vertex color, 1+ are textures
	meshop.setNumMaps msh (addMapCount+1) keep:true
	
	if Color_array.count > 0 then (
		meshop.setNumMapVerts msh 0 Color_array.count keep:true
		meshop.setMapSupport msh 0 true
		for i = 1 to Color_array.count do (
			meshop.setMapVert msh 0 i Color_array[i]
		) 
	) else (
		meshop.setMapSupport msh 0 false  --关闭颜色通道
	)
	
	--setNumTVerts msh UV0_array.count
	--for i = 1 to UV0_array.count do (setTVert msh i UV0_array[i]) 
	if UV0_array.count > 0 then (
		meshop.setNumMapVerts msh 1 UV0_array.count keep:true
		meshop.setMapSupport msh 1 true
		for i = 1 to UV0_array.count do (
			meshop.setMapVert msh 1 i UV0_array[i]
		) 
	)
	if UV1_array.count > 0 then (
		meshop.setNumMapVerts msh 2 UV1_array.count keep:true
		meshop.setMapSupport msh 2 true
		for i = 1 to UV1_array.count do (
			meshop.setMapVert msh 2 i UV1_array[i]
		) 
	)
	if UV2_array.count > 0 then (
		meshop.setNumMapVerts msh 3 UV2_array.count keep:true
		meshop.setMapSupport msh 3 true
		for i = 1 to UV2_array.count do (
			meshop.setMapVert msh 3 i UV2_array[i]
		) 
	)
	if UV3_array.count > 0 then (
		meshop.setNumMapVerts msh 4 UV3_array.count keep:true
		meshop.setMapSupport msh 4 true
		for i = 1 to UV3_array.count do (
			meshop.setMapVert msh 4 i UV3_array[i]
		) 
	)
	if UV4_array.count > 0 then (
		meshop.setNumMapVerts msh 5 UV4_array.count keep:true
		meshop.setMapSupport msh 5 true
		for i = 1 to UV4_array.count do (
			meshop.setMapVert msh 5 i UV4_array[i]
		) 
	)
	if UV5_array.count > 0 then (
		meshop.setNumMapVerts msh 6 UV5_array.count keep:true
		meshop.setMapSupport msh 6 true
		for i = 1 to UV5_array.count do (
			meshop.setMapVert msh 6 i UV5_array[i]
		) 
	)
	if UV6_array.count > 0 then (
		meshop.setNumMapVerts msh 7 UV6_array.count keep:true
		meshop.setMapSupport msh 7 true
		for i = 1 to UV6_array.count do (
			meshop.setMapVert msh 7 i UV6_array[i]
		) 
	)
	
	buildTVFaces msh false
	for i = 1 to Face_array.count do (setTVFace msh i Face_array[i])
	-- 下面这个原来就注释了要max2015才有用
	--for i = 1 to Normal_array.count do (setNormal msh j Normal_array[j])

	--Aplly mesh rotation
	currentMatrix = msh.transform
	preRotate currentMatrix (eulertoquat (eulerAngles g_ninjarotX g_ninjarotY g_ninjarotZ))
	msh.transform = currentMatrix
	resetxform msh
	maxOps.CollapseNode msh off
		
	msh.name = getFilenameFile RipFilePath
	msh.material = thenewmaterial	
		
		
	if g_applyNormal == 1 then (
		max modify mode --必须转到修改面板，否则修改器的设置不保证绝对生效
		addModifier msh (edit_Normals()) before:(msh.modifiers.count)
		modPanel.setCurrentObject msh.edit_Normals node:msh ui:on
		local normalSel = #{}
		for vInd=1 to Normal_array.count do( 
			msh.edit_Normals.ConvertVertexSelection #{vInd} normalSel node:msh 
			local vNormalArr = normalSel as array
			for ind in vNormalArr do(
				msh.Edit_Normals.SetNormalExplicit ind explicit:true node:msh
				msh.Edit_Normals.SetNormal ind Normal_array[vInd] node:msh
			)
		)
	)
	
	update msh
		
	
	--Redraw screen
	--windows.processPostedMessages() -- This prevents 3DS Max from hanging!
	--completeredraw()
	--gw.updateScreen()
)

fn ImportRip2 RipFilePath =
(
	f = fopen RipFilePath "rb"

	Signature     = readlong f #unsigned
	Version       = readlong f #unsigned

	if Version != RipFileVersion do(
		printDebug "Not RIP file"
		---print ( "FileSig: " + Version as String )
		---print ( "Sig : " + RipFileVersion as String )
		return 0
	)

	dwFacesCnt    = readlong f #unsigned
	dwVertexesCnt = readlong f #unsigned
	VertexSize    = readlong f #unsigned
	TextureFilesCnt= readlong f #unsigned
	ShaderFilesCnt= readlong f #unsigned
	VertexAttributesCnt= readlong f #unsigned

	
	printDebug ( "*****ImportRip() File: " + RipFilePath as String )
	printDebug ( "dwFacesCnt=" + dwFacesCnt as String )
	printDebug ( "dwVertexesCnt=" + dwVertexesCnt as String )
	printDebug ( "VertexAttributesCnt=" + VertexAttributesCnt as String )
	
	
	
	VertexAttribTypesArray= #()   ---Contain all types
	TextureFiles = #()
	ShaderFiles  = #()
	
	Face_array = #()
	Normal_array = #()
	Vert_array = #()
	UV0_array = #()		
	
	
	
	TempPosIdx = 0      ---Get only first index attribute flag
	TempNormalIdx = 0
	TempTexCoordIdx = 0

	---Read vertex attributes
	for i = 1 to VertexAttributesCnt do (
		Semantic = ReadStr f
		SemanticIndex = readlong f #unsigned
		Offset = readlong f #unsigned
		Size   = readlong f #unsigned
		TypeMapElements = readlong f #unsigned
		for j = 1 to TypeMapElements do (
			TypeElement = readlong f #unsigned
			append VertexAttribTypesArray TypeElement
		)
		printDebug "------------"
		printDebug( "Semantic="+ Semantic )
		printDebug( "SemanticIndex=" + SemanticIndex as String )
		printDebug( "Offset=" + Offset as String )
		printDebug( "Size=" + Size as String )
		printDebug( "TypeMapElements=" + TypeMapElements as String )

		---Recognize semantic if "AUTO" set
		if g_VertexFormatRecog == 0 do ( ---AUTO recognition	
			if Semantic == "POSITION" do (  --- Get as "XYZ_"
				if TempPosIdx == 0 do (
					g_PosX_Idx = Offset / 4
					g_PosY_Idx = g_PosX_Idx + 1
					g_PosZ_Idx = g_PosX_Idx + 2
					
					TempPosIdx = TempPosIdx + 1
				)
			)
			
			if Semantic == "NORMAL" do (
				if TempNormalIdx == 0 do (
					g_NormX_Idx = Offset / 4
					g_NormY_Idx = g_NormX_Idx + 1
					g_NormZ_Idx = g_NormX_Idx + 2
					
					TempNormalIdx = TempNormalIdx + 1
				)
			)
			
			if Semantic == "TEXCOORD" do (
				if TempTexCoordIdx == 0 do(
					g_Tc0_X_Idx = Offset / 4
					g_Tc0_Y_Idx = g_Tc0_X_Idx + 1
					
					TempTexCoordIdx = TempTexCoordIdx + 1
				)
			)
		)
		
		
	)
	printDebug "-----------------------------"
	
	---Read texture files list to array ( if present )
	for i = 1 to TextureFilesCnt do (
		TexFile = ReadStr f
		append TextureFiles ( TexFile as String )
	)
	
	
	---Read shader files list to array ( if present )
	for i = 1 to ShaderFilesCnt do (
		ShaderFile = ReadStr f
		append ShaderFiles ( ShaderFile as String )
	)	
	
	
	
	printDebug ( "Texture Files:" )
	for i = 1 to TextureFiles.count do (
		printDebug ( TextureFiles[ i ] as String )
	)
	printDebug ( "------------" )
	
	
	
	---Read indexes
	for x = 1 to dwFacesCnt do(
		i0 = readlong f #unsigned
		i1 = readlong f #unsigned
		i2 = readlong f #unsigned
		if g_flipXZAxis == 1 then (
			append Face_array[i2+1,i1+1,i0+1]
		) else (
			append Face_array[i0+1,i1+1,i2+1]
		)
		
---		print( "idx0: " + i0 as String + " idx1: " + i1 as String + " idx2: " + i2 as String )
	)
	
	
	printDebug( "PosX idx: " + g_PosX_Idx as String )
	printDebug( "PosY idx: " + g_PosY_Idx as String )
	printDebug( "PosZ idx: " + g_PosZ_Idx as String )
	printDebug( "NormX idx: " + g_NormX_Idx as String )
	printDebug( "NormY idx: " + g_NormY_Idx as String )
	printDebug( "NormZ idx: " + g_NormZ_Idx as String )
	printDebug( "Tu0 idx: " + g_Tc0_X_Idx as String )
	printDebug( "Tv0 idx: " + g_Tc0_Y_Idx as String )
	
	
	---Read vertexes
	for k = 1 to dwVertexesCnt do(
	
---		print ( "VertexIdx : " + (k-1) as String )
	
		vx = 0.0
		vy = 0.0
		vz = 0.0
		vw = 0.0
		nx = 0.0
		ny = 0.0
		nz = 0.0
		nw = 0.0
		tu = 0.0
		tv = 0.0
	
		for j = 0 to VertexAttribTypesArray.count - 1 do(
		
---			print ( "VertAttr Idx: " + j as String )
			ElementType = VertexAttribTypesArray[ j + 1 ]
			if ElementType == 0 then (  --- EFLOAT
				z = readfloat f
			)
			else if ElementType == 1 then (  ---EUINT
				z = readlong f #unsigned
			)
			else if ElementType == 2 then (  ---ESINT
				z = readlong f #signed
			)
			else (
				z = readlong f #unsigned
			)
			
			if j == g_PosX_Idx do vx = z
			if j == g_PosY_Idx do vy = z
			if j == g_PosZ_Idx do vz = z
			if j == g_PosW_Idx do vw = z
			
			if j == g_NormX_Idx do nx = z
			if j == g_NormY_Idx do ny = z
			if j == g_NormZ_Idx do nz = z
			
			if j == g_Tc0_X_Idx do tu = z
			if j == g_Tc0_Y_Idx do tv = z
			
			
			vx = vx as Float
			vy = vy as Float
			vz = vz as Float
			vw = vw as Float			
			
			nx = nx as Float
			ny = ny as Float
			nz = nz as Float
			
			tu = tu as Float
			tv = tv as Float
		)
		append Vert_array[((vx*vw) * g_ninjaScale),((vy*vw) * g_ninjaScale),((vz*vw) * g_ninjaScale)]
		append Normal_array [nz,ny,nx]
		append UV0_array[tu,tv * g_flipUV,0]
		
---		print( "vx: " + vx as String + " vy: " + vy as String + " vz: " + vz as String )
---		print( "tu: " + tu as String + " tv: " + tv as String )
	)
	
	TexFile = TextureFiles [ 1 + g_Tex0_FileLev ]
	if TexFile == undefined do ( TexFile = "notexture.dds" )
	
	TexFileName = getFilenamePath RipFilePath 
	TexFileName = TexFileName + TexFile
	printDebug ( "TEXTURE FILE: " + TexFileName )
	
	---Material
	thenewmaterial = standardmaterial name:TexFile
	thenewmaterial.diffusemap = bitmaptexture name:TexFile
	thenewmaterial.diffusemap.filename = TexFileName
	showtexturemap thenewmaterial thenewmaterial.diffusemap true
	
	msh = mesh vertices:Vert_array faces:Face_array
	setNumTVerts msh UV0_array.count
		
	for i = 1 to UV0_array.count do (setTVert msh i UV_array[i]) 
	buildTVFaces msh false
	for i = 1 to Face_array.count do (setTVFace msh i Face_array[i])
	--for i = 1 to Normal_array.count do (setNormal msh j Normal_array[j])
		
	--Aplly mesh rotation
	currentMatrix = msh.transform
	preRotate currentMatrix (eulertoquat (eulerAngles g_ninjarotX g_ninjarotY g_ninjarotZ))
	msh.transform = currentMatrix
	resetxform msh
	maxOps.CollapseNode msh off
		
	msh.name = getFilenameFile RipFilePath
	msh.material = thenewmaterial	
	
	--Redraw screen
	--windows.processPostedMessages() -- This prevents 3DS Max from hanging!
	--completeredraw()
	--gw.updateScreen()
)

rollout MainRollout "Ninja Ripper Importer v1.3 beta8" width:340 height:450
(
	-- Source select
	groupBox grp1 "Source Select" pos:[5,5] width:289 height:113
	radioButtons RadioImport "" pos:[58,27] width:201 height:16 labels:#("Group", "Single", "List File") default:2 columns:3
		
	label lblInputFile "Input .rip File:" pos:[12,58] width:68 height:17 visible:true
	label lblInputDir "Input Dir:" pos:[12,58] width:68 height:17 visible:false
	label lblInputLst "Input .lst File:" pos:[12,58] width:68 height:17 visible:false
	editText InputSrc "" pos:[84,55] width:169 height:20
	button SelectSrc "..." pos:[260,56] width:26 height:19 toolTip:""
	
	label lbl10 "RIP File Nums" pos:[13,85] width:69 height:18 enabled:false
	editText RipList "" pos:[84,82] width:202 height:20 enabled:false
		
	-- Vertex Format
	groupBox grp2 "Vertex Layout" pos:[5,125] width:175 height:168 columns:2
	
	--imgTag theImgTag "Bitmap" pos:[5,150] width:168 height:20 bitmap:(bitmap 80 50 color:gray) align:#right

	radioButtons RadioVertexFormat "" pos:[38,144] width:48 height:32 enabled:true labels:#("Auto", "Manual") default:1 columns:2
		
	label lbl4 "Position" pos:[24,170] width:41 height:14 enabled:false
	spinner pos_x "x" pos:[21,195] width:38 height:20 type:#integer enabled:false
	spinner pos_y "y" pos:[21,225] width:38 height:20 type:#integer enabled:false
	spinner pos_z "z" pos:[21,256] width:38 height:20 type:#integer enabled:false
	
	label lbl7 "Normal" pos:[78,170] width:37 height:14 enabled:false
	spinner norm_x "x" pos:[73,195] width:38 height:20 type:#integer enabled:false
	spinner norm_y "y" pos:[73,225] width:38 height:20 type:#integer enabled:false
	spinner norm_z "z" pos:[73,256] width:38 height:20 type:#integer enabled:false
	
	label lbl5 "UV Coord" pos:[124,170] width:48 height:14 enabled:false
	spinner tc0_u "u" pos:[125,195] width:38 height:16 range:[0,500,0] type:#integer enabled:false
	spinner tc0_v "v" pos:[125,225] width:38 height:16 range:[0,500,0] type:#integer enabled:false
	--editText tc0_u "u" pos:[176,195] width:42 height:20
	--editText tc0_v "v" pos:[176,225] width:42 height:20
	--button plusUVone "+1" pos:[233,204] width:40 height:30 enabled:false
	
	--Transform
	groupBox grp4 "Transformations" pos:[185,125] width:129 height:168
	
	label lblscale "Scale" pos:[192,149] width:77 height:15 enabled:true
	spinner spnscale "" pos:[241,149] width:45 height:16 range:[1,10000,g_ninjaScale] type:#integer scale:1 enabled:true
	
	label lblrotateX "Rotate X" pos:[192,180] width:77 height:15 enabled:true
	spinner spnrotateX "" pos:[241,180] width:45 height:16 range:[0,360,g_ninjarotX] type:#float scale:90 type:#integer enabled:true
	
	label lblrotateY "Rotate Y" pos:[192,206] width:77 height:15 enabled:true
	spinner spnrotateY "" pos:[241,206] width:45 height:16 range:[0,360,g_ninjarotY] type:#float scale:90 type:#integer enabled:true
	
	label lblrotateZ "Rotate Z" pos:[192,232] width:77 height:15 enabled:true
	spinner spnrotateZ "" pos:[241,232] width:45 height:16 range:[0,360,g_ninjarotZ] type:#float scale:90 type:#integer enabled:true
	
	label lblflipXZ "Flip Face XZ Axis" pos:[192,264] width:107 height:15 enabled:true
	checkbox checkerXZAxis pos:[285,264] checked:false
	
	label lbl6 "Tex.Num" pos:[15,309] width:70 height:15
 	spinner spnTex0Lev "" pos:[65,309] width:45 height:16 range:[0,7,0] type:#integer
	
	label lblflipuv "Flip UV Vertical" pos:[15,331] width:70 height:15
 	checkbox checkerUV pos:[97,331] checked:true
	
	label lblapplynormal "Apply Normal" pos:[15,351] width:70 height:15
 	checkbox checkerApplyNormal pos:[97,351] checked:false
	
	label lblflipPosX "Flip Pos X" pos:[15,371] width:70 height:15
 	checkbox checkerFlipPosX pos:[97,371] checked:false

	--Enable debug mode? (VERY SLOW)
	label lbldbgmde "Debug Output" pos:[188,299] width:77 height:30
	checkbox debugModeState pos:[262,299] checked:false --by default, OFF!
	
	-- Import button
	button BtnImport "IMPORT" pos:[235,357] width:80 height:40
	
		-- Import button
	button BtnImport2 "IMPORT Sketchfab" pos:[135,357] width:100 height:40
	
	--CL69
	label modifiedbyCL "Modified by CarLuver69/zaramot_xentax" pos:[100, 402] width:200 height:35
	
	on spnscale changed val do g_ninjaScale = val
	on spnrotateX changed val do g_ninjarotX = val
	on spnrotateY changed val do g_ninjarotY = val	
	on spnrotateZ changed val do g_ninjarotZ = val
	on g_enabler changed val do g_enabler = val
		
	on MainRollout open  do (
		
		---Init values
		pos_x.value = 0
		pos_y.value = 1
		pos_z.value = 2
		
		norm_x.value = 3
		norm_y.value = 4
		norm_z.value = 5
		
		tc0_u.value  = 6
		tc0_v.value  = 7
		
	)
	
	-- 	on checkerUV changed UVstate do g_flipUV  = -1
	
	--debug mode
	on debugModeState changed state do (
		if debugModeState.checked == false do (
			g_debugMode = false
		)
		if debugModeState.checked == true do (
			g_debugMode = true
			messageBox "WARNING: Debug mode is now enabled! Your import time will be increased by 50 - 75%!"
		)
	)
	
	
	on checkerUV changed UVstate do (
		if checkerUV.checked == false do (
			g_flipUV  = 1
		)

		if checkerUV.checked == true then (
			g_flipUV  = -1
		)
	)
	
	on checkerFlipPosX changed FlipPosXstate do (
		if checkerFlipPosX.checked == false do (
			g_flipPosX  = 1
		)

		if checkerFlipPosX.checked == true then (
			g_flipPosX  = -1
		)
	)

	on checkerApplyNormal changed ApplyNormalstate do (
		if checkerApplyNormal.checked == false do (
			g_applyNormal  = 0
		)

		if checkerApplyNormal.checked == true then (
			g_applyNormal  = 1
		)
	)
	
	on checkerXZAxis changed XZAxistate do (
		if checkerXZAxis.checked == false do (
			g_flipXZAxis = 0
		)
		
		if checkerXZAxis.checked == true then (
			g_flipXZAxis = 1
		)
	)
	
	on RadioVertexFormat changed state do
	(
		lbl4.enabled = not lbl4.enabled
		pos_x.enabled = not pos_x.enabled
		pos_y.enabled = not pos_y.enabled
		pos_z.enabled = not pos_z.enabled
		
		lbl7.enabled = not lbl7.enabled
		norm_x.enabled = not norm_x.enabled
		norm_y.enabled = not norm_y.enabled
		norm_z.enabled = not norm_z.enabled

		lbl5.enabled = not lbl5.enabled
		tc0_u.enabled = not tc0_u.enabled
		tc0_v.enabled = not tc0_v.enabled
	)
	
	on RadioImport changed state do
	(
		if RadioImport.state == 1 then (
			lbl10.enabled = true
			RipList.enabled = true
			lblInputFile.visible = false
			lblInputDir.visible = true
			lblInputLst.visible = false
			)
		else if RadioImport.state == 2 then (
			lbl10.enabled = false
			RipList.enabled = false
			lblInputFile.visible = true
			lblInputDir.visible = false
			lblInputLst.visible = false
			)
		else if RadioImport.state == 3 then (
			lbl10.enabled = false
			RipList.enabled = false
			lblInputFile.visible = false
			lblInputDir.visible = false
			lblInputLst.visible = true
			)
	)
	
	on SelectSrc pressed  do (
		if RadioImport.state == 1 then (	---Group
			g_InputSrc   = getSavePath caption:"Choose directory with .rip files" initialDir:"$scripts"
			if g_InputSrc != undefined do (
				g_InputSrc = g_InputSrc + "\\"
				g_ImportType  = 0
				InputSrc.text = g_InputSrc
				printDebug ( "Dir selected: " + g_InputSrc )
			)
		)
		else if RadioImport.state == 2 then (   ---Single
			g_InputSrc = getOpenFileName \ 
							caption:"Ninja Ripper File Select" \
							types:"Ninja Ripper File(*.rip)|*.rip" \
							historyCategory:"Ninja Ripper"
			if g_InputSrc != undefined do (
				g_ImportType = 1
				InputSrc.text = g_InputSrc
				printDebug ( "Single File selected: " + g_InputSrc )
			)
		)
		else if RadioImport.state == 3 then ( ---List file
			g_InputSrc = getOpenFileName \ 
							caption:"Ninja Ripper List File Select" \
							types:"Ninja Ripper List File(*.lst)|*.lst" \
							historyCategory:"Ninja Ripper"
			if g_InputSrc != undefined do(
				g_ImportType = 2
				InputSrc.text = g_InputSrc
				printDebug ( "List File selected: " + g_InputSrc )
			)
		)
	)
	
	--Import button
	on BtnImport pressed  do (
		
		if RadioVertexFormat.state == 1 then ( ---Auto
			printDebug "***Auto***"
			g_VertexFormatRecog = 0
			---Set default values
			g_PosX_Idx = -1
			g_PosY_Idx = -1
			g_PosZ_Idx = -1
			
			g_NormX_Idx = -1
			g_NormY_Idx = -1
			g_NormZ_Idx = -1
			
			g_Tc0_X_Idx = -1
			g_Tc0_Y_Idx = -1
						
			g_ninjarotX = spnrotateX.value
			g_ninjarotY = spnrotateY.value
			g_ninjarotZ = spnrotateZ.value
			
			meshscale = spnscale.value
		)
		
		else ( ---Manual
			printDebug "***Manual***"
			g_VertexFormatRecog = 1
			
			---Position
			g_PosX_Idx = ( pos_x.value as Integer )
			g_PosY_Idx = ( pos_y.value as Integer )
			g_PosZ_Idx = ( pos_z.value as Integer )
			
			---Normals
			g_NormX_Idx = ( norm_x.value as Integer )
			g_NormY_Idx = ( norm_y.value as Integer )
			g_NormZ_Idx = ( norm_z.value as Integer )

			---Tex coords
			g_Tc0_X_Idx = ( tc0_u.value as Integer )
			g_Tc0_Y_Idx = ( tc0_v.value as Integer )
						
			g_ninjarotX = spnrotateX.value
			g_ninjarotY = spnrotateY.value
			g_ninjarotZ = spnrotateZ.value
			
			meshscale = spnscale.value
		)
		
		g_Tex0_FileLev = spnTex0Lev.value as Integer
		
		
		---Import part
		if g_ImportType == 1 then ( ---Single file import
			if g_InputSrc.count > 0 then (  ImportRip g_InputSrc )
			else ( messageBox "Please select a .RIP file" )
		)
		else if g_ImportType == 0 then ( ---Group import
			
			if InputSrc.text.count > 0 then (
				if RipList.text.count > 0 then ( 
					RipDir = getFilenamePath InputSrc.text
					---print ( "RipDir: " + RipDir as String )
				
					tokens = filterString RipList.text ","
					FilteredTokens = #()
					
					---Remove token whitespaces
					for i = 1 to tokens.count do (
						---print ( "Tokens: " + tokens[i] as String )
						local Str = StringClear tokens[i]
						append FilteredTokens ( Str as String )
					)
					
					---Import loop. Split tokens with "-"
					for i = 1 to FilteredTokens.count do (
						printDebug ( "Filtered Tokens: " + FilteredTokens[i] as String )
						RangeTokens = filterString FilteredTokens[ i ] "-"
						if RangeTokens.count == 1 then (  --Single element
							RipDir1 = RipDir
							ss = CreateMeshName RangeTokens[ 1 ]
							RipDir1 = RipDir1 + ss;
							printDebug ( "Single Import:" + RipDir1 as String )
							ImportRip RipDir1
						)
						else(  ---Range element
							r0 = RangeTokens[1] as Integer
							r1 = RangeTokens[2] as Integer
							if r0 < r1 then (
								t1 = r0
								t2 = r1
					
								messageBox("Screen redrawing has been disabled to help boost performance.")
								disableSceneRedraw()

								tStart = timestamp()
								
								doProcess = true
								setProgressCancel = false
								
								progressBarText = "Importing "+ (t2 as string) +" objects..."
								progressStart (progressBarText as string)

								for j = r0 to r1 while doProcess do(
									if getProgressCancel() == true do (
										doProcess = false
										setProgressCancel = true
									)
									if (getProgressCancel() == false) and (setProgressCancel == false) do (
										RipDir1 = RipDir
										ss = CreateMeshName j
										RipDir1 = RipDir1 + ss;
										printDebug ( "Group Import:" + RipDir1 as String )
										ImportRip RipDir1
										
										t1 = t1 + 1
										tp = (100.0*t1/t2)
										progressUpdate (tp)
									)
								)
								progressEnd()
								enableSceneRedraw()
								
								tEnd = timestamp()
								
								tTimer = ((tEnd-tStart)/1000.0)
								if (tTimer <= 1) do ( tTime = (((tTimer) as string)+" second"))
								if (tTimer >= 2) do ( tTime = (((tTimer) as string)+" seconds"))
								if (tTimer > 60) do ( tTime = ((((tTimer)/60) as string)+" minute"))
								if (tTimer > 120) do ( tTime = ((((tTimer)/60) as string)+" minutes"))
								
								if (doProcess == true) and (setProgressCancel == false) then (
									messageBox("Successfully imported "+ (t1 as string) +" objects in "+((tTime) as string)+"!")
								) else (
									messageBox("Import interrupted! "+ (t1 as string) +"/"+(t2 as string)+" objects imported.")
								)									
								completeRedraw()
								gw.updateScreen()
							)
							else (
								printDebug( "Incorrect range: " + r0 as String + " to " + r1 as String )
							)
						)
					)
						
				)
				else(
					printDebug "Type file list"
				)
			)
			else (
				printDebug "Select dir"
			)
		)
		else(
			printDebug "Import from list file not realized"
		)
	)
	on BtnImport2 pressed  do (
		
		if RadioVertexFormat.state == 1 then ( ---Auto
			printDebug "***Auto***"
			g_VertexFormatRecog = 0
			---Set default values
			g_PosX_Idx = 0
			g_PosY_Idx = 1
			g_PosZ_Idx = 2
			g_PosW_Idx = 3		
						
			g_ninjarotX = spnrotateX.value
			g_ninjarotY = spnrotateY.value
			g_ninjarotZ = spnrotateZ.value
			
			meshscale = spnscale.value
		)
		
		else ( ---Manual
			printDebug "***Manual***"
			g_VertexFormatRecog = 1
			
			---Position
			g_PosX_Idx = ( pos_x.value as Integer )
			g_PosY_Idx = ( pos_y.value as Integer )
			g_PosZ_Idx = ( pos_z.value as Integer )
			--g_PosW_Idx = ( pos_w.value as Integer )			
			
			---Normals
			g_NormX_Idx = ( norm_x.value as Integer )
			g_NormY_Idx = ( norm_y.value as Integer )
			g_NormZ_Idx = ( norm_z.value as Integer )

			---Tex coords
			g_Tc0_X_Idx = ( tc0_u.value as Integer )
			g_Tc0_Y_Idx = ( tc0_v.value as Integer )
						
			g_ninjarotX = spnrotateX.value
			g_ninjarotY = spnrotateY.value
			g_ninjarotZ = spnrotateZ.value
			
			meshscale = spnscale.value
		)
		
		g_Tex0_FileLev = spnTex0Lev.value as Integer
		
		
		---Import part
		if g_ImportType == 1 then ( ---Single file import
			if g_InputSrc.count > 0 then (  ImportRip2 g_InputSrc )
			else ( messageBox "Please select a .RIP file" )
		)
		else if g_ImportType == 0 then ( ---Group import
			
			if InputSrc.text.count > 0 then (
				if RipList.text.count > 0 then ( 
					RipDir = getFilenamePath InputSrc.text
					---print ( "RipDir: " + RipDir as String )
				
					tokens = filterString RipList.text ","
					FilteredTokens = #()
					
					---Remove token whitespaces
					for i = 1 to tokens.count do (
						---print ( "Tokens: " + tokens[i] as String )
						local Str = StringClear tokens[i]
						append FilteredTokens ( Str as String )
					)
					
					---Import loop. Split tokens with "-"
					for i = 1 to FilteredTokens.count do (
						printDebug ( "Filtered Tokens: " + FilteredTokens[i] as String )
						RangeTokens = filterString FilteredTokens[ i ] "-"
						if RangeTokens.count == 1 then (  --Single element
							RipDir1 = RipDir
							ss = CreateMeshName RangeTokens[ 1 ]
							RipDir1 = RipDir1 + ss;
							printDebug ( "Single Import:" + RipDir1 as String )
							ImportRip2 RipDir1
						)
						else(  ---Range element
							r0 = RangeTokens[1] as Integer
							r1 = RangeTokens[2] as Integer
							if r0 < r1 then (
								t1 = r0
								t2 = r1
					
								messageBox("Screen redrawing has been disabled to help boost performance.")
								disableSceneRedraw()

								tStart = timestamp()
								
								doProcess = true
								setProgressCancel = false
								
								progressBarText = "Importing "+ (t2 as string) +" objects..."
								progressStart (progressBarText as string)

								for j = r0 to r1 while doProcess do(
									if getProgressCancel() == true do (
										doProcess = false
										setProgressCancel = true
									)
									if (getProgressCancel() == false) and (setProgressCancel == false) do (
										RipDir1 = RipDir
										ss = CreateMeshName j
										RipDir1 = RipDir1 + ss;
										printDebug ( "Group Import:" + RipDir1 as String )
										ImportRip2 RipDir1
										
										t1 = t1 + 1
										tp = (100.0*t1/t2)
										progressUpdate (tp)
									)
								)
								progressEnd()
								enableSceneRedraw()
								
								tEnd = timestamp()
								
								tTimer = ((tEnd-tStart)/1000.0)
								if (tTimer <= 1) do ( tTime = (((tTimer) as string)+" second"))
								if (tTimer >= 2) do ( tTime = (((tTimer) as string)+" seconds"))
								if (tTimer > 60) do ( tTime = ((((tTimer)/60) as string)+" minute"))
								if (tTimer > 120) do ( tTime = ((((tTimer)/60) as string)+" minutes"))
								
								if (doProcess == true) and (setProgressCancel == false) then (
									messageBox("Successfully imported "+ (t1 as string) +" objects in "+((tTime) as string)+"!")
								) else (
									messageBox("Import interrupted! "+ (t1 as string) +"/"+(t2 as string)+" objects imported.")
								)									
								completeRedraw()
								gw.updateScreen()
							)
							else (
								printDebug( "Incorrect range: " + r0 as String + " to " + r1 as String )
							)
						)
					)
						
				)
				else(
					printDebug "Type file list"
				)
			)
			else (
				printDebug "Select dir"
			)
		)
		else(
			printDebug "Import from list file not realized"
		)
	)	
)

createDialog MainRollout 320 420 50 60