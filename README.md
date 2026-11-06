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

The upstream FilmCraft project provides a WebAssembly build that can be served as a static website. This repository automates building that web application from upstream source and packages the generated files into a lightweight NGINX-based Docker image.

The goals are to:

- Publish a matching GitHub Release only after the Docker build and push succeed.
- Build the WebAssembly application from official release tags in [storytold/filmcraft](https://github.com/storytold/filmcraft).
- Include the shared font assets from [storytold/craft-fonts](https://github.com/storytold/craft-fonts).
- Check weekly for new official releases and publish a versioned image to GHCR.
- Provide Docker deployment for Unraid Community Applications.
- Keep this packaging project separate from the upstream FilmCraft source code.

This is an independent community packaging project. It is **not an official FilmCraft release** and is not affiliated with or endorsed by the FilmCraft or ArtCraft maintainers.

## How it works

FilmCraft's web application runs in the browser using WebAssembly. The container serves the compiled static web files through NGINX; it does not run a remote desktop.

- **Browser-based editor:** use FilmCraft through a compatible modern browser.
- **Local media processing:** media is handled by the browser application on the user's device. FilmCraft may also use browser storage, including OPFS, for application data and recovery-related functionality; this container is not a remote media-processing or document-storage service.
- **No remote desktop:** no VNC session or Linux graphical desktop is required.
- **Self-hosted:** run the web app on your own server and access it over your local network or through a properly configured reverse proxy.

FilmCraft is in **alpha** and is under active development. Features, compatibility and behaviour may change between upstream builds. Test updates before relying on the application for important projects.

## Docker image

The published image is:

```text
ghcr.io/mikapst/filmcraft-web:latest
```

Each official upstream release is also published under its exact version tag, for example:

```text
ghcr.io/mikapst/filmcraft-web:vX.Y.Z
```

Use a versioned tag if you want to keep a deployment on a specific release. The `latest` tag updates when an image is published.

### Quick start with Docker Compose

A `docker-compose.yml` file is provided at the repository root:

```yaml
services:
  filmcraft-web:
    image: ghcr.io/mikapst/filmcraft-web:latest
    container_name: filmcraft-web
    ports:
      - "8080:8080"
    restart: unless-stopped
```

Start FilmCraft Web from the repository directory:

```bash
docker compose up -d
```

Then open:

```text
http://YOUR_SERVER_IP:8080
```

Replace `YOUR_SERVER_IP` with the IP address or hostname of your server. On the same computer, use `http://localhost:8080`.

### Run directly with Docker

```bash
docker run -d \
  --name filmcraft-web \
  --restart unless-stopped \
  -p 8080:8080 \
  ghcr.io/mikapst/filmcraft-web:latest
```

### Useful commands

```bash
# View logs
docker compose logs -f

# Pull the latest image and recreate the container
docker compose pull
docker compose up -d

# Stop and remove the container
docker compose down
```

No `.env` file or persistent volume is required for the default configuration. The host port is `8080`; to use a different host port, change the left-hand side of the port mapping, for example `8081:8080`.

### Reverse proxy and browser requirements

The image's NGINX configuration is generated as part of the GitHub Actions build. It is configured to:

- serve `.wasm` files with the `application/wasm` MIME type;
- send `Cross-Origin-Opener-Policy: same-origin`;
- send `Cross-Origin-Embedder-Policy: require-corp`.

The COOP and COEP headers provide cross-origin isolation for browser features that may require it. They are part of the web-serving configuration; browser compatibility can still depend on the browser, GPU, operating system and media being edited.

If you expose the application outside your local network, use HTTPS through a reverse proxy such as Traefik and avoid exposing plain HTTP directly to the public Internet. WebGPU generally requires a secure context (HTTPS, or localhost). FilmCraft also provides a WebGL2 fallback; actual performance and available features depend on the browser and hardware.

## Automated builds

GitHub Actions checks the official [FilmCraft releases](https://github.com/storytold/filmcraft/releases), builds the WebAssembly application from the selected upstream tag and publishes the image to GHCR.

| Trigger | Behaviour |
|---|---|
| Weekly schedule | Checks the latest official FilmCraft release and builds it if it has not already been published here |
| Manual workflow dispatch | Builds the latest official release, or a specified `upstream_tag` |
| Force rebuild | Rebuilds an already published version with `force_rebuild: true` |
| Changes to packaging files on `main` | Rebuilds the current official upstream release with the updated workflow |

### Published tags

- `latest` — the latest successfully published image (mutable tag).
- `<upstream-version>` — the exact official upstream tag, for example `vX.Y.Z`.
- `upstream-<commit>` — the upstream source commit used for the image (first 12 hexadecimal characters).

The image targets both `linux/amd64` and `linux/arm64`. The workflow checks out **the official upstream release tag**, rather than compiling `main` as the versioned source.

### GitHub Releases

After a successful Docker build and GHCR push, the workflow creates or updates a [GitHub Release](https://github.com/MikaPST/filmcraft-web/releases) matching the upstream tag. It includes the upstream release notes, source link and commit, Docker tags, supported architectures and (when available) the published image digest.

The Release badge at the top of this README updates automatically. Scheduled runs skip versions already released here. You can force a rebuild from **Actions → Build and publish FilmCraft Web → Run workflow**.

> [!IMPORTANT]
> A GitHub Release is created only after the Docker image has been successfully published. The `latest` tag may change after a rebuild; pin a versioned image tag for a stable deployment. Auxiliary source repositories (for example `craft-fonts`) may be checked out separately and are not necessarily pinned to the upstream release commit.

### Build pipeline

The workflow:

1. Checks out this repository.
2. Checks out FilmCraft and the shared `craft-fonts` repository.
3. Installs the Rust WebAssembly target and the `wasm-bindgen-cli` version required by the upstream project (`0.2.129`).
4. Runs `cargo xtask web` to generate the web build in `upstream/target/web/dist`.
5. Packages the generated static site into an NGINX image and publishes it to GHCR.

The workflow supplies the generated web files as the Docker build context and defines the Dockerfile and NGINX configuration inline during the image build. Separate `Dockerfile`, `nginx.conf` and `.dockerignore` files are therefore not required in this packaging repository.

The repository is primarily intended as an automated image-build and publication pipeline; the normal way to consume it is to pull the published image.

## Unraid Community Applications

This image can be deployed on Unraid.

The Unraid Community Applications template is maintained in [MikaPST/unraid-community-apps](https://github.com/MikaPST/unraid-community-apps), separately from this image-build repository.

In the meantime, FilmCraft Web can be deployed on Unraid using the Docker Compose configuration above or by configuring the container manually with:

- **Repository:** `ghcr.io/mikapst/filmcraft-web:latest`
- **Container port:** `8080`
- **Host port:** `8080` by default
- **Template:** [filmcraft-web.xml](https://github.com/MikaPST/unraid-community-apps/blob/main/templates/filmcraft-web.xml)

## Upstream project

- **FilmCraft source code:** [storytold/filmcraft](https://github.com/storytold/filmcraft)
- **FilmCraft web build instructions:** [docs/web.md](https://github.com/storytold/filmcraft/blob/main/docs/web.md)
- **FilmCraft contribution and font-build instructions:** [docs/contributing.md](https://github.com/storytold/filmcraft/blob/main/docs/contributing.md)
- **Shared font assets:** [storytold/craft-fonts](https://github.com/storytold/craft-fonts)
- **Official releases:** [FilmCraft releases](https://github.com/storytold/filmcraft/releases)

The MikaPST GitHub Release tracks the upstream version but represents independent Docker packaging, not an official FilmCraft distribution.

## License and attribution

FilmCraft's source code is dual-licensed under the MIT License or Apache License 2.0, at the user's option, as specified by the upstream project. The `craft-fonts` assets have their own licensing and attribution requirements; consult that repository for the applicable notices.

The license of the upstream application and its assets does not automatically determine the license of the packaging files maintained in this repository. If you want to grant reuse rights for your own workflow, Compose file and documentation, select and include a separate `LICENSE` for this repository.

FilmCraft names, artwork and logos remain subject to the upstream project's trademark and usage terms.

## Disclaimer

This repository is maintained independently and is not affiliated with, sponsored by or endorsed by the FilmCraft project or its maintainers.

FilmCraft is alpha software. Use it at your own risk and keep independent backups of important media and project files.
