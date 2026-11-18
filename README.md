# 🔥 EmberCore

![TypeScript](https://img.shields.io/badge/TypeScript-5.x-blue)
![Lua](https://img.shields.io/badge/Lua-5.1-2C2D72)
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

The installer is [`installer/embercore.lua`](installer/embercore.lua). Put it on the computer once
(for example with `pastebin get <code> embercore`), then:

```
embercore install ui        install a component or project with its dependencies
embercore update            update everything installed
embercore remove ui         remove it, and the dependencies nothing else needs
embercore list              available (and installed *) components
```

An id is a full id (`modules/ui`, `core/config`) or its last part when unique (`ui`, `config`).
Files come from the `lua` branch through `raw.githubusercontent.com` and are installed at the root
of the computer, so `require("core.config")` works as is. Each component is downloaded completely
before anything is written. What is installed is recorded in `/.embercore/installed`.

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
* Lua 5.1 (CC:Tweaked's Cobalt VM)
* ComputerCraft / CC:Tweaked

---

## 📄 License

MIT
