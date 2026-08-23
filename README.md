# Freeplix

An open-source, ad-free movie and TV **catalogue**, built with Flutter and
powered by the [TMDB API](https://www.themoviedb.org/). One codebase, web
first; iOS and Android are wired up but not yet the focus.

**Live:** https://iamnabink.github.io/Freeplix/

No accounts. No backend. No tracking. No ads.

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

Two workflows:

- **`pages.yaml`** — every push to `main` rebuilds and republishes GitHub Pages.
- **`release.yaml`** — pushing a `v*` tag runs the checks, cuts a GitHub
  Release with the static bundle attached, and deploys the same build.

Set these repository secrets under **Settings → Secrets and variables →
Actions**:

| Secret | Required | Purpose |
| --- | --- | --- |
| `TMDB_API_READ_ACCESS_TOKEN` | yes | TMDB v4 read token |
| `TMDB_API_KEY` | fallback | TMDB v3 key |
| `FREEPLIX_SOURCES` | no | JSON array of playback sources |

Then set **Settings → Pages → Source** to **GitHub Actions**.

Because Pages has no SPA rewrite, the build copies `index.html` to `404.html`
so deep links reach the router instead of a Pages 404.

## Tests

```bash
fvm flutter test
```

Models, blocs, cubits and the source registry are covered. `flutter analyze`
runs clean under `very_good_analysis` and `bloc_lint`.

## Roadmap

- iOS and Android builds (Swift Package Manager is already the iOS default in
  3.44)
- Continue-watching progress, kept locally
- Person pages and filmographies
- More locales — `l10n` is wired, only English and Spanish are filled in

## Licence and attribution

Freeplix is released under the [MIT licence](LICENSE), for educational use.

This product uses the TMDB API but is not endorsed or certified by TMDB. All
metadata and artwork belong to TMDB and its contributors, under
[TMDB's terms of use](https://www.themoviedb.org/terms-of-use).
