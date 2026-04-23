# Estiñol

Estiñol on minimalistlik sõnastik, mis on loodud spetsiaalselt hispaania keele õppimiseks.

## Põhifunktsioonid

- **Sõnastik:** Kiire lokaalne otsing otse seadme mälust. Sünkroniseerib end Firebase'i pilvega ainult siis, kui andmetes on toimunud muudatusi, hoides kokku kasutaja mobiilset andmesidet.
- **Sõnakaardid:** Õppesessioonid põhinevad raskusastmetel ja juhuslikul valikul. Sessiooni lõpus kuvatakse visuaalne statistika ja tagasiside.
- **"Minu komplektid":** Kasutajad saavad luua oma isiklikke sõna-nimekirju. Komplektid on täielikult hallatavad: sõnu saab lisada, nende järjekorda saab lohistades muuta ning neid saab kustutada. Kogu see info püsib privaatselt ainult kasutaja seadmes.

## Tehniline (Tech Stack)

- **Raamistik:** Flutter (Dart)
- **Andmebaas:** Firebase Firestore (andmete hoidmiseks pilves)
- **Lokaalne salvestus:** SharedPreferences (seaded ja kasutaja komplektid) ning JSON vahemälu (sõnastik)
- **Stiil:** Material Design 3
- **Ikoonid:** Kohandatud disain koos `flutter_launcher_icons` toega

## Paigaldamine ja arendus

### Eeldused
- Flutter SDK (versioon 3.x või uuem)
- Android Studio / VS Code
- Firebase projekt (koos Firestore andmebaasiga)

### Käivitamine arendusrežiimis
```bash
flutter pub get
flutter run

## Projekti struktuur
- lib/models/ - Andmemudelid (nt Word)
- lib/services/ - Andmebaasi loogika ja sünkroniseerimine
- lib/screens/ - Rakenduse erinevad vaated (Kodu, Sõnastik, Kaardid)
- lib/widgets/ - Korduvkasutatavad UI komponendid
- assets/ - Rakenduse ikoonid ja staatilised failid
