# 🚀 Solar System - The Sunrise server orchestrator

<p align="center">
  <img src="https://github.com/SunriseCommunity/Solar-System/blob/main/.github/workflows/default.png?raw=true" alt="Artwork made by kita (kitairoha). We don't own the rights to this image.">
</p>

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![GitHub stars](https://img.shields.io/github/stars/SunriseCommunity/Solar-System.svg?style=social&label=Star)](https://github.com/SunriseCommunity/Solar-System)

Monorepo with all services to run instance of Sunrise server

## Description 📖

Solar System is a **monorepo** containing all the essential components required to run a complete Sunrise server stack. Each major piece is managed as a submodule within this repository, allowing you to orchestrate, develop, and deploy everything together with ease.

## Preview 🖼️

TODO: Add preview image with frontend + osu client + discord bot + grafana

![New Project (3)](https://github.com/user-attachments/assets/5cba5334-3455-4a56-aa9a-8930bb16abfd)

## Components 🧩

- [**🌅 Sunrise**](https://github.com/SunriseCommunity/Sunrise)  
  The main server backend, handling core game logic and API for osu! servers.

- [**🌇 Sunset**](https://github.com/SunriseCommunity/Sunset)  
  The frontend web interface of Sunrise. Allows to browse profiles, leaderboards, multiplayer lobbies, and manage users/beatmaps using admin panel.

- [**🔭 Observatory**](https://github.com/SunriseCommunity/Observatory)  
  Powerful "on demand" beatmap manager which uses osu! API and popular beatmap mirrors to prioritize speed and efficiency. Used by Sunrise to fetch beatmaps and calculate performance points.

- [**🌻 Sunshine**](https://github.com/SunriseCommunity/Sunshine)  
  A Discord bot that integrates directly with your Sunrise server, delivering community features and server utilities directly into your Discord server.

## Installation 📩

### Prerequisites

Before you begin, ensure you have the following installed:

- [**Git**](https://git-scm.com/)
- [**Docker** and **Docker Compose**](https://www.docker.com/get-started/)
- Basic knowledge of command line operations

### Installation Steps

1. **Clone the repository with submodules:**

   ```bash
   git clone --recursive https://github.com/SunriseCommunity/Solar-System.git
   cd Solar-System
   ```

   Or if you've already cloned without submodules:

   ```bash
   git submodule update --init --recursive --remote
   ```

2. **Follow the installation guide:**
   Visit the [documentation](https://docs.sunrize.uk/) and follow the instructions.

> [!TIP]
> Join our [Discord server](https://discord.gg/BjV7c9VRfn) if you have any questions or just want to chill with us!

## Contributing 💖

If you want to contribute to the project, feel free to fork the repository and submit a pull request. We are open to any
suggestions and improvements.
