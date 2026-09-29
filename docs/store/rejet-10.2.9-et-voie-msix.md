# UNIFLOW DESKTOP rejeté par le Store (politique 10.2.9) et voie MSIX

Constat du 28/09/2026, rapport de certification du produit
`88e64b68-bdd0-4163-a604-d2cca375437f`.

## Ce que dit le rapport

La phrase de la politique 10.2.9 a **deux branches**, et la recopier à moitié
prête à chercher le mauvais problème :

> The binary and all of its Portable Executable (PE) files **has been signed
> with a certificate that has been observed being abused to sign malicious
> content** *or* **must be digitally signed with a code sign certificate** that
> chains up to a certificate issued by a Certificate Authority (CA) that is part
> of the Microsoft Trusted Root Program. […] If your EXE or MSI cannot comply
> with Microsoft Store policy 10.2.9, you can consider repackaging your existing
> EXE or MSI to MSIX format.
>
> | Package URL | Code signing type |
> | https://uniflow.kernelforge.codes/download/uniflow-1.0.0-1-windows-setup-x64.exe | **Unsigned** |

La colonne « Code signing type » tranche entre les deux branches : **Unsigned**.
Aucun certificat n'a été relevé sur notre binaire, donc la première branche —
une AC révoquée parce qu'utilisée pour signer des maliciels — ne nous vise pas.
Ce qui tombe, c'est la seconde : l'absence de signature.

Le refus n'est donc ni l'URL (le 302 de GitHub a été réglé en auto-hébergeant le
binaire sur Vercel), ni l'installateur silencieux, ni la fiche : c'est
l'absence de signature Authenticode, et rien dans `uniflow-desktop` ne la produit.

## Mesure, pas opinion

L'en-tête PE de l'installateur a été lu octet à octet : `NumberOfRvaAndSizes` à
l'offset optionnel + 92 vaut 16, le répertoire de données n° 4 (Security /
Authenticode) a une **taille de 0**, et aucun marqueur PKCS#7 n'apparaît en fin
de fichier. Le blob de signature est absent, confirmé par la taille du fichier
servi en ligne identique à celle de l'asset GitHub
(`sha256 b8e0e521…b4e1`, 21 461 704 octets).

Ce n'est pas propre à l'installateur : les `.dll` embarquées par Flutter et ses
greffons (`flutter_windows.dll`, celles de `flutter_webrtc` et de
`desktop_webview_window`) ne sont signées par personne. La politique porte sur
« the binary **and all of its PE files** », donc signer seulement l'`.exe` de
setup ne suffirait pas.

## Et un `.msi` à la place du `.exe` ? Même refus, mot pour mot

La page d'exigences de la voie Win32 ne distingue pas les deux extensions :

> The installer binary may only be an **.msi or .exe**.
> The binary and all of its Portable Executable (PE) files **must be digitally
> signed** with a code signing certificate that chains up to a certificate
> issued by a Certificate Authority (CA) that is part of the Microsoft Trusted
> Root Program.

C'est littéralement la phrase du rapport de certification. Un `.msi` serait donc
rejeté pour la même raison, avec en plus deux régressions : la chaîne de
construction actuelle (`ISCC.exe` + les commutateurs `/VERYSILENT`, `/DIR=`,
`/LOG` vérifiés en CI sur le poste de build) est à refaire, et `flutter_distributor`
n'a pas de maker `msi` — il faudrait l'outillage Windows Installer XML (WiX) à
côté. Côté Store, rien ne change : « Microsoft does **not** re-sign your
installer » pour un MSI comme pour un EXE.

Seul le MSIX est signé : « MSIX benefits include: **Free Microsoft code
signing** and CDN hosting. »

## L'autre suggestion du rapport : MSIX Packaging Tool, et pourquoi on ne la prend pas

Le rapport propose aussi de « run your EXE or MSI installers through MSIX
Packaging Tool ». L'outil a bien une ligne de commande de conversion, ce n'est
donc pas un refus par incapacité. C'est un refus par coût, lu dans sa propre page
de préparation :

> A **clean machine** for conversion is important because during the installation
> step of the MSIX Packaging Tool, **we will be listening to everything in the
> environment to capture what the installer is doing**. A clean machine means
> that there aren't extraneous apps or services running on your machine that
> could get captured in your package. […] We recommend that you create a **clean
> VM** […] create a **checkpoint** for the VM, so you can use the VM to convert,
> **revert** to your previous checkpoint.

La conversion est une **capture de différences** : machine vierge, instantané
Hyper-V, architecture identique à la cible, droits administrateur, outil installé
depuis le Store. Un runner `windows-latest` de GitHub Actions n'est rien de tout
ça (pas de checkpoint réinitialisable, pas de machine vierge), et le paquet qui en
sortirait dépendrait de l'état de la VM le jour de la capture.

Surtout : cet outil est conçu pour « convert an application **without having the
source code** ». Nous avons la source et la chaîne de build. Le maker `msix` part
du répertoire `build/windows/x64/runner/Release` déjà produit par l'étape
précédente et écrit l'`AppxManifest.xml` — même livrable, déterministe, sans
étape de capture. La conversion n'a d'intérêt que si le `.msix` natif se révèle
impossible à faire tourner.

## Les deux sorties, et leur coût réel

| Sortie | Ce que ça demande | Ce que ça donne |
| --- | --- | --- |
| Signer (`.exe` **ou** `.msi`) | un certificat enchaînant à une AC du *Microsoft Trusted Root Program*. Le tableau de comparaison de Microsoft marque Azure Artifact Signing « Store eligible : **No** » ; un certificat OV coûte 150–300 $/an et la clé privée doit tenir sur un jeton HSM depuis juin 2023. La signature se rejoue sur **chaque** PE du bundle | la voie EXE/MSI reste ouverte, avec ses commutateurs silencieusement vérifiés en CI |
| Repasser en MSIX | `flutter_distributor package --targets msix` sur le runner Windows, rien à acheter | le Store le **signe lui-même** après certification |

Le rapport lui-même presse la seconde option (« you can consider repackaging
your existing EXE or MSI to MSIX format. Microsoft Store offers many
complimentary benefits such as code signing »), et c'est elle qui est câblée.

> Azure Artifact Signing est de toute façon hors de portée pour le compte : la
> page réserve le service aux organisations établies aux États-Unis, au Canada,
> dans l'Union européenne et au Royaume-Uni, et aux **particuliers des seuls
> États-Unis et Canada**. Pour signer l'`.exe` de la page Téléchargements, le
> certificat OV d'une AC commerciale est donc la seule voie réaliste.

## Ce qui est câblé

- `windows/packaging/msix/make_config.yaml` — `store: 'true'` : dans le paquet
  `msix` 3.18.0, les trois branches de signature sont gardées par
  `if (signMsix && !store)`, donc le paquet sort non signé et aucun certificat
  n'est installé. Les autres clés et leurs pièges (valeurs obligatoirement
  entre guillemets, `--add-execution-alias` inexistant, `languages` lu uniquement
  depuis `pubspec.yaml`) sont détaillées en commentaire dans le fichier.
- `distribute_options.yaml` — job `windows-msix` à côté de `windows-setup`.
- `.github/workflows/ci.yml` — le job Windows produit l'installateur, **puis**
  un `.msix`, et affiche dans le résumé du run l'identité réellement gravée dans
  l'`AppxManifest.xml` du paquet, pas celle qu'on croit avoir configurée. Deux
  branches exclusives, décrites ci-dessous.
- La release GitHub attache `dist/**/*-store.msix`. Avec `store: 'true'` le
  paquet n'est **pas signé** (`msix.dart` l. 125-127 : la signature est gardée
  par `if (signMsix && !store)`) — le Store le signe à l'ingestion, mais hors du
  Store il ne s'installe pas. Le `.exe` reste la voie de téléchargement direct.
  Le paquet de test, lui, n'y va pas.

## Les deux branches du job Windows, et pourquoi aucune ne tourne à vide

`identity_name` a été laissé vide tant que le Package ID n'était pas lu dans
Partner Center, et le premier câblage faisait alors sauter l'étape MSIX : le run
restait vert, sans paquet — exactement ce qu'on observe quand on cherche « où est
passé le `.msix` ». Deux suites, gardées par la condition inverse l'une de
l'autre ; la seconde est le repli si l'identité vient à manquer :

| Étape | Quand | Ce qu'elle écrit dans `make_config.yaml` (copie du runner, jamais commise) |
| --- | --- | --- |
| `Paquet MSIX pour le Microsoft Store` | `identity_name` renseigné | rien : le fichier tel quel, avec `store: 'true'` |
| `Paquet MSIX de test, signé par le certificat fourni par msix` | `identity_name` absent | retire la ligne `store:`, ajoute `identity_name: 'codes.kernelforge.uniflowtest'` et `install_certificate: 'false'` — **rien d'autre** : pas de `signtool_options`, voir le troisième point |

Trois détails qui ne sont pas du goût personnel, lus dans `msix` 3.18.0 :

- **`store` est un drapeau** (`configuration.dart` l. 110 : `_args.wasParsed
  ('store') || yaml['store'] == 'true'`). Écrire `store: 'false'` l'active
  quand même — le maker transmet `--store false`, `wasParsed` devient vrai. La
  seule façon d'obtenir `store = false` est de **supprimer la ligne**.
- **`install_certificate` est une option**, donc `'false'` fonctionne (l. 98-101,
  `addOption` l. 403). Sans lui, `msix.dart` l. 143-147 appelle
  `SignTool.installCertificate()` : le certificat n'est pas dans
  `Cert:\CurrentUser\Root` sur un runner neuf, et l'outil demande
  `(y/N)` sur stdin (l. 166) — lecture non interactive, valeur nulle, plantage.
- **Pas de `signtool_options`, et c'est un correctif.** Le premier câblage posait
  une commande explicite `/f … /p 1234 /fd SHA256` pour couper le réseau : le run
  #61 a rendu `SignerSign() failed. (-2147024885/0x8007000b)`. Lu dans
  `sign_tool.dart` : dès qu'une commande custom est détectée
  (`isCustomSignCommand`, l. 204-253), `getCertificatePublisher()` relit le sujet
  du certificat en exécutant `powershell.exe` avec le chemin tel que le
  convertisseur de ligne de commande l'a reconstruit ; l'échec n'est pas
  terminant, `exitOnError()` (`method_extensions.dart` l. 74-79) ne regarde que
  `exitCode`, donc un stdout vide passe inaperçu, le sujet reste vide, et
  l'`AppxManifest` conserve le `Publisher` de `make_config.yaml` (à l'époque du
  run `CN=3a54a224-…`) alors que le paquet est signé avec le certificat
  « Msix Testing ». Sur un paquet Appx, `0x8007000b` veut dire exactement cela :
  éditeur du manifeste différent du sujet du certificat, champ pour champ. Sans
  `signtool_options`, `msix` signature via `_config.certificatePath` — une chaîne
  Dart, jamais repassée par un shell — et lit le sujet correctement.
- **L'horodatage n'était pas en cause** : le `/tr http://timestamp.digicert.com`
  par défaut (`sign_tool.dart` l. 240-249) est gardé. Mesure locale, requête
  RFC 3161 construite avec `openssl ts -query -sha256 -cert` et postée en curl :
  HTTP 200, 6 008 octets, 0,51 s.

Le paquet de test **n'est pas téléversable** : signature ne chainant à aucune
autorité du *Microsoft Trusted Root Program*, et nom de paquet inventé. Il sert
à valider la chaîne — icônes, VCLibs, `MakeAppx`, `MakePri`, signature — avant
d'avoir l'identité, et à prouver qu'un run vert rend bien un `.msix`.

## Ce que le MSIX change au stockage de l'app

Un paquet MSIX n'exécute pas l'app dans le même environnement disque, et le
projet a trois façons d'écrire, qui ne sont pas touchées de la même manière. Lu
dans « Flexible virtualization » : les écritures dans **AppData** vont à un
emplacement privé par utilisateur et par application, fusionné à la lecture pour
paraître à la vraie place, et **« when the app is uninstalled, the virtualized
entries are removed »** ; alors qu'« **apart from AppData, the app can write to
any location where the user has write access, including other parts of
`%userprofile%`** ».

| Ce que l'app écrit | Où ça passe sous MSIX | Conséquence |
| --- | --- | --- |
| `session_profile.json` (`FileSessionSnapshotStore`, via `getApplicationSupportDirectory()`) et le `shared_preferences.json` des deux providers (`preferences_provider`, et le `prefs.keepSession` lu par `auth_provider` l. 19) | les deux passent par AppData : `path_provider_windows_real.dart` l. 120 résout le dossier connu `RoamingAppData` puis y crée le sous-dossier de l'app → `%APPDATA%\<app>` | conteneur privé du paquet, supprimé à la désinstallation. Rien à faire : profil de session et préférences doivent mourir avec le paquet, et personne ne veut laisser sa session Appwrite derrière lui en désinstallant |
| `%USERPROFILE%\.uniflow\conference` (`conference_paths.dart`, `HOME` puis `USERPROFILE`) : config et journaux du serveur LiveKit local, feuilles de présence | **hors AppData donc hors virtualisation**, chemin réel | conforme à l'intention écrite dans le fichier : « ces fichiers doivent survivre à une réinstallation ». Un mois sans réseau ne dépend d'aucun paquet |

Troisième chemin, et le seul où la virtualisation aurait été un défaut :
`attendance_export_service.dart` (`defaultDirectory()`) écrit dans
`~/Documents/UniFlow/Présences` par `getApplicationDocumentsDirectory()`, qui
résout le dossier connu `Documents` et non AppData
(`path_provider_windows_real.dart` l. 124). Hors conteneur donc : l'enseignant
retrouve son export dans l'explorateur.

C'est du comportement d'exécution, pas de la lecture de doc : à contrôler sur
machine en installant le `.msix`, en tenant une réunion, puis en comparant

```powershell
Get-ChildItem "$env:USERPROFILE\.uniflow\conference" -Recurse          # doit exister
Get-ChildItem "$env:LOCALAPPDATA\Packages\*\LocalCache" -Recurse -Filter session_profile.json
```

Si les feuilles de présence apparaissaient dans `LocalCache` plutôt que sous
`%USERPROFILE%`, la sortie existe déjà : `desktop6:FileSystemWriteVirtualization`
avec `virtualization:ExcludedDirectory`, derrière la capacité restreinte
`unvirtualizedResources` — la forme fine sous Windows 11 seulement, la forme
globale `FileSystemWriteVirtualization = disabled` datant de Windows 10 1903. À
ne pas demander au Store sans raison : une ressource non virtualisée est visible
des autres applications et survit à la désinstallation.

## La valeur qui manquait : le Package ID du produit desktop

Elle est gravée depuis (`identity_name: 'KERNELFORGE.Uniflowwork'`,
`make_config.yaml` l. 44), donc la branche de test n'est plus celle qui
s'exécute. Les deux règles de saisie qui motivaient le placeholder restent
valables pour la prochaine fiche :

- le champ Appx refuse le tiret bas (`^[a-zA-Z0-9.-]{3,50}$`) : si la valeur
  affichée contient un `_`, tout ce qui suit est le *package family name* et ne
  va pas dans `identity_name` ;
- `publisher` se relit **champ pour champ** sur le « Certificate Subject » de la
  page d'identité du produit, jamais recopié d'un autre produit : le GUID du
  desktop (`CN=200A91F7-4B15-441F-9332-83F216885B09`) diffère de celui porté
  jusque-là (`CN=3a54a224-…`, lu sur UNIFLOW WEB). Un `Publisher` de manifeste
  qui ne correspond pas au certificat de signature, c'est précisément ce que
  `signtool` rend par `0x8007000b`.

## Préalable qu'on ne peut pas sauter : le produit doit être de type MSIX

Le type de paquet n'est pas convertible. Réponse d'un modérateur Microsoft du
04/02/2026 à la question « How to change app type from exe/msi to msix ? » :
*« the app package type you submit (EXE/MSI vs MSIX) isn't something that can be
changed directly … there's no supported way to "switch" an existing EXE/MSI
submission into MSIX »*. Ce que la page Packages du compte confirme sans
ambiguïté : pour UNIFLOW DESKTOP (voie EXE/MSI) le formulaire demande une
**URL du package**, alors que pour UNIFLOW WEB (voie MSIX) c'est une zone de
déposé de fichiers. Deux produits, deux modèles, pas un champ à changer.

Il faut donc un produit de type « Computer package / MSIX » portant le nom
UniFlow. Le rapport le dit aussi : *« you have to delete your app name from
existing Win32 app in Partner Center in case you want to use the same for MSIX
packaged app »* — la réservation du nom tient dans le produit EXE/MSI actuel.

**Avant de supprimer quoi que ce soit** : UNIFLOW DESKTOP n'a jamais été publié,
donc le produit ne perd que son contenu de fiche — et ce contenu n'est nulle
part dans le dépôt. La description française, les termes de licence et les
mots-clés ont été saisis dans le formulaire du Store et jamais versionnés. Les
recoller d'abord dans `docs/store/` (ou les régénérer depuis le README) rend
l'opération sans perte ; sinon elle est irréversible.

## Ce que l'`.exe` garde comme raison d'être

Il reste le paquet de la page Téléchargements et des releases GitHub, où aucune
signature n'est exigée — avec l'avertissement SmartScreen que tout binaire non
signé provoque. Ses codes de retour et commutateurs silencieux sont documentés
dans `docs/codes-de-retour-installation.md`.

## Sources

- Certification d'une soumission et champ `genericDocUrl` (obligatoire en
  `packageType = exe`, inexistant en MSIX) —
  <https://learn.microsoft.com/en-us/windows/apps/publish/publish-your-app/msix/create-app-submission>
- Exigences des paquets MSIX, signature remplacée par le Store —
  <https://learn.microsoft.com/en-us/windows/apps/publish/publish-your-app/msix/app-package-requirements>
- Voie Win32 : la phrase « may only be an .msi or .exe » et l'exigence de
  signature sur chaque PE —
  <https://learn.microsoft.com/en-us/windows/apps/publish/publish-your-app/msi/app-package-requirements>
- Tableau comparatif des options de signature (MSIX signé gratuitement,
  « Microsoft does not re-sign your installer » pour MSI/EXE, Azure Artifact
  Signing marqué non éligible au Store, certificats OV et jeton HSM) —
  <https://learn.microsoft.com/en-us/windows/apps/package-and-deploy/code-signing-options>
- « How to change app type from exe/msi to msix? » —
  <https://learn.microsoft.com/en-us/answers/questions/5759723/how-to-change-app-type-from-exe-msi-to-msix>
- Ce qui est virtualisé (AppData) et ce qui ne l'est pas (reste de
  `%USERPROFILE%`), et la bascule `unvirtualizedResources` —
  <https://learn.microsoft.com/en-us/windows/msix/desktop/flexible-virtualization>
- Machine vierge, capture de tout ce que fait l'installant, checkpoint Hyper-V,
  outil destiné à la conversion **sans code source** —
  <https://learn.microsoft.com/en-us/windows/msix/packaging-tool/prepare-your-environment>
- Fabriqués et champs lus dans le code, pas dans un résumé :
  `~/.pub-cache/hosted/pub.dev/flutter_app_packager-0.6.11/lib/src/makers/msix/`,
  `~/.pub-cache/hosted/pub.dev/msix-3.18.0/lib/src/configuration.dart`,
  `~/.pub-cache/hosted/pub.dev/path_provider_windows-2.3.0/lib/src/path_provider_windows_real.dart`
