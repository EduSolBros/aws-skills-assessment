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