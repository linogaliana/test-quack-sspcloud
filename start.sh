#!/bin/bash
set -e

# Variables obligatoires
: "${QUACK_TOKEN:?Erreur : QUACK_TOKEN non défini}"
: "${AWS_ACCESS_KEY_ID:?Erreur : AWS_ACCESS_KEY_ID non défini}"
: "${AWS_SECRET_ACCESS_KEY:?Erreur : AWS_SECRET_ACCESS_KEY non défini}"

# Variables avec valeurs par défaut SSPCloud
S3_ENDPOINT="${S3_ENDPOINT:-minio.lab.sspcloud.fr}"
S3_REGION="${S3_REGION:-us-east-1}"
S3_BUCKET="${S3_BUCKET:-lgaliana}"
PARQUET_PATH="${PARQUET_PATH:-s3://lgaliana/data/python-ENSAE/sirene2024.parquet}"

echo "=== DuckDB Quack Server (SSPCloud) ==="
echo "Endpoint S3 : $S3_ENDPOINT"
echo "Fichier     : $PARQUET_PATH"

# Clause SESSION_TOKEN optionnelle (credentials temporaires Vault)
SESSION_TOKEN_SQL=""
if [ -n "${AWS_SESSION_TOKEN:-}" ]; then
    SESSION_TOKEN_SQL=", SESSION_TOKEN '${AWS_SESSION_TOKEN}'"
fi

# Pipe SQL vers duckdb en mode interactif.
# quack_serve() est non-bloquant : il démarre le serveur dans un thread
# et rend la main. Le `sleep infinity` maintient stdin ouvert pour que
# duckdb reste en vie et continue de servir les connexions.
(
cat <<SQL
LOAD quack;
LOAD httpfs;

CREATE OR REPLACE SECRET s3_sspcloud (
    TYPE        s3,
    KEY_ID      '${AWS_ACCESS_KEY_ID}',
    SECRET      '${AWS_SECRET_ACCESS_KEY}'${SESSION_TOKEN_SQL},
    ENDPOINT    '${S3_ENDPOINT}',
    URL_STYLE   'path',
    USE_SSL     true,
    REGION      '${S3_REGION}'
);

-- Vue exposée aux clients Quack (les credentials S3 restent côté serveur)
CREATE VIEW sirene AS
    FROM read_parquet('${PARQUET_PATH}');

CALL quack_serve(
    'quack:0.0.0.0:9494',
    allow_other_hostname => true,
    token => '${QUACK_TOKEN}'
);
SQL
sleep infinity
) | exec duckdb :memory:
