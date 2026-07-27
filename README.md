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

- `GET /` — public landing
- `GET /login` / `POST /login` — form auth
- `GET /dashboard` — requires session
- `GET /api/items` — requires session
- `POST /logout`
- `GET /healthz`
