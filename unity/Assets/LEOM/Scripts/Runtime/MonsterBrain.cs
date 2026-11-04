// Local temporary monster simulation. Server AI + loot table roll must replace this in MMO mode.
using UnityEngine;
namespace Leom.Prototype
{
    public sealed class MonsterBrain : MonoBehaviour
    {
        public float maxHealth=60f, moveSpeed=1.45f, chaseDistance=9f, hitRange=1.7f;
        public int rewardExp=35;
        public string rewardGold="20", dropItem="wood";
        public float respawnSeconds=9f;
        public float health;
        private Vector3 startPosition;
        private float nextAttack;
        private float reviveAt=-1f;
        private Renderer[] visible;
        private Collider ownCollider;
        public bool IsAlive => health>0f;
        private void Start()
        {
            startPosition=transform.position;
            health=maxHealth;
            visible=GetComponentsInChildren<Renderer>();
            ownCollider=GetComponent<Collider>();
        }
        private void Update()
        {
            if(!IsAlive)
            {
                if(reviveAt>=0f && Time.time>=reviveAt) Revive();
                return;
            }
            var player=PrototypeGame.Instance ? PrototypeGame.Instance.Player : null;
            if (!player || !player.IsAlive) return;
            Vector3 delta=player.transform.position-transform.position;
            delta.y=0;
            float distance=delta.magnitude;
            if (distance>chaseDistance || distance<.05f) return;
            transform.rotation=Quaternion.Slerp(transform.rotation,Quaternion.LookRotation(delta),5f*Time.deltaTime);
            if(distance>hitRange) transform.position+=delta.normalized*moveSpeed*Time.deltaTime;
            else if(Time.time>=nextAttack){nextAttack=Time.time+2.2f;player.TakeDamage(8f);}
        }
        public void TakeDamage(float amount)
        {
            if (!IsAlive) return;
            health=Mathf.Max(0f,health-Mathf.Max(0f,amount));
            if(!IsAlive) Die();
        }
        private void Die()
        {
            reviveAt=Time.time+respawnSeconds;
            foreach(var r in visible) if(r) r.enabled=false;
            if(ownCollider) ownCollider.enabled=false;
            PrototypeGame.Instance?.RewardMonster(rewardExp,rewardGold);
            // Preserve original Godot item IDs: wood, sword, shirt and potions.
            if(Random.value<.80f)
            {
                string rolled=Random.value<.1f ? "sword" : Random.value<.18f ? "potion" : "wood";
                SpawnDrop(rolled);
            }
        }
        private void SpawnDrop(string itemId)
        {
            GameObject orb=GameObject.CreatePrimitive(PrimitiveType.Sphere);
            orb.name="Drop - "+itemId;
            orb.transform.position=transform.position+Vector3.up*.40f;
            orb.transform.localScale=Vector3.one*.53f;
            Collider collider=orb.GetComponent<Collider>();
            if(collider) collider.isTrigger=true;
            GroundLoot drop=orb.AddComponent<GroundLoot>();
            drop.itemId=itemId;
            Renderer render=orb.GetComponent<Renderer>();
            if(render) render.material.color=new Color(1f,.72f,.16f);
        }
        private void Revive()
        {
            transform.position=startPosition;
            health=maxHealth;
            reviveAt=-1f;nextAttack=0f;
            foreach(var r in visible) if(r) r.enabled=true;
            if(ownCollider) ownCollider.enabled=true;
        }
    }
}
