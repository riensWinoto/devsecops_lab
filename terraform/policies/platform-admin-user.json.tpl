{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "kms:CreateKey",
        "kms:DescribeKey",
        "kms:EnableKeyRotation",
        "kms:ScheduleKeyDeletion",
        "kms:ListKeys"
      ],
      "Resource": [
        "arn:aws:kms:*:${account_id}:key/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:RotateSecret",
        "secretsmanager:DescribeSecret"
      ],
      "Resource": [
        "arn:aws:secretsmanager:*:${account_id}:secret:*"
      ]
    },
    {
      "Effect": "Deny",
      "Action": [
        "kms:Decrypt",
        "kms:GenerateDataKey"
      ],
      "Resource": [
        "arn:aws:kms:*:${account_id}:key/*"
      ]
    },
    {
      "Effect": "Deny",
      "Action": [
        "secretsmanager:GetSecretValue"
      ],
      "Resource": [
        "arn:aws:secretsmanager:*:${account_id}:secret:*"
      ]
    },
    {
      "Effect": "Deny",
      "Action": [
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Resource": [
        "arn:aws:s3:::*"
      ]
    }
  ]
}