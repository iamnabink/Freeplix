# Freeplix

An open source movie and TV **catalogue**, built with Flutter and
powered by the [TMDB API](https://www.themoviedb.org/). One codebase, web
first; iOS and Android are wired up but not yet the focus.

**Live:** https://iamnabink.github.io/Freeplix/

An open source project built for learning. No accounts, no backend, no tracking.

---

## What it does

- **Home** — a spotlight reel of what's trending, then carousels for what's in
  theatres, what's on the air, and what's coming.
- **Browse** — the full TMDB catalogue for films and series, filtered by genre
  and sorted by popularity, rating, or release date, with infinite scroll.
- **Search** — one debounced multi-search across films and series.
- **Details** — synopsis, cast, crew, certification, runtime, genres,
  season-by-season episode listings, and recommendations.
- **My list** — saved titles, kept in your browser's local storage.
- **Jump back in** — the home page offers back whatever you last opened in the
  player, down to the episode for a series. The player runs cross-origin so
  its position cannot be read; this records what was opened, not a percentage.
- **Filters** — genre, original language, country of origin, minimum rating,
  decade and sort, with industry shorthands (Bollywood, Tollywood, K-drama,
  Anime) that stand for a language and country pair. Results load a page at a
  time behind a **Load more** button rather than on scroll.

  TMDB has no notion of dubs — it records a title's *original* language, and
  `with_spoken_language` is silently ignored by its API — so there is no
  honest "dubbed" filter to offer.
- **Watch** — a 16:9 player stage fed by a playback source you configure
  yourself (see below).
- **Trailer** — its own button and its own URL
  (`/watch/movie/603?trailer=1`). Watching the feature and watching the
  trailer are separate intents: asking for one never silently gives you the
  other. With no source configured, the player says so instead of quietly
  substituting a trailer.

Every screen has an address: `/title/movie/603`, `/series?genre=18`,
`/search?q=dune`. Paste a link and it opens where you left it.

## Playback sources

**Freeplix ships with no playback source, and none is hard-coded anywhere in
this repository.** Out of the box it reads its catalogue from TMDB and plays
the official trailers TMDB publishes; pressing **Watch** reports that no
source is configured rather than pretending otherwise.

Freeplix is a catalogue and a player shell. It does not host, index, or
distribute video, and it is not a way to watch films you do not have the right
to watch. If you are deploying it against a library you are licensed to
stream — your own media server, a licensed provider's embed API — point the
build at it with the `FREEPLIX_SOURCES` define:

```jsonc
[
  {
    "id": "library",
    "name": "My Library",
    "movie": "https://example.com/embed/movie/{tmdbId}",
    "tv": "https://example.com/embed/tv/{tmdbId}/{season}/{episode}"
  }
]
```

`{tmdbId}`, `{season}` and `{episode}` are substituted at play time. List more
than one and a switcher appears under the player, with the trailer alongside
them as a peer rather than a fallback. Whatever you point it
at is loaded in a sandboxed iframe with `allow-popups` and
`allow-top-navigation` withheld, so an embed cannot open windows or steer the
page out from under the reader.

Please check your own licensing position before configuring a source. Whoever
deploys the build is responsible for what it points at.

## Running it

Requires [FVM](https://fvm.app/) — the project is pinned to Flutter **3.44.8**.

```bash
fvm install
fvm flutter pub get

cp .env.example .env       # then paste in your TMDB key
fvm flutter run -d chrome --dart-define-from-file=.env
```

Get a TMDB key from your [API settings](https://www.themoviedb.org/settings/api).
The v4 read access token is preferred; the v3 key is a fallback.

> The key is compiled into the client bundle, as it is in any browser-only TMDB
> app — it is visible to anyone who opens devtools. Use a read-only key, and
> keep `.env` out of version control (it is already in `.gitignore`).

Build a release bundle:

```bash
fvm flutter build web --release \
  --base-href "/Freeplix/" \
  --dart-define-from-file=.env
```

## Architecture

MVP with BLoC — a thin view layer over cubits and blocs, over repositories,
over the API.

```
lib/
  core/
    config/      build-time config and the playback source registry
    network/     Dio client and the errors the UI can act on
    router/      go_router — every screen has a URL
    theme/       colour, type, spacing and motion tokens
    widgets/     the shared kit: poster cards, carousels, states
  data/
    models/      TMDB payloads, parsed defensively
    repositories/ TMDB and the local watchlist
  features/
    home/ browse/ search/ details/ watch/ watchlist/
      bloc/      state
      view/      screens
      widgets/   parts that belong to one feature
  shell/         persistent navigation chrome
```

State lives in blocs and cubits; views are `flutter_hooks` widgets that read
state and emit intent. Networking is `dio`. Nothing is code-generated — every
file here is hand-written and readable.

Scaffolded with [Very Good CLI](https://cli.vgv.dev/).

## Design

The interface is built around a projection booth: the cool silver of a lit
screen in front of you, the warm tungsten of the lamp behind you, and the dark
of the room everywhere else. Carousels run between two strips of film
perforation and warm toward the lamp as you move through them.

Type is Bricolage Grotesque for display, Inter Tight for body, and Space Mono
for anything a projectionist would have written on the can — runtimes, years,
reel numbers. All three are bundled (SIL Open Font License; the licence texts
ship alongside them in `assets/fonts/`), so nothing is fetched from a font CDN
at runtime.

## Deployment

Releases are tag-driven. Nothing deploys on a push or a pull request:

```bash
git tag v1.0.2 && git push origin v1.0.2
```

`release.yaml` then runs `flutter analyze` and `flutter test`, builds the web
bundle, attaches it to a GitHub Release as a zip, and publishes it to Pages.

Repository secrets, under **Settings → Secrets and variables → Actions**:

| Secret | Required | Purpose |
| --- | --- | --- |
| `TMDB_API_READ_ACCESS_TOKEN` | yes | TMDB v4 read token |
| `TMDB_API_KEY` | fallback | TMDB v3 key |
| `FREEPLIX_SOURCES` | no | JSON array of playback sources |

> The TMDB key is compiled into the published bundle and is readable by anyone
> who opens devtools. A repository secret keeps it out of the source and the
> build logs, but it cannot keep it out of the artifact — the browser needs the
> key to call TMDB directly. This is inherent to every backend-less client, so
> use a read-only key and rotate it if it is ever abused.

Two pieces of one-time setup that the workflow token cannot do for itself:

- **Enable Pages.** `GITHUB_TOKEN` is not allowed to create a Pages site, so
  `enablement: true` fails on a repo that has never had Pages. Turn it on once
  under **Settings → Pages → Source: GitHub Actions**.
- **Allow tag deploys.** The `github-pages` environment only accepts
  deployments from branches by default, so a `v*` tag is rejected. Add a
  deployment branch policy for the `v*` **tag** under
  **Settings → Environments → github-pages**.

Because Pages has no SPA rewrite, the build copies `index.html` to `404.html`.
Deep links return a 404 *status* while serving the app, which is what lets
`/title/movie/603` resolve instead of hitting a Pages error page.

## Tests

```bash
fvm flutter test
```

Models, blocs, cubits and the source registry are covered. `flutter analyze`
runs clean under `very_good_analysis` and `bloc_lint`.

## Future work

Freeplix releases to the web only. The iOS and Android projects exist and
compile, but nothing ships them — `release.yaml` builds `flutter build web`
and nothing else.

- **Person pages** — tap a cast member for their filmography
- **Search upgrades** — recent searches, keyboard navigation through results
- **Mobile releases** — iOS (Swift Package Manager is already enabled) and
  Android, once there is somewhere to ship them
- **More locales** — `l10n` is wired, only English and Spanish are filled in
- **A TMDB proxy** — the only way to stop the API key shipping in the client
  bundle, at the cost of no longer being purely static

## Licence and attribution

Freeplix is released under the [MIT licence](LICENSE), for educational use.

This product uses the TMDB API but is not endorsed or certified by TMDB. All
metadata and artwork belong to TMDB and its contributors, under
[TMDB's terms of use](https://www.themoviedb.org/terms-of-use).
