resource "aws_api_gateway_rest_api_policy" "strict" {
  rest_api_id = aws_api_gateway_rest_api.external.id
  policy = <<EOF
{
  "Version":"2012-10-17",
  "Statement":[{
    "Effect":"Deny",
    "Action":"execute-api:Invoke",
    "Resource":"arn:aws:execute-api:${var.aws_region}:${var.account_id}:${aws_api_gateway_rest_api.external.id}/*/*/*",
    "Condition":{
      "StringNotEquals":{"aws:SourceVpce":"${aws_vpc_endpoint.apigw_private.id}"}
    }
  }]
}
EOF
}