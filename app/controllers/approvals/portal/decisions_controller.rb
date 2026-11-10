module Approvals
  module Portal
    # A client's answer to an ask for approval, from the task's side sheet in the portal or through
    # their own agent: approve, or say what should change. Only someone who can approve for their
    # company, on a task they see.
    class DecisionsController < ::Portal::BaseController
      agent_tool :portal_approvals, on: :index, title: "What's waiting for your approval",
        description: "The tasks the team has asked you to approve and that you haven't answered, with what they asked. Empty unless you can approve for your company (portal_me)."
      agent_tool :portal_decide_approval, on: :create, title: "Approve a task, or ask for changes",
        description: "Your answer on a task waiting for your approval (its id, from portal_approvals). decision: approve, or changes with what should change in comment (a comment on an approval is optional). The team sees it on the task.",
        params: { decision: %w[approve changes], comment: "string" },
        confirm: "It answers for the person’s company, in their name. Show them the task and your answer first."

      before_action { head :not_found unless Runwell::Plugins.enabled?(:approvals) }

      def index
        @requests = Request.waiting_on(current_contact).includes(task: :work).to_a
        respond_to do |format|
          format.json
          format.html { redirect_to portal_tasks_path }
        end
      end

      def create
        task = current_contact.portal_tasks.find(params[:task_id])
        request = Request.pending.find_by(task_id: task.id) or raise Request::Refused, "This isn’t waiting for an answer any more."
        request.decide!(params[:decision], by: current_contact, comment: params[:comment], source: Current.client_agent? ? "agent" : "portal")
        redirect_back fallback_location: portal_tasks_path(task: task.id, status: "all"), notice: request.state == "approved" ? "Approved. Thank you." : "Sent. We’ll make the changes."
      rescue Request::Refused => error
        redirect_back fallback_location: portal_tasks_path(task: params[:task_id], status: "all"), alert: error.message
      end
    end
  end
end
