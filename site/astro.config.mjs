// @ts-check
import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';

// https://astro.build/config
export default defineConfig({
  integrations: [
    starlight({
      title: 'OpenNook',
      description: 'An open-source framework for building macOS notch apps.',
      social: [
        {
          icon: 'github',
          label: 'GitHub',
          href: 'https://github.com/glendonC/opennook',
        },
      ],
      defaultLocale: 'en',
      // Dark mode by default; users can still toggle to light.
      // Starlight uses `prefers-color-scheme` by default — pin to dark.
      // The `head` injection sets the initial theme attribute.
      head: [
        {
          tag: 'script',
          content:
            "try { if (!localStorage.getItem('starlight-theme')) { document.documentElement.dataset.theme = 'dark'; } } catch (e) {}",
        },
      ],
      sidebar: [
        {
          label: 'Start',
          items: [
            { label: 'Introduction', slug: 'start/introduction' },
            { label: 'Install', slug: 'start/install' },
            { label: 'Your first nook', slug: 'start/first-nook' },
          ],
        },
        {
          label: 'Guides',
          items: [
            { label: 'Multiple modules', slug: 'guides/multiple-modules' },
            { label: 'File shelf', slug: 'guides/file-shelf' },
            { label: 'Activity queue', slug: 'guides/activity-queue' },
            { label: 'Volume glyph', slug: 'guides/volume-glyph' },
            { label: 'Theming', slug: 'guides/theming' },
            { label: 'Settings chrome', slug: 'guides/settings-chrome' },
          ],
        },
        {
          label: 'Reference',
          items: [
            { label: 'API reference', slug: 'reference/api' },
          ],
        },
      ],
    }),
  ],
});
