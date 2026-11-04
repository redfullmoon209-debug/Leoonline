// Optional Unity Build Automation (UBA) pre-export hook.
// Configure "Leoonline.EditorTools.UnityCloudPreExport.PreExport" in UBA
// Advanced Settings -> Pre-export method. No local Editor install needed for the owner.
#if UNITY_EDITOR
using UnityEditor;
using UnityEngine;

namespace Leoonline.EditorTools
{
    public static class UnityCloudPreExport
    {
        public static void PreExport()
        {
            BuildPrototypeScene.BuildHeadless();
            PlayerSettings.companyName = "Leoonline";
            PlayerSettings.productName = "LEOONLINE Offline PvE Playtest";
            PlayerSettings.WebGL.compressionFormat = WebGLCompressionFormat.Disabled;
            Debug.Log("[LEOONLINE] Cloud build pre-export prepared the prototype scene.");
        }
    }
}
#endif
