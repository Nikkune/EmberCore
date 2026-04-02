# 🔥 EmberCore

![TypeScript](https://img.shields.io/badge/TypeScript-5.x-blue)
![Lua](https://img.shields.io/badge/Lua-5.2-2C2D72)
![CC:Tweaked](https://img.shields.io/badge/CC:Tweaked-supported-orange)
![Status](https://img.shields.io/badge/status-WIP-ff6b2d)
![License](https://img.shields.io/badge/license-MIT-green)

> *An ancient core powered by eternal embers, forged to control and automate complex systems.*  
> *Write in TypeScript. Run in Lua.*

---

## ✨ Overview

**EmberCore** is a modular framework for **ComputerCraft / CC:Tweaked** that lets you:

- Write programs in **TypeScript**
- Compile them into **Lua**
- Build reusable, composable automation systems
- Create structured, scalable in-game software

---

## 🚀 Features

- 🧱 **Modular architecture** → Core / Modules / Projects
- ⚙️ **Strong abstractions** → peripherals, inventory, energy, etc.
- 🔁 **Loop & parallel utilities** → robust automation flows
- 📦 **Result-based error handling** → safe operations
- 🖥️ **UI framework** → terminal/monitor interfaces
- 🎨 **Theming system** → consistent visuals
- 🧩 **Extensible components & modules**

---

## 📚 Documentation

> ⚡ Full documentation is available in the [Wiki](https://github.com/Nikkune/EmberCore/wiki)

### Quick Links

- 🚀 [[Getting Started]]
- 🧱 [[Architecture]]
- 📦 [[Modules]]
- ⚙️ [[Core]]

### UI Framework

- 🖥️ [[Modules/UI]]
- 🎨 [[Theming]]
- 🎯 [[Event System]]
- 🧠 [[Rendering System]]
- 🔥 [[Advanced Usage]]
- 🧬 [[State Manager]]

---

## 🖥️ UI Framework

EmberCore includes a fully custom **terminal UI system**:

- Component-based architecture
- Layout engine (Stack, Grid)
- Event system (mouse, keyboard, focus)
- Rendering pipeline (measure → layout → render)
- Theme-driven styling

👉 Full docs: https://github.com/Nikkune/EmberCore/wiki/Modules/UI

---

## 🏗️ Project Structure

```text
src/
  core/        # Low-level utilities (peripherals, inventory, etc.)
  modules/     # Reusable systems (UI, storage, automation...)
  projects/    # Entry points (final programs)

dist/          # Generated Lua output
```

---

## 📦 Deployment (In-Game)

```lua
pastebin run <id> my_project
```

The installer will:

* Download the project
* Install dependencies
* Set up the environment

---

## 🧱 Philosophy

EmberCore is built around three core principles:

- **Clarity over complexity** → simple structure, no magic
- **Separation of concerns** → core / modules / projects
- **Automation-first** → everything is designed for in-game systems

---

## 📜 Lore

> Deep beneath the world, a forgotten system still burns.
> The **EmberCore** — a computational engine fueled by eternal embers.
>
> It does not sleep.
> It does not cool.
>
> It transforms. It automates. It obeys.

---

## 🛠️ Tech Stack

* TypeScript
* TypeScriptToLua
* Lua 5.2
* ComputerCraft / CC:Tweaked

---

## 📄 License

MIT
