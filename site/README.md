# opennook-site

The OpenNook documentation site. Astro 5 + Starlight, deployed to
Cloudflare Pages.

## Install

```sh
cd site
npm install
```

## Develop

```sh
npm run dev
```

Serves at `http://localhost:4321`.

## Build

```sh
npm run build      # output -> dist/
npm run preview    # serve the built site locally
```

## Deploy: Cloudflare Pages

Connect the GitHub repo to Cloudflare Pages and use:

- **Framework preset:** Astro
- **Build command:** `npm run build`
- **Build output directory:** `dist`
- **Root directory:** `site`
- **Node version:** 20 or later

No `wrangler.toml` is needed for a Pages project configured through the
dashboard. Add one only if you switch to a `wrangler`-driven deploy.

## Structure

```
site/
  astro.config.mjs           Starlight integration, sidebar, social links.
  package.json
  tsconfig.json
  src/
    content.config.ts        Starlight docs collection (docsLoader/docsSchema).
    content/docs/
      index.mdx              Splash landing page.
      start/                 Introduction, install, first nook.
      guides/                Components + theming + chrome guides.
      reference/             API reference (points at Swift Package Index).
```

## Editing content

All pages are MDX under `src/content/docs/`. Sidebar order is declared in
`astro.config.mjs`. Use Starlight's built-in components (`Card`,
`CardGrid`, `Code`, `Tabs`, etc.) by importing from
`@astrojs/starlight/components`.
