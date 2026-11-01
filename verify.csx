using System;
using System.IO;
using System.Linq;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using UndertaleModLib.Decompiler;

EnsureDataLoaded();
string root = Environment.GetEnvironmentVariable("DR_PVP_ROOT");
void Require(bool condition, string message) { if (!condition) throw new Exception(message); }
Require(Data.GeneralInfo.Name.Content == "DELTARUNE_LOCAL_PVP", "Wrong game identity.");
Require(Data.GeneralInfo.RoomOrder.Count == 1, "Unexpected playable room order.");
var room = Data.GeneralInfo.RoomOrder[0].Resource;
Require(room.Name.Content == "room_pvp_arena", "Wrong boot room.");
Require(room.CreationCodeId == null, "Unexpected room creation code.");
Require(Data.GlobalInitScripts.Count == 0, "Campaign global initialization still enabled.");
Require(Data.Extensions.All(e => e.Files.Count == 0), "Unexpected extension files.");
Require(room.GameObjects.Count == 1, "Unexpected boot instances.");
Require(room.GameObjects[0].ObjectDefinition.Name.Content == "obj_pvp_match", "Stock instance in boot room.");
Require(room.GameObjects[0].CreationCode == null, "Unexpected instance creation code.");
var obj = Data.GameObjects.ByName("obj_pvp_match");
Require(obj != null && !obj.Persistent && obj.ParentId == null, "Controller inheritance/persistence incorrect.");
var code = obj.Events.SelectMany(x => x).SelectMany(x => x.Actions).Select(a => a.CodeId).Where(c => c != null).ToArray();
Require(code.Length == 6, "Expected Create, Step, End Step, Draw GUI, networking and cleanup events.");
Require(code.Any(c => c.Name.Content.EndsWith("Other_68")), "Missing async networking event.");
Require(code.Any(c => c.Name.Content.EndsWith("Step_2")), "Missing snapshot End Step event.");
var assetManifest = JObject.Parse(File.ReadAllText(Path.Combine(root, "assets", "manifest.json")));
var spriteNames = ((JObject)assetManifest["sprites"]).Properties().Select(p => p.Name).ToArray();
var fontNames = ((JArray)assetManifest["fonts"]).Select(v => (string)v).ToArray();
foreach (var name in spriteNames) Require(Data.Sprites.ByName(name)?.Textures.Count > 0, "Missing sprite: " + name);
foreach (var name in fontNames) Require(Data.Fonts.ByName(name)?.Texture != null, "Missing font: " + name);
var context = new GlobalDecompileContext(Data);
var output = Path.Combine(root, "build", "verified-code");
Directory.CreateDirectory(output);
foreach (var entry in code) {
    var text = new Underanalyzer.Decompiler.DecompileContext(context, entry, Data.ToolInfo.DecompilerSettings).DecompileToString();
    File.WriteAllText(Path.Combine(output, entry.Name.Content + ".gml"), text);
}
var report = new {
    archive_reopened = true,
    boot_room = room.Name.Content,
    boot_instances = room.GameObjects.Select(i => i.ObjectDefinition.Name.Content).ToArray(),
    enabled_global_initializers = Data.GlobalInitScripts.Count,
    extension_files = Data.Extensions.Sum(e => e.Files.Count),
    game_name = Data.GeneralInfo.Name.Content,
    game_id = Data.GeneralInfo.GameID,
    code = code.Select(c => c.Name.Content).ToArray(),
    original_game_sprites = spriteNames,
    original_game_fonts = fontNames,
    limitations = new [] { "Static validation only: runner, rendering, controllers and OS file activity have not been observed." }
};
File.WriteAllText(Path.Combine(root, "build", "verification.json"), JsonConvert.SerializeObject(report, Formatting.Indented));
Console.WriteLine(JsonConvert.SerializeObject(report, Formatting.Indented));
