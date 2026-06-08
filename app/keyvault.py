import os
from azure.identity import ManagedIdentityCredential
from azure.keyvault.secrets import SecretClient


def get_n2yo_api_key() -> str:
    url = os.environ["KEY_VAULT_URL"]
    client = SecretClient(vault_url=url, credential=ManagedIdentityCredential())
    return client.get_secret("n2yo-api-key").value
