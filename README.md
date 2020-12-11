# docker-curator
Docker image for Elasticsearch Curator to manage Elasticsearch indices

Like a museum curator manages the exhibits and collections on display, Elasticsearch Curator helps you curate, or manage your indices and snapshots.

## Why this image
This image keeps up to date with curator releases `5.8.3`. It is also based on minimal alpine image.

## Features
- Upgrade curator to version `5.8.3`
- Add support for snapshot / restore (use `curator_cli` for single index scenario)
- Add support for snapshot / restore `ALL` indexes for ES using `curator` with actions rules (would be useful for different snapshot repo per index, and for accident recovery scenario)
- Add `DRY_RUN` mode
- Rewrite Dockerfile and use `alpine` to reduce image size

## Usage
Image `entrypoint` is set to customized script, need to pass paremeters to `CMD`, can support override `ENV`

### `[CMD]` parameters:

`TYPE[snapshot|restore]  INDEX_PREFIX[...|ALL_KERERU]  REPO_NAME  DRY_RUN[True|False]`

Default value is:
```
TYPE=snapshot
INDEX_PREFIX=.kibana
REPO_NAME=snapshot-repo
DRY_RUN=True
```

e.g.
```
# Snapshot single index with DRY_RUN mode, and delete snapshots 14 days ago
docker-compose run --rm es-curator snapshot .monitoring-es-7-2020.12.04 snapshot-repo True

# Restore single index (with latest snapshot) without DRY_RUN mode
docker-compose run --rm es-curator restore .monitoring-es-7-2020.12.04 snapshot-repo False

# Snapshot ALL indexes for ES kereru without DRY_RUN mode, and delete snapshots 14 days ago
docker-compose run --rm es-curator snapshot ALL_KERERU snapshot-repo False

# Restore ALL indexes for ES kereru (with latest snapshot) without DRY_RUN mode
docker-compose run --rm es-curator restore ALL_KERERU snapshot-repo False
```

### Pass `ENV`:

```
- ELASTICSEARCH_HOST: default is `elasticsearch`
- UNIT: default is days, support `seconds | minutes | hours | days | weeks | months | years`
- UNIT_COUNT: default is 14
```

e.g.
```
# Snapshot single index without DRY_RUN mode, and delete snapshots older than 1 minutes ago
UNIT=minutes UNIT_COUNT=1 docker-compose run --rm es-curator snapshot .monitoring-es-7-2020.12.04 snapshot-repo False
```