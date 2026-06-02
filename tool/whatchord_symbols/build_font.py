#!/usr/bin/env python3
"""Build the "WhatChord Symbols" font family.

Extracts a handful of source glyphs from local Leland .otf files (SMuFL/CFF
fonts) and emits small dedicated fonts that contain only those glyphs, remapped
to the target codepoints declared in glyph_map.txt.

Upstream Leland ships a single weight, so the Bold instance is *synthesized*:
each outline is stroked and unioned back onto itself, thickening every stem
uniformly. The two instances share a family name so the OS bold toggle links
them.

Run with:  mise run symbols:build
       or:  python tool/whatchord_symbols/build_font.py
"""

import re
import sys
import time
from dataclasses import dataclass
from pathlib import Path

import pathops
from fontTools.ttLib import TTFont, newTable
from fontTools.ttLib.tables._c_m_a_p import cmap_format_4, cmap_format_12
from fontTools.subset import Subsetter, Options
from fontTools.pens.boundsPen import BoundsPen
from fontTools.pens.t2CharStringPen import T2CharStringPen
from fontTools.pens.transformPen import TransformPen

TOOL_DIR = Path(__file__).resolve().parent
REPO_ROOT = TOOL_DIR.parents[1]
DEFAULT_SOURCE_FONT = TOOL_DIR / "LelandText.otf"
MAPPING_FILE = TOOL_DIR / "glyph_map.txt"
OUTPUT_DIR = REPO_ROOT / "assets/fonts"

FAMILY_NAME = "WhatChord Symbols"
VERSION = "1.001"
VENDOR_ID = "    "  # blank (4 spaces); avoids inheriting FontForge's 'PfEd'

# Extra horizontal breathing room added to EACH side of every glyph, in font
# units (this font is 1000 units/em, so 80 == 8% of the em per side). The source
# SMuFL glyphs ship with ~0 sidebearing because a music engraver spaces them
# externally; as standalone text symbols they look cramped. Set to 0 to disable.
SIDE_PAD = 80

# Bold emboldening: how far (font units) each outline edge is pushed outward.
# Stems thicken by 2*BOLD_STRENGTH; ~20 gives a solid bold at 1000 units/em.
# Larger = heavier (counters in the sharp/flat stay open up to ~40 or so).
BOLD_STRENGTH = 20

# Identity/licensing metadata is intentionally NOT carried inside the font:
# attribution and the SIL OFL text for the upstream Leland font live in the
# consuming repo's NOTICE.md, which travels with the .otf and satisfies OFL 1.1
# (the "stand-alone text files" route in clause 2). Keeping it out of the binary
# also keeps the font small.


@dataclass(frozen=True)
class Instance:
    """One weight in the family."""
    subfamily: str        # name ID 2, e.g. "Regular" / "Bold"
    ps_name: str          # PostScript name (no spaces, ASCII)
    weight_class: int     # OS/2 usWeightClass
    bold: bool            # set the bold selection bits + embolden outlines

    @property
    def full_name(self) -> str:
        # Regular is conventionally omitted from the full name.
        if self.subfamily == "Regular":
            return FAMILY_NAME
        return f"{FAMILY_NAME} {self.subfamily}"

    @property
    def output(self) -> str:
        # Filename mirrors the PostScript name (Family-Style.otf convention).
        return f"{self.ps_name}.otf"

    @property
    def output_path(self) -> Path:
        return OUTPUT_DIR / self.output


INSTANCES = [
    Instance("Regular", "WhatChordSymbols-Regular", 400, False),
    Instance("Bold", "WhatChordSymbols-Bold", 700, True),
]


@dataclass(frozen=True)
class MappingRow:
    source_font: Path
    source_cp: int
    target_cp: int


_ROW_RE = re.compile(
    r"""^\s*
        (?:(?P<font>[-A-Za-z0-9_.]+):)?
        U\+(?P<src>[0-9A-Fa-f]+)
        \s*->\s*
        U\+(?P<dst>[0-9A-Fa-f]+)""",
    re.VERBOSE,
)


def parse_mapping(path: Path) -> list[MappingRow]:
    """Return mapping rows with their source font, source CP, and target CP."""
    rows: list[MappingRow] = []
    for lineno, raw in enumerate(path.read_text().splitlines(), 1):
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        m = _ROW_RE.match(line)
        if not m:
            sys.exit(f"{path}:{lineno}: could not parse mapping row: {raw!r}")
        source_name = m["font"] or DEFAULT_SOURCE_FONT.name
        source_font = (TOOL_DIR / source_name).resolve()
        if source_font.parent != TOOL_DIR.resolve():
            sys.exit(f"{path}:{lineno}: source font must live in {TOOL_DIR}")
        rows.append(
            MappingRow(
                source_font=source_font,
                source_cp=int(m["src"], 16),
                target_cp=int(m["dst"], 16),
            )
        )
    if not rows:
        sys.exit(f"{path}: no mapping rows found")
    return rows


def _load_source_fonts(rows: list[MappingRow]) -> dict[Path, TTFont]:
    fonts: dict[Path, TTFont] = {}
    for path in {row.source_font for row in rows}:
        if not path.exists():
            sys.exit(f"Source font not found: {path}")
        fonts[path] = TTFont(path)
    return fonts


def _reserve_placeholder_codepoints(
    primary_font: TTFont,
    used_primary_source_cps: set[int],
    count: int,
) -> list[int]:
    """Find unused primary-font codepoints to hold copied-in foreign glyphs."""
    if count == 0:
        return []

    cmap_codepoints = sorted(primary_font.getBestCmap())

    placeholders: list[int] = []
    for cp in [cp for cp in cmap_codepoints if cp >= 0xE000] + [
        cp for cp in cmap_codepoints if 0x20 <= cp < 0xE000
    ]:
        if cp in used_primary_source_cps:
            continue
        placeholders.append(cp)
        if len(placeholders) == count:
            return placeholders

    sys.exit(
        f"{DEFAULT_SOURCE_FONT}: need {count} unused placeholder glyph(s), "
        f"but found only {len(placeholders)}."
    )


def _draw_source_glyph(font: TTFont, gname: str) -> pathops.Path:
    glyph_set = font.getGlyphSet()
    path = pathops.Path()
    glyph_set[gname].draw(path.getPen(glyphSet=glyph_set))
    return path


def resolve_glyphs(
    primary_font: TTFont,
    source_fonts: dict[Path, TTFont],
    rows: list[MappingRow],
) -> tuple[dict[int, str], dict[str, tuple[TTFont, str, int]]]:
    """Map each target codepoint to an output glyph name.

    The output font is subset from LelandText. Rows that source glyphs from
    another font reserve a spare LelandText glyph slot; its outline is replaced
    after subsetting.
    """
    primary_cmap = primary_font.getBestCmap()
    target_to_glyph: dict[int, str] = {}
    replacement_by_output_glyph: dict[str, tuple[TTFont, str, int]] = {}

    primary_source_cps = {
        row.source_cp
        for row in rows
        if row.source_font == DEFAULT_SOURCE_FONT.resolve()
    }
    foreign_rows = [
        row for row in rows if row.source_font != DEFAULT_SOURCE_FONT.resolve()
    ]
    placeholders = iter(
        _reserve_placeholder_codepoints(
            primary_font,
            primary_source_cps,
            len(foreign_rows),
        )
    )

    for row in rows:
        source_font = source_fonts[row.source_font]
        source_cmap = source_font.getBestCmap()
        source_gname = source_cmap.get(row.source_cp)
        if source_gname is None:
            sys.exit(
                f"Source U+{row.source_cp:04X} not found in "
                f"{row.source_font.name}'s cmap. Fix the SOURCE_CP in "
                f"{MAPPING_FILE}."
            )
        if row.target_cp in target_to_glyph:
            sys.exit(f"Target U+{row.target_cp:04X} is mapped more than once.")

        if row.source_font == DEFAULT_SOURCE_FONT.resolve():
            output_gname = source_gname
        else:
            placeholder_cp = next(placeholders)
            output_gname = primary_cmap[placeholder_cp]
            replacement_by_output_glyph[output_gname] = (
                source_font,
                source_gname,
                source_font["hmtx"][source_gname][0],
            )

        target_to_glyph[row.target_cp] = output_gname
        print(
            f"  {row.source_font.name}:U+{row.source_cp:04X} "
            f"({source_gname})  ->  U+{row.target_cp:04X}"
        )

    return target_to_glyph, replacement_by_output_glyph


def primary_subset_codepoints(
    rows: list[MappingRow],
    primary_font: TTFont,
) -> list[int]:
    """Return primary-font codepoints needed before cmap remapping."""
    primary_cps = [
        row.source_cp
        for row in rows
        if row.source_font == DEFAULT_SOURCE_FONT.resolve()
    ]
    foreign_count = sum(
        1 for row in rows if row.source_font != DEFAULT_SOURCE_FONT.resolve()
    )
    return primary_cps + _reserve_placeholder_codepoints(
        primary_font,
        set(primary_cps),
        foreign_count,
    )


def replace_foreign_glyphs(
    font: TTFont,
    replacements: dict[str, tuple[TTFont, str, int]],
) -> None:
    """Replace placeholder outlines with glyphs copied from non-primary fonts."""
    hmtx = font["hmtx"]
    for output_gname, (source_font, source_gname, advance) in replacements.items():
        path = _draw_source_glyph(source_font, source_gname)
        _set_charstring(font, output_gname, path, advance)
        hmtx[output_gname] = (advance, hmtx[output_gname][1])


def build_cmap(mapping: dict[int, str]) -> "newTable":
    """Build a cmap table with a BMP (format 4) and full (format 12) subtable."""
    cmap = newTable("cmap")
    cmap.tableVersion = 0

    def make_format_4(platform_id: int, encoding_id: int) -> cmap_format_4:
        subtable = cmap_format_4(4)
        subtable.platformID = platform_id
        subtable.platEncID = encoding_id
        subtable.language = 0
        subtable.cmap = {cp: gn for cp, gn in mapping.items() if cp <= 0xFFFF}
        return subtable

    def make_format_12(platform_id: int, encoding_id: int) -> cmap_format_12:
        subtable = cmap_format_12(12)
        subtable.platformID = platform_id
        subtable.platEncID = encoding_id
        subtable.reserved = 0
        subtable.length = 0
        subtable.language = 0
        subtable.nGroups = 0
        subtable.cmap = dict(mapping)
        return subtable

    subtables = [
        make_format_4(0, 3),  # Unicode BMP, useful for macOS font inspection.
        make_format_4(3, 1),  # Windows Unicode BMP.
    ]

    # Only add a format-12 subtable if we actually have astral codepoints,
    # but include the full mapping when we do (format 12 supersedes 4).
    if any(cp > 0xFFFF for cp in mapping):
        subtables.extend(
            [
                make_format_12(0, 4),  # Unicode full repertoire.
                make_format_12(3, 10),  # Windows Unicode full repertoire.
            ]
        )

    cmap.tables = subtables
    return cmap


def set_names(font: TTFont, inst: Instance) -> None:
    """Replace the name table with WhatChord Symbols metadata."""
    name = font["name"]
    name.names = []  # wipe inherited Leland names
    values = {
        1: FAMILY_NAME,                          # Family
        2: inst.subfamily,                       # Subfamily
        3: f"{inst.ps_name};{VERSION}",          # Unique ID
        4: inst.full_name,                       # Full name
        5: f"Version {VERSION}",                 # Version string
        6: inst.ps_name,                         # PostScript name
    }
    for nid, val in values.items():
        # Windows (3,1,0x409) and Mac (1,0,0) records for broad compatibility.
        name.setName(val, nid, 3, 1, 0x409)
        name.setName(val, nid, 1, 0, 0)


def rename_cff(font: TTFont, inst: Instance) -> None:
    """Rewrite the CFF-internal identity, which the name table does NOT cover.

    Also drops the inherited Notice (Leland trademark) and Copyright (OFL text);
    that attribution is carried in the consuming repo's NOTICE.md instead.
    """
    cff = font["CFF "].cff
    top = cff[cff.fontNames[0]]
    cff.fontNames = [inst.ps_name]
    top.FullName = inst.full_name
    top.FamilyName = FAMILY_NAME
    top.Weight = inst.subfamily
    top.version = VERSION
    for key in ("Notice", "Copyright"):
        top.rawDict.pop(key, None)
        if hasattr(top, key):
            delattr(top, key)


def _set_charstring(font: TTFont, gname: str, path, advance: int) -> None:
    """Replace one glyph's CFF charstring from a pen-drawable `path`."""
    cff = font["CFF "].cff
    top = cff[cff.fontNames[0]]
    pen = T2CharStringPen(advance, font.getGlyphSet())
    path.draw(pen)
    new_cs = pen.getCharString(top.Private, top.GlobalSubrs)
    cs = top.CharStrings[gname]
    cs.program = new_cs.program
    cs.bytecode = None  # force recompile from the new program


def embolden_glyphs(font: TTFont, strength: int) -> None:
    """Synthesize bold by stroking each outline and unioning it onto the fill.

    Pushes every edge outward by `strength` units (stems gain 2*strength), using
    a miter join so the geometric corners of the accidentals stay crisp.
    """
    if strength == 0:
        return
    glyph_set = font.getGlyphSet()
    hmtx = font["hmtx"]
    for gname in font.getGlyphOrder():
        fill = pathops.Path()
        glyph_set[gname].draw(fill.getPen(glyphSet=glyph_set))
        stroked = pathops.Path()
        glyph_set[gname].draw(stroked.getPen(glyphSet=glyph_set))
        stroked.stroke(
            2 * strength,
            pathops.LineCap.BUTT_CAP,
            pathops.LineJoin.MITER_JOIN,
            4.0,
        )
        builder = pathops.OpBuilder(fix_winding=True, keep_starting_points=False)
        builder.add(fill, pathops.PathOp.UNION)
        builder.add(stroked, pathops.PathOp.UNION)
        result = builder.resolve()
        # Advance is normalized afterwards by set_sidebearings; keep current.
        _set_charstring(font, gname, result, hmtx[gname][0])


def set_sidebearings(font: TTFont, pad: int) -> None:
    """Give every glyph exactly `pad` units of space on each side.

    Absolute (not additive): the outline is shifted so its left edge sits at
    `pad`, and the advance is set to ink-width + 2*pad. Works the same whether or
    not the glyph was just emboldened.
    """
    glyph_set = font.getGlyphSet()
    hmtx = font["hmtx"]
    for gname in font.getGlyphOrder():
        bp = BoundsPen(glyph_set)
        glyph_set[gname].draw(bp)
        if bp.bounds is None:  # empty glyph (no contours): just set advance
            hmtx[gname] = (2 * pad, pad)
            continue
        x0, _, x1, _ = bp.bounds
        shift = pad - x0
        new_adv = round((x1 + shift) + pad)
        path = pathops.Path()
        glyph_set[gname].draw(TransformPen(path.getPen(glyphSet=glyph_set),
                                           (1, 0, 0, 1, shift, 0)))
        _set_charstring(font, gname, path, new_adv)
        hmtx[gname] = (new_adv, round(pad))


def recompute_bounds(font: TTFont) -> None:
    """Refresh head and CFF FontBBox to enclose all (possibly shifted) glyphs."""
    glyph_set = font.getGlyphSet()
    box = None
    for gname in font.getGlyphOrder():
        bp = BoundsPen(glyph_set)
        glyph_set[gname].draw(bp)
        if bp.bounds is None:
            continue
        x0, y0, x1, y1 = bp.bounds
        if box is None:
            box = [x0, y0, x1, y1]
        else:
            box = [min(box[0], x0), min(box[1], y0),
                   max(box[2], x1), max(box[3], y1)]
    if box is None:
        return
    ibox = [round(v) for v in box]
    head = font["head"]
    head.xMin, head.yMin, head.xMax, head.yMax = ibox
    font["CFF "].cff[font["CFF "].cff.fontNames[0]].FontBBox = ibox


def fix_metadata(font: TTFont, inst: Instance) -> None:
    """Correct head/OS-2 fields inherited from Leland and set weight bits."""
    head = font["head"]
    head.fontRevision = float(VERSION)  # match name-table "Version 1.000"
    head.modified = int(time.time()) - 2082844800  # now, in Mac font epoch
    head.macStyle = (head.macStyle & ~0x01) | (0x01 if inst.bold else 0)

    os2 = font["OS/2"]
    os2.achVendID = VENDOR_ID
    os2.usWeightClass = inst.weight_class
    # fsSelection: clear ITALIC/BOLD/REGULAR, then set the right one.
    fs = os2.fsSelection & ~(0x01 | 0x20 | 0x40)
    os2.fsSelection = fs | (0x20 if inst.bold else 0x40)
    # Recompute Unicode coverage bits (Leland's claimed the PUA, now untrue).
    os2.recalcUnicodeRanges(font, pruneOnly=False)

    # GSUB/GPOS survived subsetting as empty shells (0 features, 0 lookups).
    for tag in ("GSUB", "GPOS"):
        if tag in font:
            del font[tag]


def build_instance(rows: list[MappingRow], inst: Instance) -> None:
    """Build and save one weight."""
    source_fonts = _load_source_fonts(rows)
    font = TTFont(DEFAULT_SOURCE_FONT)
    target_to_glyph, replacements = resolve_glyphs(font, source_fonts, rows)

    # Subset down to just the glyphs we want (handles CFF, hmtx, layout tables).
    options = Options()
    options.name_IDs = ["*"]
    options.name_legacy = True
    options.name_languages = ["*"]
    options.notdef_outline = True
    options.recalc_bounds = True
    options.drop_tables = ["DSIG"]
    subsetter = Subsetter(options=options)
    subsetter.populate(unicodes=primary_subset_codepoints(rows, font))
    subsetter.subset(font)

    replace_foreign_glyphs(font, replacements)

    # Rebuild the cmap at the target codepoints.
    font["cmap"] = build_cmap(target_to_glyph)

    # Identity, scrub Leland from the CFF interior, and weight metadata.
    set_names(font, inst)
    rename_cff(font, inst)
    fix_metadata(font, inst)

    # Geometry: embolden (bold only), normalize sidebearings, refresh bounds.
    if inst.bold:
        embolden_glyphs(font, BOLD_STRENGTH)
    set_sidebearings(font, SIDE_PAD)
    recompute_bounds(font)

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    font.save(inst.output_path)
    print(f"Wrote {inst.output_path} ({inst.subfamily}, "
          f"{len(target_to_glyph)} glyph(s)).\n")


def main() -> None:
    rows = parse_mapping(Path(MAPPING_FILE))
    for inst in INSTANCES:
        build_instance(rows, inst)


if __name__ == "__main__":
    main()
