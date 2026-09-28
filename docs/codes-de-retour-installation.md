# Codes de retour de l'installateur Windows

Page destinée au champ **« URL de documentation des codes de retour »** de
Partner Center (politique Store 10.2.9 : pour un paquet `exe`, un lien documentant
les codes personnalisés est obligatoire), et aux utilisateurs qui veulent savoir ce
que signifie un échec d'installation.

L'installateur est produit par **Inno Setup 6** via `flutter_distributor`
(`windows/packaging/exe/make_config.yaml`). Les codes ci-dessous sont ceux
d'Inno Setup, tels que la documentation de l'éditeur les énonce
([Setup Exit Codes](https://jrsoftware.org/ishelp/index.php?topic=setupexitcodes),
[Uninstaller Exit Codes](https://jrsoftware.org/ishelp/index.php?topic=uninstexitcodes)),
et non des codes inventés pour le Store : un code que l'installateur ne peut pas
rendre n'a rien à faire dans un tableau de correspondance.

## Comment l'installateur est lancé

```
uniflow-1.0.0-1-windows-setup-x64.exe /VERYSILENT /SUPPRESSMSGBOXES /NORESTART
```

Téléchargement : `https://uniflow.kernelforge.codes/download/uniflow-1.0.0-1-windows-setup-x64.exe`
(20,5 Mo, installateur complet — rien n'est retéléchargé à l'exécution).

Désinstallation, depuis `unins000.exe` posé dans le dossier de l'application :

```
unins000.exe /VERYSILENT /SUPPRESSMSGBOXES /NORESTART
```

Sans commutateurs, Inno Setup affiche son assistant : c'est pour cela que le
Store déclare ce paquet « silencieux, mais nécessitant des commutateurs ».
`/SUPPRESSMSGBOXES` n'a d'effet qu'avec `/VERYSILENT` ou `/SILENT`, et
`/NORESTART` empêche Inno de redémarrer la machine de sa propre initiative.

`[Setup] PrivilegesRequired=none` : l'installateur ne demande jamais
d'élévation. Sur un compte standard, la pose est par utilisateur
(`%LOCALAPPDATA%\Programs\UniFlow`, clé d'enregistrement en HKCU) ; sur un
compte administrateur déjà élevé, elle est par machine (`Program Files\UniFlow`,
HKLM). Le même binaire rend les mêmes codes dans les deux cas.

## Tableau des codes

| Code | Ce qu'il signifie (Inno Setup) |
|------|--------------------------------|
| `0`  | Installation menée à son terme. Rendu aussi si `/HELP` ou `/?` a été utilisé. |
| `1`  | L'installateur n'a pas pu s'initialiser. C'est aussi ce que renvoie un second exemplaire lancé pendant qu'un premier travaille : Inno refuse l'instance supplémentaire à l'initialisation. |
| `2`  | Annulation par l'utilisateur **avant** le début de l'installation (bouton Annuler de l'assistant, ou « Non » à la boîte « This will install… »). |
| `3`  | Erreur fatale entre deux phases de l'installation (préparation). Cas rare : manque de mémoire ou de ressources Windows. |
| `4`  | Erreur fatale **pendant** l'installation elle-même. |
| `5`  | Annulation par l'utilisateur **pendant** l'installation, ou « Abort » dans une boîte Abort-Retry-Ignore. |
| `6`  | Processus terminé de force depuis l'IDE de compilation. Ne peut pas arriver en production. |
| `7`  | L'étape « Preparing to Install » a établi que l'installation ne peut pas avoir lieu. C'est notamment le chemin de l'espace disque insuffisant. |
| `8`  | Comme `7`, et le système doit redémarrer pour que le problème se corrige. |

Avant de rendre `1`, `3`, `4`, `7` ou `8`, Inno affiche normalement un message
expliquant le problème. Avec `/VERYSILENT /SUPPRESSMSGBOXES` cet affichage va au
journal de bord (`/LOG=fichier.log`), ce qui est la seule façon de lire la cause
d'un échec silencieux.

Deux réserves, telles que la documentation d'Inno les énonce : les versions
futures peuvent ajouter des codes, donc **tout code non nul signifie que
l'installation n'est pas allée au bout** ; et les codes `2` et `5`
supposent un assistant visible, donc deviennent inaccessibles quand
l'installation est lancée avec `/VERYSILENT`.

## Ce que le Microsoft Store demande de déclarer

Correspondance assumée dans Partner Center › UNIFLOW DESKTOP › Packages :

| Scénario Store | Code saisi | Justification |
|----------------|-----------|---------------|
| Installation réussie | `0` | — |
| Installation annulée par l'utilisateur | `2`, `5` | Avant / pendant l'installation. |
| Installation déjà en cours | `1` | Refus de la seconde instance à l'initialisation. |
| L'espace disque est plein | `7` | Échec détecté à l'étape « Preparing to Install ». |
| Redémarrage requis | `8` | Le seul code qui dit explicitement « redémarrer ». |
| Package rejeté pendant l'installation | `4` | Erreur fatale en cours d'installation. |
| Divers scénarios d'échec | `3`, `6` | Et, par la règle d'Inno, tout code non nul inattendu. |
| L'application existe déjà | *rien* | Inno n'a pas de code pour ce cas : réinstaller UniFlow écrase l'installation en place et renvoie `0`. Inventer un code ici documenterait un comportement qui n'existe pas. |
| Échec du réseau | *rien* | L'installateur est autonome : les 20 Mo contiennent l'application entière, rien n'est téléchargé à l'exécution. |
