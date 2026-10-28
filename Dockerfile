FROM nginx:alpine

ARG FILMCRAFT_COMMIT=unknown
ARG CRAFT_FONTS_COMMIT=unknown

LABEL org.opencontainers.image.title="FilmCraft Web" \
      org.opencontainers.image.description="Community-maintained NGINX image for the FilmCraft WebAssembly video editor" \
      org.opencontainers.image.source="https://github.com/MikaPST/filmcraft-web" \
      org.opencontainers.image.documentation="https://github.com/MikaPST/filmcraft-web#readme" \
      com.mikapst.filmcraft.source-commit="${FILMCRAFT_COMMIT}" \
      com.mikapst.craft-fonts.source-commit="${CRAFT_FONTS_COMMIT}"

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY dist/ /usr/share/nginx/html/

EXPOSE 8080
