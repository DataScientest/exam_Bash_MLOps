# Linux & Bash

## Examen

Cet examen se décompose en 2 exercices :

- Le premier porte sur le langage bash (Obligatoire pour valider le module)
- Le second porte sur l'outil jq (Optionnelle)

### Examen : Bash - OBLIGATOIRE


#### Mise en place de l'API

Dans ce cours, nous avons vu comment fonctionne un système Linux. Nous aurions pu aller encore plus en détail mais nous avons construit la base pour la suite du parcours. Suivez les instructions suivantes pour réaliser l'exercice.

<div class="alert alert-info"><i class="icon circle info"></i>
Exercise to be completed <i>mandatory</i> on the Linux machine provided to you.
</div>

> Connect to your machine and run the following command to retrieve the API

```shell
wget --no-cache https://dst-de.s3.eu-west-3.amazonaws.com/bash_fr/api.tar
```

You now have a file with the `.tar` extension. It is simply an archive similar to a compressed `zip` file, but specific to Linux. To manipulate this file, we use the `tar` command (for _tape archiver_). For all tar-based formats, you will see that the options for tar are the same:

- c : create the archive
- x : extract the archive
- f : use the specified file as a parameter
- v : enable verbose mode.

> Unzip the archive using the following command:

```shell
    tar -xvf api.tar
```

The archive excerpt reveals the _api_ script.

> Launch the `api` script after granting execution rights:

```shell
chmod +x api
./api &
```

Our API is now running on `localhost` (0.0.0.0) on port 5000.

<div class="alert alert-info"> <i class="icon circle info"></i>
It is entirely possible to run the API without putting it in the background, but doing so will block any manipulation on your VM. You will then need to open a 2nd terminal and reconnect to the VM, working only with the 2nd terminal.
</div>

This API reveals the sales per minute of the largest graphics card resellers for the models rtx3060, rtx3070, rtx3080, rtx3090, and rx6700.
It is possible to retrieve this information using the **cURL** command. However, you may not have cURL on your machine; to remedy this, we use `apt` on Linux.


#### Commande apt

`apt` est un gestionnaire de paquets qui contiennent différents logiciels que vous pouvez installer assez facilement avec une seule ligne de code.
Pour ce faire, nous pouvons faire comme suit :

```shell
apt install software_name
```

Dans les anciennes versions d'Ubuntu, vous aviez besoin d'utiliser `apt-get` au lieu de `apt`.
Dans la plupart des cas, vous avez besoin de `sudo` pour forcer les droits d'installation d'un logiciel.

Pour vous assurer que les paquets sont à jour, vous pouvez utiliser `sudo apt update` . Pour mettre à jour les
logiciels, vous pouvez utiliser `sudo apt upgrade` . Vous pouvez ajouter ou supprimer certains paquets et supprimer complètement un logiciel utilisant la fonction `apt purge`.

> Installez `curl` avec `apt`.

```shell
sudo apt-get update
```
```shell	
sudo apt-get install curl
```

Now that we have `curl`, let's explain the tool.

#### curl Command

cURL, which stands for client URL, is a command-line tool for transferring files with a URL syntax. It supports a number of protocols (HTTP, HTTPS, FTP, and many others). HTTP/HTTPS makes it an excellent candidate for interacting with APIs.

We can, for example, retrieve the sales of RTX 3060 using the following command.

```shell
curl "http://0.0.0.0:5000/rtx3060"
```

> Créez un dossier exam_NOM ou NOM est votre nom de famille.

> Ajoutez un dossier nommé exam_bash


When cloning the git, you will have the following structure:
```txt
exam_NAME/
  ├── exam_bash/
      ├── data/
        ├── processed/              # Dossier contenant les fichiers CSV prétraités
        └── raw/
            └── sales_data.csv      # Fichier CSV contenant 500 lignes de données brutes
      ├── logs/
          ├── test_logs/
          ├── collect.logs            # Fichier de logs pour la collecte des données
          ├── preprocessed.logs       # Fichier de logs pour le prétraitement des données collectées
          └── train.logs              # Fichier de logs pour l'entraînement du modèle avec les données prétraitées
      ├── model/                      # Dossier stockant toutes les versions des modèles entraînés
      ├── scripts/
          ├── collect.sh              # Script de collecte des données toutes les 2 minutes
          ├── preprocessed.sh         # Script lançant le prétraitement des données collectées
          ├── train.sh                # Script lançant l'entraînement du modèle avec les données prétraitées
          └── cron.txt                # Fichier de configuration pour les tâches cron 
      ├── src/
          ├── preprocessed.py         # Script de prétraitement des données collectées
          └── train.py                # Script d'entraînement du modèle avec les données prétraitées
      ├── tests/
          ├── test_collect.py         # Script de test pour vérifier la collecte des données et l'existence de fichiers CSV dans data/raw
          ├── test_model.py           # Script de test pour vérifier l'entraînement du modèle et l'existence du fichier model.pkl
          └── test_preprocessed.py    # Script de test pour vérifier le bon traitement des données                   
      ├── Makefile                    # Fichier Makefile pour automatiser les tâches
      ├── README.md                   # Fichier de documentation du projet
      └── requirements.txt            # Fichier contenant les dépendances du projet

```

> Vous trouverez dans les répertoires **scripts/** et **src/** l’ensemble des consignes et des éléments attendus à mettre en œuvre.
>
> Veuillez ne pas modifier les fichiers de tests. Vous pouvez toutefois les consulter pour mieux comprendre les vérifications attendues. Ces tests vous offrent un premier aperçu de la conformité de votre travail. Pour les exécuter, utilisez la commande `make tests`.

<br>

Votre fichier **cron.txt** doit être configuré pour exécuter automatiquement la collecte, le prétraitement et l'entraînement du modèle toutes les 3 minutes.

Configurez également votre **Makefile** afin qu'une simple commande `make bash` permette de lancer l'ensemble du programme : collecte des données, prétraitement et entraînement du modèle.

Votre fichier **requirements.txt** doit inclure uniquement les bibliothèques indispensables à l'exécution de votre programme, avec leurs versions précises.

Voici un diagramme qui résume brièvement le fonctionnement attendu du programme : 

<center><img src="https://assets-datascientest.s3.eu-west-1.amazonaws.com/MLOPS/image.png" style="width:80%"/></center>

Plus qu'un exercice à faire pour valider ce module !

### 10.2 Examen : JQ - OPTIONNEL

#### Mise en place

Vous rentrerez les commandes dans un fichier exécutable (avec le droit d'exécution +x) `exam_jq.sh`. Afin de valider l'exercice, vous devez rendre le fichier `exam_jq.sh` ainsi qu'un fichier `res_jq.txt` alimenté à l'aide de la commande `./exam_jq.sh > res_jq.txt`. N'oubliez pas qu'un être humain corrigera vos fichiers, pensez donc à bien présenter vos résultats dans vos 2 fichiers.

> Créez dans votre dossier exam\_NOM, le dossier exam\_jq

> Rendez-vous dans celui-ci, et créez un fichier `exam_jq.sh` comme ceci :

```bash
#!/bin/bash

echo "1. Énoncé de la question 1"
<commande pour répondre>
echo "Commande : <commande pour répondre>"
echo "Réponse : réponse de la question 1 si demandé"
echo -e "\n---------------------------------\n"
...

echo "n. Énoncé de la question n"
<commande pour répondre>
echo "Commande : <commande pour répondre>"
echo "Réponse : réponse de la question n si demandé"
echo -e "\n---------------------------------\n"
```

- <commande pour répondre> : placez la commande liée à la question afin d'avoir le résultat de la commande dans le fichier `res_jq.txt`.

Remplissez les champs selon les questions évidemment. La réponse n'est pas le résultat du code mais votre interprétation de celui-ci.

#### Questions

Voici le fichier json qui va servir pour la réalisation de l'examen: 

```bash
wget https://dst-de.s3.eu-west-3.amazonaws.com/bash_fr/people.json
```

Seules les questions 1, 2 et 4 attendent une Réponse interprétée.

1. Affichez le nombre d'attributs par document ainsi que l'attribut name. Combien y a-t-il d'attribut par document ? N'affichez que les 12 premières lignes avec la commande head (notebook #2).

2. Combien y a-t-il de valeur "unknown" pour l'attribut "birth_year" ? Utilisez la commande tail afin d'isoler la réponse.

3. Affichez la date de création de chaque personnage et son nom. La date de création doit être de cette forme : l'année, le mois et le jour. N'affichez que les 10 premières lignes. (Pas de Réponse attendue)

4. Certains personnages sont nés en même temps. Retrouvez toutes les pairs d'ids (2 ids) des personnages nés en même temps.

5. Renvoyez le numéro du premier film (de la liste) dans lequel chaque personnage a été vu suivi du nom du personnage. N'affichez que les 10 premières lignes. (Pas de Réponse attendue)

#### Bonus

Ajoutez cette commande pour séparer la partie obligatoire de la partie optionnelle.

```bash
echo -e "\n----------------BONUS----------------\n"
```

Aucune Réponse n'est demandée.

Enregistrez chacune des commandes dans des fichiers au format : people_\<numéro\_de\_la\_question>.json
Ces fichiers doivent se trouver dans un dossier bonus/.

N'ajoutez rien au fichier `res_jq.txt`. Vous devez faire la redirection directement dans le fichier `exam_jq.sh`.

Les questions sont à réaliser depuis le fichier créé à la question précédente, sauf pour la question 6.

6. Supprimez les documents lorsque l'attribut height n'est pas un nombre.

7. Transformer l'attribut height en nombre.

8. Ne renvoyez que les personnages dont la taille est entre 156 et 171.

9. Renvoyez le plus petit individu de `people_8.json` et affichez cette phrase en une seule commande : "\<nom\_du\_personnage> is \<taille> tall"
Renvoyez la commande dans un fichier `people_9.txt` et non `.json`.

#### Rendu : JQ

Nous avons les dossiers et fichiers suivants :

- exam\_NOM/exam\_jq/exam\_jq.sh
- exam\_NOM/exam\_jq/res\_jq.txt
- exam\_NOM/exam\_jq/bonus/people\_\<6 à 9>.\<json ou txt>

#### Rendu final

> Créez une archive exam_NOM.tar

```bash
# Create a tar archive named exam_NAME.tar from the directory exam_NAME

# Command:
tar -cvf exam_NAME.tar exam_NAME
```

### SCP Command

The `scp` command allows for the secure transfer of a file or an archive (folders cannot be transferred) via an SSH connection.

You can download your archive by running the following command `on a terminal of your own machine`.

```shell
scp -i "data_enginering_machine.pem" ubuntu@VOTRE_IP:~/exam_NAME.tar .
```

<div class="alert alert-info"> <i class="icon circle info"></i>
Several details regarding the above order:
  <br>
  </br>
  - When you open your terminal on your local computer to transfer your archive from the VM, specify the absolute path to your file data_enginering_machine.pem
  <br>
  </br>
  - Your archive will be downloaded in the same folder where your file data_enginering_machine.pem is located
</div>

Once you have downloaded your archive to your local machine, you can upload it via the `My Exams` tab.

Good luck!
