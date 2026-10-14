# Sample app — only if your own component cannot run yet

Use **your own** component for the deploy exercise. If it cannot run in a container yet, deploy this
one so the team still practises the whole flow — then swap in yours later.

```bash
python app.py                       # http://localhost:8000/health -> {"status": "ok", "version": "v1"}
docker build --platform linux/amd64 -t sample-app:v1 .
```

Port **8000**. Change the version for checkpoint 5 with a setting, not a code change:
`terraform apply -var 'settings={APP_VERSION="v2"}' …`
