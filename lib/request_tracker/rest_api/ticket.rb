module RT::REST
  class Ticket
    LOG = Rails.logger

    attr_reader :id

    def initialize(id:, session: RT::REST::Session.new)
      @session = session.client
      @id = id
    end

    def self.create(queue_name:, subject:, owner_name: 'Nobody', initial_comment: '', session: RT::REST::Session.new)
      client = session.client
      id = client.create(Queue:          queue_name,
                         Owner:          owner_name,
                         Text:           '', # I add a comment instead because text here doesn't add linebreaks
                         Subject:        subject,)

      rest_ticket = RT::REST::Ticket.new(id: id, session: session)
      rest_ticket.comment(text: initial_comment) unless initial_comment.empty?

      RT::Ticket.find(id)
    end

    def change_owner(new_owner:)
      raise "RT::REST::Ticket.change_owner Invalid username: #{new_owner}" if RT::User.find_by_name(new_owner).nil?

      # return true if already owner
      return true if RT::Ticket.find(@id).owner.name == new_owner

      response = @session.edit(id: @id,
                               owner: "#{new_owner}")
      response.to_s.downcase.include?('200 ok')
    end

    def edit(attributes: {}, custom_fields: {})
      unless attributes.is_a?(Hash) && custom_fields.is_a?(Hash)
        raise "Attributes and custom_fields must be supplied as hash formats"
      end

      check_valid_attributes(attributes: attributes, custom_fields: custom_fields)

      prepared_hash = {}
      prepared_hash[:id] = @id
      attributes.map { |name, value| prepared_hash[name] = value }
      custom_fields.map { |name, value| prepared_hash["CF.{#{name}}".to_sym] = value }

      response = @session.edit(prepared_hash)
      response.to_s.downcase.include?('200 ok')
    end

    def comment(text:)
      @session.comment(id: @id, Text: text)
    end

    private

    def check_valid_attributes(attributes: {}, custom_fields: {})
      ticket = RT::Ticket.find(@id)
      raise "No ticket matching id" unless ticket

      attributes.each do |attribute, _|
        raise "#{attribute} is not known to ticket" unless ticket.respond_to?(attribute)
      end

      available_custom_fields = ticket.custom_fields.pluck(:name)
      custom_fields.each do |field, _|
        raise "#{field} not available to ticket" unless available_custom_fields.include?(field)
      end

      true
    end
  end
end