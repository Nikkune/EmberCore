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
- 🔥 **Tinkers' Construct, fluids & network modules** → Smeltery, reservoirs, rednet messaging

---

## 📚 Documentation

> ⚡ Full documentation is available in the [Wiki](https://github.com/Nikkune/EmberCore/wiki)

### Quick Links

- 🚀 [[Getting Started]]
- 🧱 [[Architecture]]
- 📦 [[Modules]]
- ⚙️ [[Core]]

### Modules & Projects

- 🔥 [Projects/Smeltery](https://github.com/Nikkune/EmberCore/wiki/Projects-Smeltery)
- ⚗️ [Modules/Tinkers](https://github.com/Nikkune/EmberCore/wiki/Modules-Tinkers)
- 💧 [Modules/Fluids](https://github.com/Nikkune/EmberCore/wiki/Modules-Fluids)
- 📡 [Modules/Net](https://github.com/Nikkune/EmberCore/wiki/Modules-Net)
- 🚀 [Deployment & Installer](https://github.com/Nikkune/EmberCore/wiki/Deployment-&-Installer)

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

## 🔥 Smeltery

A Tinkers' Construct Smeltery that runs itself, controlled from a touch monitor. Two computers share the
work: the **controller** melts, casts and stores leftover fluids; the **display** shows it all and takes your
orders. Modes (auto, alloy, melt, drain, purge…), casts, reservoirs and alloy recipes are set from the
monitor.

```
embercore install smeltery-controller   on the computer next to the Smeltery
embercore install smeltery-display      on the computer with the monitor
```

👉 Full docs: https://github.com/Nikkune/EmberCore/wiki/Projects-Smeltery

---

## 🏗️ Project Structure

```text
src/
  core/        # Low-level utilities (peripherals, inventory, etc.)
  modules/     # Reusable systems (UI, storage, automation...)
  projects/    # Entry points (final programs)

luas/          # Generated Lua output
```

---

## 📦 Deployment (In-Game)

The installer is [`installer/embercore.lua`](installer/embercore.lua), also on
[Pastebin](https://pastebin.com/PKV47STh). Put it on the computer once:

```
pastebin get PKV47STh embercore
```

then:

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

A project whose computers do different jobs is published as one project per role
(`smeltery-controller`, `smeltery-display`): each role installs only the files it loads, so it fits on a
computer (1 MB by default).

The paste is not updated automatically: when `installer/embercore.lua` changes, update it on Pastebin.

### 🔧 Dev mode (any server)

Work in TypeScript on your machine and see every change on a computer of a server you do not own:

```bash
npm run dev
```

It compiles continuously (`tstl --watch`), serves `luas/` and `scripts/ingame/`, and opens a public
tunnel with [`cloudflared`](https://github.com/cloudflare/cloudflared) when it is installed
(CC:Tweaked refuses local addresses, so the tunnel is needed even in single player). Once the new
URL answers (it can take a minute), it prints the commands to type in game:

```
wget <url>/client embercore-dev
embercore-dev <url> embercore-check ui
```

`embercore-dev` downloads what changed (only files whose content changed) and restarts the program;
if the program crashes it waits for the next change. Afterwards `embercore-dev` alone reuses the
same server and program, and `embercore-dev <program> [args...]` switches program. Ctrl+T quits.
It only deletes files it downloaded itself. `DEV_PORT` (default: any free port, the tunnel follows it)
and `DEV_TUNNEL=0` configure `npm run dev`.

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
