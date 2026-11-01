#!/usr/bin/env python3
"""Original storage-chest icon for Leoonline. No source image crops or screenshot art."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter

SIZE=96
S=4
OUT=Path(__file__).resolve().parents[1]/"assets"/"ui"/"inventory"/"icon_storage.png"
def b(x0,y0,x1,y1):
    return tuple(int(n*S) for n in (x0,y0,x1,y1))
def pts(values):
    return [(round(x*S),round(y*S)) for x,y in values]
def draw_icon():
    img=Image.new("RGBA",(SIZE*S,SIZE*S),(0,0,0,0))
    d=ImageDraw.Draw(img)
    gold=(243,189,89,255)
    pale=(255,229,155,255)
    dark=(100,38,29,255)
    red=(93,11,26,255)
    d.ellipse(b(16,78,83,89),fill=(25,8,11,85))
    # Independently drawn chest body, hinged lid and metal hardware.
    d.rounded_rectangle(b(18,42,80,81),radius=7*S,fill=(42,7,14,255),outline=gold,width=3*S)
    d.polygon(pts([(21,50),(77,50),(74,76),(25,76)]),fill=red)
    d.line(pts([(24,54),(74,54)]),fill=(186,91,49,225),width=2*S)
    for x in (31,66):
        d.rectangle(b(x,45,x+5,78),fill=(159,99,48,255),outline=gold,width=1*S)
    d.polygon(pts([(14,44),(20,25),(35,16),(65,16),(79,26),(85,44),(80,51),(17,51)]),
              fill=(78,12,20,255))
    d.line(pts([(14,44),(20,25),(35,16),(65,16),(79,26),(85,44)]),fill=gold,width=4*S,joint="curve")
    d.line(pts([(20,25),(79,26)]),fill=pale,width=2*S)
    d.line(pts([(21,37),(78,37)]),fill=(206,135,64,255),width=2*S)
    d.polygon(pts([(41,44),(59,44),(60,67),(40,67)]),fill=(204,150,68,255),outline=pale,width=2*S)
    d.ellipse(b(47,50,54,58),fill=(79,31,28,255))
    d.polygon(pts([(48,56),(53,56),(55,61),(46,61)]),fill=(79,31,28,255))
    for x in (20,79):
        d.ellipse(b(x-3,42,x+3,48),fill=pale,outline=(154,104,53,255),width=1*S)
    d.line(pts([(20,77),(78,77)]),fill=gold,width=2*S)
    img.resize((SIZE,SIZE),Image.Resampling.LANCZOS).save(OUT,optimize=True)
    print(f"Created standalone original PNG: {OUT}")
if __name__=="__main__":
    draw_icon()
