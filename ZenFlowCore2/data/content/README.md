# SPIFFS/SD content (Phase 4)

This `data/` directory is flashed to the SPIFFS partition with
`pio run -t uploadfs`. Ambient sound assets and any large JSON content go here.

Planned layout for Phase 4 (ambient sounds + daily Zen moment):

```
data/
└── content/
    ├── sounds/           # 16-bit mono/stereo WAV loops (from ZenFlow/Assets.xcassets/Sounds)
    │   ├── rain.wav
    │   ├── ocean.wav
    │   └── ...
    └── quotes.json       # optional: externalized Zen quotes/teachings
```

Compiled-in content (breathing patterns, intents, quotes, tree/badge tables)
currently lives in `src/content.cpp` and needs no SD card. Only bulky audio
requires this partition.
