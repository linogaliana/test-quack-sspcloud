FROM ubuntu:24.04

RUN apt-get update && apt-get install -y curl unzip && rm -rf /var/lib/apt/lists/*

# DuckDB v1.5.3 (première version stable avec Quack)
RUN curl -L \
    https://github.com/duckdb/duckdb/releases/download/v1.5.3/duckdb_cli-linux-amd64.zip \
    -o /tmp/duckdb.zip \
    && unzip /tmp/duckdb.zip -d /usr/local/bin/ \
    && chmod +x /usr/local/bin/duckdb \
    && rm /tmp/duckdb.zip

# Pré-installation des extensions (évite les téléchargements au runtime)
RUN duckdb -c "INSTALL quack; INSTALL httpfs;"

COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

EXPOSE 9494
CMD ["/app/start.sh"]
