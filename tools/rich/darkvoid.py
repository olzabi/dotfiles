"""Pygments style derived from Hunk's custom Darkvoid theme."""

from __future__ import annotations

import os
import tomllib
from pathlib import Path

from pygments.style import Style
from pygments.token import (
    Comment,
    Error,
    Generic,
    Keyword,
    Name,
    Number,
    Operator,
    Punctuation,
    String,
    Text,
    Token,
)

_DEFAULTS = {
    "background": "#1c1c1c",
    "text": "#c0c0c0",
    "selectedHunk": "#303030",
    "muted": "#585858",
    "default": "#c0c0c0",
    "keyword": "#f1f1f1",
    "string": "#d1d1d1",
    "comment": "#585858",
    "number": "#b2d8d8",
    "function": "#e1e1e1",
    "property": "#b1b1b1",
    "type": "#a1a1a1",
    "variable": "#b1b1b1",
    "operator": "#1bfd9c",
    "punctuation": "#e6e6e6",
    "error": "#dea6a0",
}


def _load_colors() -> dict[str, str]:
    config_home = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config"))
    try:
        with (config_home / "hunk" / "config.toml").open("rb") as config_file:
            custom = tomllib.load(config_file)["custom_theme"]
    except (OSError, KeyError, tomllib.TOMLDecodeError):
        return _DEFAULTS.copy()

    colors = _DEFAULTS.copy()
    for key in ("background", "text", "selectedHunk", "muted"):
        if isinstance(custom.get(key), str):
            colors[key] = custom[key]
    syntax = custom.get("syntax", {})
    if isinstance(syntax, dict):
        for key in (
            "default",
            "keyword",
            "string",
            "comment",
            "number",
            "function",
            "property",
            "type",
            "variable",
            "operator",
            "punctuation",
        ):
            if isinstance(syntax.get(key), str):
                colors[key] = syntax[key]
    return colors


DARKVOID_COLORS = _load_colors()


class DarkvoidStyle(Style):
    """Darkvoid syntax colors, with Hunk's custom theme as the source of truth."""

    background_color = DARKVOID_COLORS["background"]
    highlight_color = DARKVOID_COLORS["selectedHunk"]
    default_style = DARKVOID_COLORS["default"]

    styles = {
        Token: DARKVOID_COLORS["default"],
        Text: DARKVOID_COLORS["default"],
        Comment: DARKVOID_COLORS["comment"],
        Keyword: DARKVOID_COLORS["keyword"],
        Keyword.Operator: f"bold {DARKVOID_COLORS['operator']}",
        Keyword.Constant: f"bold {DARKVOID_COLORS['number']}",
        Name: DARKVOID_COLORS["variable"],
        Name.Tag: f"bold {DARKVOID_COLORS['property']}",
        Name.Function: DARKVOID_COLORS["function"],
        Name.Class: DARKVOID_COLORS["type"],
        Name.Builtin: DARKVOID_COLORS["type"],
        Name.Attribute: DARKVOID_COLORS["property"],
        String: DARKVOID_COLORS["string"],
        Number: DARKVOID_COLORS["number"],
        Operator: f"bold {DARKVOID_COLORS['operator']}",
        Punctuation: DARKVOID_COLORS["punctuation"],
        Error: DARKVOID_COLORS["error"],
        Generic.Error: DARKVOID_COLORS["error"],
    }
