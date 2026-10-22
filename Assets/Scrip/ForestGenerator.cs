
using UnityEngine;
using System.Collections.Generic;

#if UNITY_EDITOR
using UnityEditor;
#endif

public class ForestGenerator : MonoBehaviour
{
    [Header("Tree Models")]
    public GameObject[] trees;

    [Header("Grass Models")]
    public GameObject[] grass;

    [Header("Environment")]
    public Renderer ground;
    public Transform player;

    [Header("Tree Settings")]
    public int treeCount = 100;
    public float spacing = 4f;
    public float playerClearRadius = 8f;
    public float minScale = 0.8f;
    public float maxScale = 1.2f;

    [Header("Grass Settings")]
    public int grassCount = 300;
    public float grassSpacing = 1.5f;
    public float grassClearRadius = 3f;
    public float grassMinScale = 0.8f;
    public float grassMaxScale = 1.2f;

    [Header("Model Adjustments")]
    public Vector3 treeRotationOffset;
    public float treeScaleMultiplier = 1f;

    public Vector3 grassRotationOffset;
    public float grassScaleMultiplier = 1f;

#if UNITY_EDITOR

    [ContextMenu("Generate Forest")]
    private void GenerateForest()
    {
        if (Application.isPlaying)
        {
            Debug.LogWarning("Exit Play Mode first.");
            return;
        }

        if (ground == null)
        {
            Debug.LogWarning("Assign your ground Plane!");
            return;
        }

        List<GameObject> validTrees = GetModels(trees);
        List<GameObject> validGrass = GetModels(grass);

        if (validTrees.Count == 0 && validGrass.Count == 0)
        {
            Debug.LogWarning("Assign trees or grass first!");
            return;
        }

        ClearForest();

        GameObject forest = new GameObject("Generated Forest");
        Undo.RegisterCreatedObjectUndo(
            forest, "Generate Forest");

        forest.transform.SetParent(transform, true);

        Bounds area = ground.bounds;

        Scatter(
            validTrees,
            treeCount,
            spacing,
            playerClearRadius,
            minScale,
            maxScale,
            treeRotationOffset,
            treeScaleMultiplier,
            area,
            forest.transform,
            "Trees"
        );

        Scatter(
            validGrass,
            grassCount,
            grassSpacing,
            grassClearRadius,
            grassMinScale,
            grassMaxScale,
            grassRotationOffset,
            grassScaleMultiplier,
            area,
            forest.transform,
            "Grass"
        );

        Debug.Log("Forest generated successfully!");
    }

    private List<GameObject> GetModels(GameObject[] models)
    {
        List<GameObject> result = new List<GameObject>();

        if (models == null)
            return result;

        foreach (GameObject model in models)
        {
            if (model != null)
                result.Add(model);
        }

        return result;
    }

    private void Scatter(
        List<GameObject> models,
        int count,
        float minimumSpacing,
        float clearRadius,
        float minSize,
        float maxSize,
        Vector3 rotationOffset,
        float scaleMultiplier,
        Bounds area,
        Transform parent,
        string groupName)
    {
        if (models.Count == 0 || count <= 0)
            return;

        GameObject group = new GameObject(groupName);
        group.transform.SetParent(parent, false);

        Undo.RegisterCreatedObjectUndo(
            group, "Create " + groupName);

        List<Vector2> positions = new List<Vector2>();

        int attempts = 0;
        int maxAttempts = count * 40;

        while (positions.Count < count &&
               attempts < maxAttempts)
        {
            attempts++;

            float x = Random.Range(area.min.x, area.max.x);
            float z = Random.Range(area.min.z, area.max.z);

            Vector2 point = new Vector2(x, z);

            if (player != null)
            {
                Vector2 playerPoint = new Vector2(
                    player.position.x,
                    player.position.z
                );

                if (Vector2.Distance(point, playerPoint)
                    < clearRadius)
                    continue;
            }

            bool tooClose = false;

            foreach (Vector2 previous in positions)
            {
                if (Vector2.Distance(point, previous)
                    < minimumSpacing)
                {
                    tooClose = true;
                    break;
                }
            }

            if (tooClose)
                continue;

            GameObject prefab =
                models[Random.Range(0, models.Count)];

            GameObject objectCreated;

            if (PrefabUtility.IsPartOfPrefabAsset(prefab))
            {
                objectCreated = (GameObject)
                    PrefabUtility.InstantiatePrefab(
                        prefab, group.transform);
            }
            else
            {
                objectCreated =
                    Instantiate(prefab, group.transform);
            }

            Undo.RegisterCreatedObjectUndo(
                objectCreated, "Scatter " + groupName);

            objectCreated.transform.position =
                new Vector3(x, area.max.y, z);

            objectCreated.transform.rotation =
                Quaternion.Euler(
                    0, Random.Range(0f, 360f), 0)
                * Quaternion.Euler(rotationOffset)
                * objectCreated.transform.rotation;

            float randomSize = Random.Range(
                Mathf.Min(minSize, maxSize),
                Mathf.Max(minSize, maxSize)
            );

            objectCreated.transform.localScale *=
                randomSize * Mathf.Max(0.01f, scaleMultiplier);

            // Place the bottom of the model on the ground.
            Renderer[] renderers =
                objectCreated.GetComponentsInChildren<Renderer>();

            if (renderers.Length > 0)
            {
                float lowestPoint = float.MaxValue;

                foreach (Renderer mesh in renderers)
                {
                    lowestPoint = Mathf.Min(
                        lowestPoint, mesh.bounds.min.y);
                }

                Vector3 position =
                    objectCreated.transform.position;

                position.y += area.max.y - lowestPoint;

                objectCreated.transform.position = position;
            }

            positions.Add(point);
        }

        Debug.Log(groupName + " generated: " + positions.Count);
    }

    [ContextMenu("Clear Forest")]
    private void ClearForest()
    {
        Transform existing = transform.Find("Generated Forest");

        if (existing != null)
        {
            Undo.DestroyObjectImmediate(existing.gameObject);
        }
    }

#endif
}
