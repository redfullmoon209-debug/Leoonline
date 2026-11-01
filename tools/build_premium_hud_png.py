#!/usr/bin/env python3
"""Draw 10 independent richly layered fantasy art icons as RGBA PNG.

The input is original illustration code per icon, not a screenshot, an asset
sheet, a clip/crop, or an extract from the approved concept image. Each png
is rendered alone from original SVG art. Text and notification dots are never
embedded in image pixels.
"""
from __future__ import annotations
import math
import random
import re
from pathlib import Path
import cairosvg
from PIL import Image
from io import BytesIO

ROOT=Path(__file__).resolve().parents[1] if Path(__file__).parent.name=='tools' else Path('/mnt/data')
OUTPUT=ROOT/'assets/ui/hud/premium'
ORDER=['bag','world','party','friends','ranking','settings','guild','quest','mail','events']


def star(cx,cy,outer,inner,points=8,offset=-math.pi/2):
    vertices=[]
    for i in range(points*2):
        t=offset+i*math.pi/points
        r=outer if i%2==0 else inner
        vertices.append(f'{cx+math.cos(t)*r:.2f},{cy+math.sin(t)*r:.2f}')
    return ' '.join(vertices)


def gear_poly(cx,cy,outer=74,inner=64,n=12):
    vertices=[]
    for i in range(n*4):
        angle=-math.pi/2+i*math.tau/(n*4)
        r=outer if i%4 in [1,2] else inner
        vertices.append(f'{cx+math.cos(angle)*r:.2f},{cy+math.sin(angle)*r:.2f}')
    return ' '.join(vertices)


def base_art():
    rng=random.Random(9)
    nicks=''.join(f'<circle cx="{rng.randint(42,214)}" cy="{rng.randint(34,174)}" r="{rng.choice([.4,.6,.8,1])}" fill="{rng.choice(["#f9c76a","#95431f","#ffffff"])}" opacity="{rng.uniform(.1,.35):.2f}"/>' for _ in range(90))
    filigree=''
    for i in range(12):
        angle=i*math.tau/12-math.pi/2
        x=128+83*math.cos(angle)
        y=98+83*math.sin(angle)
        filigree+=f'<circle cx="{x:.2f}" cy="{y:.2f}" r="2.8" fill="url(#gold3d)" stroke="#542307" stroke-width=".6"/>'
    for x,y,flip in [(47,99,1),(209,99,-1)]:
        filigree+=f'<path d="M{x} {y-26} q{flip*18} 11 {flip*12} 22 q{-flip*17} 2 {-flip*8} 25" stroke="url(#gold3d)" stroke-width="3" fill="none" opacity=".91"/>'
    return f'''
      <ellipse cx="128" cy="232" rx="105" ry="13" fill="#000000" opacity=".35"/>
      <circle cx="128" cy="101" r="96" fill="#3a130a" stroke="#421b08" stroke-width="4"/>
      <circle cx="128" cy="98" r="94" fill="url(#gold3d)" stroke="#4f1b05" stroke-width="3"/>
      <circle cx="128" cy="98" r="88" fill="url(#darkGold)" stroke="#fff1a9" stroke-width="1.6"/>
      <circle cx="128" cy="98" r="82" fill="url(#gold3d)" stroke="#542205" stroke-width="2"/>
      <circle cx="128" cy="98" r="76" fill="url(#redInner)" stroke="#301007" stroke-width="5"/>
      <circle cx="128" cy="98" r="72" fill="none" stroke="#ffeaba" stroke-opacity=".35" stroke-width="1.6"/>
      <circle cx="115" cy="79" r="63" fill="url(#warmHalo)" opacity=".55"/>
      <path d="M46 43Q120 0 194 43" fill="none" stroke="#fff1b1" stroke-width="3" opacity=".55"/>
      <path d="M41 156Q129 211 216 156" fill="none" stroke="#7e350c" stroke-width="4"/>
      {nicks}{filigree}
      <path d="M120 4L128 0 136 4 141 13 128 22 115 13Z" fill="url(#gold3d)" stroke="#4a1c04" stroke-width="2"/>
      <path d="M128 6L134 13 128 20 122 13Z" fill="url(#sapphire)" stroke="#f9ecc4" stroke-width="1.4"/>
      <!-- Ornamental underlay blank nameplate: all text lives in Godot UI. -->
      <path d="M28 178L40 173 216 173 228 178 237 193 229 228 216 240 41 240 27 227 18 193Z" fill="#401805" opacity=".75" transform="translate(0 3)"/>
      <path d="M26 177L40 170 216 170 230 177 238 195 229 231 218 240 38 240 27 229 18 196Z" fill="url(#gold3d)" stroke="#602909" stroke-width="3"/>
      <path d="M35 183L47 178 208 178 221 184 229 196 219 223 210 231 46 231 37 224 28 197Z" fill="url(#nameplate)" stroke="#ffdc76" stroke-width="1.8"/>
      <path d="M43 187Q129 176 215 187" stroke="#ffe7ad" opacity=".58" stroke-width="1.7" fill="none"/>
      <path d="M42 222Q129 232 215 222" stroke="#a56322" opacity=".6" stroke-width="1.7" fill="none"/>
      <path d="M26 191L13 198 27 206M230 191L243 198 229 206" fill="url(#gold3d)" stroke="#592000" stroke-width="1.7"/>
      <path d="M121 169L128 161 135 169 128 179Z" fill="url(#gold3d)" stroke="#582505" stroke-width="1.4"/>
      <path d="M128 164L133 169 128 175 123 169Z" fill="url(#sapphire)" stroke="#d8eef9" stroke-width=".7"/>
      <path d="M121 237L128 229 135 237 128 249Z" fill="url(#gold3d)" stroke="#59270c" stroke-width="1.5"/>
      <path d="M128 232L133 238 128 245 123 238Z" fill="url(#sapphire)" stroke="#d8eef9" stroke-width=".7"/>
      '''


def bag():
    straps=''
    for x in [97,146]:
        straps+=f'''
        <path d="M{x} 67L{x+3} 156" stroke="#4b2209" stroke-width="14"/>
        <path d="M{x-3} 65L{x} 156" stroke="url(#brightGold)" stroke-width="8"/>
        <rect x="{x-10}" y="106" width="18" height="21" rx="3" fill="url(#gold3d)" stroke="#5a2405" stroke-width="2"/>
        <rect x="{x-5}" y="112" width="8" height="10" rx="2" fill="#5c2b0b" stroke="#ffeac2" stroke-width="1"/>
        '''
    return f'''
    <path d="M78 62Q70 54 74 33Q83 25 101 36L102 64" fill="none" stroke="#5e2e0c" stroke-width="18"/>
    <path d="M78 62Q70 54 74 33Q83 25 101 36L102 64" fill="none" stroke="url(#leatherHi)" stroke-width="10"/>
    <path d="M156 66Q155 34 173 35Q188 49 176 74" fill="none" stroke="#44210c" stroke-width="20"/>
    <path d="M156 66Q155 34 173 35Q188 49 176 74" fill="none" stroke="url(#leatherHi)" stroke-width="12"/>
    <path d="M68 72Q74 51 106 48Q142 41 179 63L185 140Q180 160 166 163L87 166Q64 153 63 134Z" fill="url(#leatherDark)" stroke="#48240b" stroke-width="6"/>
    <path d="M69 77Q91 57 128 57Q162 56 182 76L178 119Q165 132 130 129Q96 133 69 118Z" fill="url(#leatherHi)" stroke="#f4ba5b" stroke-width="3"/>
    <path d="M75 91Q130 106 177 91" fill="none" stroke="#fff2bb" stroke-width="3" opacity=".42"/>
    <path d="M67 126L78 123 90 159 74 154Z" fill="url(#leatherDark)" stroke="#b17a36" stroke-width="3"/>
    <path d="M165 125L179 124 182 149 166 158Z" fill="url(#leatherHi)" stroke="#b17a36" stroke-width="3"/>
    <path d="M91 120Q127 115 160 122L159 162 92 161Z" fill="url(#leatherHi)" stroke="#56280c" stroke-width="4"/>
    {straps}
    <path d="M91 121L163 119 157 145Q129 153 96 144Z" fill="url(#leatherHi)" stroke="#f0bb64" stroke-width="2"/>
    <path d="M118 105L138 105 136 128 120 128Z" fill="url(#gold3d)" stroke="#67370b" stroke-width="2"/>
    <path d="M123 107L133 107 131 116 125 116Z" fill="url(#sapphire)" stroke="#f3e6bb" stroke-width="1"/>
    <path d="M82 141v11M170 137v13" stroke="#f9e9ae" stroke-width="2" stroke-dasharray="3 3" opacity=".7"/>
    <circle cx="82" cy="149" r="4" fill="url(#gold3d)"/><circle cx="169" cy="147" r="4" fill="url(#gold3d)"/>
    <path d="M89 64Q127 46 170 68" stroke="#fff4cc" opacity=".5" stroke-width="4" fill="none"/>
    '''


def world():
    return '''
    <!-- rolled parchment with shaded rollers -->
    <path d="M68 50Q119 64 168 48L170 150Q119 140 72 151Z" fill="url(#paper)" stroke="#7b3c0b" stroke-width="5"/>
    <path d="M86 69Q117 56 155 68L148 126Q118 135 88 117Z" fill="#dbbf70" stroke="#a87132" stroke-width="2"/>
    <path d="M99 80L120 77 129 93 121 110 106 110 91 94Z" fill="#6c9f74" opacity=".9"/>
    <path d="M122 74L144 84 139 104 154 117 132 116Z" fill="#7baa74" opacity=".8"/>
    <path d="M82 73Q103 77 112 106T151 119" stroke="#a77a32" fill="none" stroke-width="2" stroke-dasharray="3 5"/>
    <path d="M64 47Q71 29 83 37Q90 42 85 53L84 146Q72 161 62 147Q55 132 62 117Z" fill="url(#gold3d)" stroke="#73400d" stroke-width="3"/>
    <path d="M69 42Q78 37 80 47L79 146Q66 157 66 141Z" fill="url(#paper)" stroke="#b2792f" stroke-width="1"/>
    <path d="M159 51Q167 33 176 39Q186 51 178 63L177 143Q165 160 157 144Z" fill="url(#gold3d)" stroke="#73400d" stroke-width="3"/>
    <path d="M164 44Q174 39 176 55L172 145Q164 151 162 138Z" fill="url(#paper)"/>
    <!-- Scarlet waypoint pin -->
    <path d="M131 58C118 58 115 69 119 79L131 96 144 79C150 67 141 58 131 58Z" fill="url(#ruby)" stroke="#ffcb74" stroke-width="2.8"/>
    <circle cx="131" cy="72" r="5.5" fill="#ffebae"/>
    <!-- Antique compass -->
    <circle cx="166" cy="130" r="27" fill="#321b11" stroke="url(#gold3d)" stroke-width="6"/>
    <circle cx="166" cy="130" r="21" fill="url(#bronze)" stroke="#ffebc1" stroke-width="1.3"/>
    <path d="M166 110L171 125 185 130 171 135 166 150 161 135 147 130 161 125Z" fill="url(#silver)" stroke="#3f2e18" stroke-width="1.5"/>
    <path d="M166 112L169 130 166 149 163 130Z" fill="#8b3620"/>
    <circle cx="166" cy="130" r="3" fill="url(#gold3d)"/>
    '''


def party():
    return '''
    <circle cx="126" cy="95" r="67" fill="url(#blueAura)"/>
    <g stroke="#d7fbff" stroke-width="2.5" stroke-linejoin="round">
      <circle cx="89" cy="71" r="15" fill="url(#blueBody)"/>
      <path d="M66 123Q66 92 91 92Q114 92 115 127L109 137H76Z" fill="url(#blueBody)"/>
      <circle cx="163" cy="71" r="15" fill="url(#blueBody)"/>
      <path d="M143 129Q141 96 161 94Q183 94 191 125L181 139H147Z" fill="url(#blueBody)"/>
      <circle cx="126" cy="61" r="18" fill="url(#blueBody)"/>
      <path d="M98 135Q103 91 127 91Q151 91 157 133L146 146H111Z" fill="url(#blueBody)"/>
    </g>
    <path d="M83 56Q90 50 96 56M119 48Q128 40 135 48M158 58Q165 51 171 58" fill="none" stroke="#ffffff" opacity=".9" stroke-width="2"/>
    <circle cx="178" cy="132" r="28" fill="url(#bronze)" stroke="#4b2a11" stroke-width="3"/>
    <circle cx="178" cy="132" r="21" fill="#30100d" stroke="url(#gold3d)" stroke-width="4"/>
    <path d="M178 117V147M163 132H193" stroke="#fff4c0" stroke-width="7" stroke-linecap="round"/>
    <path d="M178 117V147M163 132H193" stroke="#a77626" stroke-width="1.4"/>
    '''


def friends():
    return '''
    <circle cx="104" cy="73" r="21" fill="url(#ivory)" stroke="#764218" stroke-width="2"/>
    <circle cx="148" cy="72" r="22" fill="url(#ivory)" stroke="#764218" stroke-width="2"/>
    <path d="M59 141Q61 102 89 101H115Q134 110 138 145Z" fill="url(#ivory)" stroke="#7f4a28" stroke-width="3"/>
    <path d="M110 141Q112 102 139 101H159Q185 109 195 143Z" fill="url(#ivory)" stroke="#7f4a28" stroke-width="3"/>
    <path d="M88 63Q99 50 109 60M134 64Q150 51 160 63" stroke="#ffffff" stroke-width="4" fill="none" opacity=".55"/>
    <path d="M78 127Q101 111 120 126M131 128Q152 112 174 128" stroke="#f7e2ad" opacity=".75" fill="none" stroke-width="3"/>
    <path d="M178 119Q169 103 157 116Q150 131 177 154Q206 130 196 117Q187 108 178 119Z" fill="url(#pink)" stroke="#f9a6bb" stroke-width="3"/>
    <path d="M167 118Q171 115 176 120" fill="none" stroke="#ffeef4" stroke-width="3" opacity=".65"/>
    '''


def ranking():
    laurel=''
    for side in [-1,1]:
        for i in range(6):
            y=75+i*15
            x=128+side*(65+8*math.sin(i*.48))
            dx=side*(17 if i%2 else 6)
            laurel+=f'<ellipse cx="{x+dx:.1f}" cy="{y:.1f}" rx="6" ry="13" transform="rotate({side*(-40+15*i)} {x+dx:.1f} {y:.1f})" fill="url(#gold3d)" stroke="#6f3406" stroke-width="1"/>'
    return f'''
    <path d="M84 71Q63 67 69 95Q75 109 96 109" fill="none" stroke="url(#gold3d)" stroke-width="11"/>
    <path d="M171 71Q194 64 190 94Q185 113 163 109" fill="none" stroke="url(#gold3d)" stroke-width="11"/>
    <path d="M82 62H174V89Q171 115 144 126H112Q84 117 82 89Z" fill="url(#gold3d)" stroke="#7b3805" stroke-width="3"/>
    <path d="M98 69Q104 103 126 115" stroke="#fff6cf" stroke-width="9" opacity=".62" fill="none"/>
    <path d="M120 125V139M136 125V139" stroke="url(#gold3d)" stroke-width="8"/>
    <path d="M99 143L157 143 167 154H89Z" fill="url(#gold3d)" stroke="#64320a" stroke-width="3"/>
    <path d="M96 55L88 33 106 43 117 19 130 40 144 20 152 43 171 32 164 55Z" fill="url(#gold3d)" stroke="#5b2a0b" stroke-width="3"/>
    <path d="M98 52H161" stroke="#fef3c7" stroke-width="3"/>
    <circle cx="117" cy="42" r="4" fill="url(#ruby)"/><circle cx="144" cy="42" r="4" fill="url(#sapphire)"/>
    <path d="M68 78Q44 120 84 155" fill="none" stroke="url(#gold3d)" stroke-width="7"/>
    <path d="M188 78Q212 120 172 155" fill="none" stroke="url(#gold3d)" stroke-width="7"/>
    {laurel}
    '''


def settings():
    cog=gear_poly(128,102,78,67,10)
    spokes=''
    for i in range(10):
        a=math.tau*i/10
        x1,y1=128+44*math.cos(a),102+44*math.sin(a)
        x2,y2=128+65*math.cos(a),102+65*math.sin(a)
        spokes+=f'<path d="M{x1:.1f} {y1:.1f}L{x2:.1f} {y2:.1f}" stroke="#b7d1e3" stroke-width="5"/>'
    lines=''
    for i in range(12):
        a=math.tau*i/12
        x1,y1=128+6*math.cos(a),102+6*math.sin(a)
        x2,y2=128+34*math.cos(a),102+34*math.sin(a)
        lines+=f'<path d="M{x1:.1f} {y1:.1f}L{x2:.1f} {y2:.1f}" stroke="#c0eaff" opacity=".6" stroke-width="1.3"/>'
    return f'''
    <polygon points="{cog}" fill="url(#steel)" stroke="#313b4b" stroke-width="5" stroke-linejoin="round"/>
    <polygon points="{gear_poly(128,102,70,61,10)}" fill="none" stroke="#e4f5ff" stroke-width="2.3"/>
    <circle cx="128" cy="102" r="62" fill="url(#steel2)" stroke="#29374c" stroke-width="5"/>
    {spokes}
    <circle cx="128" cy="102" r="46" fill="url(#steel)" stroke="#ffffff" opacity=".88" stroke-width="3"/>
    <circle cx="128" cy="102" r="36" fill="url(#blueDark)" stroke="#59cafa" stroke-width="4"/>
    <circle cx="128" cy="102" r="31" fill="url(#blueAura)"/>
    {lines}
    <circle cx="128" cy="102" r="21" fill="url(#blueCore)"/>
    <path d="M128 59L134 95 166 102 134 108 128 143 122 108 89 102 122 95Z" fill="#9cf8ff" opacity=".72"/>
    <circle cx="128" cy="102" r="6" fill="#ffffff"/>
    '''


def guild():
    mane=''
    for i in range(12):
        a=math.tau*i/12
        px=128+30*math.cos(a)
        py=99+31*math.sin(a)
        mane+=f'<path d="M128 99L{px:.1f} {py:.1f}L{128+47*math.cos(a+.23):.1f} {99+46*math.sin(a+.23):.1f}Z" fill="url(#gold3d)" stroke="#a2681c" stroke-width=".7"/>'
    return f'''
    <path d="M48 54L204 54 201 155 182 142 156 162 128 148 99 162 76 143 53 159Z" fill="url(#rubyCloth)" stroke="url(#gold3d)" stroke-width="7"/>
    <path d="M66 61L188 61 185 141 161 151 128 137 97 151 69 142Z" fill="url(#redVelvet)" stroke="#ffad54" stroke-width="2"/>
    <path d="M50 55L206 55" stroke="#61280c" stroke-width="17" stroke-linecap="round"/>
    <path d="M50 50L206 50" stroke="url(#gold3d)" stroke-width="10" stroke-linecap="round"/>
    <path d="M55 44L55 61M201 44L201 61" stroke="url(#gold3d)" stroke-width="9"/>
    <path d="M128 42L138 53 128 65 118 53Z" fill="url(#sapphire)" stroke="#ffe8b9" stroke-width="3"/>
    {mane}
    <path d="M102 86Q110 65 126 77Q146 65 155 86L150 120Q141 138 128 135Q110 137 105 117Z" fill="url(#gold3d)" stroke="#6b300b" stroke-width="2.8"/>
    <path d="M109 91L120 94 118 102 109 99M137 94L148 91 147 99 137 102" fill="#4b200b"/>
    <path d="M113 89L122 92M133 92L143 89" stroke="#fff5d0" stroke-width="2.3"/>
    <path d="M118 110L128 104 138 110 132 119 128 116 124 119Z" fill="#62370d"/>
    <path d="M122 121L128 129 134 121" fill="none" stroke="#632c09" stroke-width="3"/>
    <path d="M73 70V140M182 70V141" stroke="#f0a646" opacity=".45" stroke-width="4"/>
    '''


def quest():
    checks=''
    for i in range(3):
        y=80+i*22
        checks+=f'''
        <rect x="90" y="{y}" width="13" height="13" fill="#f8dfae" stroke="#9d5f20" stroke-width="1.8"/>
        <path d="M90 {y+6}L95 {y+10}L105 {y-2}" fill="none" stroke="#a44a1d" stroke-width="3"/>
        <path d="M111 {y+5}h43" stroke="#af7c41" stroke-width="3"/>
        '''
    return f'''
    <path d="M80 55Q77 48 85 44H163Q174 48 173 62L168 155H82Z" fill="url(#paper)" stroke="#875322" stroke-width="4"/>
    <path d="M81 50Q76 45 72 52Q70 60 82 65L171 65Q183 58 173 50Z" fill="url(#gold3d)" stroke="#66320e" stroke-width="2"/>
    <path d="M81 143Q75 144 79 155Q88 161 99 157H171Q178 153 169 145Z" fill="url(#gold3d)" stroke="#713f0b" stroke-width="2"/>
    {checks}
    <path d="M164 122Q183 75 204 28Q213 12 213 39Q207 81 173 132Z" fill="url(#ivory)" stroke="#654a31" stroke-width="2"/>
    <path d="M167 126L210 24Q183 57 174 100" fill="none" stroke="#b5c9ce" stroke-width="2.5"/>
    <path d="M168 128L158 150" fill="none" stroke="#573719" stroke-width="3"/>
    <circle cx="164" cy="143" r="17" fill="url(#ruby)" stroke="url(#gold3d)" stroke-width="4"/>
    <path d="M153 142L161 150 175 133" stroke="#ffe2a2" stroke-width="5" stroke-linecap="round" fill="none"/>
    '''


def mail():
    return '''
    <!-- The red circular indicator at TOP RIGHT from the concept is intentionally absent. -->
    <rect x="58" y="69" width="143" height="88" rx="10" fill="url(#paper)" stroke="#86451c" stroke-width="5"/>
    <path d="M59 73L129 126 200 73" fill="none" stroke="#914f23" stroke-width="5"/>
    <path d="M61 149L106 109M197 149L151 109" fill="none" stroke="#cba56d" stroke-width="3"/>
    <path d="M63 74L126 120Q130 123 135 120L196 74" fill="url(#ivory)" stroke="#a2703e" stroke-width="3"/>
    <path d="M67 78L127 118" stroke="#fffaf0" stroke-width="3" opacity=".72"/>
    <path d="M68 148Q130 159 193 147" fill="none" stroke="#b78a4e" stroke-width="2"/>
    <circle cx="130" cy="130" r="17" fill="url(#ruby)" stroke="url(#gold3d)" stroke-width="4"/>
    <path d="M123 128l6 7 10-12" stroke="#ffcf92" stroke-width="3" fill="none"/>
    <!-- no floating notification orb; the center wax seal is part of the envelope. -->
    '''


def events():
    return '''
    <rect x="70" y="48" width="129" height="114" rx="8" fill="url(#ivory)" stroke="#6a3617" stroke-width="5"/>
    <path d="M74 54h121v31H74Z" fill="url(#rubyCloth)" stroke="#a4632d" stroke-width="2"/>
    <path d="M94 42v24M172 42v24" stroke="#5c290b" stroke-width="12" stroke-linecap="round"/>
    <path d="M94 42v24M172 42v24" stroke="url(#gold3d)" stroke-width="7" stroke-linecap="round"/>
    <path d="M83 90H185M83 120H185M83 149H160M111 89v69M145 89v67" stroke="#ae8d64" stroke-width="1.5" opacity=".9"/>
    <polygon points="'''+star(130,122,26,12,5)+'''" fill="url(#ruby)" stroke="#7b1b10" stroke-width="3"/>
    <path d="M116 108L129 98L144 111" stroke="#ffdca0" fill="none" opacity=".8" stroke-width="2"/>
    <path d="M169 134L203 132 213 163 165 169Z" fill="url(#purple)" stroke="#4c1b51" stroke-width="3"/>
    <path d="M166 126L199 126 209 137 174 141Z" fill="url(#gold3d)" stroke="#764516" stroke-width="2"/>
    <path d="M183 126L188 170" stroke="#fff1ae" stroke-width="8"/>
    <path d="M168 149L210 146" stroke="#fff1ae" stroke-width="7"/>
    <path d="M186 128Q169 102 164 118Q163 128 186 130Z" fill="url(#gold3d)" stroke="#66340b" stroke-width="2"/>
    <path d="M186 128Q206 105 212 120Q208 133 186 130Z" fill="url(#gold3d)" stroke="#66340b" stroke-width="2"/>
    '''


GLYPHS={'bag':bag,'world':world,'party':party,'friends':friends,'ranking':ranking,
        'settings':settings,'guild':guild,'quest':quest,'mail':mail,'events':events}

DEFS='''
  <defs>
  <linearGradient id="gold3d" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#fff5c9"/><stop offset=".19" stop-color="#f4b851"/><stop offset=".42" stop-color="#9c4c0b"/><stop offset=".61" stop-color="#f8d982"/><stop offset=".81" stop-color="#b36e21"/><stop offset="1" stop-color="#ffe39c"/></linearGradient>
  <linearGradient id="brightGold" x1="0" y1="0" x2=".8" y2="1"><stop offset="0" stop-color="#fff9d5"/><stop offset=".27" stop-color="#ffc86b"/><stop offset=".61" stop-color="#8c4f0f"/><stop offset="1" stop-color="#f9e5ab"/></linearGradient>
  <radialGradient id="darkGold"><stop stop-color="#ffe69a"/><stop offset=".35" stop-color="#ba802f"/><stop offset=".74" stop-color="#704012"/><stop offset="1" stop-color="#3b1b06"/></radialGradient>
  <radialGradient id="redInner" cx=".39" cy=".28" r=".91"><stop stop-color="#723018"/><stop offset=".31" stop-color="#441b16"/><stop offset=".78" stop-color="#180912"/><stop offset="1" stop-color="#070308"/></radialGradient>
  <radialGradient id="warmHalo"><stop stop-color="#d18c45" stop-opacity=".65"/><stop offset=".68" stop-color="#3d160b" stop-opacity=".38"/><stop offset="1" stop-color="#17030d" stop-opacity="0"/></radialGradient>
  <linearGradient id="nameplate" x1="0" y1="0" x2="0" y2="1"><stop stop-color="#5f2615"/><stop offset=".22" stop-color="#291008"/><stop offset=".76" stop-color="#1c0709"/><stop offset="1" stop-color="#623017"/></linearGradient>
  <linearGradient id="leatherDark" x1="0" y1="0" x2="1" y2="1"><stop stop-color="#6b2f14"/><stop offset=".24" stop-color="#b8772e"/><stop offset=".61" stop-color="#603016"/><stop offset="1" stop-color="#b47b3a"/></linearGradient>
  <linearGradient id="leatherHi" x1=".2" y1="0" x2=".8" y2="1"><stop stop-color="#f4c379"/><stop offset=".22" stop-color="#a85b27"/><stop offset=".49" stop-color="#633014"/><stop offset=".78" stop-color="#c08a44"/><stop offset="1" stop-color="#602c0a"/></linearGradient>
  <linearGradient id="paper" x1="0" y1="0" x2="1" y2=".8"><stop stop-color="#ffecb9"/><stop offset=".42" stop-color="#e5b97b"/><stop offset=".71" stop-color="#cba06a"/><stop offset="1" stop-color="#e8cf9c"/></linearGradient>
  <radialGradient id="bronze" cx=".33" cy=".19"><stop stop-color="#fff5c0"/><stop offset=".28" stop-color="#c69852"/><stop offset=".65" stop-color="#6d482b"/><stop offset="1" stop-color="#2d1a15"/></radialGradient>
  <linearGradient id="silver" x1="0" y1="0" x2=".8" y2="1"><stop stop-color="#ffffff"/><stop offset=".33" stop-color="#abb8c6"/><stop offset=".54" stop-color="#5e6a79"/><stop offset=".85" stop-color="#e0e4ef"/><stop offset="1" stop-color="#7d8692"/></linearGradient>
  <linearGradient id="steel" x1="0" y1="0" x2=".8" y2="1"><stop stop-color="#f7f9ff"/><stop offset=".18" stop-color="#9ba8b9"/><stop offset=".43" stop-color="#4d5869"/><stop offset=".67" stop-color="#c8d4e3"/><stop offset="1" stop-color="#677382"/></linearGradient>
  <radialGradient id="steel2"><stop stop-color="#41566b"/><stop offset=".67" stop-color="#80909f"/><stop offset="1" stop-color="#202a3a"/></radialGradient>
  <radialGradient id="sapphire" cx=".28" cy=".23"><stop stop-color="#efffff"/><stop offset=".16" stop-color="#4ecbff"/><stop offset=".56" stop-color="#0069ba"/><stop offset="1" stop-color="#001d5a"/></radialGradient>
  <radialGradient id="blueAura"><stop stop-color="#269eff" stop-opacity=".9"/><stop offset=".66" stop-color="#0845ca" stop-opacity=".35"/><stop offset="1" stop-color="#00326d" stop-opacity="0"/></radialGradient>
  <radialGradient id="blueBody" cx=".35" cy=".25"><stop stop-color="#c7faff"/><stop offset=".37" stop-color="#208efc"/><stop offset=".8" stop-color="#0637b2"/><stop offset="1" stop-color="#031756"/></radialGradient>
  <radialGradient id="blueCore"><stop stop-color="#ffffff"/><stop offset=".17" stop-color="#c4ffff"/><stop offset=".47" stop-color="#00a4ee"/><stop offset="1" stop-color="#00239a"/></radialGradient>
  <radialGradient id="blueDark"><stop stop-color="#002e70"/><stop offset=".62" stop-color="#00144e"/><stop offset="1" stop-color="#000818"/></radialGradient>
  <radialGradient id="ivory" cx=".36" cy=".18"><stop stop-color="#fffcef"/><stop offset=".32" stop-color="#ffe3a9"/><stop offset=".67" stop-color="#dbb47f"/><stop offset="1" stop-color="#986a3d"/></radialGradient>
  <radialGradient id="pink" cx=".29" cy=".16"><stop stop-color="#fff4f6"/><stop offset=".28" stop-color="#ff95b9"/><stop offset=".67" stop-color="#e34782"/><stop offset="1" stop-color="#8c114c"/></radialGradient>
  <radialGradient id="ruby" cx=".32" cy=".18"><stop stop-color="#ffdabb"/><stop offset=".2" stop-color="#f24737"/><stop offset=".56" stop-color="#b51616"/><stop offset="1" stop-color="#5d050d"/></radialGradient>
  <linearGradient id="rubyCloth" x1="0" y1="0" x2=".8" y2="1"><stop stop-color="#f6a43f"/><stop offset=".2" stop-color="#950c1a"/><stop offset=".59" stop-color="#4e0016"/><stop offset=".82" stop-color="#b22324"/><stop offset="1" stop-color="#560a10"/></linearGradient>
  <linearGradient id="redVelvet" x1="0" y1="0" x2="1" y2="1"><stop stop-color="#d13d2e"/><stop offset=".38" stop-color="#790b17"/><stop offset=".65" stop-color="#8c1821"/><stop offset="1" stop-color="#470414"/></linearGradient>
  <linearGradient id="purple" x1="0" y1="0" x2=".8" y2="1"><stop stop-color="#dfb9ff"/><stop offset=".33" stop-color="#8739a4"/><stop offset=".67" stop-color="#4d1e79"/><stop offset="1" stop-color="#e4a8e6"/></linearGradient>
  </defs>'''


def svg(name):
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256" viewBox="0 0 256 256">{DEFS}<g>{base_art()}</g><g>{GLYPHS[name]()}</g></svg>'


def main():
    OUTPUT.mkdir(parents=True,exist_ok=True)
    for name in ORDER:
        png=cairosvg.svg2png(bytestring=svg(name).encode(),output_width=512,output_height=512)
        im=Image.open(BytesIO(png)).convert('RGBA').resize((256,256),Image.Resampling.LANCZOS)
        out=OUTPUT/(name+'.png')
        im.save(out,optimize=True)
        print('Rendered independent PNG:',out,im.size)
    assert len(list(OUTPUT.glob('*.png')))==10

if __name__=='__main__':
    main()