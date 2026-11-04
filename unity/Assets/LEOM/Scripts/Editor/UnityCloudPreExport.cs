// Optional Unity Build Automation (UBA) pre-export hook.
// Configure "Leoonline.EditorTools.UnityCloudPreExport.PreExport" in UBA
// Advanced Settings -> Pre-export method. No local Editor install needed for the owner.
#if UNITY_EDITOR
using UnityEditor;
using UnityEngine;

namespace Leom.EditorTools
{
    public static class UnityCloudPreExport
    {
        public static void PreExport()
        {
            BuildPrototypeScene.BuildHeadless();
            PlayerSettings.companyName = "Leoonline";
            PlayerSettings.productName = "LEOM Offline PvE Playtest";
            PlayerSettings.WebGL.compressionFormat = WebGLCompressionFormat.Disabled;
            Debug.Log("[LEOM] Cloud build pre-export prepared the prototype scene.");
        }
    }
}
#endif
