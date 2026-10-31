#!/usr/bin/env python3
"""Generate individual transparent fantasy UI PNGs from native vector primitives.

Every output is drawn independently; no screenshots or composite artwork are cropped.
The output can be regenerated before a Godot build using Pillow.
"""
from PIL import Image, ImageDraw, ImageFilter
from pathlib import Path
import math, random

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets' / 'ui' / 'inventory'
OUT.mkdir(parents=True, exist_ok=True)
S = 2
random.seed(911)

GOLD = (255, 201, 90)
GOLD_LIGHT = (255, 241, 167)
GOLD_DARK = (135, 73, 20)
CYAN = (64, 216, 255)
CYAN_LIGHT = (184, 248, 255)
BLUE = (14, 71, 144)
PURPLE = (206, 95, 255)
NAVY = (3, 15, 42)


def u(v): return round(v * S)
def pt(seq): return [(u(x), u(y)) for x, y in seq]
def rgba(c, a=255): return tuple(c[:3]) + (a,)

def rr(d, b, radius, *, fill=None, outline=None, width=1):
    d.rounded_rectangle(tuple(u(q) for q in b), radius=u(radius), fill=fill, outline=outline, width=u(width))

def line(d, points, fill, width=1, joint='curve'):
    d.line(pt(points), fill=fill, width=max(1,u(width)), joint=joint)

def polygon(d, points, fill, outline=None, width=1):
    d.polygon(pt(points), fill=fill)
    if outline: line(d, points+[points[0]], outline, width)

def ell(d, b, *, fill=None, outline=None, width=1):
    d.ellipse(tuple(u(q) for q in b), fill=fill, outline=outline, width=u(width))

def imnew(w,h): return Image.new('RGBA',(u(w),u(h)),(0,0,0,0))
def save(im, name):
    # RGBA PNGs, not atlas/spritesheet, ready to import as separate Godot textures.
    im.resize((im.width//S,im.height//S),Image.Resampling.LANCZOS).save(OUT/f'{name}.png',optimize=True)

def diamond(d, cx, cy, r, fill, edge, width=1):
    polygon(d, [(cx,cy-r),(cx+r*.8,cy),(cx,cy+r),(cx-r*.8,cy)],fill,edge,width)

def glows(im, box, radius, c, strength=100):
    l=Image.new('RGBA',im.size,(0,0,0,0))
    d=ImageDraw.Draw(l)
    rr(d,box,radius,outline=rgba(c,200),width=3)
    im.alpha_composite(l.filter(ImageFilter.GaussianBlur(u(6))))
    if strength>100:
        im.alpha_composite(l.filter(ImageFilter.GaussianBlur(u(2))))

def panel(name, w=340, h=300, tone='blue', special=False):
    base=imnew(w,h)
    c = GOLD if tone=='gold' else (PURPLE if tone=='purple' else CYAN)
    edge=rgba(c,230)
    glows(base,(11,11,w-11,h-11),26,c)
    d=ImageDraw.Draw(base)
    for y in range(u(12),u(h-12)):
        t=(y/u(h))
        r=int(3+5*t); g=int(21+20*(1-t)); b=int(55+20*(1-t))
        d.line((u(17),y,u(w-17),y),fill=(r,g,b,238),width=1)
    rr(d,(12,12,w-12,h-12),22,outline=(17,92,152,245),width=5)
    rr(d,(16,16,w-16,h-16),18,outline=rgba(GOLD_DARK,210),width=2)
    rr(d,(19,19,w-19,h-19),16,outline=edge,width=2)
    rr(d,(24,24,w-24,h-24),11,outline=(34,92,160,105),width=1)
    # Art nouveau filigree at nine-slice corners, independently painted.
    for flip_x in [False,True]:
        for flip_y in [False,True]:
            def xy(x,y): return (w-x if flip_x else x, h-y if flip_y else y)
            polygon(d,[xy(13,47),xy(13,22),xy(29,10),xy(59,12),xy(44,20),xy(27,23),xy(22,44)],rgba(GOLD_DARK,240),rgba(GOLD,245),1)
            line(d,[xy(25,35),xy(30,28),xy(43,25),xy(58,17)],rgba(GOLD_LIGHT),2)
            line(d,[xy(26,54),xy(36,38),xy(54,28)],rgba(CYAN,210),1)
            diamond(d,*xy(24,24),4,rgba(CYAN_LIGHT),rgba(GOLD,245),1)
    for x,y in [(w/2,15),(w/2,h-15),(15,h/2),(w-15,h/2)]:
        diamond(d,x,y,7,rgba(CYAN,245),rgba(GOLD,250),1)
    if special:
        for i in range(34):
            x=random.randint(45,w-45);y=random.randint(32,h-32)
            ell(d,(x-0.5,y-0.5,x+0.5,y+0.5),fill=(63,174,255,random.randint(35,85)))
    save(base,name)

def flat_style(name,w,h,c='blue',roundness=20):
    img=imnew(w,h)
    outline= GOLD if c in ('gold','red') else (PURPLE if c=='purple' else CYAN)
    top=(28,99,160) if c=='blue' else ((123,73,11) if c=='gold' else ((118,29,46) if c=='red' else (65,28,107)))
    bot=(4,21,54) if c=='blue' else ((47,24,4) if c=='gold' else ((53,9,27) if c=='red' else (29,6,50)))
    glows(img,(8,9,w-8,h-9),roundness,outline)
    d=ImageDraw.Draw(img)
    for y in range(u(10),u(h-10)):
        t=(y-u(10))/max(1,u(h-20))
        col=tuple(round(top[k]*(1-t)+bot[k]*t) for k in range(3))+(249,)
        d.line((u(14),y,u(w-14),y),fill=col,width=1)
    rr(d,(10,10,w-10,h-10),roundness,outline=rgba(GOLD_DARK,230),width=5)
    rr(d,(12,12,w-12,h-12),roundness-2,outline=rgba(outline,255),width=2)
    rr(d,(15,15,w-15,h-15),roundness-4,outline=(211,248,255,125),width=1)
    for x in (13,w-13):
        diamond(d,x,h/2,5,rgba(GOLD_LIGHT),rgba(GOLD,255),1)
    if w>200:
        for x in (w*.17,w*.83):
            line(d,[(x,14),(x+8,14)],rgba(CYAN_LIGHT,160),1)
    save(img,name)

def slot(name,color='blue',locked=False):
    w=h=120
    im=imnew(w,h)
    c=GOLD if color=='gold' else (PURPLE if color=='purple' else ((117,135,160) if locked else CYAN))
    glows(im,(13,13,107,107),13,c,120)
    d=ImageDraw.Draw(im)
    rr(d,(11,11,109,109),13,fill=(4,20,47,249),outline=rgba(c,230),width=5)
    rr(d,(16,16,104,104),11,outline=(34,92,151,190),width=2)
    polygon(d,[(60,39),(65,56),(82,60),(65,65),(60,82),(55,65),(38,60),(55,55)],(42,101,165,55))
    for x in (17,103):
        for y in (17,103):
            diamond(d,x,y,5,rgba(c,225),rgba(GOLD_LIGHT,180),1)
    if locked:
        rr(d,(49,56,71,76),4,fill=(111,129,153,248),outline=(222,231,240,255),width=2)
        d.arc(tuple(u(v) for v in (52,42,68,65)),180,360,fill=(208,228,240,255),width=u(4))
        ell(d,(59,65,61,67),fill=(22,32,51,255))
    save(im,name)

def currency_row():
    flat_style('currency_row',340,74,'blue',11)

def banner():
    w,h=820,160
    img=imnew(w,h)
    g=Image.new('RGBA',img.size,(0,0,0,0));d=ImageDraw.Draw(g)
    for x in range(u(35),u(w-35)):
        t=abs(x/u(w)-.5)*2
        d.line((x,u(60),x,u(120)),fill=(4,20,56,int(210*(1-t*.3))),width=1)
    img.alpha_composite(g)
    d=ImageDraw.Draw(img)
    polygon(d,[(32,66),(147,45),(236,52),(276,34),(316,52),(410,18),(504,52),(547,34),(590,52),(681,45),(790,66),(710,94),(610,87),(552,117),(410,98),(268,117),(213,87),(115,94)], (10,38,82,235),rgba(GOLD,225),2)
    for x in [25,90,185,635,725,795]:
        diamond(d,x,72,13,rgba(CYAN,205),rgba(GOLD,240),2)
    for cx,cy,s in [(410,30,22),(410,120,12),(286,56,7),(534,56,7)]:
        diamond(d,cx,cy,s,rgba(CYAN_LIGHT,255),rgba(GOLD,255),2)
    line(d,[(84,95),(290,97),(319,108),(503,108),(531,97),(736,95)],rgba(CYAN,255),2)
    save(img,'banner')

def divider():
    img=imnew(580,40);d=ImageDraw.Draw(img)
    line(d,[(8,18),(280,18)],rgba(GOLD,185),2);line(d,[(300,18),(572,18)],rgba(GOLD,185),2)
    line(d,[(22,22),(276,22)],rgba(CYAN,185),1);line(d,[(304,22),(558,22)],rgba(CYAN,185),1)
    diamond(d,290,19,12,rgba(CYAN),rgba(GOLD,255),2)
    for x in (12,568): diamond(d,x,19,4,rgba(GOLD_LIGHT),rgba(GOLD))
    save(img,'divider')

# Solid geometry icons drawn as individual transparent PNG files.
# UI labels, item counts, currency values and all changeable copy remain Godot text controls.
def icon(name,what,color=GOLD, glow_color=None):
    w=h=96
    img=imnew(w,h)
    glow_color=glow_color or color
    shadow=imnew(w,h);ds=ImageDraw.Draw(shadow)
    ell(ds,(15,15,81,81),fill=rgba(glow_color,80))
    img.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(u(10))))
    d=ImageDraw.Draw(img)
    dark=(14,37,69,255);edge=rgba(GOLD_LIGHT,255); fill=rgba(color,240)
    if what=='bag':
        rr(d,(20,31,76,78),10,fill=(122,68,21,248),outline=edge,width=3)
        d.arc(tuple(u(v) for v in (35,18,61,52)),180,360,fill=edge,width=u(5))
        line(d,[(22,46),(74,46)],edge,2);rr(d,(42,44,54,60),2,fill=edge)
    elif what=='character':
        ell(d,(38,15,60,43),fill=edge)
        polygon(d,[(22,77),(27,55),(42,45),(59,45),(73,56),(78,78)],fill,edge,2)
    elif what=='skill':
        polygon(d,[(25,68),(67,26),(78,37),(36,79)],fill,edge,2)
        polygon(d,[(57,23),(67,11),(85,29),(75,41)],(68,162,233,255),edge,2)
        line(d,[(23,63),(34,74)],edge,4)
    elif what=='shop':
        polygon(d,[(20,28),(79,28),(72,61),(34,61)],fill,edge,3)
        line(d,[(14,19),(24,19),(34,61)],edge,4)
        ell(d,(37,65,47,75),fill=edge);ell(d,(62,65,72,75),fill=edge)
        line(d,[(36,39),(71,39)],rgba(GOLD_LIGHT),2)
    elif what=='hat':
        polygon(d,[(18,69),(76,69),(61,59),(59,32),(48,20),(37,30),(34,58)],fill,edge,3)
        line(d,[(30,60),(66,60)],edge,2)
    elif what=='shirt':
        polygon(d,[(26,24),(39,18),(48,29),(59,18),(74,25),(84,44),(70,53),(67,78),(29,78),(26,52),(12,43)],fill,edge,3)
        line(d,[(41,22),(48,38),(56,22)],rgba(CYAN_LIGHT),2)
    elif what=='gloves':
        for x in (17,52):
            polygon(d,[(x,44),(x+4,20),(x+10,14),(x+13,31),(x+18,16),(x+22,18),(x+23,38),(x+30,31),(x+31,48),(x+23,75),(x+4,73)],fill,edge,2)
    elif what=='pants':
        polygon(d,[(25,20),(71,20),(68,76),(51,76),(48,47),(45,76),(28,76)],fill,edge,3)
        line(d,[(24,31),(72,31)],rgba(CYAN_LIGHT),2)
    elif what=='shoes':
        for x in (14,52):
            polygon(d,[(x+5,22),(x+27,22),(x+28,59),(x+34,70),(x+32,79),(x,79),(x,64)],fill,edge,2)
    elif what in ('sword','fashion_sword'):
        blade=PURPLE if what=='fashion_sword' else color
        polygon(d,[(22,72),(65,18),(82,12),(74,34),(30,79)],rgba(blade),edge,2)
        line(d,[(19,60),(43,82)],rgba(GOLD_LIGHT),5)
        ell(d,(14,78,22,86),fill=edge)
    elif what=='double_sword':
        polygon(d,[(15,24),(24,15),(76,74),(70,81)],fill,edge,2)
        polygon(d,[(80,24),(71,15),(20,74),(26,81)],fill,edge,2)
        line(d,[(16,61),(36,78)],edge,3);line(d,[(78,61),(58,78)],edge,3)
    elif what=='mask':
        polygon(d,[(18,35),(26,28),(44,31),(49,36),(55,31),(72,28),(79,35),(74,64),(60,72),(49,66),(38,72),(23,64)],fill,edge,3)
        polygon(d,[(27,43),(41,42),(45,49),(35,52)],(7,22,47,255),rgba(CYAN_LIGHT),1)
        polygon(d,[(54,49),(59,42),(72,43),(64,52)],(7,22,47,255),rgba(CYAN_LIGHT),1)
        diamond(d,49,38,6,rgba(CYAN_LIGHT),edge,1)
    elif what=='cape':
        polygon(d,[(34,18),(62,18),(76,77),(56,69),(48,83),(39,69),(19,77)],fill,edge,3)
        polygon(d,[(41,30),(55,30),(63,63),(49,57),(36,64)],rgba((28,92,164),235),rgba(CYAN_LIGHT,190),1)
        diamond(d,48,21,8,rgba(CYAN_LIGHT),edge,2)
    elif what=='pet':
        ell(d,(28,47,68,77),fill=fill,outline=edge,width=2)
        for x,y in [(20,39),(38,27),(58,27),(76,39)]:ell(d,(x-8,y-10,x+8,y+6),fill=fill,outline=edge,width=2)
    elif what=='mount':
        polygon(d,[(20,73),(28,40),(42,26),(59,23),(68,12),(71,35),(79,45),(70,55),(65,79),(38,78)],fill,edge,2)
        ell(d,(59,35,64,40),fill=dark)
    elif what=='ring':
        ell(d,(25,38,73,80),fill=(0,0,0,0),outline=edge,width=7)
        diamond(d,49,31,15,rgba(CYAN),rgba(GOLD_LIGHT),3)
    elif what=='bracelet':
        ell(d,(22,29,75,76),fill=(0,0,0,0),outline=edge,width=9)
        diamond(d,48,29,9,rgba(CYAN),rgba(GOLD_LIGHT),2)
    elif what=='necklace':
        d.arc(tuple(u(v) for v in (16,15,80,77)),5,175,fill=edge,width=u(4))
        diamond(d,48,69,14,rgba(CYAN),edge,3)
    elif what=='lock':
        rr(d,(29,44,67,76),6,fill=fill,outline=edge,width=3)
        d.arc(tuple(u(v) for v in (35,22,62,55)),180,360,fill=edge,width=u(6))
    elif what=='gold':
        ell(d,(18,18,80,80),fill=(149,80,8,255),outline=edge,width=5)
        ell(d,(27,27,71,71),fill=(236,156,33,255),outline=rgba(GOLD_LIGHT),width=3)
        diamond(d,49,48,17,rgba(GOLD_LIGHT),rgba(GOLD),2)
    elif what in ('blue','purple','green'):
        col={'blue':CYAN,'purple':PURPLE,'green':(70,240,131)}[what]
        polygon(d,[(22,34),(37,19),(65,19),(79,34),(66,75),(48,87),(30,71)],rgba(col),edge,2)
        polygon(d,[(22,34),(49,45),(79,34),(65,19),(37,19)],rgba(GOLD_LIGHT,120))
    elif what=='potion':
        rr(d,(31,33,66,79),9,fill=rgba((225,62,104)),outline=edge,width=3)
        rr(d,(35,16,62,32),3,fill=rgba(CYAN_LIGHT),outline=edge,width=2)
        ell(d,(39,44,57,63),fill=rgba(GOLD_LIGHT,180))
    elif what=='scroll':
        rr(d,(23,23,73,73),6,fill=(206,160,98,245),outline=edge,width=3)
        rr(d,(18,21,31,75),5,fill=(148,86,41,255),outline=edge,width=2)
        rr(d,(65,21,78,75),5,fill=(148,86,41,255),outline=edge,width=2)
        line(d,[(41,40),(60,40)],rgba(GOLD_DARK),2);line(d,[(41,52),(57,52)],rgba(GOLD_DARK),2)
    elif what=='wood':
        polygon(d,[(23,71),(39,28),(62,18),(74,27),(56,71)],(116,69,38,255),edge,3)
        line(d,[(31,64),(59,27)],rgba(GOLD_LIGHT,180),2)
    elif what=='sparkle':
        diamond(d,48,48,30,rgba(CYAN),rgba(GOLD_LIGHT),2)
        diamond(d,76,27,11,rgba(GOLD),rgba(GOLD_LIGHT),1)
    else:
        diamond(d,48,48,22,fill,edge,2)
    save(img,'icon_'+name)




def character_silhouette():
    # Character pedestal and armour silhouette, painted as a separate transparent asset.
    w,h=260,350
    img=imnew(w,h)
    halo=imnew(w,h);dg=ImageDraw.Draw(halo)
    for i in range(5):
        ell(dg,(38-i*2,30-i*2,222+i*2,300+i*2),outline=rgba(CYAN,90),width=1)
    ell(dg,(30,300,230,335),outline=rgba(CYAN,220),width=3)
    ell(dg,(55,306,205,329),outline=rgba(CYAN_LIGHT,225),width=2)
    img.alpha_composite(halo.filter(ImageFilter.GaussianBlur(u(6))))
    d=ImageDraw.Draw(img)
    for r in [106,91,74]:
        ell(d,(130-r,168-r,130+r,168+r),outline=rgba(CYAN,80),width=1)
    # Face and fantasy armor pieces. No external source art is reused.
    ell(d,(111,49,148,96),fill=rgba((61,166,232),220),outline=rgba(CYAN_LIGHT,230),width=3)
    polygon(d,[(104,84),(153,84),(175,116),(162,180),(140,206),(116,206),(96,177),(85,118)],rgba((28,104,174),235),rgba(CYAN_LIGHT),3)
    polygon(d,[(95,105),(72,100),(54,119),(68,143),(92,147),(113,121)],rgba((32,127,205),230),rgba(CYAN_LIGHT),3)
    polygon(d,[(165,105),(187,100),(206,119),(190,143),(166,147),(148,121)],rgba((32,127,205),230),rgba(CYAN_LIGHT),3)
    polygon(d,[(72,136),(92,147),(89,209),(68,226),(55,218)],rgba((36,122,193),232),rgba(CYAN_LIGHT),2)
    polygon(d,[(166,147),(190,136),(205,218),(189,226),(170,209)],rgba((36,122,193),232),rgba(CYAN_LIGHT),2)
    polygon(d,[(111,198),(144,198),(158,252),(145,309),(124,309),(121,258),(111,305),(92,305),(95,247)],rgba((39,128,205),236),rgba(CYAN_LIGHT),3)
    polygon(d,[(97,172),(162,172),(176,212),(128,240),(82,209)],rgba((24,81,161),245),rgba(CYAN_LIGHT),2)
    polygon(d,[(117,102),(128,90),(139,103),(128,164)],rgba((195,236,255),216),rgba(CYAN_LIGHT),2)
    for x,y in [(129,76),(128,184),(81,122),(175,122)]:diamond(d,x,y,7,rgba(CYAN_LIGHT),rgba(GOLD,245),1)
    ell(d,(20,305,240,333),outline=rgba(CYAN_LIGHT,220),width=3)
    save(img,'character_silhouette')

def generate():
    panel('frame_main', 360,360, special=True)
    panel('frame_panel',320,320)
    panel('frame_inner',280,280)
    panel('frame_fashion',320,260,tone='purple')
    flat_style('tab_blue',320,88,'blue',21)
    flat_style('tab_gold',320,88,'gold',21)
    flat_style('button_blue',280,84,'blue',16)
    flat_style('button_gold',280,84,'gold',16)
    flat_style('button_red',280,84,'red',16)
    flat_style('button_purple',280,84,'purple',16)
    slot('slot_normal')
    slot('slot_selected','gold')
    slot('slot_locked',locked=True)
    slot('slot_equipment','gold')
    slot('slot_fashion','purple')
    currency_row()
    banner()
    divider()
    character_silhouette()
    features = {
      'inventory': 'bag','character':'character','skill':'skill','shop':'shop',
      'hat':'hat','shirt':'shirt','gloves':'gloves','pants':'pants','shoes':'shoes',
      'weapon_right':'sword','weapon_left':'double_sword',
      'fashion_weapon_right':'fashion_sword','fashion_weapon_left':'double_sword',
      'pet':'pet','mount':'mount','bracelet':'bracelet','ring':'ring','necklace':'necklace',
      'fashion':'sparkle','fashion_mask':'mask','fashion_cape':'cape','mask':'mask','cape':'cape','lock':'lock','gold':'gold','blue':'blue','purple':'purple','green':'green',
      'sword':'sword','boots':'shoes','potion':'potion','scroll':'scroll','wood':'wood',
      'fashion_blade':'fashion_sword','fashion_dagger':'double_sword',
    }
    for name,shape in features.items():
        ic=PURPLE if 'fashion' in name else ((67,222,255) if name in ('pet','mount','blue','boots') else GOLD)
        icon(name,shape,ic)
    files=list(OUT.glob('*.png'))
    print('Generated',len(files),'independent PNG assets in',OUT)
    for p in sorted(files): print(' ',p.name,format(p.stat().st_size,','),'bytes')

if __name__=='__main__': generate()
