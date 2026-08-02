Writing Dialogue

Dialogue is written using a speaker expression "Text" format.
Code snippet

# Standard dialogue using the 'angry' animation from the SpriteFrames
npc_hero angry "Where is my hammer?!"

# Dialogue with an inline voice tag triggered simultaneously
npc_hero sad "I guess it's gone..." <voice: sigh>

Logic & Math

Variables can be modified directly in the script using the $ prefix. The engine safely evaluates these updates at runtime using Godot's built-in Expression class.
Code snippet

$gold += 50$ has_sword = true

Godot Signals (Event Bus)

Use the emit keyword to trigger game events (like giving items or starting quests). The DialogueManager fires these as generic broadcast signals that your game's Event Bus can listen to.
Code snippet

# Emits the 'give_item' signal with the arguments "hammer" and 1
emit give_item("hammer", 1)

# You can also pass variables natively!
emit take_damage(enemy_attack_power)

Routing (Labels & Jumps)

Control the flow of the conversation using labels.
Code snippet

label start:
    npc_hero "Let's go to the shop."
    jump shop_menu

label shop_menu:
    npc_smith "Welcome!"
