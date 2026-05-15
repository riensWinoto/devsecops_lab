{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "kms:*"
      ],
      "Principal": {
        "AWS": "arn:aws:iam::${account_id}:root"
      },
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:GenerateDataKey"
      ],
      "Principal": {
        "AWS": "${data_processor_role_arn}"
      },
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt"
      ],
      "Principal": {
        "AWS": "${audit_server_role_arn}"
      },
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "kms:CreateKey",
        "kms:DescribeKey",
        "kms:EnableKeyRotation",
        "kms:ScheduleKeyDeletion"
      ],
      "Principal": {
        "AWS": "${platform_admin_user_arn}"
      },
      "Resource": "*"
    },
    {
      "Effect": "Deny",
      "Action": [
        "kms:Decrypt",
        "kms:GenerateDataKey"
      ],
      "Principal": {
        "AWS": "${platform_admin_user_arn}"
      },
      "Resource": "*"
    }
  ]
}