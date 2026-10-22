"""Register and adapt the repository-local Darkvoid style for Rich's CLI."""

from typing import Any, cast

from pygments import styles as pygments_styles

from darkvoid import DARKVOID_COLORS
from rich.default_styles import DEFAULT_STYLES
from rich.style import Style
from rich.syntax import PygmentsSyntaxTheme

# Pygments discovers only built-in styles and installed entry points. Register the
# repository-local style before Rich resolves ``--theme=darkvoid``.
pygments_styles._STYLE_NAME_TO_MODULE_MAP["darkvoid"] = ("darkvoid", "DarkvoidStyle")

# Rich normally paints each syntax cell with the Pygments background. Yazi owns
# the pane background, so retain syntax foregrounds without an opaque rectangle.
_original_syntax_theme_init: Any = PygmentsSyntaxTheme.__init__


def _transparent_syntax_theme_init(
    self: PygmentsSyntaxTheme, *args: object, **kwargs: object
) -> None:
    _original_syntax_theme_init(self, *args, **kwargs)
    self._background_color = cast(Any, None)
    self._background_style = Style.null()


PygmentsSyntaxTheme.__init__ = cast(Any, _transparent_syntax_theme_init)

# Rich's structured renderers use named console styles rather than Pygments.
DEFAULT_STYLES.update(
    {
        "json.bool_false": Style.parse(f"italic {DARKVOID_COLORS['error']}"),
        "json.bool_true": Style.parse(f"italic {DARKVOID_COLORS['number']}"),
        "json.brace": Style.parse(f"bold {DARKVOID_COLORS['punctuation']}"),
        "json.key": Style.parse(f"bold {DARKVOID_COLORS['property']}"),
        "json.null": Style.parse(f"italic {DARKVOID_COLORS['type']}"),
        "json.number": Style.parse(f"bold {DARKVOID_COLORS['number']}"),
        "json.str": Style.parse(DARKVOID_COLORS["string"]),
        "repr.bool_false": Style.parse(f"italic {DARKVOID_COLORS['error']}"),
        "repr.bool_true": Style.parse(f"italic {DARKVOID_COLORS['number']}"),
        "repr.brace": Style.parse(f"bold {DARKVOID_COLORS['punctuation']}"),
        "repr.number": Style.parse(f"bold {DARKVOID_COLORS['number']}"),
        "repr.str": Style.parse(DARKVOID_COLORS["string"]),
        "table.header": Style.parse(f"bold {DARKVOID_COLORS['function']}"),
    }
)
