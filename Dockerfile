ARG NODE_VERSION=24.7.0-alpine
ARG NGINX_VERSION=alpine3.23

FROM node:${NODE_VERSION} AS builder
WORKDIR /app
COPY /app/package.json /app/yarn.lock ./
RUN yarn install --frozen-lockfile # using frozen-lockfile to make sure that versioning is consistent
COPY /app .
RUN yarn build

FROM nginxinc/nginx-unprivileged:${NGINX_VERSION} AS runner
RUN apk update && apk upgrade --no-cache
USER nginx
COPY /app/nginx.conf /etc/nginx/nginx.conf
COPY --chown=nginx:nginx --from=builder /app/build /usr/share/nginx/html
EXPOSE 8080

# Start Nginx directly with custom config
ENTRYPOINT ["nginx", "-c", "/etc/nginx/nginx.conf"]
CMD ["-g", "daemon off;"]