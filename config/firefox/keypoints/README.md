# keypoints

Dataset side of the Firefox highlighter (`../userscripts/keypoints.user.js`, Ctrl+Alt+K or F2).

- `keypoints serve` (`keypoints.service`): the userscript POSTs every page you read 30s+ (text only) and every page you highlight to `127.0.0.1:11500/pages`; stored in `~/.local/share/keypoints/pages.jsonl`. Requires an `X-Keypoints` header, which web pages cannot send cross-origin.
- `keypoints label --if-idle` (`keypoints-label.timer`, nightly 04:00, max 2h): `qwen3:30b-a3b` re-marks new pages into `labels.jsonl`, skipped if the GPU is busy, VRAM freed after. Desktop notification with the result.
- `keypoints stats`: captures, labelled pages, languages.

Userscript: open http://127.0.0.1:11500/keypoints.user.js in Firefox once; Violentmonkey updates from there (bump `@version`).

Install:

```sh
ln -s ~/Dotfiles/config/firefox/keypoints/keypoints{.service,-label.service,-label.timer} ~/.config/systemd/user/
systemctl --user daemon-reload && systemctl --user enable --now keypoints.service keypoints-label.timer
```

Env: `KEYPOINTS_DIR`, `KEYPOINTS_PORT`, `KEYPOINTS_TEACHER`, `KEYPOINTS_OLLAMA`.

Later: train a small multilingual model from `labels.jsonl`, serve it from `keypoints serve`, and let the userscript fall back to Ollama when it is unsure.
