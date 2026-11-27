# Écoute le Coach

Application d'entraînement pour le cyclisme sur route (courses de 90 à 130 km), avec course à pied et musculation en complément.

**Ouvrir l'application :** https://thomassss77-22.github.io/ecoutelecoach/

## Ce qu'elle fait

- Plan de saison calculé à rebours depuis tes objectifs (base, construction, spécifique, affûtage, compétition, transition).
- Séance du jour adaptée au check-in du matin, semaines et mois modifiables jour par jour.
- Import des sorties (.fit, .tcx, .gpx, export complet Garmin en .zip) et analyse détaillée de chaque séance.
- Séances à télécharger en .fit pour une montre ou un compteur Garmin.

## Communauté et partage

Profil, fil d'actualité, classement et bravos (tables créées par `supabase/social.sql`).
Si tu l'acceptes (Mon profil), les personnes qui te suivent voient aussi ton plan de la semaine sur ton profil et peuvent ouvrir l'analyse détaillée de tes sorties depuis le fil ou ton profil. Ce partage utilise les tables de `supabase/partage.sql`, à exécuter une fois dans l'éditeur SQL de Supabase ; décocher l'option efface ce détail du serveur.

## Tes données

Ton profil et tes sorties restent dans ton navigateur, sur ton appareil : rien n'est envoyé à un serveur.
Pour passer sur un autre appareil : Réglages → « Copier mes données », puis « Importer le texte collé » sur l'autre appareil.

La synchronisation automatique Garmin ou Strava n'existe que dans la version de l'application ouverte depuis Claude.
