output "aws_s3_bucket_url" {
  description = "value of the website_domain attribute of the aws_s3_bucket.my_bucket resource"
  value       = "http://${var.bucket_name}.s3-website-${var.region}.amazonaws.com/"
                #http://imad-terraform-bucket.s3-website-us-east-1.amazonaws.com/
}

output "cdn_link" {
  value = aws_cloudfront_distribution.my_distribution.domain_name
}

output "aws_cloud_front_distribution_id" {
   value = aws_cloudfront_distribution.my_distribution.id
}