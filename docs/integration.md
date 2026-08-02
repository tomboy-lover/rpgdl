# Integration & Setup

Welcome to the RPGDL Engine! This addon replaces heavy visual node graphs with a lightning-fast, compiled text markup language directly inside Godot 4.

## Installation

1. Download the `rpgdl_engine` folder and place it inside your Godot project's `res://addons/` directory.
2. Open your Godot Editor and navigate to **Project > Project Settings > Plugins**.
3. Check the **Enable** box next to RPGDL Engine. 

## The Custom Workspace

Once enabled, you will see a new **RPGDL** tab at the top center of your Godot Editor. This is your dedicated writing workspace, complete with a file browser, syntax highlighting, and `Ctrl + S` saving support.

## How the Compiler Works (Zero Runtime Lag)

RPGDL does **not** parse raw text files at runtime. Instead, it acts as a true compiler. 

It leverages Godot's `EditorImportPlugin` to silently convert your `.rpgdl` text files into highly-optimized binary arrays the moment you hit save. 

* **Editor-Time Compilation:** When you save a file, the importer instantly compiles the text and saves a `.res` file in Godot's hidden `.godot/imported/` folder.
* **Performance:** Your players will experience exactly 0.0 milliseconds of parsing lag. At runtime, the `DialogueManager` simply loads a pre-formatted Dictionary, which takes microseconds.
* **Exporting:** When you export your final game, Godot automatically strips out the raw `.rpgdl` text files and only packages the compiled binary resources, protecting your source scripts from data-miners.

## Executing Dialogue at Runtime

To start a conversation in your game, simply call the global `DialogueManager` AutoLoad:

Code output

Generated integration.md

```gdscript
# Provide the path to the script and the starting label
DialogueManager.start_dialogue("res://dialogue/town.rpgdl", "start")
```