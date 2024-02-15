// Copyright (c) 2017, 2024, Oracle and/or its affiliates. All rights reserved.
// Licensed under the Mozilla Public License v2.0

provider "oci" {
  region              = var.region
  ignore_defined_tags = ["testexamples-tag-namespace.tf-example-tag"]
}

