class kubernetes_addons::cluster_autoscaler(
  String $image='gcr.io/google_containers/cluster-autoscaler',
  String $version='',
  String $limit_cpu='200m',
  String $limit_mem='500Mi',
  String $request_cpu='100m',
  String $request_mem='300Mi',
  String $instance_pool_name='worker',
  Integer $min_instances=3,
  Integer $max_instances=6,
  Boolean $enable_overprovisioning = false,
  String $proportional_image='k8s.gcr.io/cluster-proportional-autoscaler-amd64',
  String $proportional_version='',
  Integer $reserved_millicores_per_replica = 0,
  Integer $reserved_megabytes_per_replica = 0,
  Integer $cores_per_replica = 0,
  Integer $nodes_per_replica = 0,
  Integer $replica_count = 0,
  $ca_mounts=$::kubernetes_addons::params::ca_mounts,
  $cloud_provider=$::kubernetes_addons::params::cloud_provider,
  $aws_region=$::kubernetes_addons::params::aws_region,
) inherits ::kubernetes_addons::params {
  require ::kubernetes

  $authorization_mode = $::kubernetes::_authorization_mode
  if member($authorization_mode, 'RBAC'){
    $rbac_enabled = true
  } else {
    $rbac_enabled = false
  }

  if defined('$kubernetes::cluster_name') and $instance_pool_name != '' {
    $asg_name="${::kubernetes::cluster_name}-kubernetes-${instance_pool_name}"
  } else {
    fail('asg name must be set')
  }

  if $version == '' {
    if versioncmp($::kubernetes::version, '1.10.0') >= 0 {
      $_version = '1.2.0'
    } elsif versioncmp($::kubernetes::version, '1.9.0') >= 0 {
      $_version = '1.1.0'
    } elsif versioncmp($::kubernetes::version, '1.8.0') >= 0 {
      $_version = '1.0.0'
    } elsif versioncmp($::kubernetes::version, '1.7.0') >= 0 {
      $_version = '0.6.0'
    } elsif versioncmp($::kubernetes::version, '1.6.0') >= 0 {
      $_version = '0.5.4'
    } elsif versioncmp($::kubernetes::version, '1.5.0') >= 0 {
      $_version = '0.4.0'
    } else {
      $_version = '0.3.0'
    }
  } else {
    $_version = $version
  }

  if versioncmp($_version, '0.6.0') >= 0 {
    $balance_similar_node_groups = true
  }

  if versioncmp($::kubernetes::version, '1.6.0') >= 0 {
    $version_before_1_6 = false
  } else {
    $version_before_1_6 = true
  }

  if $cores_per_replica == 0 and $nodes_per_replica == 0 {
    if $replica_count == 0 {
      $_replica_count = 1
    } else {
      $_replica_count = $replica_count
    }
  }

  if $proportional_version == '' {
    $_proportional_version = '1.1.2'
  } else {
    $_proportional_version = $proportional_version
  }

  if $enable_overprovisioning and versioncmp($::kubernetes::version, '1.9.0') >= 0 {
    kubernetes::apply{'cluster-autoscaler-overprovisioning':
      manifests => [
        template('kubernetes_addons/cluster-autoscaler-overprovisioning.yaml.erb'),
        template('kubernetes_addons/cluster-autoscaler-overprovisioning-rbac.yaml.erb'),
      ],
    }
  }

  kubernetes::apply{'cluster-autoscaler':
    manifests => [
      template('kubernetes_addons/cluster-autoscaler-deployment.yaml.erb'),
      template('kubernetes_addons/cluster-autoscaler-rbac.yaml.erb'),
    ],
  }
}
