resource "aws_iam_policy" "secrets-policy" {
  name        = "get_secret_policy"
  path        = "/"
  description = "Policy to allow instance to get the secrets from the secret manager"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": "secretsmanager:GetSecretValue",
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_role" "EC2-role" {
  name = "EC2_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
  tags = {
    Name = "Web_servers_role"
  }
}

resource "aws_iam_role_policy_attachment" "role-attachment" {
  role       = aws_iam_role.EC2-role.name
  policy_arn = aws_iam_policy.secrets-policy.arn
}

resource "aws_iam_instance_profile" "ec2-instance-profile" {
  name = "ec2-instance-profile"
  role = aws_iam_role.EC2-role.name
}
