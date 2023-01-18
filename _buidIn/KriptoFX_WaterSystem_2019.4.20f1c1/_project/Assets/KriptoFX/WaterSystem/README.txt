Version 1.3.0

My email is "kripto289@gmail.com"
Discord channel https://discord.gg/GUUZ9D96Uq (you can get all new changes/fixes/features in the discord channel. The asset store version will only receive major updates)
You can contact me for any questions.
My English is not very good, and if I have any translation errors, you can write me :)


-----------------------------------  WATER FIRST STEPS ---------------------------------------------------------------------------------------------------------

1) Right click in hierarchy -> Effects -> Water system
2) See the description of each setting: just click the help box with the symbol "?" or go over the cursor to any setting to see a text description. 

----------------------------------------------------------------------------------------------------------------------------------------------------------------




-----------------------------------  DEMO SCENE CORRECT SETTINGS -----------------------------------------------------------------------------------------------

1) Use linear color space. Edit -> Project settings -> Player -> Other settings -> Color space -> Linear
If you use gamma space, then you need to change light intensity and water transparent/turbidity for better looking.
2) Import "cinemachine" (for camera motion) and "post processing"
Window -> Package Manager -> click button bellow "packages" tab -> select "All Packages" or "Packages: Unity registry" -> Cinemachine -> "Install"
Window -> Package Manager -> click button bellow "packages" tab -> select "All Packages" or "Packages: Unity registry" -> Post Processing-> "Install"
3) Restart unity (post processing required)
4) Palms and trees cannot be included in the project under the asset store license, you can download it here http://kripto289.com/AssetStore/WaterSystem/1.1.0/KWS_Trees.unitypackage

----------------------------------------------------------------------------------------------------------------------------------------------------------------




----------------------------------- USING THE FLOWING EDITOR ---------------------------------------------------------------------------------------------------------
1) Click the "Flowmap Painter" button
2) Set the "Flowmap area position" and "Area Size" parameters. You must draw flowmap in this area!
3) Press and hold the left mouse button to draw on the flowmap area.
4) Use the "control" (ctrl) button + left mouse to erase mode.
5) Use the mouse wheel to change the brush size.
6) Press the "Save All" button.
7) All changes will be saved in the folder "Assets/StreamingAssets/WaterSystemData/WaterGUID", so be careful and don't remove it.
You can see the current waterGUID under section "water->rendering tab". It's look like a "74e75fc51de5773448e4fca07d21c2ff"
----------------------------------------------------------------------------------------------------------------------------------------------------------------




----------------------------------- USING SHORELINE EDITOR ---------------------------------------------------------------------------------------------------------
1) Disable the "selection outline" and "selection wire" in Gizmos (Scene tab -> Gizmos button).
Otherwise shoreline rendering will be slow when you select the water in hierarchy.
2) Click the "Edit mode" button
3) Set the "Drawing area position" and "Shoreline area size" parameters. You must add shoreline waves only in this area!
4) Click the "Add Wave" button. 
You can also add waves to the mouse cursor position using the "Insert" key button. For removal, select a wave and press the "Delete" button.

5) Avoid crossing boxes of the same color! Blue wave boxes should not intersect with other blue boxes. Yellow boxes should not intersect yellow boxes! 
6) You can use move/rotate/scale as usual for any other game object. 
7) Save all changes.
8) All changes will be saved in the folder "Assets/StreamingAssets/WaterSystemData/WaterGUID", so be careful and don't remove it.
You can see the current waterGUID under section "water->rendering tab". It's look like a "74e75fc51de5773448e4fca07d21c2ff"
----------------------------------------------------------------------------------------------------------------------------------------------------------------



----------------------------------- USING RIVER SPLINE EDITOR ---------------------------------------------------------------------------------------------------------
1) In this mode, a river mesh is generated using splines (control points).
Press the button "Add River" and left click on your ground and set the starting point of your river
2) Press 
SHIFT + LEFT click to add a new point.
Ctrl + Left click deletes the selected point.
Use "scale tool" (or R button) to change the river width
3) A minimum of 3 points is required to create a river. Place the points approximately at the same distance and avoid strong curvature of the mesh 
(otherwise you will see red intersections gizmo and artifacts)
4) Press "Save Changes"
----------------------------------------------------------------------------------------------------------------------------------------------------------------




----------------------------------- USING ADDITIONAL FEATURES ---------------------------------------------------------------------------------------------------------
1) You can use the "water depth mask" feature (used for example for ignoring water rendering inside a boat). 
Just create a mesh mask and use shader "KriptoFX/Water/KW_WaterHoleMask"

2) For buoyancy, add the script "KW_Buoyancy" to your object with rigibody. 

3) For compatibility with third-party assets (Enviro/Azure/WeatherMaker/Atmospheric height fog/Volumetric fog and mist2/etc) use WaterSystem -> Rendering -> Third-party fog support
----------------------------------------------------------------------------------------------------------------------------------------------------------------



----------------------------------- WATER API --------------------------------------------------------------------------------------------------------------------------
1) To get the water position/normal (for example for bouyancy) use follow code:

_waterInstance.EnableWaterSurfaceDataComputation = true; //Enable this setting to get actual WaterSurfaceData
var waterSurfaceData = _waterInstance.GetWaterSurfaceData(position); 
if (waterSurfaceData.IsActualDataReady) //checking if the surface data is ready. Since I use asynchronous updating, the data may be available with a delay, so the first frames can be null. 
{
    var waterPosition = waterSurfaceData.Position;
    var waterNormal = waterSurfaceData.Normal;
}

2) if you want to manually synchronize the time for all clients over the network, use follow code:

_waterInstance.UseNetworkTime = true;
_waterInstance.NetworkTime = ...  //your time in seconds
----------------------------------------------------------------------------------------------------------------------------------------------------------------





Demo scenes include open source projects for volumetric lighting and volumetric clouds.
https://github.com/SlightlyMad/VolumetricLights
https://github.com/yangrc1234/VolumeCloud
Other resources: 
Galleon https://sketchfab.com/Harry_L
Shark https://sketchfab.com/Ravenloop
Pool https://sketchfab.com/aurelien_martel
