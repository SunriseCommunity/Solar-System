# 🚀 Solar System - The Sunrise server orchestrator

<p align="center">
  <img src="https://github.com/SunriseCommunity/Solar-System/blob/main/.github/default.png?raw=true" alt="Artwork made by kita (kitairoha). We don't own the rights to this image.">
</p>

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![GitHub stars](https://img.shields.io/github/stars/SunriseCommunity/Solar-System.svg?style=social&label=Star)](https://github.com/SunriseCommunity/Solar-System)

Monorepo with all services to run instance of Sunrise server

## Description 📖

Solar System is a **monorepo** containing all the essential components required to run a complete Sunrise server stack. Each major piece is managed as a submodule within this repository, allowing you to orchestrate, develop, and deploy everything together with ease.

## Preview 🖼️

![preview](./.github/preview.jpg)

## Components 🧩

- [x] [**🌅 Sunrise (Server Core)**](https://github.com/SunriseCommunity/Sunrise)  
  The main server backend, handling core game logic and API for osu! servers.

- [x] [**🌇 Sunset (Frontend)**](https://github.com/SunriseCommunity/Sunset)  
  The frontend web interface of Sunrise. Allows to browse profiles, leaderboards, multiplayer lobbies, and manage users/beatmaps using admin panel.

- [x]  [**🔭 Observatory (Beatmap Manager)**](https://github.com/SunriseCommunity/Observatory)  
  Powerful "on demand" beatmap manager which uses osu! API and popular beatmap mirrors to prioritize speed and efficiency. Used by Sunrise to fetch beatmaps and calculate performance points.

- [x] [**🌻 Sunshine (Discord Bot)**](https://github.com/SunriseCommunity/Sunshine)  
  A Discord bot that integrates directly with your Sunrise server, delivering community features and server utilities directly into your Discord server.

## Installation 📩

> [!TIP]
> 👀 We recommend watching the **[installation video guide](https://youtu.be/ukVc4anmtIs?si=ElITsNDIXw6ijxGP)** for a step-by-step walkthrough. 
>
> [![IMAGE ALT TEXT HERE](https://img.youtube.com/vi/ukVc4anmtIs/mqdefault.jpg)](https://youtu.be/ukVc4anmtIs?si=ElITsNDIXw6ijxGP)
>
> From it you will learn how to set up Solar-System and how to customize it for your branding

### Prerequisites

Before you begin, ensure you have the following installed:

- [**Git**](https://git-scm.com/)
- [**Docker** and **Docker Compose**](https://www.docker.com/get-started/)
- Basic knowledge of command line operations

### Installation Steps

1. **Clone the repository with submodules:**

   ```console
   git clone --recursive https://github.com/SunriseCommunity/Solar-System.git
   cd Solar-System
   ```

   Or if you've already cloned without submodules:

   ```console
   git submodule update --init --recursive --remote
   ```

2. **Set up configuration files:**
   
   Create copies of the example configuration files:
   
   ```console
   cp .env.example .env
   cp Sunrise.Config.Production.json.example Sunrise.Config.Production.json
   ```
   
   Fill in the required parameters in both files.
   
  > [!IMPORTANT]
  > Make sure to edit `WEB_DOMAIN=` in `.env` to your actual domain that you plan to host on.
   
  > [!TIP]
  > You can customize the configuration files to match your requirements. For example, in `Sunrise.Config.Production.json`, you can change the bot username:
  > ```json
  > "Bot": {
  >   "Username": "Sunshine Bot",
  >   ...
  > }
  > ```

3. **Generate API keys:**
   
   #### 3.1 Generate the token secret for Sunrise API requests:
   
   ```console
   chmod +x lib/scripts/generate-api-sunrise-key.sh
   ./lib/scripts/generate-api-sunrise-key.sh
   ```

   This will generate a token secret for the Sunrise API requests.
   
   #### 3.2 Generate the Observatory API key (allows Sunrise to request Observatory without internal rate limits):
   
   ```console
   chmod +x lib/scripts/generate-observatory-api-key.sh
   ./lib/scripts/generate-observatory-api-key.sh
   ```

   This will generate an API key for the Observatory to ignore rate limits for requests coming from Sunrise.

   #### 3.3 Generate secure database passwords:

   ```console
   chmod +x lib/scripts/generate-database-passwords.sh
   ./lib/scripts/generate-database-passwords.sh
   ```
   This will generate secure passwords for both MySQL and PostgreSQL databases. 
  
   Make sure to not lose these credentials as they are required to access the databases! You can find them in the `.env` file under `SUNRISE_MYSQL_ROOT_PASSWORD` and `OBSERVATORY_POSTGRES_PASSWORD`.
   
  > [!TIP]
  > You will be prompted to run multiple `.sh` scripts during setup, if you are using **Windows**, please use `.bat` equivalent scripts located in the same folder.
   

4. **Start the server:**
   
   ```console
   chmod +x ./start.sh
   ./start.sh
   ```
   
   This should start the server without any problems.

5. **Verify the server is running:**
   
   You can check that all containers are running with:
   
   ```console
   docker ps
   ```
   
   You should see containers for Sunrise server, Sunset website, Observatory, Sunshine Discord bot, and supporting services (PostgreSQL, Redis, Grafana, etc.) all running.

> [!NOTE]
> For more in-depth documentation with detailed setup instructions, visit [https://docs.sunrize.uk/](https://docs.sunrize.uk/).

> [!TIP]
> Join our [Discord server](https://discord.gg/BjV7c9VRfn) if you have any questions or just want to chill with us!

### Hosting to the Internet 🌐

To make your server accessible on the internet:

1. **Configure DNS records:**
   
   Make sure you have DNS records pointing the following subdomains to your server's IP address:
   
   - `*` (wildcard)
   - `api`
   - `osu`
   - `a`
   - `c`
   - `assets`
   - `cho`
   - `c4`
   - `b`
   - `grafana`
   
   These subdomains are required for the server to function properly.

2. **Start Caddy reverse proxy:**
   
   For simplicity, we use Caddy as a reverse proxy. By default, the `Caddyfile` is configured to host the website, server, and Grafana. You can uncomment additional configurations in the `Caddyfile` if needed.

   Start Caddy by running:
   
   ```console
   sudo caddy start --envfile .env
   ```
   
   Your server should now be up and accessible!

  > [!IMPORTANT]
  > If you are intending to use **Grafana** for monitoring, make sure to uncomment the Grafana section in the `Caddyfile` before starting Caddy.
  > After starting Caddy, make sure to visit `grafana.*` subdomain and change the default password for the admin account!

  > [!CAUTION]
  > Make sure you have the correct ports open in your firewall (80 and 443) for the server to be accessible from the internet.
  >
  > Also to readers notice, docker containers are capable of overriding firewall rules, which can expose your server to the internet even if you don't want it to. We recommend setting up ufw-docker to manage this. You can find the instructions in the [ufw-docker](https://github.com/chaifeng/ufw-docker#install) repository.

## Contributing 💖

If you want to contribute to the project, feel free to fork the repository and submit a pull request. We are open to any
suggestions and improvements.
