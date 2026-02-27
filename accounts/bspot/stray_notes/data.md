## Docker

### Build
```
docker build --no-cache -t gpn_warehouse .
```

### Run
```
docker run -it \
  --entrypoint /bin/bash \
  --env-file /Users/mlacorte/dev/dotfiles/local/.env \
  -v ${PWD}:${PWD} \
  -v ~/.aws/credentials:/root/.aws/credentials \
  -w ${PWD} \
  -p 8080:8080 \
  gpn-dbt-warehouse
```

### How to run as a background process / Single container
1. Background the process (simplest)
In the same container, just background the docs server:


dbt docs serve --host 0.0.0.0 --port 8080 &
Now you can keep working. Use fg to bring it back or kill %1 to stop it.

2. Run a second shell in the same container
From a second terminal on your Mac:


docker exec -it f0bc1f394f79 /bin/bash
This gives you another shell inside the same running container -- same filesystem, same network. No need to spin up a whole new container or re-map ports.

3. Generate once, serve statically from your Mac
Since you're volume-mounting ${PWD}, the target/ directory with catalog.json and manifest.json is already on your Mac after dbt docs generate. You could serve it locally outside Docker entirely (e.g. python3 -m http.server in the target/ dir), though dbt's index.html expects a specific structure so option 1 or 2 is usually easier.

Option 2 is the most common Docker pattern -- docker exec into the already-running container whenever you need another terminal. You avoid duplicate containers, duplicate port mappings, and duplicate env setup.