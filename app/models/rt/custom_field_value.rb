class RT::CustomFieldValue < RequestTrackerRecord
  self.table_name = 'customfieldvalues'
  belongs_to :custom_field, class_name: 'CustomField', foreign_key: 'customfield'

  alias_attribute :value, :name
end