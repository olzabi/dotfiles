// Firefox prefs applied on every start (overrides about:config / Settings for these keys).
// Symlinked into the profile by bin/symlinks. Keep to prefs that differ from defaults.

// Web content follows the system color-scheme (0 dark, 1 light, 2 system), so sites switch with darkvoid-mode.
user_pref("layout.css.prefers-color-scheme.content-override", 2);

// Hardware video decode on NVIDIA (blocklisted by default) via libva-nvidia-driver.
// Verify: about:support -> Media -> "Hardware decoding", or `nvidia-smi dmon -s u` dec column while a video plays.
user_pref("media.hardware-video-decoding.force-enabled", true);
user_pref("widget.dmabuf.force-enabled", true);

// Main monitor runs at scale 1.1: render natively instead of upscaled-blurry.
user_pref("widget.wayland.fractional-scale.enabled", true);

// Quieter new tab.
user_pref("browser.newtabpage.activity-stream.showSponsored", false);
user_pref("browser.newtabpage.activity-stream.showSponsoredTopSites", false);
user_pref("browser.newtabpage.activity-stream.feeds.section.topstories", false);

// Load chrome/userChrome.css + userContent.css (darkvoid UI theme).
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);

// English everywhere: UI, what sites are asked to serve, and search region (was geo-detected as UA).
user_pref("intl.locale.requested", "en-US");
user_pref("intl.accept_languages", "en-US, en");
user_pref("browser.search.region", "US");
user_pref("spellchecker.dictionary", "en-US");

// memory: one content process per site instead of up to 4
user_pref("dom.ipc.processCount.webIsolated", 1);
user_pref("browser.ml.linkPreview.optin", false); // runs a local ML model in-browser
user_pref("browser.sessionstore.interval", 60000);
user_pref("browser.cache.disk.capacity", 512000);
user_pref("browser.tabs.unloadOnLowMemory", true); // off by default on Linux
user_pref("browser.sessionhistory.max_total_viewers", 2); // back/forward cache: auto = 8 pages on 62 GB
user_pref("dom.ipc.processPrelaunch.enabled", false); // no spare content process kept warm

// telemetry
user_pref("datareporting.healthreport.uploadEnabled", false);
user_pref("toolkit.telemetry.enabled", false);
user_pref("app.shield.optoutstudies.enabled", false);

// darkvoid / dim-light: pages that set no colours (about:blank, plain text) use the palette, not white/black.
user_pref("browser.display.background_color", "#c6c4c0");
user_pref("browser.display.foreground_color", "#393734");
user_pref("browser.display.background_color.dark", "#1c1c1c");
user_pref("browser.display.foreground_color.dark", "#c0c0c0");
// The built-in "System theme — auto": a Firefox colour theme (e.g. Nova Ash) overrides userChrome.css colours.
user_pref("extensions.activeThemeID", "default-theme@mozilla.org");

// Reopen last session's windows and tabs, in both profiles (main and bin/firefox-side).
user_pref("browser.startup.page", 3);
