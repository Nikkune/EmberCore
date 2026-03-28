# 🔥 EmberCore

> _An ancient core powered by eternal embers, forged to control and automate complex systems._
> _Written in TypeScript. Forged into Lua._

---

## ✨ Overview

**EmberCore** is a development framework for ComputerCraft / CC:Tweaked that allows you to:

- Write your programs in **TypeScript**
- Compile them into **Lua**
- Build modular and reusable automation systems
- Deploy projects directly into your Minecraft world

---

## 🧱 Philosophy

EmberCore is built around three core principles:

- **Clarity over complexity** → simple structure, no magic
- **Separation of concerns** → core / modules / projects
- **Automation-first** → everything is designed for in-game systems

---

## 🏗️ Project Structure

```text
src/
  core/        # Low-level utilities (peripherals, inventory, etc.)
  modules/     # Reusable systems (smeltery, storage, UI...)
  projects/    # Final programs (entrypoints)

dist/          # Generated Lua output
```

---

## ⚙️ Setup

### 1. Install dependencies

```bash
npm install
```

### 2. Build Lua

```bash
npm run build
```

This will compile all TypeScript files into Lua inside the `dist/` folder.

---

## 🚀 First Program

Create a new project:

```text
src/projects/hello/main.ts
```

```ts
print('Hello from EmberCore 🔥');
```

Build and copy the generated Lua to your ComputerCraft computer.

---

## 🔥 Example: Smeltery Controller

```ts
import {SmelteryController} from '../../modules/smeltery/controller';

const controller = new SmelteryController({
	input: 'minecraft:chest_0',
	output: 'minecraft:chest_1',
});

controller.run();
```

---

## 📦 Deployment (In-Game)

Projects are installed using a lightweight bootstrap script:

```lua
pastebin run <id> smeltery
```

The installer will:

- Download the project
- Install required modules
- Set up the environment

---

## 🧩 Architecture

### Core

Low-level building blocks:

- peripheral wrappers
- inventory handling
- logging
- utilities

### Modules

Reusable systems:

- smeltery automation
- storage management
- UI / monitors
- networking

### Projects

Executable programs:

- entrypoints
- configuration
- orchestration

---

## 🔮 Roadmap

- [ ] Project manifest system
- [ ] Auto-deployment from GitHub
- [ ] Module dependency resolver
- [ ] Update system (in-game)
- [ ] CLI tools

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

- TypeScript
- TypeScriptToLua
- Lua 5.2
- ComputerCraft / CC:Tweaked

---

## 📄 License

MIT
