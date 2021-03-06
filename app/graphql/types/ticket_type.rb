class Types::TicketType < Types::BaseObject
  field :effective_id, ID,                                            null: false
  field :type, String,                                                null: false
  field :subject, String,                                             null: false
  field :status, String,                                              null: false
  field :queue, Types::QueueType      ,                               null: false
  field :owner, Types::UserType,                                      null: false
  field :last_updated_by, Types::UserType,                            null: false
  field :creator, Types::UserType,                                    null: false
  field :resolved, GraphQL::Types::ISO8601DateTime,                   null: true
  field :last_updated, GraphQL::Types::ISO8601DateTime,               null: true
  field :due, GraphQL::Types::ISO8601DateTime,                        null: true
  field :priority,  Integer,                                          null: false
  field :history, [Types::HistoryType],                               null: true
  field :comments_and_correspondence, [Types::AttachmentType],        null: true
  field :custom_fields_and_values, [Types::CustomFieldAndValueType],  null: true
  field :refers_to, [Types::TicketType],                              null: true
  field :referred_to_by, [Types::TicketType],                         null: true
  field :depends_on, [Types::TicketType],                             null: true
  field :depended_on_by, [Types::TicketType],                         null: true
  field :parents, [Types::TicketType],                                null: true
  field :children, [Types::TicketType],                               null: true
  field :reminders, [Types::TicketType],                              null: true
  field :no_reminder, Boolean,                                        null: false

  field :custom_field_value, Types::CustomFieldAndValueType, null: true do
    argument :field_name, String, required: true
  end

  def no_reminder
    self.object.no_reminder?
  end

  def custom_field_value(field_name:)
    field = self.object.custom_fields.where(name: field_name).limit(1)&.first
    return nil unless field

    { name: field.name, value: field.value_for(object_id: self.object.id) }
  end

  def custom_fields_and_values
    self.object.custom_fields_and_values.map do |name, value|
      { name: name, value: value }
    end
  end
end
