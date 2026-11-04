// Unity Editor-only automated browser build.
#if UNITY_EDITOR
using System;
using System.IO;
using UnityEditor;
using UnityEditor.Build.Reporting;
using UnityEngine;

namespace Leom.EditorTools
{
    public static class UnityWebGLBuild
    {
        // This method is invoked by GameCI's "buildMethod" option in GitHub Actions.
        public static void Build()
        {
            BuildPrototypeScene.BuildHeadless();

            PlayerSettings.companyName = "Leoonline";
            PlayerSettings.productName = "LEOM Offline PvE Playtest";
            // GitHub Pages doesn't provide the configurable Content-Encoding headers
            // required by all compressed WebGL distribution variants.
            PlayerSettings.WebGL.compressionFormat = WebGLCompressionFormat.Disabled;

            var output = Path.GetFullPath(Path.Combine(Application.dataPath, "..", "build", "WebGL"));
            Directory.CreateDirectory(output);
            var options = new BuildPlayerOptions
            {
                scenes = new[] { "Assets/LEOM/Scenes/Prototype.unity" },
                locationPathName = output,
                target = BuildTarget.WebGL,
                options = BuildOptions.None
            };
            BuildReport report = BuildPipeline.BuildPlayer(options);
            if (report.summary.result != BuildResult.Succeeded)
                throw new InvalidOperationException("Unity WebGL build failed: " + report.summary.result);
            if (!File.Exists(Path.Combine(output, "index.html")))
                throw new IOException("Unity WebGL build index.html is missing");
            Debug.Log("[LEOM] WebGL export ready: " + output);
        }
    }
}
#endif
