from opensearchpy import OpenSearch
import os

def get_opensearch_client():
    mode = os.getenv("OPENSEARCH_MODE", "local") 

    if mode == "cloud":
        host = os.getenv("OPENSEARCH_HOST")
        auth = (
            os.getenv("OPENSEARCH_USERNAME"),
            os.getenv("OPENSEARCH_PASSWORD")
        )
        return OpenSearch(
            hosts=[{"host": host, "port": 443}],
            http_auth=auth,
            use_ssl=True,
            verify_certs=True
        )
    else:  # Local
        # Get OpenSearch endpoint from environment variable or use default
        opensearch_endpoint = os.getenv("OPENSEARCH_ENDPOINT", "http://localhost:9200")
        
        # Parse host and port from endpoint
        # Remove protocol prefix if present
        if opensearch_endpoint.startswith("http://"):
            opensearch_endpoint = opensearch_endpoint[7:]
        elif opensearch_endpoint.startswith("https://"):
            opensearch_endpoint = opensearch_endpoint[8:]
            
        # Split host and port
        if ":" in opensearch_endpoint:
            host, port_str = opensearch_endpoint.split(":")
            port = int(port_str)
        else:
            host = opensearch_endpoint
            port = 9200
            
        return OpenSearch(
            hosts=[{"host": host, "port": port}],
            http_auth=("admin", "aStrongPassw0rd!"),  # Default for local demo
            use_ssl=False,
            verify_certs=False
        )
