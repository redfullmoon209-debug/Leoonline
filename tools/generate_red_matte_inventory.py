#!/usr/bin/env python3
"""Make eleven original PNG sprites: matte crimson and gold, no neon/glow.

All sprites are drawn independently by Pillow; NO screenshots or existing PNGs
are cropped, sampled, recolored, or pasted. All words remain Godot labels.
"""
from __future__ import annotations

import hashlib
import json
from pathlib import Path
from PIL import Image, ImageDraw

SCALE = 3
OUT = Path(__file__).resolve().parents[1] / "assets" / "ui" / "red_matte"
OUT.mkdir(parents=True, exist_ok=True)

GOLD = (201, 150, 65, 255)
GOLD_LIGHT = (249, 216, 146, 255)
GOLD_DARK = (93, 51, 23, 255)
INNER_GOLD = (141, 82, 37, 255)


def P(t):
    if t and isinstance(t[0], (tuple, list)):
        return [P(point) for point in t]
    return tuple(round(v * SCALE) for v in t)


def canvas(w, h):
    return Image.new("RGBA", (w * SCALE, h * SCALE), (0, 0, 0, 0))


def gradient_masked(image, pts, stops, rounded=None):
    w, h = image.size
    mask = Image.new("L", (w, h), 0)
    d = ImageDraw.Draw(mask)
    if rounded is None:
        d.polygon(P(pts), fill=255)
    else:
        d.rounded_rectangle(P(pts), radius=rounded*SCALE, fill=255)
    strip = Image.new("RGBA", (w, h))
    g = ImageDraw.Draw(strip)
    for y in range(h):
        t = y / max(1, h - 1) * (len(stops)-1)
        i = min(len(stops)-2, int(t))
        f = t-i
        c = tuple(int(stops[i][k]*(1-f) + stops[i+1][k]*f) for k in range(4))
        g.line((0,y,w,y), fill=c)
    image.paste(strip, (0,0), mask)


def save(image, name):
    image.resize((image.width//SCALE,image.height//SCALE),Image.Resampling.LANCZOS).save(OUT/name,optimize=True)


def rect(image, points, radius, color, width):
    ImageDraw.Draw(image).rounded_rectangle(P(points), radius*SCALE, outline=color, width=width*SCALE)


def panel(name, outer=False):
    w = 240
    im=canvas(w,w)
    bg = [(43,5,9,245),(31,4,8,250),(25,3,8,252)] if outer else [(58,8,14,248),(29,4,9,250),(26,3,8,252)]
    gradient_masked(im,(3,3,w-4,w-4),bg,18 if outer else 14)
    rect(im,(3,3,w-4,w-4),18 if outer else 14,GOLD_DARK,4)
    rect(im,(6,6,w-7,w-7),16 if outer else 12,GOLD,2)
    rect(im,(9,9,w-10,w-10),15 if outer else 11,(251,207,126,230),1)
    rect(im,(14,14,w-15,w-15),10,(100,33,21,255),1)
    ImageDraw.Draw(im).line(P((24,17,w-24,17)), fill=(164,105,49,170),width=2*SCALE)
    save(im,name)


def bevel(w,h,c):
    return [(c,3),(w-c,3),(w-3,c),(w-3,h-c),(w-c,h-3),(c,h-3),(3,h-c),(3,c)]


def outline_poly(draw,pts,color,width):
    q=P(pts)
    draw.line(q+[q[0]],fill=color,width=width*SCALE,joint="curve")


def button(name, variant):
    w,h=320,84
    im=canvas(w,h)
    colors={
        "active":[(114,12,22,255),(86,8,16,255),(58,5,13,255)],
        "idle":[(67,9,14,255),(37,5,10,255),(25,4,8,255)],
        "action":[(79,11,18,255),(48,6,13,255),(29,4,10,255)],
        "close":[(137,16,28,255),(94,8,16,255),(63,5,15,255)],
        "pager":[(67,10,18,255),(42,4,10,255),(26,4,9,255)]
    }[variant]
    c=12 if variant=="pager" else 18
    pts=bevel(w,h,c)
    gradient_masked(im,pts,colors)
    d=ImageDraw.Draw(im)
    outline_poly(d,pts,GOLD_DARK,5)
    outline_poly(d,[(x+2 if x<w/2 else x-2,y+2 if y<h/2 else y-2) for x,y in pts],GOLD,2)
    d.line(P((c+6,8,w-c-6,8)),fill=GOLD_LIGHT,width=2*SCALE)
    d.line(P((c+8,h-10,w-c-8,h-10)),fill=INNER_GOLD,width=2*SCALE)
    save(im,name)


def slot(name,mode):
    w=104
    im=canvas(w,w)
    stops={
        "empty":[(73,8,14,254),(35,3,9,255),(25,3,8,255)],
        "selected":[(122,28,27,254),(66,9,13,255),(47,4,11,255)],
        "locked":[(38,24,26,252),(17,9,13,254),(15,7,11,255)]
    }[mode]
    gradient_masked(im,(5,5,99,99),stops,11)
    color=GOLD_LIGHT if mode=="selected" else GOLD_DARK if mode=="locked" else GOLD
    rect(im,(5,5,99,99),11,(53,25,19,255),3)
    rect(im,(7,7,97,97),9,color,2)
    rect(im,(10,10,94,94),8,(153,84,41,175) if mode!="locked" else (76,63,61,190),1)
    d=ImageDraw.Draw(im)
    c2=GOLD if mode!="locked" else (108,88,79,255)
    for x,y,sx,sy in [(8,8,1,1),(96,8,-1,1),(8,96,1,-1),(96,96,-1,-1)]:
        d.line(P((x,y+11*sy,x,y)),fill=c2,width=2*SCALE)
        d.line(P((x,y,x+11*sx,y)),fill=c2,width=2*SCALE)
    if mode=="locked":
        d.rounded_rectangle(P((41,53,63,72)),4*SCALE,fill=(130,122,118,245),outline=(228,193,140,255),width=2*SCALE)
        d.arc(P((42,38,62,62)),180,360,fill=(218,192,158,245),width=4*SCALE)
        d.ellipse(P((50,58,54,62)),fill=(38,27,25,255))
    save(im,name)


def row():
    w,h=490,65
    im=canvas(w,h)
    gradient_masked(im,(3,4,w-4,h-5),[(49,7,12,255),(29,4,9,255),(22,3,8,255)],12)
    rect(im,(3,4,w-4,h-5),12,GOLD_DARK,3)
    rect(im,(6,7,w-7,h-8),9,INNER_GOLD,2)
    save(im,"currency_row.png")


def main():
    panel("outer_panel.png",True)
    panel("inner_panel.png",False)
    button("tab_active.png","active")
    button("tab_idle.png","idle")
    button("action_button.png","action")
    button("close_button.png","close")
    button("pager_button.png","pager")
    slot("slot_empty.png","empty")
    slot("slot_selected.png","selected")
    slot("slot_locked.png","locked")
    row()
    result={p.name:{"width":Image.open(p).width,"height":Image.open(p).height,"sha256":hashlib.sha256(p.read_bytes()).hexdigest()} for p in sorted(OUT.glob("*.png"))}
    (OUT/"manifest.json").write_text(json.dumps(result,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    print("Created",len(result),"standalone matte ruby-gold PNGs; no source PNG modified")


if __name__=="__main__":
    main()
