Customizing the Canvas (set_ui & scroll_mode)

You can give your writers the power to configure the visual layout directly from the text file. This is perfect if you want one conversation to look like a standard dialogue box, and another to look like a smartphone text message screen.
Changing UI Overlays

Use set_ui to swap out header and footer textures dynamically.
Code snippet

# Switches the UI to look like a cellphone
set_ui "res://ui/phone_header.png" "res://ui/phone_footer.png"

npc_friend "Are you there?"

Scroll Modes

By default, panels might stack sequentially. However, you can use scroll_mode to control how the canvas behaves.
Code snippet

# Clears the screen completely before adding the new panel
scroll_mode paged

panel "res://backgrounds/castle_interior.tscn"

npc_king "Welcome to my throne room."

    scroll_mode paged: The engine aggressively deletes the previous page/scene using queue_free() before adding the new one. This instantly clears the screen, allowing you to use the manga panel system for traditional, static visual novel framing where one background replaces another seamlessly.

Auto-Focusing Portraits (Fire Emblem Style)

To keep your .rpgdl scripts clean, you do not need to manually emit dimming or highlighting commands for character portraits.

RPGDL uses an "Auto-Focus" architecture. Because the engine knows exactly who is speaking on the current line (e.g., npc_smith "Anyway..."), the runtime automatically iterates through active portraits. It highlights the speaker and slightly dims/greys out the others, giving you a dynamic visual presentation with zero extra scripting required from your writers!