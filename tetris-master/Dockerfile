FROM node:current-alpine3.23 AS build

WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci

COPY dev.html gulpfile.js index.html manifest.json sw.js ./
COPY public ./public
COPY src ./src

RUN npm run build

FROM cgr.dev/chainguard/nginx:latest@sha256:0139db41f6bc4cc30a9502ec58e90029315273dd474f309e0e02d8509ae02b18 AS runtime

WORKDIR /usr/share/nginx/html

COPY --from=build /app/index.html ./index.html
COPY --from=build /app/manifest.json ./manifest.json
COPY --from=build /app/sw.js ./sw.js
COPY --from=build /app/public ./public
COPY --from=build /app/src ./src

EXPOSE 8080
# Start Nginx server
ENTRYPOINT ["nginx", "-g", "daemon off;"]