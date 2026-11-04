// Unity Editor menu: generate a runnable offline demo without external assets.
#if UNITY_EDITOR
using Leoonline.Prototype;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.SceneManagement;

namespace Leoonline.EditorTools
{
    public static class BuildPrototypeScene
    {
        private const string SceneFolder = "Assets/LEOONLINE/Scenes";
        private const string ScenePath = SceneFolder + "/Prototype.unity";

        [MenuItem("Tools/LEOONLINE/Build Prototype Scene")]
        public static void Build()
        {
            if (EditorApplication.isPlayingOrWillChangePlaymode)
            {
                EditorUtility.DisplayDialog("LEOONLINE", "Exit Play Mode before building the scene.", "OK");
                return;
            }
            if (!EditorSceneManager.SaveCurrentModifiedScenesIfUserWantsTo())
                return;
            Scene scene = EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);
            var game = new GameObject("LEOONLINE Offline Game");
            game.AddComponent<PrototypeGame>();
            game.AddComponent<PrototypeHUD>();

            GameObject ground = GameObject.CreatePrimitive(PrimitiveType.Cube);
            ground.name = "Hunting Zone - Test Ground";
            ground.transform.position = new Vector3(0, -0.5f, 0);
            ground.transform.localScale = new Vector3(90, 1f, 90);
            Colorize(ground, new Color(0.17f, 0.29f, 0.23f));

            var player = new GameObject("Leo - Test Player");
            player.transform.position = new Vector3(0f, 1.1f, 0f);
            var controller = player.AddComponent<CharacterController>();
            controller.height = 2f;
            controller.radius = 0.38f;
            controller.center = new Vector3(0f, 1f, 0f);
            player.AddComponent<LeoonlinePlayer>();
            GameObject visiblePlayer = GameObject.CreatePrimitive(PrimitiveType.Capsule);
            visiblePlayer.name = "TEMP PLAYER VISUAL - replace with original FemaleLeo FBX";
            visiblePlayer.transform.SetParent(player.transform, false);
            visiblePlayer.transform.localPosition = new Vector3(0, 1, 0);
            var visualCollider = visiblePlayer.GetComponent<Collider>();
            if (visualCollider) Object.DestroyImmediate(visualCollider);
            Colorize(visiblePlayer, new Color(0.22f, 0.55f, 0.88f));

            GameObject cameraObject = new GameObject("Third Person Camera");
            cameraObject.tag = "MainCamera";
            var camera = cameraObject.AddComponent<Camera>();
            camera.nearClipPlane = 0.1f;
            camera.farClipPlane = 500;
            var cameraFollow = cameraObject.AddComponent<CameraFollow>();
            cameraFollow.target = player.transform;
            cameraObject.transform.position = new Vector3(0, 6, -8);
            cameraObject.AddComponent<AudioListener>();

            GameObject sun = new GameObject("Directional Light");
            var light = sun.AddComponent<Light>();
            light.type = LightType.Directional;
            light.intensity = 1.2f;
            sun.transform.rotation = Quaternion.Euler(45f, -35f, 0f);
            RenderSettings.ambientLight = new Color(0.6f, 0.65f, 0.7f);

            for (int i = 0; i < 9; i++)
            {
                float angle = i * Mathf.PI * 2f / 9f;
                Vector3 location = new Vector3(Mathf.Sin(angle) * 13f, 0.55f, Mathf.Cos(angle) * 13f);
                GameObject monster = GameObject.CreatePrimitive(PrimitiveType.Capsule);
                monster.name = "Demo Monster " + (i + 1);
                monster.transform.position = location;
                monster.transform.localScale = new Vector3(0.75f, 0.55f, 0.75f);
                Colorize(monster, new Color(0.7f, 0.22f, 0.25f));
                monster.AddComponent<MonsterBrain>();
            }

            // Surround the center with primitive landmarks to make the direction of travel readable.
            for (int i = 0; i < 12; i++)
            {
                float angle = i * Mathf.PI * 2f / 12f;
                var landmark = GameObject.CreatePrimitive(PrimitiveType.Cylinder);
                landmark.name = "Stone Landmark " + (i + 1);
                landmark.transform.position = new Vector3(Mathf.Sin(angle) * 25f, 1.8f, Mathf.Cos(angle) * 25f);
                landmark.transform.localScale = new Vector3(1.2f, 1.8f, 1.2f);
                Colorize(landmark, new Color(0.47f, 0.51f, 0.54f));
            }

            if (!AssetDatabase.IsValidFolder(SceneFolder))
                AssetDatabase.CreateFolder("Assets/LEOONLINE", "Scenes");
            EditorSceneManager.SaveScene(scene, ScenePath);
            EditorBuildSettings.scenes = new[] { new EditorBuildSettingsScene(ScenePath, true) };
            Selection.activeGameObject = game;
            Debug.Log("[LEOONLINE] Prototype scene generated at " + ScenePath);
            EditorUtility.DisplayDialog("LEOONLINE", "Offline scene created. Press Play to test the PvE loop. This is not networked multiplayer.", "OK");
        }

        private static void Colorize(GameObject obj, Color color)
        {
            var render = obj.GetComponent<Renderer>();
            if (render && render.sharedMaterial)
            {
                var material = new Material(Shader.Find("Standard"));
                material.color = color;
                render.sharedMaterial = material;
            }
        }
    }
}
