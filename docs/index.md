# Welcome to RPGDL Engine

**RPGDL (RPG Dialogue Language)** is a lightning-fast, Ren'Py-style dialogue parser and runtime engine designed specifically for Godot 4. 

Built to keep writers out of complex visual node graphs and inside their favorite text editors, RPGDL introduces a clean, indentation-aware markup language (`.rpgdl`). It allows developers and writers to script branching narratives, trigger game logic, and manage translations seamlessly.

---

## ✨ Key Features

* **Zero Runtime Overhead:** Instead of parsing text files at runtime, RPGDL acts as a true compiler. It leverages Godot's `EditorImportPlugin` to silently convert your text files into highly-optimized binary arrays the moment you hit save. Your players experience 0.0ms of parsing lag.
* **Writer-Friendly Markup:** Write dialogue, define character portraits, and build branching menus using a clean, Python/Ren'Py-inspired syntax.
* **Native Localization Support:** The compiler automatically extracts spoken text and generates unique keys for Godot's built-in CSV translation server. Translators never see your code; they only see the text.
* **Complex Branching & Logic:** Supports nested `if/elif/else` conditions and dialogue menus. The compiler automatically "flattens" these structures into linear jumps so the runtime engine stays lightweight.
* **Dynamic Variables & Math:** Safely execute game logic directly from the dialogue script (e.g., `$ gold += 10`) using Godot's native `Expression` class.
* **Engine Integration:** Easily trigger game events by emitting global Godot signals directly from your script (e.g., `emit start_quest("find_sword")`).
* **Visual Novel & Manga Panels:** Advanced built-in support for controlling UI layouts, triggering manga-style panel reveals, and dynamic scene transitions directly from text.

## 🚀 Why build RPGDL?

While incredible tools like Dialogic exist, they often come with massive ecosystems (their own saving subsystems, audio managers, and heavy UI editors). If you install them, you are effectively installing a visual novel engine inside of your RPG.

**RPGDL is a micro-tool.** It does exactly two things: 
1. It compiles text files into flat Godot Arrays.
2. It reads those Arrays to update your UI.

It natively points to your game's data, has almost zero file size, and adds zero background processes to your game unless someone is actively speaking. It is mathematically as fast as Godot can possibly run.

---

## 📖 Navigation

* **[Integration & Setup](integration.md):** Learn how to install the addon and use the custom Godot Editor workspace.
* **[Syntax Reference](syntax.md):** Your daily cheat sheet for writing `.rpgdl` scripts.
* **[Branching & Menus](branching.md):** Deep dive into handling `if/else` logic and player choices.
* **[Manga Panels & UI](visuals.md):** Learn how to trigger visual changes, background swaps, and dynamic manga panels.
* **[Architecture](architecture.md):** For developers who want to understand how the compiler flattens data and how to use the Event Bus.
