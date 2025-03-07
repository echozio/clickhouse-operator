// Copyright 2019 Altinity Ltd and/or its affiliates. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package v1

// InheritSettingsFrom inherits settings from specified cluster
func (shard *ChiShard) InheritSettingsFrom(cluster *Cluster) {
	shard.Settings = shard.Settings.MergeFrom(cluster.Settings)
}

// InheritFilesFrom inherits files from specified cluster
func (shard *ChiShard) InheritFilesFrom(cluster *Cluster) {
	shard.Files = shard.Files.MergeFrom(cluster.Files)
}

// InheritTemplatesFrom inherits templates from specified cluster
func (shard *ChiShard) InheritTemplatesFrom(cluster *Cluster) {
	shard.Templates = shard.Templates.MergeFrom(cluster.Templates, MergeTypeFillEmptyValues)
	shard.Templates.HandleDeprecatedFields()
}

// GetServiceTemplate gets service template
func (shard *ChiShard) GetServiceTemplate() (*ChiServiceTemplate, bool) {
	if !shard.Templates.HasShardServiceTemplate() {
		return nil, false
	}
	name := shard.Templates.GetShardServiceTemplate()
	return shard.CHI.GetServiceTemplate(name)
}

// WalkHosts runs specified function on each host
func (shard *ChiShard) WalkHosts(f func(host *ChiHost) error) []error {
	if shard == nil {
		return nil
	}

	res := make([]error, 0)

	for replicaIndex := range shard.Hosts {
		host := shard.Hosts[replicaIndex]
		res = append(res, f(host))
	}

	return res
}

// FindHost finds host by name or index.
// Expectations: name is expected to be a string, index is expected to be an int.
func (shard *ChiShard) FindHost(needle interface{}) (res *ChiHost) {
	shard.WalkHosts(func(host *ChiHost) error {
		switch v := needle.(type) {
		case string:
			if host.Address.HostName == v {
				res = host
			}
		case int:
			if host.Address.ShardScopeIndex == v {
				res = host
			}
		}
		return nil
	})
	return
}

// FirstHost finds first host in the shard
func (shard *ChiShard) FirstHost() *ChiHost {
	var result *ChiHost
	shard.WalkHosts(func(host *ChiHost) error {
		if result == nil {
			result = host
		}
		return nil
	})
	return result
}

// HostsCount returns count of hosts in the shard
func (shard *ChiShard) HostsCount() int {
	count := 0
	shard.WalkHosts(func(host *ChiHost) error {
		count++
		return nil
	})
	return count
}

// GetCHI gets CHI of the shard
func (shard *ChiShard) GetCHI() *ClickHouseInstallation {
	return shard.CHI
}

// GetCluster gets cluster of the shard
func (shard *ChiShard) GetCluster() *Cluster {
	return shard.CHI.Spec.Configuration.Clusters[shard.Address.ClusterIndex]
}

// HasWeight checks whether shard has applicable weight value specified
func (shard *ChiShard) HasWeight() bool {
	if shard == nil {
		return false
	}
	if shard.Weight == nil {
		return false
	}
	return *shard.Weight >= 0
}

// GetWeight gets weight
func (shard *ChiShard) GetWeight() int {
	if shard.HasWeight() {
		return *shard.Weight
	}
	return 0
}
