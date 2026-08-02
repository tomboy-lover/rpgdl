# The Event Bus

One of the core design philosophies of RPGDL is that it should never try to guess your game's architecture. It shouldn't need to know about your `InventoryManager`, your `QuestManager`, or your `CombatEngine`.

To achieve this absolute decoupling, RPGDL relies on an **Event Bus** pattern using a Delegate Signal.

## The Delegate Signal

When your writers type an `emit` command in an `.rpgdl` file:

```rpgdl
# dialogue.rpgdl
npc_hero "Here, take this potion."
emit give_item("potion", 1)
```

The `DialogueManager` does *not* try to call `Inventory.give_item()`. Instead, it broadcasts a single, generic signal.

Every `DialogueManager` has this built-in signal:
```gdscript
signal dialogue_event(event_name: String, args: Array)
```

When the runtime engine reaches the `emit give_item("potion", 1)` instruction, it fires:
`dialogue_event.emit("give_item", ["potion", 1])`

## Setting up your Game's Event Bus

To bridge the gap between the dialogue text and your actual gameplay, you should create a simple AutoLoad (e.g., `EventBus.gd`) that acts as the central routing hub.

```gdscript
# EventBus.gd (AutoLoad)
extends Node

func _ready():
    # Connect to the DialogueManager's generic broadcast
    DialogueManager.dialogue_event.connect(_on_dialogue_event)

func _on_dialogue_event(event_name: String, args: Array):
    match event_name:
        "give_item":
            # args[0] is item name, args[1] is amount
            InventoryManager.add_item(args[0], args[1])
            
        "start_quest":
            QuestManager.start(args[0])
            
        "take_damage":
            CombatManager.deal_damage(args[0])
            
        _:
            push_warning("Unknown dialogue event emitted: " + event_name)
```

## Why this Architecture is Powerful

* **Total Decoupling:** Your dialogue engine can be copy-pasted into your next 10 Godot projects without changing a single line of its internal code. It has zero external dependencies.
* **Writer Freedom (No Crashes):** Writers can invent new events on the fly in the script (e.g., `emit shake_camera()`). If you haven't programmed that logic into the game yet, it just silently fails (or throws the warning you set up in the `match` statement) instead of crashing the engine with a "missing method" error.
* **Centralized Logic:** You always know exactly where dialogue transitions into gameplay—right inside your `EventBus.gd` script.