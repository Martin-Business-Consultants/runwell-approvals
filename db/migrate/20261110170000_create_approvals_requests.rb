# One ask for a client's approval of a task: who asked and for what, its state, and, once decided,
# who at the client decided, when, and what they said.
class CreateApprovalsRequests < ActiveRecord::Migration[8.1]
  def change
    create_table :approvals_requests do |t|
      t.integer :task_id, null: false
      t.integer :requested_by_id
      t.string :note
      t.string :state, default: "pending", null: false
      t.integer :decided_by_id
      t.datetime :decided_at
      t.string :comment
      t.timestamps
    end
    add_index :approvals_requests, %i[task_id state]
  end
end
