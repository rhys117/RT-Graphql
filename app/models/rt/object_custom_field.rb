class RT::ObjectCustomField < RequestTrackerRecord
  self.table_name = 'objectcustomfields'

  belongs_to :custom_field, :class_name => 'CustomField', primary_key: :id, foreign_key: :customfield
  belongs_to :queue, class_name: 'Queue', primary_key: :id, foreign_key: :objectid
end