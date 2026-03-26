Docker Installation
Upon every release of the CAS software, docker images are tagged and pushed to the Apereo CAS repository on Docker Hub. Images can be pulled down via the following command:

```bash
docker pull apereo/cas
```

```bash
docker run --rm -e SERVER_SSL_ENABLED=false -e SERVER_PORT=8080 -p 8080:8080 --name casserver apereo/cas
```

CAS should be running on http://localhost:8080/cas
L'interface d'administration est accessible par CAS_HOSTNAME/cas-management

Modifier le fichier etc/config/admin-users.json. Mettre l'id CAS (le login) à la place de casuser.
