json.summary "#{pluralize @requests.size, "task"} waiting for a client's approval"
json.approvals @requests do |request|
  json.task agent_ref(request.task)
  json.client request.task.client&.name
  json.asked request.note
  json.asked_at request.created_at
  json.approvers Approvals::Request.approvers_for(request.task).map(&:name)
end
