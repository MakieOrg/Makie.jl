// .vitepress/theme/index.ts
import { h, watch } from "vue";
import type { Theme } from "vitepress";
import DefaultTheme from "vitepress/theme";
import VersionPicker from "./VersionPicker.vue"

import { enhanceAppWithTabs } from "vitepress-plugin-tabs/client";
import "./style.css";

export default {
  extends: DefaultTheme,
  Layout() {
    return h(DefaultTheme.Layout, null, {
      // https://vitepress.dev/guide/extending-default-theme#layout-slots
    });
  },
  async enhanceApp({ app, router, siteData }) {
    enhanceAppWithTabs(app);
    app.component('VersionPicker', VersionPicker);
    // Only run this on the client. Not during build.
    // this function replaces the version in the URL with the stable prefix whenever a
    // new route is navigated to. VitePress does not support relative links all over the site,
    // so urls will go to v0.XY even if we start at stable. This solution is not ideal as
    // there is a noticeable delay between navigating to a new page and editing the url, but it's
    // currently better than nothing, as users are bound to copy versioned links to the docs otherwise
    // which will lead users to outdated docs in the future.
    if (typeof window !== "undefined") {
      function rewriteURL() {
        // DOCUMENTER_NEWEST is defined in versions.js, DOCUMENTER_CURRENT_VERSION and DOCUMENTER_STABLE
        // in siteinfo.js.
        if (
          window.DOCUMENTER_NEWEST === undefined ||
          window.DOCUMENTER_CURRENT_VERSION === undefined ||
          window.DOCUMENTER_STABLE === undefined
        ) {
          return;
        }

        // Current version is newest version, so we can rewrite the url
        if (window.DOCUMENTER_NEWEST === window.DOCUMENTER_CURRENT_VERSION) {
          const rewritten_url = window.location.href.replace(
            window.DOCUMENTER_CURRENT_VERSION,
            window.DOCUMENTER_STABLE
          );
          window.history.replaceState(
            { additionalInformation: "URL rewritten to stable" },
            "Makie",
            rewritten_url
          );
          return;
        }
      }

      // rewrite on router changes through vitepress
      watch(() => router.route.data.relativePath, rewriteURL, {
        immediate: true,
      });
      // also rewrite at initial load
      document.addEventListener("DOMContentLoaded", rewriteURL);
    }
  },
} satisfies Theme;
