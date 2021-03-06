require 'search_object/plugin/graphql'

class Resolvers::TicketsSearch
  include SearchObject.module(:graphql)

  description "Returns tickets matching query."

  def self.with_scope(get_scope)
    Class.new(self) do
      scope do
        # This adds support for dynamic and static scopes
        if get_scope.respond_to? :call
          get_scope.call(object, filters, context)
        else
          get_scope
        end
      end
    end
  end

  type types[Types::TicketType]

  scope do
    object.respond_to?(:tickets) ? object.tickets : RT::Ticket.all
  end

  # inline input type definition for the advance filter
  class TicketFilter < ::Types::BaseInputObject
    argument :OR, [self], required: false
    argument :status, String, required: false
    argument :ownerId, Integer, required: false
  end

  # when "filter" is passed "apply_filter" would be called to narrow the scope
  option :filter, type: TicketFilter, with: :apply_filter

  # apply_filter recursively loops through "OR" branches
  # WARNING: .with_scope can be overridden by filters
  def apply_filter(scope, value)
    branches = normalize_filters(value).reduce { |a, b| a.or(b) }
    scope.merge branches
  end

  def normalize_filters(value, branches = [])
    scope = RT::Ticket.all
    scope = scope.where(status: value['status']) if value['status']
    scope = scope.where(owner: value['ownerId']) if value['ownerId']

    branches << scope

    value['OR'].reduce(branches) { |s, v| normalize_filters(v, s) } if value['OR'].present?

    branches
  end
end