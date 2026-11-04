#!/usr/bin/env python3
"""Render seven individually authored Leoonline combat HUD sprites as real RGBA PNGs.
No crop, screenshots, baked labels, or notification badges.
"""
from io import BytesIO
from pathlib import Path
import cairosvg
from PIL import Image

OUT=Path(__file__).resolve().parents[1]/"assets/ui/hud/premium"
DEFS="""
<defs>
 <linearGradient id="steel" x1="0" x2="1" y1="0" y2=".2"><stop stop-color="#223449"/><stop offset=".32" stop-color="#f6ffff"/><stop offset=".58" stop-color="#8ebecf"/><stop offset=".88" stop-color="#edfaff"/><stop offset="1" stop-color="#516778"/></linearGradient>
 <linearGradient id="gold" x1="0" y1="0" x2="1" y2="1"><stop stop-color="#fff3c0"/><stop offset=".25" stop-color="#ffd66e"/><stop offset=".55" stop-color="#9e4b18"/><stop offset=".75" stop-color="#ffc85c"/><stop offset="1" stop-color="#fff0b1"/></linearGradient>
 <linearGradient id="fire" x1="0" y1="1" x2="1" y2="0"><stop stop-color="#520a20"/><stop offset=".34" stop-color="#d31b38"/><stop offset=".7" stop-color="#ff7643"/><stop offset="1" stop-color="#fff3b6"/></linearGradient>
 <linearGradient id="azure" x1="0" y1="1" x2="1" y2="0"><stop stop-color="#084579"/><stop offset=".44" stop-color="#1caddc"/><stop offset=".8" stop-color="#adffff"/><stop offset="1" stop-color="#f6ffff"/></linearGradient>
 <radialGradient id="halo"><stop stop-color="#d72738" stop-opacity=".65"/><stop offset=".54" stop-color="#721324" stop-opacity=".26"/><stop offset="1" stop-color="#510a18" stop-opacity="0"/></radialGradient>
 <radialGradient id="dark"><stop stop-color="#5f1830"/><stop offset=".65" stop-color="#2e1024"/><stop offset="1" stop-color="#0e111f"/></radialGradient>
</defs>"""
ART={
"button_attack_swords":"""
<g transform="translate(0 3)">
<g transform="rotate(-42 128 130)"><path d="M128 14L152 74 140 151 128 166 116 151 104 74Z" fill="#ffad4e" opacity=".22" stroke="#ff773b" stroke-width="16"/>
<path d="M128 16L150 77 139 152 128 165 117 152 106 77Z" fill="url(#steel)" stroke="#ffe2a2" stroke-width="4" stroke-linejoin="round"/>
<path d="M128 21V158" stroke="#fff" stroke-width="4" opacity=".9"/><path d="M96 163Q128 143 160 163L160 177Q128 164 96 177Z" fill="url(#gold)" stroke="#613014" stroke-width="4"/>
<path d="M124 171L132 171 137 226 119 226Z" fill="#7f2631" stroke="url(#gold)" stroke-width="5"/>
<path d="M121 187L135 195M121 202L135 210" stroke="#ffdc89" stroke-width="5"/><circle cx="128" cy="232" r="9" fill="url(#gold)"/></g>
<g transform="rotate(42 128 130)"><path d="M128 16L152 74 140 151 128 166 116 151 104 74Z" fill="#ff8535" opacity=".17" stroke="#ff6929" stroke-width="15"/>
<path d="M128 18L150 77 139 151 128 163 117 151 106 77Z" fill="url(#steel)" stroke="#ffe8ad" stroke-width="4" stroke-linejoin="round"/>
<path d="M128 24V156" stroke="#fff" stroke-width="3.5" opacity=".85"/><path d="M96 162Q128 141 160 162L160 176Q128 165 96 176Z" fill="url(#gold)" stroke="#643416" stroke-width="4"/>
<path d="M123 174L133 174 138 228 118 228Z" fill="#872436" stroke="url(#gold)" stroke-width="5"/>
<path d="M121 188L136 198M121 206L136 216" stroke="#ffdb7f" stroke-width="4"/><circle cx="128" cy="232" r="9" fill="url(#gold)"/></g>
<path d="M128 106L151 128 128 152 105 128Z" fill="url(#fire)" stroke="url(#gold)" stroke-width="5"/>
<path d="M128 114L138 128 128 139 119 128Z" fill="#fff1ce" opacity=".9"/></g>""",
"button_target_lock":"""
<path d="M128 30A98 98 0 0 1 226 128" fill="none" stroke="url(#gold)" stroke-width="11" stroke-linecap="round"/>
<path d="M226 128A98 98 0 0 1 128 226" fill="none" stroke="url(#fire)" stroke-width="11" stroke-linecap="round"/>
<path d="M128 226A98 98 0 0 1 30 128" fill="none" stroke="url(#gold)" stroke-width="11" stroke-linecap="round"/>
<path d="M30 128A98 98 0 0 1 128 30" fill="none" stroke="url(#fire)" stroke-width="11" stroke-linecap="round"/>
<circle cx="128" cy="128" r="63" fill="none" stroke="#fff1be" stroke-width="5" stroke-dasharray="32 15" opacity=".9"/>
<path d="M128 6V76M128 180V250M6 128H76M180 128H250" stroke="#572217" stroke-width="20" stroke-linecap="round"/>
<path d="M128 6V76M128 180V250M6 128H76M180 128H250" stroke="url(#gold)" stroke-width="12" stroke-linecap="round"/>
<path d="M128 89L149 128 128 167 107 128Z" fill="url(#fire)" stroke="#ffe4a3" stroke-width="6"/>
<circle cx="128" cy="128" r="9" fill="#fff6dd"/>
<path d="M44 44L78 78M212 44L178 78M44 212L78 178M212 212L178 178" stroke="#ffb64d" stroke-width="7" opacity=".75"/>""",
"button_dash":"""
<path d="M15 167L96 142M6 196L100 163M37 219L111 187" fill="none" stroke="url(#azure)" stroke-width="13" stroke-linecap="round" opacity=".85"/>
<path d="M28 112L118 84 144 49 139 107 216 59 178 135 243 128 174 178 135 222 139 162 83 187 112 146Z"
fill="url(#azure)" stroke="#d4ffff" stroke-width="6" stroke-linejoin="round"/>
<path d="M102 139L165 94 141 155 205 133 127 195 145 157Z" fill="url(#gold)" stroke="#fff6ce" stroke-width="5" stroke-linejoin="round"/>
<path d="M26 79L94 99M18 106L75 115" stroke="#fff2a2" stroke-width="7" stroke-linecap="round" opacity=".75"/>""",
"button_jump":"""
<path d="M34 194Q124 258 223 186" fill="none" stroke="#ffcd68" stroke-width="10" stroke-linecap="round" opacity=".8"/>
<path d="M124 16L67 95 104 95 104 167 151 167 151 95 190 95Z" fill="url(#azure)" stroke="url(#gold)" stroke-width="8" stroke-linejoin="round"/>
<path d="M124 36L124 153" stroke="#fff" stroke-width="7" stroke-linecap="round" opacity=".85"/>
<path d="M55 163Q80 151 97 181L131 188Q146 196 141 209Q91 224 48 201Q39 180 55 163Z" fill="url(#steel)" stroke="url(#gold)" stroke-width="6"/>
<path d="M54 190Q89 210 138 201" stroke="#fff3c1" stroke-width="6" fill="none"/>
<path d="M197 135l21 -25m-15 48l28 -13" stroke="#fbe49e" stroke-width="7" stroke-linecap="round"/>""",
"button_pickup":"""
<path d="M128 19L151 53 137 89 119 89 105 53Z" fill="url(#azure)" stroke="url(#gold)" stroke-width="7"/>
<path d="M128 29L138 55 128 76 117 55Z" fill="#eaffff" opacity=".92"/>
<path d="M69 120Q63 106 71 99Q82 89 94 105L119 146 120 93Q122 80 135 82Q146 84 147 99L148 140 162 102Q170 87 184 95Q195 102 187 119L179 151 192 126Q202 112 216 121Q229 132 217 151L188 205Q171 228 132 229L101 224Q83 213 63 179L42 156Q37 144 46 136Q58 127 69 139L92 160Z"
fill="url(#gold)" stroke="#5c2a17" stroke-width="8" stroke-linejoin="round"/>
<path d="M88 173Q137 189 178 165M97 196Q139 211 174 187" stroke="#fff0ba" stroke-width="5" stroke-linecap="round" fill="none"/>
<path d="M91 103L77 79M158 74L176 51M196 96L218 77" stroke="#b5ffff" stroke-width="7" stroke-linecap="round"/>""",
"joystick_base":"""
<circle cx="128" cy="128" r="108" fill="url(#dark)" fill-opacity=".72" stroke="#49202a" stroke-width="11"/>
<circle cx="128" cy="128" r="97" fill="none" stroke="url(#gold)" stroke-width="9"/>
<circle cx="128" cy="128" r="79" fill="#391729" fill-opacity=".55" stroke="#ffcf80" stroke-opacity=".6" stroke-width="3"/>
<circle cx="128" cy="128" r="57" fill="none" stroke="#d97160" stroke-opacity=".4" stroke-width="3" stroke-dasharray="8 11"/>
<path d="M128 15V44M128 212V241M15 128H44M212 128H241" stroke="url(#gold)" stroke-width="12" stroke-linecap="round"/>
<path d="M128 63L117 84H139Z M128 193L117 172H139Z M63 128L84 117V139Z M193 128L172 117V139Z" fill="#ffe8ad" opacity=".75"/>""",
"joystick_knob":"""
<circle cx="128" cy="128" r="107" fill="#180d1d" fill-opacity=".83" stroke="#582031" stroke-width="7"/>
<circle cx="128" cy="128" r="97" fill="url(#gold)" stroke="#7c3b21" stroke-width="5"/>
<circle cx="128" cy="128" r="82" fill="url(#dark)" stroke="#fff0ac" stroke-width="4"/>
<circle cx="128" cy="128" r="57" fill="url(#fire)" stroke="#501020" stroke-width="7"/>
<path d="M77 118Q103 63 163 91" fill="none" stroke="#fff4cd" stroke-opacity=".7" stroke-width="9" stroke-linecap="round"/>
<path d="M118 91L138 91 150 128 128 154 106 128Z" fill="url(#gold)" stroke="#fff4ca" stroke-width="3"/>"""
}
def main():
 OUT.mkdir(parents=True,exist_ok=True)
 for name,art in ART.items():
  svg='<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256" viewBox="0 0 256 256">'+DEFS+'<circle cx="128" cy="130" r="113" fill="url(#halo)" opacity=".45"/>'+art+'</svg>'
  raw=cairosvg.svg2png(bytestring=svg.encode(),output_width=1024,output_height=1024)
  image=Image.open(BytesIO(raw)).convert("RGBA").resize((256,256),Image.Resampling.LANCZOS)
  path=OUT/(name+".png")
  image.save(path,optimize=True)
  assert image.getpixel((0,0))[3]==0,(name,"must be transparent")
  print(path,len(path.read_bytes()))
if __name__=="__main__":
 main()
