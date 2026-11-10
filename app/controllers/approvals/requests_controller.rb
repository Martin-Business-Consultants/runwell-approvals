module Approvals
  # Asking a client to approve a task, and taking the ask back (its card in the task's sidebar),
  # with every ask still waiting listed for agents.
  class RequestsController < ApplicationController
    allow_staff
    agent_tool :list_approvals, on: :index, title: "What's waiting for a client's approval",
      description: "Every task put to its client that they haven't answered yet, oldest first: the task, the client, what was asked and who can decide."
    agent_tool :ask_for_approval, on: :create, title: "Ask the client to approve a task",
      description: "Puts a task shown to the client to them for a yes: their people who can approve are emailed and decide in the portal (approve, or ask for changes), and the answer lands on the task's discussion. note: one line saying what you need a yes on.",
      params: { request: { note: "string" } }, confirm: "The client’s approvers are emailed and asked to decide in the portal.", next_tools: %i[list_approvals]
    agent_tool :withdraw_approval, on: :destroy, title: "Take back an ask for approval",
      description: "The task stops waiting for the client's answer. Nothing is sent."

    def index
      @requests = Request.pending.order(:created_at).includes(task: %i[client work]).to_a
      respond_to do |format|
        format.json
        format.html { redirect_to main_app.tasks_path }
      end
    end

    def create
      task = Task.find(params[:task_id])
      request = Request.ask!(task: task, by: Current.user, note: params.dig(:request, :note))
      redirect_back fallback_location: main_app.task_path(task), notice: "Asked #{Request.approvers_for(task).map(&:name).to_sentence} to approve it. #{task.client.name} decides in the portal."
    rescue Request::Refused => error
      redirect_back fallback_location: main_app.task_path(params[:task_id]), alert: error.message
    end

    def destroy
      task = Task.find(params[:task_id])
      request = Request.pending.find_by(task_id: task.id)
      return redirect_back(fallback_location: main_app.task_path(task), alert: "It isn’t waiting for an answer.") unless request

      request.withdraw!
      redirect_back fallback_location: main_app.task_path(task), notice: "Taken back: #{task.client.name} is no longer asked to approve it."
    end
  end
end
