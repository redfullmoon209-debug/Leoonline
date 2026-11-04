// Editor-generated TEMPORARY original-geometry test level and humanoids.
// Does not import any Leoonline/LEOM original FBX, GLB, textures or terrain.
#if UNITY_EDITOR
using System;
using UnityEditor;
using UnityEngine;

namespace Leom.EditorTools
{
    public static class LeomProceduralScene
    {
        private static Transform root;
        public static void Build()
        {
            root = new GameObject("TEMP WORLD - procedural Unity primitives only").transform;
            var ground = Part("Main island ground",PrimitiveType.Cube,new Vector3(0f,-.6f,0f),
                new Vector3(145f,1.2f,145f),new Color(.15f,.32f,.27f),root,true);
            // Town square; open hunting grounds stay clear near the center for combat.
            Region("Safe town / merchant + storage", new Vector3(-31f,.06f,-16f),
                new Vector3(25f,.12f,21f), new Color(.28f,.33f,.39f));
            Region("Arena - visual placeholder", new Vector3(32f,.06f,31f),
                new Vector3(21f,.12f,21f), new Color(.44f,.22f,.26f));
            Region("Guild war battleground - visual placeholder", new Vector3(-34f,.06f,35f),
                new Vector3(27f,.12f,24f), new Color(.27f,.27f,.42f));
            Path(new Vector3(-31,.08f,-16),new Vector3(0,.08f,0),4f);
            Path(new Vector3(0,.08f,0),new Vector3(32,.08f,31),3f);
            Path(new Vector3(0,.08f,0),new Vector3(-34,.08f,35),3f);

            for(int i=0;i<8;i++)
            {
                float a=i*Mathf.PI*2f/8f;
                Vector3 p=new Vector3(Mathf.Cos(a)*19,.45f,Mathf.Sin(a)*19);
                var stone=Part("Hunting circle standing stone",PrimitiveType.Cylinder,p,
                    new Vector3(.65f,.9f,.65f),new Color(.45f,.55f,.62f),root,true);
                Part("Rune cap",PrimitiveType.Cube,new Vector3(p.x,1.48f,p.z),
                    new Vector3(1.2f,.3f,1.2f),new Color(.22f,.7f,.78f),stone.transform,false);
            }
            // Safe-zone merchant and storage characters are procedurally constructed too.
            CreateHumanoid("Placeholder Merchant NPC",new Vector3(-35f,.15f,-14f),
                new Color(.65f,.48f,.22f),root,false);
            CreateHumanoid("Placeholder Storage NPC",new Vector3(-27f,.15f,-14f),
                new Color(.19f,.65f,.67f),root,false);

            // Deterministic trees and rock clusters; keep demo spawn/monsters unobstructed.
            var random = new System.Random(209);
            for(int i=0;i<92;i++)
            {
                float x=(float)(random.NextDouble()*132-66);
                float z=(float)(random.NextDouble()*132-66);
                Vector3 p=new Vector3(x,0,z);
                if(p.magnitude<26f || (x>-46&&x<-17&&z>-30&&z<0) ||
                    (x>19&&z>18&&x<46&&z<46) || (x<-17&&z>18&&x>-50&&z<50))
                    continue;
                if (i%4==0) Rock(p,(float)random.NextDouble()*1.1f+.7f);
                else Tree(p,(float)random.NextDouble()*1.5f+.9f);
            }
            for(int i=0;i<4;i++)
            {
                float z=-26+i*6.4f;
                Tower(new Vector3(-44f,0,z),new Color(.43f,.44f,.52f));
            }
            for(int i=0;i<4;i++)
            {
                float a=i*Mathf.PI*.5f;
                Tower(new Vector3(32f+Mathf.Cos(a)*11.4f,0,31f+Mathf.Sin(a)*11.4f),
                    new Color(.72f,.26f,.22f));
            }
        }
        private static void Region(string label,Vector3 center,Vector3 size,Color tint)
        {
            Part(label,PrimitiveType.Cube,center,size,tint,root,true);
        }
        private static void Path(Vector3 from,Vector3 to,float width)
        {
            Vector3 mid=(from+to)*.5f;
            Vector3 diff=to-from;
            GameObject road=Part("Stone path",PrimitiveType.Cube,mid,
                new Vector3(width,.11f,diff.magnitude),new Color(.45f,.43f,.38f),root,false);
            road.transform.rotation=Quaternion.LookRotation(diff);
        }
        private static void Tree(Vector3 p,float size)
        {
            Part("Tree trunk",PrimitiveType.Cylinder,new Vector3(p.x,size*.85f,p.z),
                new Vector3(.28f*size,.85f*size,.28f*size),new Color(.34f,.22f,.17f),root,true);
            Part("Tree canopy",PrimitiveType.Sphere,new Vector3(p.x,size*2.1f,p.z),
                new Vector3(2.2f*size,1.8f*size,2.2f*size),
                new Color(.13f+(Mathf.Abs(p.x)%5f)*.01f,.36f,.22f),root,false);
        }
        private static void Rock(Vector3 p,float size)
        {
            var stone=Part("Rock",PrimitiveType.Cube,new Vector3(p.x,size*.35f,p.z),
                new Vector3(1.5f*size,.7f*size,size),new Color(.33f,.39f,.42f),root,true);
            stone.transform.rotation=Quaternion.Euler(0,37,12);
        }
        private static void Tower(Vector3 p,Color color)
        {
            Part("Watch tower",PrimitiveType.Cylinder,p+Vector3.up*2.2f,
                new Vector3(1.5f,2.2f,1.5f),color,root,true);
            Part("Tower roof",PrimitiveType.Cylinder,p+Vector3.up*4.7f,
                new Vector3(1.95f,.28f,1.95f),new Color(.15f,.17f,.23f),root,true);
        }
        public static GameObject CreateHumanoid(string name,Vector3 worldPosition,Color coat,
            Transform parent,bool useSword)
        {
            GameObject actor=new GameObject(name);
            actor.transform.SetParent(parent,false);
            actor.transform.position=worldPosition;
            Transform r=actor.transform;
            Color skin=new Color(.83f,.62f,.49f);
            Color metal=new Color(.55f,.69f,.78f);
            BodyPart("Torso",PrimitiveType.Capsule,new Vector3(0,1.27f,0),
                new Vector3(.82f,.67f,.54f),coat,r);
            BodyPart("Head",PrimitiveType.Sphere,new Vector3(0,2.31f,0),
                new Vector3(.56f,.64f,.55f),skin,r);
            BodyPart("Hair",PrimitiveType.Sphere,new Vector3(0,2.64f,-.03f),
                new Vector3(.61f,.26f,.62f),new Color(.16f,.13f,.21f),r);
            for(int side=-1;side<=1;side+=2)
            {
                float x=side*.52f;
                var arm=BodyPart("Arm",PrimitiveType.Capsule,new Vector3(x,1.38f,0),
                    new Vector3(.28f,.72f,.28f),skin,r);
                arm.transform.rotation=Quaternion.Euler(0,0,side*18f);
                BodyPart("Glove",PrimitiveType.Sphere,new Vector3(side*.64f,.76f,0),
                    new Vector3(.27f,.28f,.27f),metal,r);
                BodyPart("Leg",PrimitiveType.Capsule,new Vector3(side*.22f,.49f,0),
                    new Vector3(.34f,.49f,.35f),new Color(.11f,.14f,.25f),r);
                BodyPart("Boot",PrimitiveType.Cube,new Vector3(side*.22f,.15f,.12f),
                    new Vector3(.35f,.28f,.62f),new Color(.11f,.1f,.14f),r);
                BodyPart("Eye",PrimitiveType.Sphere,new Vector3(side*.15f,2.38f,.26f),
                    new Vector3(.08f,.07f,.06f),new Color(.06f,.1f,.12f),r);
            }
            if(useSword)
            {
                BodyPart("Sword hilt",PrimitiveType.Cylinder,new Vector3(.71f,.8f,.2f),
                    new Vector3(.07f,.28f,.07f),new Color(.3f,.22f,.12f),r);
                BodyPart("Sword blade",PrimitiveType.Cube,new Vector3(.71f,.24f,.2f),
                    new Vector3(.14f,.79f,.08f),metal,r);
            }
            return actor;
        }
        private static GameObject BodyPart(string name,PrimitiveType mesh,Vector3 local,Vector3 scale,
            Color color,Transform parent)
        {
            var obj=Part(name,mesh,local,scale,color,parent,false);
            obj.transform.localPosition=local;
            return obj;
        }
        public static GameObject Part(string name,PrimitiveType shape,Vector3 pos,Vector3 scale,
            Color color,Transform parent,bool collision)
        {
            GameObject obj=GameObject.CreatePrimitive(shape);
            obj.name=name;
            obj.transform.SetParent(parent,false);
            obj.transform.position=pos;
            obj.transform.localScale=scale;
            if (!collision)
            {
                Collider col=obj.GetComponent<Collider>();
                if (col) UnityEngine.Object.DestroyImmediate(col);
            }
            Renderer renderer=obj.GetComponent<Renderer>();
            if(renderer)
            {
                Shader shader=Shader.Find("Standard");
                if (shader != null)
                {
                    var material=new Material(shader);
                    material.color=color;
                    renderer.sharedMaterial=material;
                }
            }
            return obj;
        }
    }
}
#endif
