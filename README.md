# aegis-demo-ruby

Sinatra + session login. Target for Aegis-generated scanner pipelines.

## Run

```bash
bundle install
bundle exec puma -b tcp://0.0.0.0:4567
# open http://localhost:4567/login
# demo creds: demo@example.com / demo1234
```

## Endpoints

### Cookie session (form login)

- `GET /` — public landing
- `GET /login` / `POST /login` — form auth, fields named `email` / `password`
- `GET /dashboard` — requires session
- `GET /api/items` — requires session
- `POST /logout`
- `GET /healthz`

### HTTP Basic realm

Exists so ZAP's `http` authentication has a target — the only one in the demo
estate. Basic auth is scoped to a host and port, not to a URL, which is why the
Aegis DAST panel asks for those directly instead of taking a `DAST_TARGET_URL`.

- `GET /basic/items` — requires `Authorization: Basic …`
- `GET /basic/profile` — requires `Authorization: Basic …`

Aegis DAST config for this target:

| field | value |
|---|---|
| Authentication method | `http` |
| Session | `cookie` |
| Authentication host | `127.0.0.1` (or the deployed hostname) |
| Port | `4567` |
| Login path | `/basic/items` |
