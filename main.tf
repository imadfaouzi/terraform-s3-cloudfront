## Create a S3 bucket
resource "aws_s3_bucket" "my_bucket" {
  bucket = var.bucket_name

  tags = {
    Name        = var.bucket_name
    Environment = "Production"
  }

}

# aws_s3_bucket_ownership_controls serve to specify the Object Ownership setting for the S3 bucket.
resource "aws_s3_bucket_ownership_controls" "ownership_control_S3" {
  bucket = aws_s3_bucket.my_bucket.id

  rule {
    object_ownership = "BucketOwnerPreferred" # 
  }
}

# this activates the public access block settings for the S3 bucket
resource "aws_s3_bucket_public_access_block" "public_access_block" {
  bucket = aws_s3_bucket.my_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# this will allow anyone to read the objects in the bucket  
resource "aws_s3_bucket_acl" "bucket_acl" {
  depends_on = [
    aws_s3_bucket_ownership_controls.ownership_control_S3,
    aws_s3_bucket_public_access_block.public_access_block
  ]
  bucket = aws_s3_bucket.my_bucket.id
  acl    = "public-read"
}


# this will allow anyone to read the objects in the bucket 
# resource "aws_s3_bucket_policy" "bucket_policy" {
#   bucket = aws_s3_bucket.my_bucket.id
#   policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Effect    = "Allow",
#         Principal = "*",
#         Action    = "s3:GetObject",
#         Resource  = "arn:aws:s3:::${var.bucket_name}/*"
#       }
#     ]
#   })
# }

# Update S3 bucket policy to allow access from CloudFront only
resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.my_bucket.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "Grant CloudFront access to the bucket",
        Effect    = "Allow",
        Principal = {
          AWS = aws_cloudfront_origin_access_identity.my_oai.iam_arn
        },
        Action    = "s3:GetObject",
        Resource  = "${aws_s3_bucket.my_bucket.arn}/*"
      }
    ]
  })
}

# Enable web static 
resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.my_bucket.id
  index_document {
    suffix = "index.html"
  }
  error_document {
    key = "error.html"
  }

}


##################################
# Create a CloudFront distribution
##################################

locals {
  s3_origin_id   = "${var.bucket_name}-origin"
  s3_domain_name = "${var.bucket_name}.s3.${var.region}.amazonaws.com"
}

# Create a CloudFront distribution
# Define CloudFront distribution
resource "aws_cloudfront_distribution" "my_distribution" {

  depends_on = [ 
       aws_s3_bucket.my_bucket
   ]

  enabled = true

  origin {
    domain_name = local.s3_domain_name
    origin_id   = local.s3_origin_id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.my_oai.cloudfront_access_identity_path
    }
  }

  default_root_object = "index.html"

  default_cache_behavior {

    target_origin_id = local.s3_origin_id
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]

    forwarded_values {
      query_string = true

      cookies {
        forward = "all"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0
  }

  # Disable security protections if needed
  # (This example disables all security features, adjust as needed)
  viewer_certificate {
    cloudfront_default_certificate = true
  }

  # Other distribution settings like caching behavior, default TTL, etc.
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}

# Create Origin Access Identity (OAI)
resource "aws_cloudfront_origin_access_identity" "my_oai" {
  comment = "Allows CloudFront to access the S3 bucket"
}



# this will 