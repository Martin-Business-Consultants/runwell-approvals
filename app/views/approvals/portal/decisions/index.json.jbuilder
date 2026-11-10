json.summary @requests.any? ? "#{pluralize @requests.size, "task"} waiting for your approval" : "Nothing is waiting for your approval."
json.approvals @requests do |request|
  json.task_id request.task_id
  json.title request.task.title
  json.asked request.note
  json.asked_at request.created_at
  json.work request.task.work&.title
  json.url portal_tasks_url(task: request.task_id, status: "all")
end
