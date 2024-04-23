ARG NGINX_VERSION=1.25.5
FROM soulteary/prebuilt-nginx-modules:ngx-${NGINX_VERSION}-set-misc-master AS modules

FROM nginx:${NGINX_VERSION}
COPY --from=modules /ndk_http_module.so /usr/lib/nginx/modules/
COPY --from=modules /ngx_http_set_misc_module.so /usr/lib/nginx/modules/
