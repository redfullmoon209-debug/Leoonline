// Functional temporary RPG test UI. Original Godot PNG layout stays in source repository.
// IMGUI is used deliberately for a no-asset cross-platform prototype, not the final mobile HUD.
using System;
using System.Collections.Generic;
using UnityEngine;
using Leom.Gameplay;

namespace Leom.Prototype
{
    public sealed class LeomGameHUD : MonoBehaviour
    {
        private enum Tab { None, Inventory, Storage, Shop, Equipment, Character, Skills, Map, PvP, Settings }
        private Tab tab = Tab.None;
        private int bagPage, storagePage, shopPage, selectedBag = -1, selectedStorage = -1, selectedOffer = -1;
        private int selectedHotbar;
        private string moneyAmount = "100", moneyKind = "gold";
        private Vector2 scroll;
        private string confirmText;
        private Action confirmation;
        private float respawnAt = -1f;
        private Vector3 spawnPoint = new Vector3(0,0,0);
        private bool showThai;
        public bool WindowOpen => tab != Tab.None || confirmation != null;

        private void Update()
        {
            if (Input.GetKeyDown(KeyCode.B) || Input.GetKeyDown(KeyCode.I))
                tab = tab == Tab.Inventory ? Tab.None : Tab.Inventory;
            if (Input.GetKeyDown(KeyCode.C)) tab = tab == Tab.Character ? Tab.None : Tab.Character;
            if (Input.GetKeyDown(KeyCode.K)) tab = tab == Tab.Skills ? Tab.None : Tab.Skills;
            if (Input.GetKeyDown(KeyCode.Escape)) { confirmation = null; tab = Tab.None; }
            var player = PrototypeGame.Instance ? PrototypeGame.Instance.Player : null;
            if (!player) return;
            if (!player.IsAlive && respawnAt < 0) respawnAt = Time.time + 8f;
            if (!player.IsAlive && Time.time >= respawnAt && respawnAt >= 0)
            {
                player.Respawn(spawnPoint);
                respawnAt = -1f;
            }
        }

        private void OnGUI()
        {
            var rpg = LeomRpgService.Instance;
            if (rpg == null || rpg.Character == null) return;
            Matrix4x4 previous = GUI.matrix;
            float scale = Mathf.Clamp(Screen.height / 900f, .62f, 1.3f);
            GUI.matrix = Matrix4x4.Scale(new Vector3(scale,scale,1f));
            float w = Screen.width / scale, h = Screen.height / scale;
            float headerWidth = Mathf.Min(490f, w - 20f);
            var c = rpg.Character;
            var p = PrototypeGame.Instance ? PrototypeGame.Instance.Player : null;

            GUI.Box(new Rect(9,9,headerWidth,120),"LEOM — OFFLINE RPG MIGRATION TEST");
            GUI.Label(new Rect(20,35,headerWidth-25,23),
                "Lv " + c.level + "  EXP " + c.experience + "/" + rpg.ExperienceRequired() +
                "   Class " + c.job + "   SP " + c.skillPoints);
            GUI.Label(new Rect(20,58,headerWidth-25,23),
                "HP " + (p ? Mathf.CeilToInt(p.health).ToString() : "-") +
                "  Stamina " + (p ? Mathf.CeilToInt(p.stamina).ToString() : "-") +
                "  Gold " + LeomAmount.Format(c.wallet[0]));
            GUI.Label(new Rect(20,80,headerWidth-25,23),
                "Bag " + Count(c.bag) + "/" + c.unlocked + "/200 | Bank " +
                Count(c.storage) + "/200 | Kills " + c.pveKills + " | Target " +
                (p ? p.CurrentTarget : "none"));
            GUI.Label(new Rect(20,102,headerWidth-25,23),
                "WASD move | RMB orbit | LMB hit | T target | Q auto | 1/2/3 skills | E loot");
            float navY = 136f;
            float navWidth = Mathf.Min(840f,w-18f);
            string[] labels = {"Bag [B]","Bank","Shop","Gear","Stats [C]","Skills [K]","Map","PvP","Prefs"};
            int navCols = w < 710f ? 3 : 9;
            int navRows = (labels.Length + navCols - 1)/navCols;
            for(int i=0;i<labels.Length;i++)
            {
                float btnW = navWidth/navCols;
                if(GUI.Button(new Rect(9+(i%navCols)*btnW,navY+(i/navCols)*37f,btnW-2f,33f),labels[i]))
                {
                    Tab choice = (Tab)(i+1);
                    tab = tab == choice ? Tab.None : choice;
                    scroll = Vector2.zero;
                }
            }
            if (rpg.NoticeUntil > Time.time)
                GUI.Box(new Rect(Mathf.Max(9f,w-440),h-62f,Mathf.Min(430,w-18),35),rpg.Notice);
            if (tab != Tab.None)
            {
                float panelWidth = Mathf.Min(w-20f, 900f);
                float panelTop = navY + navRows*37f + 8f;
                float panelHeight = Mathf.Max(280f,Mathf.Min(h-panelTop-10f,625f));
                Rect window = new Rect((w-panelWidth)*.5f,panelTop,panelWidth,panelHeight);
                GUI.Box(window,tab + " — original Leoonline IDs, temporary Unity UI");
                if (GUI.Button(new Rect(window.xMax-46f,window.y+6f,36f,27f),"X"))
                    { tab = Tab.None; confirmation = null; }
                Rect area = new Rect(window.x+12f,window.y+39f,window.width-24f,window.height-51f);
                switch(tab)
                {
                    case Tab.Inventory: DrawInventory(rpg,area); break;
                    case Tab.Storage: DrawStorage(rpg,area); break;
                    case Tab.Shop: DrawShop(rpg,area); break;
                    case Tab.Equipment: DrawEquipment(rpg,area); break;
                    case Tab.Character: DrawCharacter(rpg,area); break;
                    case Tab.Skills: DrawSkills(rpg,area); break;
                    case Tab.Map: DrawMap(rpg,area); break;
                    case Tab.PvP: DrawPvP(area); break;
                    case Tab.Settings: DrawSettings(rpg,area); break;
                }
            }
            if (confirmation != null)
            {
                Rect modal = new Rect((w-480f)*.5f,(h-180f)*.5f,Mathf.Min(480,w-24),180);
                GUI.Box(modal,"Confirm item transaction");
                GUI.Label(new Rect(modal.x+18,modal.y+45,modal.width-36,50),confirmText);
                if(GUI.Button(new Rect(modal.x+24,modal.y+114,170,42),"Confirm"))
                {
                    Action action = confirmation; confirmation = null;
                    action?.Invoke();
                }
                if(GUI.Button(new Rect(modal.x+modal.width-196,modal.y+114,170,42),"Cancel"))
                    confirmation = null;
            }
            GUI.matrix=previous;
        }
        private static int Count(string[] slots)
        {
            int count=0;
            if(slots!=null)foreach(string id in slots)if(!string.IsNullOrEmpty(id))count++;
            return count;
        }
        private static string ItemName(string id)
        {
            var item=LegacyCatalog.Item(id);
            return item == null ? id : item.name;
        }
        private static void Text(Rect parent,float x,float y,string value,float width=400f)
        {
            GUI.Label(new Rect(parent.x+x,parent.y+y,Mathf.Min(width,parent.width-10),25),value);
        }
        private static bool Click(Rect parent,float x,float y,float width,string value)
        {
            return GUI.Button(new Rect(parent.x+x,parent.y+y,width,29f),value);
        }
        private void ShowConfirm(string prompt,Action action) { confirmText=prompt; confirmation=action; }
        private void DrawInventory(LeomRpgService rpg,Rect a)
        {
            var c=rpg.Character;
            Text(a,3,2,"Bag " + Count(c.bag) + "/" + c.unlocked + " / 200 slots | page " + (bagPage+1) + "/4");
            float gridW=Mathf.Min(a.width*.70f,590f);
            int columns=5;
            float cw=(gridW-6)/columns;
            float ch=Mathf.Clamp((a.height-81f)/10f,24f,43f);
            for(int i=0;i<50;i++)
            {
                int slot=bagPage*50+i;
                if(slot>=200)break;
                string id=c.bag[slot];
                string label=slot>=c.unlocked ? "[LOCK]" :
                    string.IsNullOrEmpty(id) ? (slot+1).ToString() : (slot+1)+":"+id;
                if(GUI.Button(new Rect(a.x+2+(i%columns)*cw,a.y+31+(i/columns)*ch,cw-2,ch-2),label))
                {
                    if(slot<c.unlocked) selectedBag=slot;
                }
            }
            float bx=gridW+12, bw=Mathf.Max(88f,a.width-bx-3f);
            string selected=selectedBag>=0 && selectedBag<200 ? c.bag[selectedBag] : "";
            Text(a,bx,27,"Selected: " + (string.IsNullOrEmpty(selected)?"none":ItemName(selected)),bw);
            if(Click(a,bx,65,bw,"Equip") && !string.IsNullOrEmpty(selected))rpg.EquipItem(selectedBag);
            if(Click(a,bx,101,bw,"Deposit to bank") && !string.IsNullOrEmpty(selected))rpg.DepositItem(selectedBag);
            if(Click(a,bx,137,bw,"Sell") && !string.IsNullOrEmpty(selected))
            {
                int index=selectedBag;string id=selected;
                ShowConfirm("Sell "+ItemName(id)+" for "+LegacyCatalog.Item(id)?.sell+" Gold?",
                    ()=>{if(c.bag[index]==id)rpg.SellItem(index);});
            }
            if(Click(a,bx,173,bw,"Discard") && !string.IsNullOrEmpty(selected))
            {
                int index=selectedBag;string id=selected;
                ShowConfirm("Permanently discard "+ItemName(id)+"?",
                    ()=>{if(c.bag[index]==id)rpg.TrashItem(index);});
            }
            if(Click(a,bx,209,bw,"Use potion") && !string.IsNullOrEmpty(selected))
                rpg.UsePotion(selectedBag,PrototypeGame.Instance ? PrototypeGame.Instance.Player : null);
            if(Click(a,bx,245,bw,"Sort items"))rpg.SortBag();
            if(Click(a,bx,281,bw,"Use Bag +10 Scroll"))rpg.UnlockWithScroll();
            if(Click(a,2,a.height-33,105,"< Prev"))bagPage=Mathf.Max(0,bagPage-1);
            if(Click(a,116,a.height-33,105,"Next >"))bagPage=Mathf.Min(3,bagPage+1);
            Text(a,232,a.height-33,"Five hours active time => +10 slots",340);
        }
        private void DrawStorage(LeomRpgService rpg,Rect a)
        {
            var c=rpg.Character;
            Text(a,3,2,"Warehouse " + Count(c.storage) + "/200 | page " + (storagePage+1) + "/4");
            float half=(a.width-12)*.5f;
            float rowH=Mathf.Clamp((a.height-158)/10f,23f,36f);
            float cw=(half-8)/5f;
            for(int i=0;i<50;i++)
            {
                int index=storagePage*50+i;
                string id=c.storage[index];
                string label=string.IsNullOrEmpty(id)?(index+1).ToString():id;
                if(GUI.Button(new Rect(a.x+(i%5)*cw,a.y+34+(i/5)*rowH,cw-2,rowH-1),label))
                    selectedStorage=index;
                int bag=bagPage*50+i;
                string bagLabel=bag>=c.unlocked?"[LOCK]":string.IsNullOrEmpty(c.bag[bag])?(bag+1).ToString():c.bag[bag];
                if(GUI.Button(new Rect(a.x+half+12+(i%5)*cw,a.y+34+(i/5)*rowH,cw-2,rowH-1),bagLabel))
                    if(bag<c.unlocked)selectedBag=bag;
            }
            float bottom=34+10*rowH+4;
            Text(a,2,bottom,"Storage slot: " +(selectedStorage+1),half);
            Text(a,half+12,bottom,"Bag slot: " +(selectedBag+1),half);
            if(Click(a,2,bottom+30,half-5,"Withdraw selected"))rpg.WithdrawItem(selectedStorage);
            if(Click(a,half+12,bottom+30,half-13,"Deposit selected"))rpg.DepositItem(selectedBag);
            if(Click(a,2,bottom+65,80,"< Bank"))storagePage=Mathf.Max(0,storagePage-1);
            if(Click(a,86,bottom+65,80,"Bank >"))storagePage=Mathf.Min(3,storagePage+1);
            if(Click(a,half+12,bottom+65,80,"< Bag"))bagPage=Mathf.Max(0,bagPage-1);
            if(Click(a,half+96,bottom+65,80,"Bag >"))bagPage=Mathf.Min(3,bagPage+1);
            float moneyY=a.height-55f;
            Text(a,3,moneyY-26,"Currency: " + moneyKind+" | Wallet "+rpg.Balance(moneyKind)+
                " | Vault "+rpg.Balance(moneyKind),a.width-10);
            moneyAmount=GUI.TextField(new Rect(a.x+6,a.y+moneyY,120,29),moneyAmount);
            int ci=Array.IndexOf(LegacyCatalog.CurrencyIds,moneyKind);
            if(Click(a,135,moneyY,85,"Currency"))moneyKind=LegacyCatalog.CurrencyIds[(ci+1)%4];
            if(Click(a,227,moneyY,95,"Deposit"))rpg.TransferMoney(moneyKind,moneyAmount,false);
            if(Click(a,326,moneyY,95,"Withdraw"))rpg.TransferMoney(moneyKind,moneyAmount,true);
        }
        private void DrawShop(LeomRpgService rpg,Rect a)
        {
            Text(a,3,3,"NPC shop: 500 reserved listing slots, 21 original offers, 50/page");
            Text(a,3,25,"Wallet Gold: "+LeomAmount.Format(rpg.Character.wallet[0]));
            var offers=LegacyCatalog.Data.offers;
            scroll=GUI.BeginScrollView(new Rect(a.x+3,a.y+55,a.width*.67f,a.height-110),
                scroll,new Rect(0,0,a.width*.67f-23,Mathf.Max(offers.Length,50)*31f));
            for(int i=0;i<50;i++)
            {
                int index=shopPage*50+i;
                string label=index<offers.Length ?
                    $"{index+1}. {ItemName(offers[index].id)} — {offers[index].price} Gold"
                    : $"{index+1}. [Reserved]";
                if(GUI.Button(new Rect(0,i*31f,a.width*.67f-30,29),label) && index<offers.Length)
                    selectedOffer=index;
            }
            GUI.EndScrollView();
            float bx=a.width*.69f,bw=a.width-bx-8;
            string item=selectedOffer>=0&&selectedOffer<offers.Length?offers[selectedOffer].id:"";
            Text(a,bx,60,ItemName(item),bw);
            if(Click(a,bx,91,bw,"Buy 1")&&!string.IsNullOrEmpty(item))rpg.BuyItem(item);
            string bagItem=selectedBag>=0&&selectedBag<200?rpg.Character.bag[selectedBag]:"";
            Text(a,bx,142,"Bag selected: "+(string.IsNullOrEmpty(bagItem)?"none":bagItem),bw);
            if(Click(a,bx,176,bw,"Sell selected bag slot")&&!string.IsNullOrEmpty(bagItem))
            {
                int slot=selectedBag;string id=bagItem;
                ShowConfirm("Sell "+ItemName(id)+" for "+LegacyCatalog.Item(id)?.sell+" Gold?",
                    ()=>{if(rpg.Character.bag[slot]==id)rpg.SellItem(slot);});
            }
            Text(a,bx,229,"Select bag item in Bag tab",bw);
            if(Click(a,3,a.height-39,120,"< Previous"))shopPage=Mathf.Max(0,shopPage-1);
            if(Click(a,133,a.height-39,120,"Next >"))shopPage=Mathf.Min(9,shopPage+1);
        }
        private void DrawEquipment(LeomRpgService rpg,Rect a)
        {
            Text(a,3,2,"23 equipment/fashion slots — click equipped item to return it to bag");
            scroll=GUI.BeginScrollView(new Rect(a.x+3,a.y+35,a.width-6,a.height-39),
                scroll,new Rect(0,0,a.width-25,LegacyCatalog.EquipmentSlotIds.Length*35+8));
            for(int i=0;i<LegacyCatalog.EquipmentSlotIds.Length;i++)
            {
                string slot=LegacyCatalog.EquipmentSlotIds[i];
                string item=rpg.Equipped(slot);
                if(GUI.Button(new Rect(0,i*35,a.width-36,33),slot+" : "+(item==""?"[empty]":ItemName(item))))
                    if(item!="")rpg.UnequipItem(slot);
            }
            GUI.EndScrollView();
        }
        private void DrawCharacter(LeomRpgService rpg,Rect a)
        {
            var c=rpg.Character;
            Text(a,3,2,"Character: "+c.name+" | "+c.job+" | Lv "+c.level);
            Text(a,3,27,"Unspent Stats: "+c.statPoints+" | Skill Points: "+c.skillPoints);
            string[] keys={"strength","vitality","agility","intelligence","dexterity","luck"};
            for(int i=0;i<keys.Length;i++)
            {
                string key=keys[i];
                Text(a,8,63+i*39,key.ToUpper()+": "+rpg.EffectiveAttribute(key),260);
                if(Click(a,260,63+i*39,60,"+1"))rpg.AddAttribute(key);
            }
            float x=Mathf.Max(335f,a.width*.46f);
            Text(a,x,64,"Professions (choose at lv 10 / 50)",a.width-x);
            scroll=GUI.BeginScrollView(new Rect(a.x+x,a.y+93,a.width-x-8,a.height-99),
                scroll,new Rect(0,0,a.width-x-20,13*42));
            var jobs=LegacyCatalog.Data.jobs;
            for(int i=0;i<jobs.Length;i++)
            {
                var job=jobs[i];float y=i*42f;
                GUI.Label(new Rect(0,y,a.width-x-150,34f),job.id+" / "+job.nameEn);
                if(GUI.Button(new Rect(a.width-x-145,y,65f,34f),"View"))
                    rpg.SetPreviewJob(job.id);
                if(job.tier>0 && GUI.Button(new Rect(a.width-x-77,y,70f,34f),"Choose"))
                    rpg.ChangeProfession(job.id);
            }
            GUI.EndScrollView();
        }
        private void DrawSkills(LeomRpgService rpg,Rect a)
        {
            Text(a,3,2,"Skill catalog: "+rpg.ActiveJob+
                (rpg.PreviewJob!=""?" (preview only; no permanent changes)":""));
            string[] bar=rpg.Character.skillHotbar;
            for(int i=0;i<3;i++)
            {
                int capture=i;
                if(Click(a,3+i*170,32,166,$"Hotbar {i+1}: {bar[i]}"))
                    selectedHotbar=capture;
            }
            Text(a,3,71,"Selected hotbar "+(selectedHotbar+1)+"; clicking an active skill equips it");
            var skills=new List<SkillDefinition>(LegacyCatalog.SkillsForJob(rpg.ActiveJob));
            scroll=GUI.BeginScrollView(new Rect(a.x+3,a.y+101,a.width-6,a.height-104),
                scroll,new Rect(0,0,a.width-30,skills.Count*46));
            for(int i=0;i<skills.Count;i++)
            {
                var sk=skills[i];float y=i*46;
                string label=sk.id+" | "+(showThai?sk.nameTh:sk.nameEn)+" | "+sk.kind;
                GUI.Label(new Rect(3,y,a.width-245,37),label);
                if(GUI.Button(new Rect(a.width-240,y,66,36),"Use"))
                {
                    if(sk.kind=="timed_buff")rpg.ActivateTimedBuff(sk.id);
                    else if(sk.kind=="passive")rpg.UpgradePassive(sk.id);
                    else {var p=PrototypeGame.Instance?.Player; if(p!=null)p.UseSkill(sk.id);}
                }
                if(sk.kind!="passive" && GUI.Button(new Rect(a.width-170,y,154,36),
                    sk.implemented?"Set hotbar":"Set hotbar (data)"))
                    rpg.EquipHotbar(selectedHotbar,sk.id);
            }
            GUI.EndScrollView();
        }
        private void DrawMap(LeomRpgService rpg,Rect a)
        {
            var p=PrototypeGame.Instance?.Player;
            Text(a,8,5,"TEMP 3D level — not original Bangkok map");
            Text(a,8,36,"Current location: "+(p? p.transform.position.ToString("F1"):"unknown"));
            Text(a,8,78,"Center (0,0) — Monster hunting zone");
            Text(a,8,115,"Southwest (-31,-16) — safe town, merchant and warehouse NPCs");
            Text(a,8,152,"Northeast (32,31) — arena visual mockup");
            Text(a,8,189,"Northwest (-34,35) — guild war visual mockup");
            Text(a,8,246,"Only terrain/landmarks are simulated. PvP requires a dedicated server.");
        }
        private void DrawPvP(Rect a)
        {
            Text(a,8,8,"PvP / Social systems — SERVER-ONLY development contract");
            Text(a,8,56,"Open PK: safe zone / hunting / allowed-PK policy defined; NOT LIVE");
            Text(a,8,93,"Arena: 1v1 / 3v3 / 5v5 matchmaking design; NOT LIVE");
            Text(a,8,130,"Guild War: capture points, scoring, guild authorization design; NOT LIVE");
            Text(a,8,167,"Party / trade / login / guild persistence await network services.");
            Text(a,8,220,"No client-side demo will grant PvP victories or online currency.");
        }
        private void DrawSettings(LeomRpgService rpg,Rect a)
        {
            Text(a,8,5,"LEOM offline migration test. Godot originals kept in source repo.");
            if(Click(a,8,48,200,"Language: "+(showThai?"TH":"EN"))) showThai=!showThai;
            if(Click(a,8,89,200,"Save locally [F5]"))rpg.SaveLocal();
            if(Click(a,8,130,200,"Quality: cycle"))
                QualitySettings.SetQualityLevel((QualitySettings.GetQualityLevel()+1)%Mathf.Max(1,QualitySettings.names.Length));
            if(Click(a,8,169,250,"Get LOCAL TEST starter items"))
            {
                // Browser testing only, not a real grant or server-side entitlement.
                foreach (string id in new[]{"sword","shirt","boots","hp_potion_small","scroll"})
                    rpg.AddItem(id);
                rpg.TryCredit("gold","2000");
                rpg.Tell("Granted temporary LOCAL TEST items + 2,000 Gold");
            }
            Text(a,8,218,"F8 toggles touch/gamepad UI. Right-drag or touch upper-right to orbit.");
            Text(a,8,255,"Not a real account, server, PvP arena or guild war.");
            Text(a,8,292,"This demo menu must never be used as online server authority.");
        }
    }
}
