using System;
using System.Collections.Generic;
using System.IO;
using UnityEngine;

namespace Leom.Prototype
{
public sealed class PrototypeHUD : MonoBehaviour
    {
        private bool showBag;
        private Vector3 spawn = new Vector3(0f, 1.1f, 0f);
        private float respawnTime = -1f;

        private void Update()
        {
            if (Input.GetKeyDown(KeyCode.B)) showBag = !showBag;
            var player = PrototypeGame.Instance ? PrototypeGame.Instance.Player : null;
            if (player && !player.IsAlive && respawnTime < 0f) respawnTime = Time.time + 4f;
            if (player && !player.IsAlive && Time.time >= respawnTime && respawnTime >= 0f)
            {
                player.Respawn(spawn);
                respawnTime = -1f;
            }
        }

        private void OnGUI()
        {
            var game = PrototypeGame.Instance;
            if (!game) return;
            GUI.Box(new Rect(10, 10, 355, 142), "LEOM — OFFLINE UNITY TEST");
            GUI.Label(new Rect(23, 39, 320, 24), "Level " + game.Profile.level + "   EXP " + game.Profile.exp + "/" + game.ExpToNextLevel());
            GUI.Label(new Rect(23, 63, 320, 24), "HP " + (game.Player ? Mathf.CeilToInt(game.Player.health).ToString() : "-") +
                "   Gold " + game.Profile.currency[0]);
            GUI.Label(new Rect(23, 87, 320, 24), "Monsters defeated: " + game.Profile.defeated);
            GUI.Label(new Rect(23, 112, 320, 25), "Bag " + game.Profile.bag.Count + "/40 unlocked (200 max)");
            GUI.Box(new Rect(10, Screen.height - 85, 510, 75), "Controls");
            GUI.Label(new Rect(22, Screen.height - 61, 490, 24), "WASD Move  Shift Sprint  Space Jump  RMB Camera");
            GUI.Label(new Rect(22, Screen.height - 38, 490, 24), "LMB Attack  E Loot  B Inventory  F5 Local Save");
            if (game.MessageUntil > Time.time)
                GUI.Box(new Rect(Screen.width / 2f - 240f, 15, 480, 34), game.Message);

            if (!showBag) return;
            float width = Mathf.Min(365f, Screen.width - 40f);
            Rect bounds = new Rect(Screen.width - width - 15f, 15f, width, 365f);
            GUI.Box(bounds, "Inventory (local development view)");
            int row = 0;
            foreach (var item in game.Profile.bag)
            {
                if (row >= 12) break;
                if (item != null)
                    GUI.Label(new Rect(bounds.x + 15, bounds.y + 35 + row * 23, width - 20, 21), item.id + " x" + item.count);
                row++;
            }
        }
    }
}
