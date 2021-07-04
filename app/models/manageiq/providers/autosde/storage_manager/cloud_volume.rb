class ManageIQ::Providers::Autosde::StorageManager::CloudVolume < ::CloudVolume
  supports :create
  supports :safe_delete
  supports :update do
    unsupported_reason_add(:update, _("The Volume is not connected to an active Provider")) unless ext_management_system
  end

  def self.raw_create_volume(_ext_management_system, _options = {})
    # @type [StorageService]
    storage_service = _options[:storage_service]

    vol_to_create = _ext_management_system.autosde_client.VolumeCreate(
      :service => storage_service.ems_ref,
      :name    => _options[:name],
      :size    => _options[:size]
    )
    _ext_management_system.autosde_client.VolumeApi.volumes_post(vol_to_create)
    EmsRefresh.queue_refresh(_ext_management_system)
  end

  # has to be overriden and return a specifically-formatted hash.
  def self.validate_create_volume(ext_management_system)
    # check that the ems isn't nil and return a correctly formatted hash.
    validate_volume(ext_management_system)
  end

  # ================= delete  ================

  def raw_delete_volume
    ems = ext_management_system
    ems.autosde_client.VolumeApi.volumes_pk_delete(ems_ref)
    EmsRefresh.queue_refresh(ems)
  end

  def validate_delete_volume
    {:available => true, :message => nil}
  end

  # ================= edit  ================

  def raw_update_volume(options = {})
    ems = ext_management_system
    update_details = ems.autosde_client.VolumeUpdate(
      :name => options[:name],
      :size => options[:size]
    )

    ems.autosde_client.VolumeApi.volumes_pk_put(ems_ref, update_details)
    EmsRefresh.queue_refresh(ems)
  end

  # ================ safe-delete ================
  def validate_safe_delete_volume
    {:available => true, :message => nil}
  end

  def raw_safe_delete_volume
    ext_management_system.autosde_client.VolumeApi.volumes_safe_delete(ems_ref)

    EmsRefresh.queue_refresh(ext_management_system)
  end

  def self.params_for_create(provider)
    services = provider.storage_services.map { |service| {:value => service.id, :label => service.name} }
    @params_for_create ||= {
      :fields => [
        {
          :component    => "select",
          :name         => "storage.pools",
          :id           => "storage.pools",
          :label        => _("Storage Pool"),
          :isRequired   => true,
          :validate     => [{:type => "required"}],
          :options      => services,
          :includeEmpty => true
        },
        {
          :component  => "text-field",
          :id         => "storage.volume.size",
          :name       => "storage.volume.size",
          :label      => _("Size (GiB)"),
          :isRequired => true,
          :validate   => [{:type => "required"},
                          {:type => "pattern", :pattern => '^[-+]?[0-9]\\d*$', :message => _("Must be an integer")},
                          {:type => "min-number-value", :value => 1, :message => _('Must be greater than or equal to 1')}],
        }
      ]
    }
  end
end
