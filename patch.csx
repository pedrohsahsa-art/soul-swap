// Builds a separate arena archive. This script must never receive an in-place output.
using System;
using System.IO;
using System.Linq;
using UndertaleModLib;
using UndertaleModLib.Models;
using UndertaleModLib.Compiler;
using UndertaleModLib.Scripting;
using Newtonsoft.Json.Linq;

EnsureDataLoaded();
string root = Environment.GetEnvironmentVariable("DR_PVP_ROOT");
if (String.IsNullOrWhiteSpace(root)) throw new Exception("DR_PVP_ROOT is required.");
if (Data.GeneralInfo.DisplayName.Content != "DELTARUNE Chapter 2" || Data.GeneralInfo.BytecodeVersion != 17)
    throw new Exception("Unsupported archive identity. Use build.py for SHA-256 validation.");
if (Data.GameObjects.ByName("obj_pvp_match") != null || Data.Rooms.ByName("room_pvp_arena") != null)
    throw new Exception("The input already contains a PvP patch.");
if (Data.Extensions.Any(e => e.Files.Count != 0))
    throw new Exception("Unexpected extension startup files; isolation needs review.");
var assets = JObject.Parse(File.ReadAllText(Path.Combine(root, "assets", "manifest.json")));
foreach (var entry in ((JObject)assets["sprites"]).Properties()) {
    var sprite = Data.Sprites.ByName(entry.Name);
    if (sprite == null || sprite.Textures.Count == 0 || sprite.Textures.Any(t => t?.Texture == null))
        throw new Exception("Missing embedded sprite frames: " + entry.Name);
}
foreach (var entry in (JArray)assets["fonts"]) {
    var font = Data.Fonts.ByName((string)entry);
    if (font == null || font.Texture == null || font.Glyphs.Count == 0)
        throw new Exception("Missing embedded font: " + entry);
}
foreach (var entry in (JArray)assets["sounds"])
    if (Data.Sounds.ByName((string)entry) == null) throw new Exception("Missing game sound: " + entry);

// This build is arena-only: no campaign globals or original room startup runs.
Data.GlobalInitScripts.Clear();
Data.GeneralInfo.Name = Data.Strings.MakeString("DELTARUNE_LOCAL_PVP");
Data.GeneralInfo.FileName = Data.Strings.MakeString("DELTARUNE_LOCAL_PVP");
Data.GeneralInfo.DisplayName = Data.Strings.MakeString("DELTARUNE / SOUL SWAP / Local PvP");
Data.GeneralInfo.GameID = 1827331257;
Data.GeneralInfo.GMS2GameGUID = Guid.Parse("599b786a-883f-4406-b01f-a9d1d8e68bbc").ToByteArray();
Data.GeneralInfo.GMS2FPS = 30;
Data.GeneralInfo.DefaultWindowWidth = 640;
Data.GeneralInfo.DefaultWindowHeight = 480;

var controller = new UndertaleGameObject {
    Name = Data.Strings.MakeString("obj_pvp_match"), Persistent = false, Visible = true
};
Data.GameObjects.Add(controller);
var imports = new CodeImportGroup(Data) { MainThreadAction = MainThreadAction };
imports.QueueReplace(controller.EventHandlerFor(EventType.Create, Data),
    File.ReadAllText(Path.Combine(root, "build", "rules-header.gml")) + "\n" + File.ReadAllText(Path.Combine(root, "gml", "create.gml")) + "\n" + File.ReadAllText(Path.Combine(root, "gml", "network.gml")));
imports.QueueReplace(controller.EventHandlerFor(EventType.Step, (uint)0, Data),
    File.ReadAllText(Path.Combine(root, "gml", "step.gml")));
imports.QueueReplace(controller.EventHandlerFor(EventType.Draw, EventSubtypeDraw.DrawGUI, Data),
    File.ReadAllText(Path.Combine(root, "gml", "draw.gml")));
imports.QueueReplace(controller.EventHandlerFor(EventType.Step, (uint)2, Data),
    File.ReadAllText(Path.Combine(root, "gml", "end-step.gml")));
// GameMaker async networking is Other event 68; cleanup runs on destruction/game exit.
imports.QueueReplace(controller.EventHandlerFor(EventType.Other, (uint)68, Data),
    File.ReadAllText(Path.Combine(root, "gml", "network-event.gml")));
imports.QueueReplace(controller.EventHandlerFor(EventType.CleanUp, (uint)0, Data),
    File.ReadAllText(Path.Combine(root, "gml", "cleanup.gml")));
imports.Import();
if (Data.GlobalInitScripts.Count != 0) throw new Exception("Unexpected global script initialization after compilation.");

uint layerId = Data.Rooms.SelectMany(r => r.Layers).Select(l => l.LayerId).DefaultIfEmpty(0u).Max() + 1;
var arena = new UndertaleRoom {
    Name = Data.Strings.MakeString("room_pvp_arena"),
    Caption = Data.Strings.MakeString("SOUL SWAP / Local PvP"),
    Width = 640, Height = 480, Speed = 30,
    Flags = UndertaleRoom.RoomEntryFlags.EnableViews | UndertaleRoom.RoomEntryFlags.ClearViewBackground |
            UndertaleRoom.RoomEntryFlags.IsGMS2 | UndertaleRoom.RoomEntryFlags.IsGMS2_3
};
arena.Views[0].Enabled = true;
arena.Views[0].ViewWidth = 640;
arena.Views[0].ViewHeight = 480;
arena.Views[0].PortWidth = 640;
arena.Views[0].PortHeight = 480;
var layer = new UndertaleRoom.Layer {
    LayerName = Data.Strings.MakeString("PvP_Instances"), LayerId = layerId,
    LayerType = UndertaleRoom.LayerType.Instances, LayerDepth = 0, IsVisible = true,
    Data = new UndertaleRoom.Layer.LayerInstancesData()
};
arena.Layers.Add(layer);
var instance = new UndertaleRoom.GameObject {
    InstanceID = Data.GeneralInfo.LastObj++, ObjectDefinition = controller, X = 0, Y = 0
};
arena.GameObjects.Add(instance);
layer.InstancesData.Instances.Add(instance);
arena.SetupRoom();
Data.Rooms.Add(arena);
Data.GeneralInfo.RoomOrder.Clear();
Data.GeneralInfo.RoomOrder.Add(new UndertaleResourceById<UndertaleRoom, UndertaleChunkROOM> { Resource = arena });
Console.WriteLine("PvP compiled: dedicated arena, one controller, no campaign initializers.");
