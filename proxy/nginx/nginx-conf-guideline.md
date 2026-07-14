# nginx.conf — Production Best Practice Guide

Start from the default nginx.conf, then apply the changes below.
Only sections that need modification are listed here.

---

## worker_processes

**Default:**
```nginx
worker_processes 1;
```

**Change to:**
```nginx
worker_processes auto;
```

Automatically matches the number of CPU cores.

---

## events block

**Default:**
```nginx
events {
    worker_connections 1024;
}
```

**Change to:**
```nginx
events {
    worker_connections 4096;
    use epoll;
    multi_accept on;
}
```

- `epoll` — efficient I/O event model for Linux
- `multi_accept` — accept as many connections as possible per event loop tick

---

## http block — core tweaks

### server_tokens

**Default:** not explicitly set (nginx version exposed in response headers)

**Add:**
```nginx
server_tokens off;
```

Hides nginx version from `Server` response header.

---

### tcp settings

**Default:**
```nginx
sendfile on;
# tcp_nopush and tcp_nodelay not set
```

**Add:**
```nginx
sendfile    on;
tcp_nopush  on;
tcp_nodelay on;
```

`tcp_nopush` batches response headers into one packet.
`tcp_nodelay` disables Nagle's algorithm for low-latency sends.

---

### keepalive

**Default:**
```nginx
keepalive_timeout 65;
```

**Change to:**
```nginx
keepalive_timeout  30;
keepalive_requests 1000;
```

65s is longer than necessary for most apps.
`keepalive_requests` limits reuse per connection before forcing a new one.

---

### client body size

**Default:**
```nginx
client_max_body_size 1m;
```

**Change to match your app's upload needs**, e.g.:
```nginx
client_max_body_size 50m;
```

---

### buffer sizes

**Default:** not explicitly set

**Add:**
```nginx
client_body_buffer_size      128k;
client_header_buffer_size    1k;
large_client_header_buffers  4 16k;
```

Prevents frequent disk writes for small request bodies.

---

### client timeouts

**Default:** not explicitly set (nginx defaults to 60s)

**Add:**
```nginx
client_body_timeout   12;
client_header_timeout 12;
send_timeout          10;
```

Protects against slow-loris style attacks where clients send requests very slowly.

---

## gzip

**Default:**
```nginx
gzip off;
```

**Change to:**
```nginx
gzip              on;
gzip_comp_level   5;
gzip_min_length   256;
gzip_vary         on;
gzip_types
    text/plain
    text/css
    text/xml
    application/json
    application/javascript
    application/xml
    image/svg+xml;
```

- `gzip_comp_level 5` — good balance between compression ratio and CPU usage
- `gzip_min_length 256` — skip compressing tiny responses, not worth the overhead
- `gzip_vary on` — adds `Vary: Accept-Encoding` header for correct caching behavior

---

## logging

**Default:**
```nginx
access_log /var/log/nginx/access.log;
error_log  /var/log/nginx/error.log;
```

**Change to:**
```nginx
access_log /var/log/nginx/access.log combined buffer=512k flush=1m;
error_log  /var/log/nginx/error.log warn;
```

Buffered access log reduces disk I/O.
`warn` level for error log filters out noise from `notice` and `info`.

---

## What to leave as default

These are already well-tuned in the default config and do not need changes:

| Directive | Default | Reason |
|---|---|---|
| `include mime.types` | on | covers all common MIME types |
| `default_type` | `application/octet-stream` | safe fallback |
| `types_hash_max_size` | 2048 | sufficient |
| `proxy_buffering` | on | correct default, override per-location if needed |
