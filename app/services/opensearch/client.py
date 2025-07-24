from opensearchpy import OpenSearch
from app.config import settings

def get_opensearch_client():
    if settings.opensearch.mode == "cloud":
        if not settings.opensearch.host:
            raise ValueError("OpenSearch host is required for cloud mode")
            
        auth = (
            settings.opensearch.username,
            settings.opensearch.password
        )
        return OpenSearch(
            hosts=[{"host": settings.opensearch.host, "port": 443}],
            http_auth=auth,
            use_ssl=True,
            verify_certs=True
        )
    else:  # Local
        # Parse host and port from endpoint
        opensearch_endpoint = settings.opensearch.endpoint
        
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
            http_auth=(settings.opensearch.username, settings.opensearch.password),
            use_ssl=settings.opensearch.use_ssl,
            verify_certs=settings.opensearch.verify_certs
        )
