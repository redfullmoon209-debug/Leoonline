#!/usr/bin/env python3
"""Create THREE independent transparent skill PNGs. No screenshots or crops."""
import math
import struct
import zlib
from pathlib import Path

N=192
OUT=Path(__file__).resolve().parents[1]/"assets/ui/skills"
OUT.mkdir(parents=True,exist_ok=True)

def clamp(x):return max(0,min(255,int(x)))
def pixel_image(kind):
 buf=bytearray()
 for y in range(N):
  for x in range(N):
   X=(x+0.5-N/2)/(N/2)
   Y=(y+0.5-N/2)/(N/2)
   if kind==0:  # diagonal crescent slash, fiery orange/white
    t=(X+Y+0.15)
    a=math.exp(-((X-0.30+0.56*Y)/0.23)**2)*math.exp(-((Y+0.17)/0.7)**4)
    cres=math.exp(-((math.hypot(X+0.1,Y+0.02)-0.7)/0.11)**2)
    v=max(a,cres*max(0.0,(X-Y+0.6)/1.7))
    heat=clamp(v*255)
    r=255;g=clamp(50+230*v);b=clamp(8+240*max(0,v-0.65)/0.35)
   elif kind==1: # blue lightning/rush
    dist=abs(X-0.55*math.sin(Y*3.5)-Y*0.62)
    ray=math.exp(-(dist/0.1)**2)
    flare=math.exp(-((X-0.48)**2+(Y+0.65)**2)/0.075)
    v=max(ray*math.exp(-(Y/1.0)**6),flare)
    heat=clamp(v*255)
    r=clamp(12+225*v);g=clamp(95+160*v);b=255
   else: # radiant shield, crisp golden polyline
    yy=(Y+0.75)/1.55
    bound=0.57*(1.0-0.25*max(0,yy))
    outline=math.exp(-((abs(X)-bound)/0.045)**2) if -0.75<Y<0.75 else 0
    top=math.exp(-((Y+0.75)/0.05)**2) if abs(X)<0.57 else 0
    low=math.exp(-((Y-0.75+0.22*abs(X))/0.055)**2) if abs(X)<bound else 0
    inside=max(0,(bound-abs(X)))*0.45 if -0.72<Y<0.72 else 0
    star=math.exp(-(X/0.07)**2)*math.exp(-(Y/0.43)**2)+math.exp(-(Y/0.07)**2)*math.exp(-(X/0.35)**2)
    v=min(1,max(outline,top,low,inside,star))
    heat=clamp(v*255)
    r=255;g=clamp(117+128*v);b=clamp(15+205*max(0,v-0.55)*2)
   buf.extend((r,g,b,heat))
 return bytes(buf)

def chunk(tag,data):
 return struct.pack(">I",len(data))+tag+data+struct.pack(">I",zlib.crc32(tag+data)&0xffffffff)

def write(path,pixels):
 rows=b"".join(bytes([0])+pixels[y*N*4:(y+1)*N*4] for y in range(N))
 hdr=bytes([137,80,78,71,13,10,26,10])
 hdr+=chunk(b"IHDR",struct.pack(">IIBBBBB",N,N,8,6,0,0,0))
 hdr+=chunk(b"IDAT",zlib.compress(rows,9))+chunk(b"IEND",b"")
 path.write_bytes(hdr)

for i,name in enumerate(("novice_slash.png","novice_rush.png","novice_guard.png")):
 write(OUT/name,pixel_image(i))
 print(OUT/name)
