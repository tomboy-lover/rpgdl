# Engine & Code Reference

## The Flat Array Architecture

The core of RPGDL is the **Flattened Array**. To ensure lightning-fast performance, the compiler never nests dictionaries inside each other. 

When the parser reads an indented `if/else` block or a `menu`, it automatically generates invisible routing labels and jumps behind the scenes. This keeps the runtime array completely flat, meaning your `DialogueManager` never has to deal with nested line counts—it just loops sequentially or jumps.

## RPGDLResource

When a file is compiled, it outputs an `RPGDLResource` with the following core properties:

* `instructions (Array)`: The flattened array of dictionaries containing all dialogue, math, and UI commands.
* `bookmarks (Dictionary)`: A map linking label names to specific array indices (e.g., `{"start": 0, "shop": 15}`) for instant jumping.
* `characters (Dictionary)`: Cached definitions for NPCs, linking aliases to display names and `SpriteFrames` paths.
* `audio_channels (Dictionary)`: Cached definitions for audio streams.

## The Delegate Signal Pattern

To keep the addon decoupled from your specific game logic, `DialogueManager` does not try to guess your game's signal names. Instead, it uses a **Delegate Signal** pattern.

The `DialogueManager` Autoload emits one generic signal:
```gdscript
signal dialogue_event(event_name: String, args: Array)
```

Your game's specific EventBus simply listens to this broadcast and routes it to your inventory, quest, or combat systems. This guarantees the addon remains 100% reusable across any future game you build without hard-coding external dependencies.
