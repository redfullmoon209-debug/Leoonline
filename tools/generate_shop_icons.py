#!/usr/bin/env python3
"""Draw 21 independent transparent PNG icons for shop products.

Original art constructed from polygons/gradients. No images are cropped,
recolored, generated from screenshots, or baked with item-name text.
This file is intentionally deterministic so future catalog additions remain simple.
"""
from __future__ import annotations
from pathlib import Path
import hashlib, json, math
from PIL import Image, ImageDraw

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/"assets"/"ui"/"shop"
OUT.mkdir(parents=True,exist_ok=True)
S=4
SIZE=96
GOLD=(236,178,80,255)
LIGHT=(255,232,176,255)
DARK=(55,24,31,255)

def p(points):
    return [(round(a*S),round(b*S)) for a,b in points]

def box(a,b,c,d):
    return tuple(round(z*S) for z in [a,b,c,d])

def canvas():
    return Image.new("RGBA",(SIZE*S,SIZE*S),(0,0,0,0))

def save(image,name):
    path=OUT/f"{name}.png"
    image.resize((SIZE,SIZE),Image.Resampling.LANCZOS).save(path,optimize=True)

def potion(kind,size):
    image=canvas()
    d=ImageDraw.Draw(image)
    low={"small":68,"medium":75,"large":82}[size]
    upper={"small":32,"medium":26,"large":20}[size]
    radii={"small":(29,67),"medium":(24,72),"large":(18,78)}[size]
    color=(226,28,60,255) if kind=="hp" else (17,142,252,255)
    shadow=(128,7,44,255) if kind=="hp" else (9,65,141,255)
    d.ellipse(box(20,81,77,87),fill=(15,7,14,75))
    d.rounded_rectangle(box(42,10,54,29),radius=2*S,fill=(111,65,40,245),outline=LIGHT,width=2*S)
    d.rounded_rectangle(box(38,7,59,17),radius=3*S,fill=(155,103,52,255),outline=GOLD,width=2*S)
    outline=[(40,upper),(56,upper),(radii[1]-5,upper+13),(radii[1],upper+20),
             (radii[1],low-8),(radii[1]-8,low+5),(radii[0]+8,low+5),
             (radii[0],low-8),(radii[0],upper+20),(radii[0]+5,upper+13)]
    d.polygon(p(outline),fill=(28,37,65,242))
    d.line(p(outline+[outline[0]]),fill=LIGHT,width=3*S,joint="curve")
    left=radii[0]+4
    right=radii[1]-4
    d.polygon(p([(left,upper+21),(right,upper+21),(right,low-7),(right-5,low),
                 (left+5,low),(left,low-7)]),fill=shadow)
    d.ellipse(box(left,upper+16,right,upper+24),fill=color,outline=(248,222,196,160),width=1*S)
    d.polygon(p([(left+4,upper+25),(right-3,upper+23),(right-3,low-8),
                 (right-8,low-2),(left+5,low-2)]),fill=color)
    d.line(p([(left+7,upper+19),(left+5,low-9)]),fill=(255,255,255,200),width=3*S)
    d.ellipse(box(left+12,low-19,left+17,low-14),fill=(255,255,255,155))
    d.ellipse(box(right-15,upper+30,right-11,upper+34),fill=(254,230,251,130))
    d.line(p([(37,upper+13),(59,upper+13)]),fill=(255,219,149,150),width=1*S)
    save(image,f"{kind}_potion_{size}")

COLORS=[
    (180,190,217),(113,191,236),(78,211,194),(92,170,252),(169,124,243),
    (221,117,222),(249,114,164),(245,125,100),(255,164,62),(245,205,73),
    (161,238,108),(92,223,224),(103,165,245),(199,134,249),(255,206,115)
]
def stone(tier):
    im=canvas()
    d=ImageDraw.Draw(im)
    rr,gg,bb=COLORS[tier-1]
    ring=(241,188,87,245) if tier>=6 else (131,128,159,245)
    core=(rr,gg,bb,255)
    hi=(min(255,rr+47),min(255,gg+53),min(255,bb+50),255)
    low=(max(0,rr-80),max(0,gg-80),max(0,bb-95),255)
    d.ellipse(box(18,78,77,84),fill=(11,7,18,65))
    center=(48,47)
    verts=[(48,11),(70,25),(80,50),(62,75),(37,81),(16,54),(23,26)]
    d.polygon(p(verts),fill=low,outline=GOLD if tier>=10 else ring,width=3*S)
    facets=[
       ([(48,11),(70,25),(53,44)],hi),
       ([(70,25),(80,50),(53,44)],core),
       ([(80,50),(62,75),(53,44)],low),
       ([(62,75),(37,81),(53,44)],core),
       ([(37,81),(16,54),(53,44)],low),
       ([(16,54),(23,26),(53,44)],core),
       ([(23,26),(48,11),(53,44)],hi)
    ]
    for poly,color in facets:
       d.polygon(p(poly),fill=color)
    d.line(p(verts+[verts[0]]),fill=LIGHT if tier>=10 else ring,width=3*S,joint="curve")
    d.polygon(p([(35,28),(44,18),(53,32),(47,46),(35,43)]),fill=(255,255,255,105))
    d.line(p([(52,15),(55,28),(62,31)]),fill=(255,255,255,210),width=2*S)
    if tier>=6:
       d.ellipse(box(5,45,12,52),fill=ring)
       d.ellipse(box(82,29,88,35),fill=ring)
    if tier>=11:
       d.line(p([(10,12),(10,22)]),fill=LIGHT,width=2*S)
       d.line(p([(5,17),(15,17)]),fill=LIGHT,width=2*S)
       d.line(p([(85,66),(85,77)]),fill=LIGHT,width=2*S)
       d.line(p([(80,72),(91,72)]),fill=LIGHT,width=2*S)
    save(im,f"upgrade_stone_{tier}")

def main():
    for kind in ("hp","sp"):
        for size in ("small","medium","large"):
            potion(kind,size)
    for tier in range(1,16):
        stone(tier)
    results={}
    for png in sorted(OUT.glob("*.png")):
        data=png.read_bytes()
        results[png.name]={"width":96,"height":96,"sha256":hashlib.sha256(data).hexdigest()}
    assert len(results)==21
    (OUT/"manifest.json").write_text(json.dumps(results,indent=2)+"\n",encoding="utf-8")
    print("Created 21 unique transparent shop item PNGs; no cropped images")

if __name__=="__main__":
    main()
