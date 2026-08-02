Note on Indentation: RPGDL uses spaces or tabs to determine what belongs inside the block. Once you un-indent, the dialogue returns to the main flow.
Menus (Player Choices)

To give the player options, use the menu: keyword followed by the text for each button.
Code snippet

npc_guard "Halt! State your business."

menu:
    "I am a friend of the King.":
        npc_guard "Oh, my apologies! Go right in."
        jump inside_castle
        
    "I want to fight!":
        npc_guard "Big mistake!"
        emit start_combat("guard")
        
    "Nevermind.":
        npc_guard "Move along, then."

When a player clicks a choice, the engine executes the indented block beneath it. When that block finishes, the engine automatically skips past the other choices and continues reading the script (unless you explicitly use a jump command).
Conditional Menu Choices

Sometimes you want a choice to only appear (or be disabled) based on the player's progress. You can add an if condition directly to the choice string.
Code snippet

menu:
    # This choice is completely hidden if the player doesn't have the key
    "Unlock the door" if $has_key:
        sfx "door_unlock"
        "The door swings open."
        
    # This choice appears as disabled, showing the alt-text instead
    "Unlock the door" if $has_key (alt: "Requires Iron Key"):
        "You need a key to open this."
        
    "Walk away":
        "You decide to leave it alone."

How the Compiler Handles Menus (The Flattened Array)

If you are implementing the DialogueManager in your Godot game, you don't have to worry about recursive loops or nested dictionaries.

When you write a menu block, the RPGDL compiler extracts the nested dialogue, places it further down the JSON/Array, and turns the menu into a simple routing hub.

    The runtime engine reads {"type": "menu"} and spawns your UI buttons.

    The choices array simply contains the button text and a hidden target label.

    When clicked, your engine just sets current_line = bookmarks[target] and resumes reading in a straight line.

This flat architecture guarantees that your dialogue engine never gets trapped in complex loops!