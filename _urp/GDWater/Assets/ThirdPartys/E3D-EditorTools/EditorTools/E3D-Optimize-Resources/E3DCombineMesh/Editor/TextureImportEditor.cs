using UnityEditor;

public class TextureImportEditor : AssetPostprocessor
{
    public void OnPreprocessTexture()
    {
        TextureImporter import = assetImporter as TextureImporter;
        import.isReadable = true;
    }
}

