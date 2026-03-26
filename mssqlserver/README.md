# MSSQL with Docker

ms sql with docker

## Versions SQL

image: mcr.microsoft.com/mssql/server:2022-latest
image: mcr.microsoft.com/mssql/server:2025-latest

## run and connect to the db

```bash
docker-compose up -d
```

Connect with SQL Server Management Studio.

You can connect to the SQL Server instance using SQL Server Management Studio (SSMS), Azure Data Studio, or any other SQL client.

Use the following connection details:

```
Server name: localhost,1433
Authentication: SQL Server Authentication
Login: sa
Password: YourStrong!Passw0rd
```

> note: localhost is usually, 127.0.0.1

## sources

[GitHub Jay-study-nildana](https://github.com/Jay-study-nildana/DockerForStudents/blob/main/MSSQLDocker/readme.md)
