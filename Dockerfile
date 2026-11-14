FROM nginx:1.27-alpine

ARG FILMCRAFT_COMMIT
ARG CRAFT_FONTS_COMMIT

LABEL org.opencontainers.image.title="FilmCraft Web" \
      org.opencontainers.image.description="Self-hosted browser build of FilmCraft" \
      org.opencontainers.image.source="https://github.com/storytold/filmcraft" \
      org.opencontainers.image.revision="${FILMCRAFT_COMMIT}" \
      io.mikapst.filmcraft.craft-fonts-revision="${CRAFT_FONTS_COMMIT}"

RUN rm -f /etc/nginx/conf.d/default.conf
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY dist/ /usr/share/nginx/html/

EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -q -O /dev/null http://127.0.0.1:8080/health || exit 1
