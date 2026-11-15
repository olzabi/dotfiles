// Firefox prefs applied on every start (overrides about:config / Settings for these keys).
// Symlinked into the profile by bin/symlinks. Keep to prefs that differ from defaults.

// Dark web content: report prefers-color-scheme: dark to sites (Google, GitHub, ...).
user_pref("layout.css.prefers-color-scheme.content-override", 0);

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

// telemetry
user_pref("datareporting.healthreport.uploadEnabled", false);
user_pref("toolkit.telemetry.enabled", false);
user_pref("app.shield.optoutstudies.enabled", false);
