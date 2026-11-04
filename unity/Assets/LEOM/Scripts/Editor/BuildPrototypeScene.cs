// Generates a complete TEMPORARY LEOM test map, humanoid character, PvE loop and RPG panels.
#if UNITY_EDITOR
using Leom.Prototype;
using Leom.Gameplay;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.SceneManagement;

namespace Leom.EditorTools
{
    public static class BuildPrototypeScene
    {
        private const string SceneFolder = "Assets/LEOM/Scenes";
        private const string ScenePath = SceneFolder + "/Prototype.unity";

        [MenuItem("Tools/LEOM/Build Prototype Scene")]
        public static void Build()
        {
            if (EditorApplication.isPlayingOrWillChangePlaymode)
            {
                EditorUtility.DisplayDialog("LEOM","Exit Play Mode before building the scene.","OK");
                return;
            }
            if (!EditorSceneManager.SaveCurrentModifiedScenesIfUserWantsTo()) return;
            BuildScene();
            EditorUtility.DisplayDialog("LEOM",
                "Offline 3D humanoid + world + RPG test generated. Press Play. No multiplayer yet.","OK");
        }
        public static void BuildHeadless() { BuildScene(); }
        private static void BuildScene()
        {
            Scene scene=EditorSceneManager.NewScene(NewSceneSetup.EmptyScene,NewSceneMode.Single);
            GameObject core=new GameObject("LEOM Offline World");
            core.AddComponent<LeomRpgService>();
            core.AddComponent<PrototypeGame>();
            core.AddComponent<LeomGameHUD>();
            core.AddComponent<LeomTouchGamepad>();

            LeomProceduralScene.Build();

            GameObject player=new GameObject("LEOM TEMP Test Hero");
            player.transform.position=new Vector3(0,1.1f,0);
            CharacterController cc=player.AddComponent<CharacterController>();
            cc.height=2f; cc.radius=.38f; cc.center=new Vector3(0,1f,0);
            player.AddComponent<LeomPlayer>();
            LeomProceduralScene.CreateHumanoid("Generated humanoid visual (no imported character)",
                player.transform.position,new Color(.19f,.41f,.8f),player.transform,true);

            GameObject cameraObj=new GameObject("Third Person Camera");
            cameraObj.tag="MainCamera";
            Camera camera=cameraObj.AddComponent<Camera>();
            camera.nearClipPlane=.1f;
            camera.farClipPlane=250f;
            camera.fieldOfView=65f;
            CameraFollow follow=cameraObj.AddComponent<CameraFollow>();
            follow.target=player.transform;
            cameraObj.transform.position=new Vector3(0,6,8);
            cameraObj.AddComponent<AudioListener>();

            GameObject sun=new GameObject("Directional sunlight");
            Light light=sun.AddComponent<Light>();
            light.type=LightType.Directional;light.intensity=1.15f;
            sun.transform.rotation=Quaternion.Euler(49,-25,0);
            RenderSettings.ambientLight=new Color(.67f,.72f,.75f);

            var mobs=new GameObject("TEMP Monster Spawns").transform;
            for(int i=0;i<12;i++)
            {
                float a=i*Mathf.PI*2f/12f;
                Vector3 position=new Vector3(Mathf.Sin(a)*12.5f,.8f,Mathf.Cos(a)*12.5f);
                GameObject monster=LeomProceduralScene.Part("Monster - Training " + (i+1),
                    PrimitiveType.Capsule,position,new Vector3(.85f,.75f,.85f),
                    new Color(.6f,.19f,.21f),mobs,true);
                monster.AddComponent<MonsterBrain>();
                // Extra primitive horns are purely visual.
                for (int horn=-1;horn<=1;horn+=2)
                    LeomProceduralScene.Part("Horn",PrimitiveType.Cylinder,
                        position + new Vector3(.23f*horn,1.0f,0),
                        new Vector3(.11f,.34f,.11f),new Color(.24f,.19f,.18f),monster.transform,false);
            }

            if (!AssetDatabase.IsValidFolder(SceneFolder))
                AssetDatabase.CreateFolder("Assets/LEOM","Scenes");
            EditorSceneManager.SaveScene(scene,ScenePath);
            EditorBuildSettings.scenes=new[]{new EditorBuildSettingsScene(ScenePath,true)};
            Selection.activeGameObject=core;
            Debug.Log("[LEOM] Generated procedural RPG test scene: " + ScenePath);
        }
    }
}
#endif
