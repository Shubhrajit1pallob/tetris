# Tetris Game | DevOps Deployment Journey

This repository tracks a staged DevOps journey using a web-based Tetris game.

The current README documents only what is completed right now. New sections will be added as each stage is implemented.

## Current Progress

- [x] Game application setup and local run instructions
- [ ] Networking & Cloud
- [ ] IaC & Containerization
- [ ] Kubernetes
- [ ] CI/CD + Security
- [ ] Observability & AIOps

## Stage Completed: Game Application Setup

The game source lives in [tetris-master](tetris-master).

Key app paths:

- Main entry page: [tetris-master/index.html](tetris-master/index.html)
- Source code: [tetris-master/src](tetris-master/src)
- Static/build assets: [tetris-master/public](tetris-master/public)
- Node scripts and dependencies: [tetris-master/package.json](tetris-master/package.json)

## Run Locally

From the [tetris-master](tetris-master) folder:

1. Install dependencies

	npm install

2. Start local server

	npm start

3. Open in browser

	http://localhost:8080

The start script uses http-server with cache disabled for local development.

## Repository Structure (Current)

- [tetris-master](tetris-master): web game code and assets
- [Terraform](Terraform): reserved for upcoming IaC work
- [k8s](k8s): reserved for upcoming Kubernetes manifests

## Credits and Attribution

This project builds on existing open-source work and extends it with staged DevOps improvements.

### Original Game Source

- Base Tetris implementation: [ytiurin/tetris](https://github.com/ytiurin/tetris)
- Original author: Eugene Tiurin
- License: MIT
- License file in this repository: [tetris-master/LICENSE](tetris-master/LICENSE)

### My Contributions

The following work is added by me in this repository as part of the DevOps journey:

- Repository-level documentation and stage tracking in [Readme.md](Readme.md)
- Upcoming infrastructure, deployment, and operations work under [Terraform](Terraform) and [k8s](k8s)
- Any CI/CD, security, and observability additions introduced in future stages

### Attribution Practice Used Here

- Keep the original license and copyright notice intact
- Explicitly mention the upstream repository and author
- Clearly separate inherited code from newly added work

## What Comes Next

Future DevOps stages will be added to this README only after they are implemented, so the document always reflects completed work.

## Score API Endpoint Configuration

The game now supports configuring the score backend endpoint at runtime.

- Default behavior keeps using the legacy score API URL.
- To point the game to the new backend, define `window.TETRIS_API_BASE_URL` before loading `all.js`.

Example:

```html
<script>
  window.TETRIS_API_BASE_URL = "https://<your-api-host>";
</script>
<script async defer src="./public/all.js"></script>
```

The game will call:

- `POST /api/scores`
- `GET /api/scores`
