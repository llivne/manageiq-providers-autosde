class ManageIQ::Providers::Autosde::Inventory::Persister < ManageIQ::Providers::Inventory::Persister
  require_nested :StorageManager
  require_nested :TargetCollection
end
