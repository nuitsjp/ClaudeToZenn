using Azure.Identity;
using Azure.Security.KeyVault.Keys;
using Azure.Security.KeyVault.Keys.Cryptography;
using System;
using System.Text;
using System.Threading.Tasks;

namespace ClaudeToZenn.Functions;

public class KeyVaultEncryptionHelper
{
    private readonly KeyClient _keyClient;
    private readonly CryptographyClient _cryptoClient;

    public KeyVaultEncryptionHelper(string keyVaultUrl, string keyName)
    {
        var credential = new DefaultAzureCredential();
        _keyClient = new KeyClient(new Uri(keyVaultUrl), credential);
        var key = _keyClient.GetKey(keyName);
        _cryptoClient = new CryptographyClient(key.Value.Id, credential);
    }

    public async Task<string> EncryptAsync(string plainText)
    {
        byte[] plainBytes = Encoding.UTF8.GetBytes(plainText);
        EncryptResult encryptResult = await _cryptoClient.EncryptAsync(EncryptionAlgorithm.RsaOaep, plainBytes);
        return ToUrlSafeBase64(encryptResult.Ciphertext);
    }

    public async Task<string> DecryptAsync(string cipherText)
    {
        byte[] cipherBytes = FromUrlSafeBase64(cipherText);
        DecryptResult decryptResult = await _cryptoClient.DecryptAsync(EncryptionAlgorithm.RsaOaep, cipherBytes);
        return Encoding.UTF8.GetString(decryptResult.Plaintext);
    }

    private static string ToUrlSafeBase64(byte[] buffer)
    {
        return Convert.ToBase64String(buffer)
            .Replace('+', '-')
            .Replace('/', '_')
            .Replace("=", "");
    }

    private static byte[] FromUrlSafeBase64(string base64)
    {
        string incoming = base64.Replace('_', '/').Replace('-', '+');
        switch (base64.Length % 4)
        {
            case 2: incoming += "=="; break;
            case 3: incoming += "="; break;
        }
        return Convert.FromBase64String(incoming);
    }
}