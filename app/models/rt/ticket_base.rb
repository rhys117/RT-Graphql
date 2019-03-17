class RT::TicketBase < ActiveRecord::Base
  establish_connection :request_tracker
  self.table_name = 'tickets'
  self.inheritance_column = :_type_disabled

  LINKS_INVERTED_VALUES = { 'RefersTo' => 'ReferredToBy', 'ReferredToBy' => 'RefersTo',
                            'DependsOn' => 'DependedOnBy', 'DependedOnBy' => 'DependsOn',
                            'Child' => 'MemberOf', 'MemberOf' => 'Child' }.freeze

  belongs_to :queue_obj, class_name: 'Queue', foreign_key: :queue

  has_many :custom_fields, class_name: 'ObjectCustomFieldValue', foreign_key: :objectid

  has_many :groups, class_name: 'Group', foreign_key: :instance
  has_one :requestor_group, -> { where type: 'Requestor' }, class_name: 'Group', foreign_key: :instance
  has_many :requestors, through: :requestor_group, class_name: 'User', source: :users

  # Below does not account for merged tickets transactions - If added remove custom methods below
=begin
    has_many :transactions, class_name: 'Transaction', foreign_key: :objectid
    has_many :attachments, through: :transactions, class_name: 'Attachment', source: :attachment
    has_many :comment_transactions, -> { where "type = ? OR type = ?", 'Comment', 'Create' }, class_name: 'Transaction', foreign_key: :objectid
    has_many :comments, through: :comment_transactions, class_name: 'Attachment', source: :attachment
=end

  has_one :owner_obj, class_name: 'User', primary_key: :owner, foreign_key: :id
  has_one :creator, class_name: 'User', primary_key: :creator, foreign_key: :id
  has_one :last_updated_by, class_name: 'User', primary_key: :lastupdatedby, foreign_key: :id

  alias_attribute :effective_id, :effectiveid
  alias_attribute :last_updated, :lastupdated

  def merged_ticket_ids
    RT::Ticket.select(:id).unscoped.where(effectiveid: id)
  end

  def transactions
    RT::Transaction.where(objectid: merged_ticket_ids).where.not(objecttype: 'RT::Group').order(:id)
  end

  alias_method :history, :transactions

  def transaction_ids
    transactions.select(:id)
  end

  def attachments
    RT::Attachment.where("transactionid IN (?)", transaction_ids.where(objecttype: 'RT::Ticket').ids)
  end

  def comments
    RT::Attachment.where("transactionid IN (?)", transaction_ids.where("objecttype = ? AND (type = ? OR type = ?)",
                                                                       'RT::Ticket', 'Comment', 'Create').ids)
  end

  def correspondence
    RT::Attachment.where("transactionid IN (?)", transaction_ids.where("objecttype = ? AND type = ?",
                                                                       'RT::Ticket', 'Correspond').ids)
  end

  def comments_and_correspondence
    RT::Attachment.where("transactionid IN (?)", transaction_ids.where("objecttype = ? AND (type = ? OR type = ? OR type = ?)",
                                                                        'RT::Ticket', 'Comment', 'Correspond', 'Create').ids)
  end

  def latest_update
    RT::Attachment.find_by_transactionid(transaction_ids.where("objecttype = ? AND (type = ? OR type = ? OR type = ?)",
                                                               'RT::Ticket', 'Comment', 'Correspond', 'Create').order(:id).last.id)
  end

  # This setup is to avoid stack to deep errors due to RT database structure
  def queue
    queue_obj
  end

  def owner
    owner_obj
  end
end