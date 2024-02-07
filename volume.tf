# Define the volumes that are attached to the compute instances.

resource "oci_core_volume" "test_block_volume" {
  count               = var.num_instances * var.num_iscsi_volumes_per_instance
  availability_domain = data.oci_identity_availability_domain.ad.name
  compartment_id      = var.compartment_ocid
  display_name        = "TestBlock${count.index}"
  size_in_gbs         = var.db_size
}

resource "oci_core_volume_attachment" "test_block_attach" {
  count           = var.num_instances * var.num_iscsi_volumes_per_instance
  attachment_type = "iscsi"
  instance_id     = oci_core_instance.test_instance[floor(count.index / var.num_iscsi_volumes_per_instance)].id
  volume_id       = oci_core_volume.test_block_volume[count.index].id
  device          = count.index == 0 ? "/dev/oracleoci/oraclevdb" : ""

  # Set this to enable CHAP authentication for an ISCSI volume attachment. The oci_core_volume_attachment resource will
  # contain the CHAP authentication details via the "chap_secret" and "chap_username" attributes.
  use_chap = true
  # Set this to attach the volume as read-only.
  #is_read_only = true
}

resource "oci_core_volume" "test_block_volume_paravirtualized" {
  count               = var.num_instances * var.num_paravirtualized_volumes_per_instance
  availability_domain = data.oci_identity_availability_domain.ad.name
  compartment_id      = var.compartment_ocid
  display_name        = "TestBlockParavirtualized${count.index}"
  size_in_gbs         = var.db_size
}

resource "oci_core_volume_attachment" "test_block_volume_attach_paravirtualized" {
  count           = var.num_instances * var.num_paravirtualized_volumes_per_instance
  attachment_type = "paravirtualized"
  instance_id     = oci_core_instance.test_instance[floor(count.index / var.num_paravirtualized_volumes_per_instance)].id
  volume_id       = oci_core_volume.test_block_volume_paravirtualized[count.index].id
  # Set this to attach the volume as read-only.
  #is_read_only = true
}

resource "oci_core_volume_backup_policy_assignment" "policy" {
  count     = var.num_instances
  asset_id  = oci_core_instance.test_instance[count.index].boot_volume_id
  policy_id = data.oci_core_volume_backup_policies.test_predefined_volume_backup_policies.volume_backup_policies[0].id
}

## 주석처리 실행 안되는 원인 파악불가
#resource "null_resource" "remote-exec" {
#  depends_on = [
#    oci_core_instance.test_instance,
#    oci_core_volume_attachment.test_block_attach,
#  ]
#  count = var.num_instances * var.num_iscsi_volumes_per_instance
#
#  provisioner "remote-exec" {
#    connection {
#      agent       = false
#      timeout     = "30m"
#      host        = oci_core_instance.test_instance[count.index % var.num_instances].public_ip
#      user        = "opc"
#      private_key = var.ssh_private_key
#    }
#
#    inline = [
#      "touch ~/IMadeAFile.Right.Here",
#      "sudo iscsiadm -m node -o new -T ${oci_core_volume_attachment.test_block_attach[count.index].iqn} -p ${oci_core_volume_attachment.test_block_attach[count.index].ipv4}:${oci_core_volume_attachment.test_block_attach[count.index].port}",
#      "sudo iscsiadm -m node -o update -T ${oci_core_volume_attachment.test_block_attach[count.index].iqn} -n node.startup -v automatic",
#      "sudo iscsiadm -m node -T ${oci_core_volume_attachment.test_block_attach[count.index].iqn} -p ${oci_core_volume_attachment.test_block_attach[count.index].ipv4}:${oci_core_volume_attachment.test_block_attach[count.index].port} -o update -n node.session.auth.authmethod -v CHAP",
#      "sudo iscsiadm -m node -T ${oci_core_volume_attachment.test_block_attach[count.index].iqn} -p ${oci_core_volume_attachment.test_block_attach[count.index].ipv4}:${oci_core_volume_attachment.test_block_attach[count.index].port} -o update -n node.session.auth.username -v ${oci_core_volume_attachment.test_block_attach[count.index].chap_username}",
#      "sudo iscsiadm -m node -T ${oci_core_volume_attachment.test_block_attach[count.index].iqn} -p ${oci_core_volume_attachment.test_block_attach[count.index].ipv4}:${oci_core_volume_attachment.test_block_attach[count.index].port} -o update -n node.session.auth.password -v ${oci_core_volume_attachment.test_block_attach[count.index].chap_secret}",
#      "sudo iscsiadm -m node -T ${oci_core_volume_attachment.test_block_attach[count.index].iqn} -p ${oci_core_volume_attachment.test_block_attach[count.index].ipv4}:${oci_core_volume_attachment.test_block_attach[count.index].port} -l",
#    ]
#  }
#}


data "oci_core_volume_backup_policies" "test_predefined_volume_backup_policies" {
  filter {
    name = "display_name"

    values = [
      "silver",
    ]
  }
}
