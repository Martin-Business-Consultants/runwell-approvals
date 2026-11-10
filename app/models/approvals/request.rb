module Approvals
  # One ask for a client's approval of a task. Its states and every move between them live here;
  # pages, the portal and the tools ask it, never keep a copy.
  #
  #   pending -> approved | changes_requested   (someone at the client who can approve, in the portal)
  #   pending -> withdrawn                      (the team)
  #
  # A task has at most one pending ask. A decision is also a message on the task's discussion, in
  # the decider's name, so whoever is on the task is told the way they are of any reply.
  class Request < ApplicationRecord
    self.table_name = "approvals_requests"

    STATES = %w[pending approved changes_requested withdrawn].freeze
    DECISIONS = { "approve" => "approved", "changes" => "changes_requested" }.freeze

    class Refused < StandardError; end

    belongs_to :task
    belongs_to :requested_by, class_name: "User", optional: true
    belongs_to :decided_by, class_name: "User", optional: true

    validates :state, inclusion: { in: STATES }
    validates :note, :comment, length: { maximum: 500 }
    normalizes :note, :comment, with: ->(text) { text.to_s.squish.presence }

    scope :pending, -> { where(state: "pending") }
    scope :newest_first, -> { order(created_at: :desc, id: :desc) }

    class << self
      # Who at a task's client can decide on it: they can approve for their company, can sign in to
      # the portal, and see the task there.
      def approvers_for(task)
        return [] unless task.client

        Contact.with_portal_access.where(client_id: task.client_id, can_approve: true).order(:name).select { it.portal? && it.sees?(task) }
      end

      # Why a task can't be put to its client, or nil when it can.
      def refusal_for(task)
        if !task.client || !task.client_visible? then "Show this to the client first: they can only approve what they can see."
        elsif pending.exists?(task_id: task.id) then "It’s already waiting for their approval."
        elsif approvers_for(task).empty? then "Nobody at #{task.client.name} can approve yet: switch on Can approve for a contact who has portal access and sees this."
        end
      end

      # Puts a task to its client for approval, and emails their approvers.
      def ask!(task:, by:, note: nil)
        refusal = refusal_for(task)
        raise Refused, refusal if refusal

        transaction do
          create!(task: task, requested_by: by&.person, note: note).tap do |request|
            task.record_event!("task.approval_requested", payload: { note: request.note }.compact)
          end
        end.tap { |request| request.tell_approvers }
      end

      # The asks waiting on this contact: pending, on tasks they see, and theirs to decide.
      def waiting_on(contact)
        return none unless contact.can_approve?

        pending.where(task_id: contact.portal_tasks.select(:id)).newest_first
      end

      def latest_for(task) = where(task_id: task.id).newest_first.first
    end

    def pending? = state == "pending"
    def state_label = { "pending" => "Awaiting approval", "approved" => "Approved", "changes_requested" => "Changes requested", "withdrawn" => "Withdrawn" }.fetch(state)

    def decidable_by?(contact) = pending? && contact.can_approve? && contact.portal? && contact.client_id == task.client_id && contact.sees?(task)

    # A contact's answer: "approve", or "changes" with what should change. It goes on the task's
    # discussion in their name (which tells the team) and into its history.
    def decide!(decision, by:, comment: nil, source: "portal")
      outcome = DECISIONS[decision.to_s] or raise Refused, "Say approve or changes."
      raise Refused, "This isn’t waiting for an answer any more." unless pending?
      raise Refused, "Only someone who can approve for #{task.client.name} can answer this." unless decidable_by?(by)
      comment = comment.to_s.squish.presence
      raise Refused, "Say what should change." if outcome == "changes_requested" && comment.nil?

      transaction do
        update!(state: outcome, decided_by: by, decided_at: Time.current, comment: comment)
        words = outcome == "approved" ? [ "Approved.", comment ].compact.join(" ") : "Changes needed: #{comment}"
        task.notes.create!(body: words, kind: "internal", client_visible: true, author: by, source: source)
        task.record_event!(outcome == "approved" ? "task.approved" : "task.changes_requested", actor: by, source: source, payload: { comment: comment }.compact)
      end
      self
    end

    # The team takes the ask back: nothing is left for the client to answer.
    def withdraw!
      raise Refused, "It isn’t waiting for an answer any more." unless pending?

      transaction do
        update!(state: "withdrawn")
        task.record_event!("task.approval_withdrawn")
      end
      self
    end

    # Emails each approver who still wants the portal's mail (the core's Notice says who can be
    # reached).
    def tell_approvers
      reachable = Notice.reachable_contacts(task.client)
      (self.class.approvers_for(task) & reachable).each { Approvals::Mailer.with(request: self, contact: it).asked.deliver_later }
    end
  end
end
