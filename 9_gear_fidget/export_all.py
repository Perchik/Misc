import subprocess
import pathlib
import re

# -------------------------------------------------
# CONFIG
# -------------------------------------------------

OPENSCAD=r"C:\Program Files\OpenSCAD (Nightly)\openscad.exe"
#OPENSCAD = r"C:\Program Files\OpenSCAD\openscad.exe"
SCAD_FILE = "9_gear_fidget.scad"

OUT_DIR = pathlib.Path("exports")
OUT_DIR.mkdir(exist_ok=True)


# -------------------------------------------------
# PARTS TO EXPORT
# -------------------------------------------------

PARTS = [
    ("lower_frame",        "lower_frame"),
    ("upper_frame",        "upper_frame"),
    ("center_gear",        "center_gear"),
    ("round_gear_x8",      "round_gear"),
    ("center_journal_x2",  "center_journal"),
    ("center_shaft",       "center_shaft"),
]


# -------------------------------------------------
# STL EXPORT
# -------------------------------------------------

for name, export_key in PARTS:
    out = OUT_DIR / f"{name}.stl"
    cmd = [
    OPENSCAD, 
    "--backend=Manifold",
    "-o", str(out),
    "-D", f'EXPORT_PART="{export_key}"',
    SCAD_FILE,
]

    print("STL:", out.name)
    subprocess.run(cmd, check=True)

# -------------------------------------------------
# PNG RENDERS
# -------------------------------------------------

def render_png(filename, define):
    out = OUT_DIR / filename
    cmd = [
        OPENSCAD,   
        "--backend=Manifold",
        "--render",
        "--imgsize=2000,2000",
        "--projection=ortho",
        "-o", str(out),
        "-D", define,
        SCAD_FILE,
    ]
    print("PNG:", out.name)
    subprocess.run(cmd, check=True)


render_png("assembly.png", "RENDER_ASSEMBLY=true")

print("Done.")
