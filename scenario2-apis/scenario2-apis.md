
## Scenario #2: APIs-as-a-Product (Internal vs. External)

### Current Weaknesses

-   **All APIs public** by default → enlarged attack surface.
    
-   **Internal traffic** routes via Internet & CloudFront → added latency.
    
-   **Single domain** complicates policy separation.
    

### Option A: Dual API Gateways

1.  **Internal APIs**: deploy a **Private API Gateway** inside your VPC.
    
2.  **External APIs**: expose via **CloudFront → Public API Gateway** with WAF & Shield Advanced.
    
3.  **DNS**:
    
    -   `internal-api.example.com` → Route 53 Private Hosted Zone → VPC Endpoint.
        
    -   `api.example.com` → CloudFront distribution.
        

### Option B: Single API Gateway with Custom Domain Mappings

1.  Use one API Gateway but define two **Custom Domain Names**:
    
    -   `internal-api.example.com` (endpoint type: PRIVATE)
        
    -   `api.example.com` (endpoint type: REGIONAL + CloudFront)
        
2.  Map stages or base paths to each domain.
    

> _Personal note:_ Option A feels cleaner in large organizations, while Option B reduces resource count if you’re under quota constraints.


### Path‑Based Routing in CloudFront

Define multiple cache behaviors:
```tf
resource "aws_cloudfront_distribution" "api_dist" {
  origin { domain_name = aws_api_gateway_rest_api.external.execution_invoke_url; origin_id = "external" }
  enabled = true
  default_cache_behavior { target_origin_id = "external"; viewer_protocol_policy = "HTTPS_ONLY" }
  ordered_cache_behavior {
    path_pattern           = "/v2/*"
    target_origin_id       = "external"
    allowed_methods        = ["GET","POST"]
    viewer_protocol_policy = "HTTPS_ONLY"
  }
  # Add more behaviors for /v1, /internal, etc.
}
```