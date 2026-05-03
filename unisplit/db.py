import requests
import pandas as pd
# connection to Oracle Apex REST API for Unisplit
BASE_URL = "https://apex.oracle.com/ords/project_unisplit/unisplit"
LEGACY_BASE_URL = "https://apex.oracle.com/ords/project_finshare/finshare"

def fetch_from_url(base_url, endpoint):
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
    }
    url = f"{base_url}/{endpoint}/"
    response = requests.get(url, timeout=10, headers=headers)
    response.raise_for_status()
    data = response.json()
    return pd.DataFrame(data.get("items", []) if isinstance(data, dict) else [])

def fetch(endpoint):
    url = None
    try:
        return fetch_from_url(BASE_URL, endpoint)
    except Exception as e:
        print(f"Unisplit endpoint failed for {endpoint}: {e}")
        try:
            print(f"Falling back to legacy endpoint for {endpoint}")
            return fetch_from_url(LEGACY_BASE_URL, endpoint)
        except Exception as fallback_e:
            print(f"Legacy endpoint also failed for {endpoint}: {fallback_e}")
            return pd.DataFrame()

def get_users():
    return fetch("users")

def get_balances():
    return fetch("balances")

def get_loans():
    return fetch("loans")

def get_groups():
    return fetch("groups")