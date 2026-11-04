// Temporary cross-platform touch test controls; replace IMGUI with production uGUI/UITK later.
using UnityEngine;

namespace Leom.Prototype
{
    public sealed class LeomTouchGamepad : MonoBehaviour
    {
        public Vector2 Movement { get; private set; }
        private bool attack, pickup, jump;
        private readonly bool[] skills = new bool[3];
        private bool forced;
        private LeomGameHUD hud;
        public bool Visible => forced || Application.isMobilePlatform || Screen.width < 950;
        private void Start() { hud = GetComponent<LeomGameHUD>(); }
        private void Update()
        {
            if (Input.GetKeyDown(KeyCode.F8)) forced = !forced;
            if (!Visible || (hud != null && hud.WindowOpen)) Movement = Vector2.zero;
        }
        public bool ConsumeAttack() { bool pressed = attack; attack = false; return pressed; }
        public bool ConsumeLoot() { bool pressed = pickup; pickup = false; return pressed; }
        public bool ConsumeJump() { bool pressed = jump; jump = false; return pressed; }
        public bool ConsumeSkill(int index)
        {
            if (index < 0 || index >= 3) return false;
            bool pressed = skills[index]; skills[index] = false; return pressed;
        }
        private void OnGUI()
        {
            if (!Visible || (hud != null && hud.WindowOpen)) return;
            float scale = Mathf.Clamp(Screen.height / 750f, .65f, 1.15f);
            Matrix4x4 original = GUI.matrix;
            GUI.matrix = Matrix4x4.Scale(new Vector3(scale,scale,1f));
            float w = Screen.width / scale, h = Screen.height / scale;
            const float s = 60f;
            Vector2 move = Vector2.zero;
            float x = 18f, y = h - 175f;
            if (GUI.RepeatButton(new Rect(x+s,y,s,s),"UP")) move.y += 1f;
            if (GUI.RepeatButton(new Rect(x,y+s,s,s),"LEFT")) move.x -= 1f;
            if (GUI.RepeatButton(new Rect(x+s,y+s,s,s),"DOWN")) move.y -= 1f;
            if (GUI.RepeatButton(new Rect(x+2*s,y+s,s,s),"RIGHT")) move.x += 1f;
            Movement = Vector2.ClampMagnitude(move, 1f);

            float bx = w - 90f;
            if (GUI.Button(new Rect(bx,h-174,74,60),"ATK")) attack = true;
            if (GUI.Button(new Rect(bx-84,h-174,74,60),"PICK")) pickup = true;
            if (GUI.Button(new Rect(bx,h-105,74,60),"JUMP")) jump = true;
            for (int i = 0; i < 3; i++)
                if (GUI.Button(new Rect(bx-(i+1)*84,h-105,74,60),"SK"+(i+1))) skills[i] = true;
            GUI.matrix = original;
        }
    }
}
