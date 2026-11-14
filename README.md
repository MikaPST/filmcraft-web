<p align="center">
  <img src="https://raw.githubusercontent.com/storytold/filmcraft/main/assets/app-icon/hicolor/256x256/apps/ai.storyteller.filmcraft.png" width="128" height="128" alt="FilmCraft application icon">
</p>

<h1 align="center">FilmCraft Web — Docker Image</h1>
<p align="center">
  A community-maintained Docker image for
  <a href="https://github.com/storytold/filmcraft">FilmCraft</a>,
  bringing its WebAssembly-based video editor to a self-hosted web interface.
  <br>
  Build automation and image publication to GitHub Container Registry (GHCR).
</p>
<p align="center">
  <a href="https://github.com/MikaPST/filmcraft-web/actions/workflows/publish-image.yml">
    <img src="https://github.com/MikaPST/filmcraft-web/actions/workflows/publish-image.yml/badge.svg" alt="Build and publish FilmCraft Web">
  </a>
  <a href="https://github.com/MikaPST/filmcraft-web/releases/latest">
    <img src="https://img.shields.io/github/v/release/MikaPST/filmcraft-web?label=Release&logo=github&color=blue" alt="Latest Release">
  </a>
  <a href="https://github.com/MikaPST/filmcraft-web/pkgs/container/filmcraft-web">
    <img src="https://ghcr-badge.egpl.dev/mikapst/filmcraft-web/latest_tag?trim=major&label=GHCR" alt="GHCR image tag">
  </a>
  <a href="docker-compose.yml">
    <img src="https://img.shields.io/badge/Docker%20Compose-ready-2496ED?logo=docker&logoColor=white" alt="Docker Compose configuration">
  </a>
</p>

---

## Why this repository?

The upstream FilmCraft project provides a WebAssembly build that can be served as a static website. This repository builds the official upstream release and packages the generated site into a lightweight NGINX Docker image.

The goals are to:

- Build the WebAssembly application from official release tags in [storytold/filmcraft](https://github.com/storytold/filmcraft).
- Include shared font assets from [storytold/craft-fonts](https://github.com/storytold/craft-fonts).
- Publish multi-platform Docker images to GHCR for `linux/amd64` and `linux/arm64`.
- Create a matching GitHub Release **only after** the image has been published successfully.
- Check daily for new official releases and support manual and packaging-triggered rebuilds.
- Provide a straightforward deployment for Docker Compose and Unraid Community Applications.
- Maintain independent, version-controlled `Dockerfile`, `nginx.conf` and `.dockerignore` files without modifying upstream source.

This is an independent community packaging project. It is **not an official FilmCraft release** and is not affiliated with or endorsed by the FilmCraft or ArtCraft maintainers.

## How it works

FilmCraft runs its video-editing engine and graphical interface in the browser using WebAssembly. NGINX serves compiled static files; the container is not a remote desktop, transcoding server or shared media library.

- **Browser-based editor:** the interface runs in a compatible modern browser.
- **Local media processing:** media stays on the user's machine; the browser may use local storage, including OPFS, for recovery and imported media.
- **No remote desktop:** no VNC or Linux graphical desktop is required.
- **Self-hosted:** serve the web app from your server and access it locally or through an HTTPS reverse proxy.
- **GPU compatibility:** WebGPU is preferred when available, with a WebGL2 fallback; actual capabilities depend on browser and hardware.

FilmCraft is **alpha software**. Test upgrades before relying on the application for important projects.

## Repository structure

```text
filmcraft-web/
├── .github/
│   └── workflows/
│       └── publish-image.yml
├── .dockerignore
├── Dockerfile
├── nginx.conf
├── docker-compose.yml
└── README.md
```

| File | Purpose |
|---|---|
| `.github/workflows/publish-image.yml` | Detects releases, builds the official WebAssembly app, publishes the image and creates GitHub Releases |
| `Dockerfile` | Version-controlled NGINX runtime image definition |
| `nginx.conf` | WebAssembly MIME type, COOP/COEP headers, cache policy and health endpoint |
| `.dockerignore` | Keeps the Docker build context limited to the compiled site and NGINX configuration |
| `docker-compose.yml` | Ready-to-use deployment |
| `README.md` | Documentation for the image, architecture and maintenance |

### Docker build architecture

The GitHub Actions workflow keeps the packaging and upstream sources separate:

```text
GitHub Actions workspace/
├── packaging/           # MikaPST/filmcraft-web
│   ├── Dockerfile
│   ├── nginx.conf
│   └── .dockerignore
├── upstream/            # storytold/filmcraft (official release tag)
├── craft-fonts/         # storytold/craft-fonts (main)
└── docker-build/        # temporary Docker context
    ├── .dockerignore
    ├── nginx.conf
    └── dist/            # upstream/target/web/dist
```

The official application is compiled using **`cargo xtask web`**, not Trunk. The workflow installs `wasm32-unknown-unknown`, reads the matching `wasm-bindgen` version from the upstream `Cargo.lock`, and provides `CRAFT_FONTS_DIR` during compilation. The resulting `target/web/dist/` files include the HTML entry point, JavaScript glue, WebAssembly module and supporting browser assets (including the audio worklet).

After compilation, the workflow copies the generated site into a temporary Docker context and uses the **versioned** root `Dockerfile` and `nginx.conf` from this repository. The final image serves the site on port `8080` with NGINX. It does not require Rust or build tools at runtime.

## Docker image

The published image is:

```text
ghcr.io/mikapst/filmcraft-web:latest
```

Versioned images follow the official upstream release tags:

```text
ghcr.io/mikapst/filmcraft-web:<upstream-version>
```

Use a versioned tag to keep a deployment on a specific release. `latest` is mutable.

### Option 1 — Docker Compose

The repository includes a `docker-compose.yml` file:

```yaml
services:
  filmcraft-web:
    image: ghcr.io/mikapst/filmcraft-web:latest
    container_name: filmcraft-web
    ports:
      - "8080:8080"
    restart: unless-stopped
```

Start the container:

```bash
docker compose up -d
```

Open `http://YOUR_SERVER_IP:8080`, or `http://localhost:8080` when using the same computer.

Useful commands:

```bash
docker compose logs -f
docker compose pull
docker compose up -d
docker compose down
```

No `.env` file or persistent volume is required for the default configuration. To change the host port, change the left-hand side of the mapping, for example `8081:8080`.

### Option 2 — Run directly with Docker

```bash
docker run -d \
  --name filmcraft-web \
  --restart unless-stopped \
  -p 8080:8080 \
  ghcr.io/mikapst/filmcraft-web:latest
```

## Network access and reverse proxies

NGINX listens on **port 8080** and serves `.wasm` as `application/wasm`. The configuration sends:

- `Cross-Origin-Opener-Policy: same-origin`
- `Cross-Origin-Embedder-Policy: require-corp`

These headers support cross-origin isolation required by some browser features. If you deploy behind Traefik, NGINX Proxy Manager or another reverse proxy, preserve these headers and use **HTTPS** for access outside localhost. WebGPU typically requires a secure browser context.

The image also provides a lightweight `GET /health` endpoint for container health checks. The HTML entry point is configured not to be cached; static assets are cached for longer periods. Browser compatibility and performance still depend on the client.

## Automated builds

GitHub Actions checks the official [FilmCraft releases](https://github.com/storytold/filmcraft/releases), compiles the selected upstream tag, builds a multi-platform NGINX image and publishes it to GHCR.

| Trigger | Behaviour |
|---|---|
| Daily schedule (03:17 UTC) | Checks for a new official FilmCraft release |
| Manual workflow dispatch | Builds the latest official release or the specified `upstream_tag` |
| Force rebuild | Rebuilds an already published release with `force_rebuild: true` |
| Packaging changes on `main` | Rebuilds the latest official release with updated packaging |

### Published tags

- `latest` — latest successfully published image.
- `<upstream-version>` — exact official release tag.
- `upstream-<commit>` — first 12 characters of the FilmCraft source commit.

Both `linux/amd64` and `linux/arm64` are published. The workflow checks out the **official release tag**, not the upstream development branch.

### GitHub Releases

After a successful Docker build and GHCR push, the workflow creates or updates a [GitHub Release](https://github.com/MikaPST/filmcraft-web/releases) matching the upstream version. The release includes source information, the shared fonts revision, supported architectures, Docker tags, image digest and upstream release notes.

Scheduled runs skip already published versions. A packaging change or manual force rebuild republishes the selected release.

> [!IMPORTANT]
> GitHub Releases are created **only after** the image has been pushed successfully. The `craft-fonts` checkout currently follows its `main` branch independently from the FilmCraft release tag; its exact commit is recorded in the image metadata and GitHub Release.

### Build pipeline

1. Checkout the packaging repository into `packaging/`.
2. Resolve the official FilmCraft release and skip it if already published (unless forced).
3. Checkout the official FilmCraft source into `upstream/` and shared fonts into `craft-fonts/`.
4. Install Rust, the WebAssembly target and the upstream-compatible `wasm-bindgen-cli`.
5. Run `cargo xtask web` to build `upstream/target/web/dist/`.
6. Copy the compiled site and versioned NGINX configuration into `docker-build/`.
7. Build and push `linux/amd64` and `linux/arm64` images using the root `Dockerfile`.
8. Create or update the matching GitHub Release.

The Dockerfile, NGINX configuration and ignore rules are maintained **in this repository**, not generated inline by the workflow.

## Unraid Community Applications

FilmCraft Web can be deployed on Unraid through Docker or the Unraid Community Applications template maintained in [MikaPST/unraid-community-apps](https://github.com/MikaPST/unraid-community-apps).

- **Repository:** `ghcr.io/mikapst/filmcraft-web:latest`
- **Container port:** `8080`
- **Default host port:** `8080`
- **Template:** [filmcraft-web.xml](https://github.com/MikaPST/unraid-community-apps/blob/main/templates/filmcraft-web.xml)

The Unraid template is maintained separately from this image-build repository.

## Upstream project

- **Official source:** [storytold/filmcraft](https://github.com/storytold/filmcraft)
- **Web build instructions:** [docs/web.md](https://github.com/storytold/filmcraft/blob/main/docs/web.md)
- **Web hosting instructions:** [packaging/web/README.md](https://github.com/storytold/filmcraft/blob/main/packaging/web/README.md)
- **Contribution and font instructions:** [docs/contributing.md](https://github.com/storytold/filmcraft/blob/main/docs/contributing.md)
- **Shared fonts:** [storytold/craft-fonts](https://github.com/storytold/craft-fonts)
- **Official releases:** [FilmCraft releases](https://github.com/storytold/filmcraft/releases)

The MikaPST release tracks the official FilmCraft version but represents independent Docker packaging.

## License and attribution

FilmCraft source code is dual-licensed under MIT or Apache License 2.0, at the user's option, as specified by the upstream project. Shared `craft-fonts` assets have their own licensing and attribution requirements; consult the corresponding repositories for details.

The upstream application's license does not automatically determine the license of the packaging files maintained here. Include an appropriate `LICENSE` file if you wish to explicitly license this repository's original packaging materials.

FilmCraft names, artwork and logos remain subject to upstream project terms.

## Disclaimer

This repository is independently maintained and is not affiliated with, sponsored by or endorsed by FilmCraft or its maintainers.

FilmCraft is alpha software. Use it at your own risk and keep independent backups of important media and project files.
