// .vitepress/theme/index.ts
import { h, watch } from "vue";
import type { Theme } from "vitepress";
import DefaultTheme from "vitepress/theme";

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
    // Example: Add a global event listener
    // Only run this on the client. Not during build.
    if (typeof window !== "undefined") {
      watch(
        () => router.route.data.relativePath,
        (path) => {
          // DOCUMENTER_NEWEST is defined in versions.js, DOCUMENTER_CURRENT_VERSION and DOCUMENTER_STABLE
          // in siteinfo.js.
          // If either of these are undefined something went horribly wrong, so we abort.
          console.log(window.DOCUMENTER_NEWEST);
          console.log(window.DOCUMENTER_CURRENT_VERSION);
          console.log(window.DOCUMENTER_STABLE);
          if (
            window.DOCUMENTER_NEWEST === undefined ||
            window.DOCUMENTER_CURRENT_VERSION === undefined ||
            window.DOCUMENTER_STABLE === undefined
          ) {
            return;
          }

          // // Current version is not a version number, so we can't tell if it's the newest version. Abort.
          // if (!/v(\d+\.)*\d+/.test(window.DOCUMENTER_CURRENT_VERSION)) {
          //   return;
          // }

          // Current version is newest version, so we can rewrite the url
          // if (window.DOCUMENTER_NEWEST === window.DOCUMENTER_CURRENT_VERSION) {
          if (window.DOCUMENTER_CURRENT_VERSION.startsWith("previews")) {
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
        },
        { immediate: true }
      );
    }
  },
} satisfies Theme;
