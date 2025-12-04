# NOM

messaging-stub

# DESCRIPTION

Générer à des fins de test un environement "bouchon" contenant un serveur Cyrus et un Webmail RoundCube.  

# DÉPLOIEMENT

## Avec les paramètres par défaut

```
$ docker compose -f messaging.yaml up -d
```

## Avec variables d'envirronnement 

```
$ docker compose -f messaging.yaml --env-file dot.env up -d
```

# FICHIERS DE CONFIGURATION

## dot.env

Permet de changer les valeurs par défaut d'exécution du docker compose.  

| NOM | DEFAUT | DESCRIPTION |
|-----|--------|-------------|
| EXT_IMAP | 20143 | IMAP |
| EXT_IMAPS | 20993 | IMAPS |
| EXT_SMTP | 20025 | SMTP |
| EXT_HTTP | 28008 | CalDav |
| EXT_WEBMAIL | 20080 | RoundCube |
| PRIVATE_REGISTRY | | Définir un registry privé. <br /> Ne pas oublier le '/'.<br />Exemple: private/ |

## users.list

Liste des utilisateurs générés à la création.  
Pour le bon fonctionnement il faut à minima un utilisateur **cyrus** qui sera l'administrateur.

Les autres utilisateurs sont de la forme nom@email.test

Exemple de syntaxe :

```
cyrus MOT_DE_PASSE_CYRUS
user1@email.test MOT_DE_PASSE_USER1
user2@email.test MOT_DE_PASSE_USER2
user3@email.test MOT_DE_PASSE_USER3
....
```

# UTILISATION

## ACCÈS WEBMAIL

Par défaut l'accès au webmail RoundCube se fait via le port 20080.  

```
http://localhost:20080
```

## ENVOYER DES MAILS À DESTINATION DE EMAIL.TEST

Il est possible d'envoyer via le port SMTP des emails aux utilisateurs créés.  

Ex: envoyer vers user1@email.test
```
$ swaks -t user1@email.test -s localhost -p 20025
```
Cependant il n'est pas possible de relayer en dehors.