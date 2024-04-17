# brapi-postgres
A BrAPI server implementation using PostgreSQL as its core technology.

# Development

1. Start up the postgreSQL container.
```shell
docker compose up -d
```

2. Install dependencies (optionally create a virtual environment first).
```shell
pip install -r requirements.txt
```

3. Run flask development server in debug mode.
```shell
flask --app server run --debug
```