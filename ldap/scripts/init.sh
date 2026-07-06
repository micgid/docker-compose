#!/bin/bash
# Chargé par le container ldap-init après que openldap soit healthy.
# Se connecte en simple bind TCP - pas besoin de socket UNIX ni de root.

HOST="openldap"
PORT="389"
CONFIG_DN="cn=admin,cn=config"
ADMIN_DN="cn=admin,dc=example,dc=com"

echo "================================================================"
echo " Initialisation LDAP"
echo "================================================================"

echo ""
echo ">>> [1/3] Schéma personnalisé (config admin -> cn=schema,cn=config)..."
ldapadd \
  -H "ldap://${HOST}:${PORT}" \
  -D "${CONFIG_DN}" \
  -w "${LDAP_CONFIG_PASSWORD}" \
  -f /ldifs/00-custom-schema.ldif \
  && echo "    Schéma chargé." \
  || echo "    Note : schéma déjà présent, on continue."

echo ""
echo ">>> [2/3] Création des OUs..."
ldapadd \
  -H "ldap://${HOST}:${PORT}" \
  -D "${ADMIN_DN}" \
  -w "${LDAP_ADMIN_PASSWORD}" \
  -c \
  -f /ldifs/01-structure.ldif \
  && echo "    Structure créée." \
  || true

echo ""
echo ">>> [3/3] Chargement des données de test..."
ldapadd \
  -H "ldap://${HOST}:${PORT}" \
  -D "${ADMIN_DN}" \
  -w "${LDAP_ADMIN_PASSWORD}" \
  -c \
  -f /ldifs/02-testdata.ldif \
  && echo "    Données chargées." \
  || true

echo ""
echo "================================================================"
echo " Terminé !"
echo " Interface web : http://localhost:8389"
echo "================================================================"
