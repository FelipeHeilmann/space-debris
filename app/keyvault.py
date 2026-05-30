import os
import logging

logger = logging.getLogger(__name__)


def get_n2yo_api_key() -> str | None:
    key_vault_url = os.getenv("KEY_VAULT_URL")

    if key_vault_url:
        try:
            from azure.identity import ManagedIdentityCredential
            from azure.keyvault.secrets import SecretClient

            credential = ManagedIdentityCredential()
            client = SecretClient(vault_url=key_vault_url, credential=credential)
            return client.get_secret("N2YO-API-KEY").value
        except Exception as e:
            logger.warning("Key Vault inacessivel, usando fallback para env var: %s", e)

    return os.getenv("N2YO_API_KEY")
