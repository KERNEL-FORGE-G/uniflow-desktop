Name:           uniflow
Version:        1.0.0
Release:        1%{?dist}
Summary:        UniFlow Desktop — Suite Académique et Campus Connecté
Group:          Applications/Education
License:        Proprietary / University Academic License
URL:            https://uniflow.kernelforge.codes
Vendor:         KERNEL FORGE
Packager:       KERNEL FORGE <support@kernelforge.codes>

AutoReqProv:    no
Requires:       gtk3, glib2, libsecret, jsoncpp

%description
UniFlow Desktop est la suite académique intégrée pour les étudiants, enseignants
et administrations universitaires. Elle regroupe les cours, les emplois du temps
officiels de l'Université de Yaoundé I, la bibliothèque numérique Z-Library,
la messagerie étudiante certifiée et la visioconférence haute définition.

%install
mkdir -p %{buildroot}/opt/uniflow
mkdir -p %{buildroot}%{_bindir}
mkdir -p %{buildroot}%{_datadir}/applications
mkdir -p %{buildroot}%{_datadir}/icons/hicolor/512x512/apps

# Copie du bundle complet
cp -r %{_sourcedir}/bundle/* %{buildroot}/opt/uniflow/

# Création du lanceur symlink
cat << 'EOF' > %{buildroot}%{_bindir}/uniflow
#!/bin/bash
exec /opt/uniflow/uniflow_desktop "$@"
EOF
chmod 755 %{buildroot}%{_bindir}/uniflow

# Fichier .desktop
cat << 'EOF' > %{buildroot}%{_datadir}/applications/uniflow.desktop
[Desktop Entry]
Name=UniFlow
GenericName=Suite Académique Universitaire
Comment=Campus Connecté, Cours, Emplois du temps, Z-Library et Messagerie
Exec=/usr/bin/uniflow %U
Icon=uniflow
Terminal=false
Type=Application
Categories=Education;Science;Office;Network;
MimeType=x-scheme-handler/uniflow;
Keywords=Education;University;Courses;Schedule;ZLibrary;Campus;
StartupWMClass=uniflow_desktop
EOF
chmod 644 %{buildroot}%{_datadir}/applications/uniflow.desktop

# Icône de l'application
if [ -f %{_sourcedir}/icon_512.png ]; then
  cp %{_sourcedir}/icon_512.png %{buildroot}%{_datadir}/icons/hicolor/512x512/apps/uniflow.png
fi

%files
/opt/uniflow
%{_bindir}/uniflow
%{_datadir}/applications/uniflow.desktop
%{_datadir}/icons/hicolor/512x512/apps/uniflow.png

%post
/usr/bin/update-desktop-database &> /dev/null || :
/usr/bin/gtk-update-icon-cache %{_datadir}/icons/hicolor &> /dev/null || :

%postun
/usr/bin/update-desktop-database &> /dev/null || :
/usr/bin/gtk-update-icon-cache %{_datadir}/icons/hicolor &> /dev/null || :

%changelog
* Fri Oct 16 2026 KERNEL FORGE <support@kernelforge.codes> - 1.0.0-1
- Release initiale officielle d'UniFlow Desktop
